
class kota::configuration ($environment, $weblog_path, $webroot_path, $website_path, $website_http_port, $website_https_port, $certificate_thumbprint) {

	# -----------------------------------------
	# Configure WinRM
	# -----------------------------------------
	service { "firewall_start":
		name => 'MpsSvc',
		ensure => 'running',
	}


	$type_exec = "exec" 
	$defaults_winrm = { path => ['C:\Windows\System32'], }

	$resources_winrm_common = {
		'winrm_config_01' => {
				command => 'winrm.cmd set winrm/config @{MaxTimeoutms="600000";MaxBatchItems="512000";MaxEnvelopeSizekb="2048"}',
				require => Service['firewall_start'],
			},
		'winrm_config_02' => {
				command => 'winrm.cmd set winrm/config/service @{AllowUnencrypted="false";MaxPacketRetrievalTimeSeconds="600";EnumerationTimeoutms="600000"}',
				require => Exec['winrm_config_01'],
			},
		'winrm_config_03'  => {
				command => 'winrm.cmd set winrm/config/winrs @{MaxMemoryPerShellMB="2048";MaxProcessesPerShell="64";MaxShellsPerUser="20"}',
				require => Exec['winrm_config_02'],
			},
	}

	# -----------------------------------------
	# Configure IIS 
	# -----------------------------------------

