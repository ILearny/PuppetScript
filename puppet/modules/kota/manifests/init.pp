class kota {
  	# -------------------------------------------------
	# Check environment & define common variables
	# -------------------------------------------------

	if ($environment == '') {
		fail( 'Environment variable must be set => (for exemple: [DEV | INT | PROD]' )
	}

	if ($::asset == 'FRONT') {
		info('Creating Front-Server configuration')
	}
	elsif ($::asset == 'BATCH') {
		info('Creating Batch-Server configuration')
	}
	elsif ($::asset == 'ALL') {
		info('Creating Batch & Front Server configuration')
	}
	else {
		fail( 'Asset type must have one of the following values => [FRONT | BATCH | ALL]' )
	}
  
  
  	$resourcespath = hiera('SoftwarePath')
	$toolspath = hiera('ToolsPath')
	$webapppath = hiera('WebAppFolder')
	
  	#------------------------
	# Create all folders
	#------------------------
  	$webrootpath = hiera('WebRootFolder')
	$weblogpath = hiera('WebLogFolder')
  	$batchpath = hiera('BatchRootFolder')
	$importfileuser = hiera('ImportUser')


	class { 'kota::folders':
		environment => $environment,
		webrootfolder => $webrootpath,
		weblogfolder => $weblogpath,
    		batchfolder => $batchpath,
		importuser => $importfileuser,
	}
  
  
  	#------------------------
	# Add all users to groups
	#------------------------
  	$admin_deployment_users=hiera('AdminUsersDeployment')
	$admin_batch_users=hiera('AdminUsersBatch')
	$admin_iis_users=hiera('AdminUsersIIS')
  
  	class { 'kota::groups':
		deployment_users => $admin_deployment_users,
		batch_users => $admin_batch_users,
		iis_users => $admin_iis_users,
	}
  
  	#-----------------------------
	# Enable all windows features
	#-----------------------------
	include kota::features
  
  
  	#------------------------
	# Install all softwares
	#------------------------
	class { 'kota::softwares':
		environment => $environment,
		sourcepath => $resourcespath,
		destinationpath => $toolspath,
	}
	
	#-----------------------------
	# Set server configuration
	#-----------------------------
	$http_port = hiera('HttpPort')
	$https_port = hiera('HttpsPort')
	if (hiera('Certificate') == '') {
		$Certificate = $::certificate
	}
	else {
		$Certificate = hiera('Certificate')
	}
	

	class { 'tomcat::configuration':
		environment => $environment,
		weblog_path => $weblogpath,
		webroot_path => $webrootpath,
		website_path => $webapppath,
		website_http_port => $http_port,
		website_https_port => $https_port,
		certificate_thumbprint => $Certificate,
	}
  
}