	if ($::asset in ['FRONT','ALL']) {


		# Relocation of IIS content directory
		# https://support.microsoft.com/en-us/kb/2752331
		# ------------------------------------------------------

		# Stop all IIS services
		exec { 'IIS_Stop' :
			command => 'iisreset /STOP',
			path    => ['C:\Windows\System32'],
			require => Class['kota::features'],
		}


		# Copy all content
		file { 'Inetsrv':
			path         => "${webroot_path}\\Inetsrv",
			ensure       => directory,
			source       => 'C:\inetpub',
			source_permissions => ignore,
			recurse      => true,
			require => Exec['IIS_Stop'],
		}


		# Move Application Pool isolation directory 
		$registry_entry_001 = 'HKLM:\System\CurrentControlSet\Services\WAS\Parameters\ConfigIsolationPath'
		registry_value { "${registry_entry_001}":
			ensure => present,
			type   => string,
			data   => "${webroot_path}\\Inetsrv\\temp\\appPools",
			require => File['Inetsrv'],
		}

		# Move logfile directories
		exec { 'iis_config_000' :
			command => "appcmd.exe set config -section:system.applicationHost/sites /siteDefaults.logFile.enabled:True /commit:apphost",
			path    => ['C:\Windows\System32', 'C:\Windows\System32\inetsrv', 'C:\Windows\System32\WindowsPowerShell\v1.0'],
			require => Registry_value["${registry_entry_001}"],
		}

		exec { 'iis_config_001' :
			command => "appcmd.exe set config -section:system.applicationHost/sites /siteDefaults.logFile.logFormat:W3C /commit:apphost",
			path    => ['C:\Windows\System32', 'C:\Windows\System32\inetsrv', 'C:\Windows\System32\WindowsPowerShell\v1.0'],
			require => Exec['iis_config_000'],
		}

		exec { 'iis_config_002' :
			command => "appcmd.exe set config -section:system.applicationHost/sites /siteDefaults.logFile.directory:\"${weblog_path}\" /commit:apphost",
			path    => ['C:\Windows\System32', 'C:\Windows\System32\inetsrv', 'C:\Windows\System32\WindowsPowerShell\v1.0'],
			require => Exec['iis_config_001'],
		}

		exec { 'iis_config_003' :
			command => "appcmd.exe set config -section:system.applicationHost/sites /siteDefaults.traceFailedRequestsLogging.enabled:True /commit:apphost",
			path    => ['C:\Windows\System32', 'C:\Windows\System32\inetsrv', 'C:\Windows\System32\WindowsPowerShell\v1.0'],
			require => Exec['iis_config_002'],
		}

		exec { 'iis_config_004' :
			command => "appcmd.exe set config -section:system.applicationHost/sites /siteDefaults.traceFailedRequestsLogging.maxLogFiles:10 /commit:apphost",
			path    => ['C:\Windows\System32', 'C:\Windows\System32\inetsrv', 'C:\Windows\System32\WindowsPowerShell\v1.0'],
			require => Exec['iis_config_003'],
		}

		exec { 'iis_config_005' :
			command => "appcmd.exe set config -section:system.applicationHost/sites /siteDefaults.traceFailedRequestsLogging.directory:\"${weblog_path}\\FailedReqLogFiles\" /commit:apphost",
			path    => ['C:\Windows\System32', 'C:\Windows\System32\inetsrv', 'C:\Windows\System32\WindowsPowerShell\v1.0'],
			require => Exec['iis_config_004'],
		}

		exec { 'iis_config_006' :
			command => "appcmd.exe set config -section:system.applicationHost/log /centralBinaryLogFile.directory:\"${webroot_path}\\Inetsrv\\logs\\logfiles\" /commit:apphost",
			path    => ['C:\Windows\System32', 'C:\Windows\System32\inetsrv', 'C:\Windows\System32\WindowsPowerShell\v1.0'],
			require => Exec['iis_config_005'],
		}

		exec { 'iis_config_007' :
			command => "appcmd.exe set config -section:system.applicationHost/log /centralW3CLogFile.directory:\"${webroot_path}\\Inetsrv\\logs\\logfiles\" /commit:apphost",
			path    => ['C:\Windows\System32', 'C:\Windows\System32\inetsrv', 'C:\Windows\System32\WindowsPowerShell\v1.0'],
			require => Exec['iis_config_006'],
		}

		# Move config history location, temporary files
		exec { 'iis_config_008' :
			command => "appcmd.exe set config -section:system.applicationhost/configHistory /path:\"${webroot_path}\\Inetsrv\\history\" /commit:apphost",
			path    => ['C:\Windows\System32', 'C:\Windows\System32\inetsrv', 'C:\Windows\System32\WindowsPowerShell\v1.0'],
			require => Exec['iis_config_007'],
		}

		exec { 'iis_config_009' :
			command => "appcmd.exe set config -section:system.webServer/asp /cache.disktemplateCacheDirectory:\"${webroot_path}\\Inetsrv\\temp\\ASP Compiled Templates\" /commit:apphost",
			path    => ['C:\Windows\System32', 'C:\Windows\System32\inetsrv', 'C:\Windows\System32\WindowsPowerShell\v1.0'],
			require => Exec['iis_config_008'],
		}

		exec { 'iis_config_010' :
			command => "appcmd.exe set config -section:system.webServer/httpCompression /directory:\"${webroot_path}\\Inetsrv\\temp\\IIS Temporary Compressed Files\" /commit:apphost",
			path    => ['C:\Windows\System32', 'C:\Windows\System32\inetsrv', 'C:\Windows\System32\WindowsPowerShell\v1.0'],
			require => Exec['iis_config_009'],
		}

		# Move custom error locations
		exec { 'iis_config_011' :
			command => "appcmd.exe set config -section:httpErrors /[statusCode='401'].prefixLanguageFilePath:\"${webroot_path}\\Inetsrv\\custerr\"",
			path    => ['C:\Windows\System32', 'C:\Windows\System32\inetsrv', 'C:\Windows\System32\WindowsPowerShell\v1.0'],
			require => Exec['iis_config_010'],
		}

		exec { 'iis_config_012' :
			command => "appcmd.exe set config -section:httpErrors /[statusCode='403'].prefixLanguageFilePath:\"${webroot_path}\\Inetsrv\\custerr\"",
			path    => ['C:\Windows\System32', 'C:\Windows\System32\inetsrv', 'C:\Windows\System32\WindowsPowerShell\v1.0'],
			require => Exec['iis_config_011'],
		}

		exec { 'iis_config_013' :
			command => "appcmd.exe set config -section:httpErrors /[statusCode='404'].prefixLanguageFilePath:\"${webroot_path}\\Inetsrv\\custerr\"",
			path    => ['C:\Windows\System32', 'C:\Windows\System32\inetsrv', 'C:\Windows\System32\WindowsPowerShell\v1.0'],
			require => Exec['iis_config_012'],
		}

		exec { 'iis_config_014' :
			command => "appcmd.exe set config -section:httpErrors /[statusCode='405'].prefixLanguageFilePath:\"${webroot_path}\\Inetsrv\\custerr\"",
			path    => ['C:\Windows\System32', 'C:\Windows\System32\inetsrv', 'C:\Windows\System32\WindowsPowerShell\v1.0'],
			require => Exec['iis_config_013'],
		}

		exec { 'iis_config_015' :
			command => "appcmd.exe set config -section:httpErrors /[statusCode='406'].prefixLanguageFilePath:\"${webroot_path}\\Inetsrv\\custerr\"",
			path    => ['C:\Windows\System32', 'C:\Windows\System32\inetsrv', 'C:\Windows\System32\WindowsPowerShell\v1.0'],
			require => Exec['iis_config_014'],
		}

		exec { 'iis_config_016' :
			command => "appcmd.exe set config -section:httpErrors /[statusCode='412'].prefixLanguageFilePath:\"${webroot_path}\\Inetsrv\\custerr\"",
			path    => ['C:\Windows\System32', 'C:\Windows\System32\inetsrv', 'C:\Windows\System32\WindowsPowerShell\v1.0'],
			require => Exec['iis_config_015'],
		}

		exec { 'iis_config_017' :
			command => "appcmd.exe set config -section:httpErrors /[statusCode='500'].prefixLanguageFilePath:\"${webroot_path}\\Inetsrv\\custerr\"",
			path    => ['C:\Windows\System32', 'C:\Windows\System32\inetsrv', 'C:\Windows\System32\WindowsPowerShell\v1.0'],
			require => Exec['iis_config_016'],
		}

		exec { 'iis_config_018' :
			command => "appcmd.exe set config -section:httpErrors /[statusCode='501'].prefixLanguageFilePath:\"${webroot_path}\\Inetsrv\\custerr\"",
			path    => ['C:\Windows\System32', 'C:\Windows\System32\inetsrv', 'C:\Windows\System32\WindowsPowerShell\v1.0'],
			require => Exec['iis_config_017'],
		}

		exec { 'iis_config_019' :
			command => "appcmd.exe set config -section:httpErrors /[statusCode='502'].prefixLanguageFilePath:\"${webroot_path}\\Inetsrv\\custerr\"",
			path    => ['C:\Windows\System32', 'C:\Windows\System32\inetsrv', 'C:\Windows\System32\WindowsPowerShell\v1.0'],
			require => Exec['iis_config_018'],
		}

		# Make sure Service Pack and Hotfix Installers know where the IIS root directories are 
		$registry_entry_002 = 'HKLM:\Software\Microsoft\inetstp\PathWWWRoot'
		registry_value { "${registry_entry_002}":
			ensure  => present,
			type    => string,
			data    => "${weblog_path}\\Inetsrv\\wwwroot",
			require => Exec['iis_config_019'],
		}

		$registry_entry_003 = 'HKLM:\Software\Wow6432Node\Microsoft\inetstp\PathWWWRoot'
		registry_value { "${registry_entry_003}":
			ensure  => present,
			type    => string,
			data    => "${weblog_path}\\Inetsrv\\wwwroot",
			require => Registry_value["${registry_entry_002}"],
		}

		# Modify Default LoggingDirectory
		#---------------------------------
		$registry_entry_006 = 'HKLM:\SOFTWARE\Microsoft\WebManagement\Server\LoggingDirectory'
		registry_value { "${registry_entry_006}":
			ensure  => present,
			type    => string,
			data    => "${weblog_path}\\wmsvc",
			require => Registry_value["${registry_entry_005}"],
		}

		# Remove default website + application pool
		# -----------------------------------------
		
		# Start all IIS services
		exec { 'IIS_Start' :
			command => 'iisreset /START',
			path    => ['C:\Windows\System32'],
			require => Exec['iis_config_101'],
		}
		
		iis::manage_site {'Default Web Site':
			ensure   => 'absent',
			require  => Exec['IIS_Start'],
		}

		iis::manage_app_pool {'DefaultAppPool':
			ensure   => 'absent',
			require  => Iis::Manage_site['Default Web Site'],
		}
		

		# Install Application Pool (since creation has been inactivated in XlDeploy)
		# ---------------------------------------------------------------------------

		$app_pool_name = "kota-ApplicationPool-${environment}"
		iis::manage_app_pool {"$app_pool_name":
			ensure                  => 'present',
			enable_32_bit           => false,
			managed_runtime_version => 'v4.0',
			managed_pipeline_mode   => 'Integrated',
			require                 => Iis::Manage_app_pool['DefaultAppPool'],
		}

		exec { 'iis_config_200' :
			command => "appcmd.exe set apppool ${app_pool_name} /processModel.idleTimeout:00:00:00",
			path    => ['C:\Windows\System32', 'C:\Windows\System32\inetsrv', 'C:\Windows\System32\WindowsPowerShell\v1.0'],
			require => Iis::Manage_app_pool["$app_pool_name"],
		}

		exec { 'iis_config_201' :
			command => "appcmd.exe set apppool ${app_pool_name} /processModel.maxProcesses:1",
			path    => ['C:\Windows\System32', 'C:\Windows\System32\inetsrv', 'C:\Windows\System32\WindowsPowerShell\v1.0'],
			require => Iis::Manage_app_pool["$app_pool_name"],
		}

		exec { 'iis_config_202' :
			command => "appcmd.exe set apppool ${app_pool_name} /recycling.periodicRestart.time:00:00:00",
			path    => ['C:\Windows\System32', 'C:\Windows\System32\inetsrv', 'C:\Windows\System32\WindowsPowerShell\v1.0'],
			require => Iis::Manage_app_pool["$app_pool_name"],
		}

		exec { 'iis_config_203' :
			command => "appcmd.exe set apppool ${app_pool_name} /autoStart:true",
			path    => ['C:\Windows\System32', 'C:\Windows\System32\inetsrv', 'C:\Windows\System32\WindowsPowerShell\v1.0'],
			require => Iis::Manage_app_pool["$app_pool_name"],
		}

		exec { 'iis_config_204' :
			command => "appcmd.exe set apppool ${app_pool_name} /startMode:AlwaysRunning",
			path    => ['C:\Windows\System32', 'C:\Windows\System32\inetsrv', 'C:\Windows\System32\WindowsPowerShell\v1.0'],
			require => Iis::Manage_app_pool["$app_pool_name"],
		}

		#exec { 'iis_config_205' :
		#	command => "appcmd.exe set apppool ${app_pool_name} /-recycling.periodicRestart.schedule.[value='01:00:00']",
		#	path    => ['C:\Windows\System32', 'C:\Windows\System32\inetsrv', 'C:\Windows\System32\WindowsPowerShell\v1.0'],
		#	returns  => [0, 4312],
		#	require => Iis::Manage_app_pool["$app_pool_name"],
		#}

		#exec { 'iis_config_206' :
		#	command => "appcmd.exe set apppool ${app_pool_name} /+recycling.periodicRestart.schedule.[value='01:00:00']",
		#	path    => ['C:\Windows\System32', 'C:\Windows\System32\inetsrv', 'C:\Windows\System32\WindowsPowerShell\v1.0'],
		#	require => Exec['iis_config_205'],
		#}

		exec { 'iis_config_207' :
			command => "appcmd.exe set config /commit:WEBROOT /section:machineKey /validation:SHA1",
			path    => ['C:\Windows\System32', 'C:\Windows\System32\inetsrv', 'C:\Windows\System32\WindowsPowerShell\v1.0'],
			require => Iis::Manage_app_pool["$app_pool_name"],
		}

		exec { 'iis_config_208' :
			command => "appcmd.exe set config /commit:WEBROOT /section:machineKey /validationKey:17F886457C978C6008B503AF9239FB3EF33271351B8B5467A0F215E311786DCEF4003A6F11D83BAED9EC12E807C4AE579C7022A3AC77BB0062F8FA298A3703D1",
			path    => ['C:\Windows\System32', 'C:\Windows\System32\inetsrv', 'C:\Windows\System32\WindowsPowerShell\v1.0'],
			require => Iis::Manage_app_pool["$app_pool_name"],
		}

		exec { 'iis_config_209' :
			command => "appcmd.exe set config /commit:WEBROOT /section:machineKey /decryption:AES",
			path    => ['C:\Windows\System32', 'C:\Windows\System32\inetsrv', 'C:\Windows\System32\WindowsPowerShell\v1.0'],
			require => Iis::Manage_app_pool["$app_pool_name"],
		}

		exec { 'iis_config_210' :
			command => "appcmd.exe set config /commit:WEBROOT /section:machineKey /decryptionKey:53709E17A14463D02E1FF0C52A5AB546BB2946E628D344F5",
			path    => ['C:\Windows\System32', 'C:\Windows\System32\inetsrv', 'C:\Windows\System32\WindowsPowerShell\v1.0'],
			require => Iis::Manage_app_pool["$app_pool_name"],
		}



		# Install Website (since creation has been inactivated in XlDeploy)
		# -----------------------------------------------------------------
		$website_name = "kotaWebSite-${environment}"
		
		if $environment != 'PROD' {
			$website_env_path = "${website_path}${environment}"
		}
		else {
			$website_env_path = "${website_path}"
		}

		iis::manage_site {"$website_name":
			ensure        => 'present',
			site_path     => "$website_env_path",
			app_pool      => "$app_pool_name",
			ip_address    => '*',
			port          => "$website_http_port",
			ssl           => false,
			require       => Iis::Manage_app_pool["$app_pool_name"],
		}
		
		if ("$certificate_thumbprint" != "") {
			iis::manage_binding {'ssl_port_binding':
				ensure                => 'present',
				site_name              => "$website_name",
				protocol               => 'https',
				port                   => "$website_https_port",
				ip_address             => '*',
				certificate_thumbprint => "$certificate_thumbprint",
				require_site           => true,
				require                => Iis::Manage_site["$website_name"],
			}
		}
	}
}
