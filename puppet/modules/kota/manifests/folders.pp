

class tomcat::folders ( $environment, $webrootfolder, $weblogfolder, $batchfolder, $importuser ) {

	# ---------------------------------
	# Define all directories to create
	# ---------------------------------
	$common_dirs_path = [ "$toolsfolder", "C:\\Temp" ]
	if $environment != 'PROD' {
		$webapppath = "${webappfolder}${environment}"
    $batchpath = "${batchfolder}${environment}"
		$import_share_name = "Import-${environment}"
	}
	else {
		$webapppath = "${webappfolder}"
		$batchpath = "${batchfolder}"
		$import_share_name = "Import"
	}

	$front_web_dirs_path = ["${webrootfolder}",  "${toolsfolder}", "${weblogfolder}",  "${weblogfolder}\\wmsvc"]
	$front_web_dirs_acl1 = 'IND\IIS_IUSRS'
	$front_web_dirs_acl2 = 'NETWORK SERVICE'
	$front_web_dirs_acl3 = "IIS AppPool\\KOTA-ApplicationPool-${environment}"

	$batch_core_dirs_path = ["${batchpath}", "${batchpath}\\Import", "${batchpath}\\Import\\Backup", "${batchpath}\\Export", "${batchpath}\\Export\\FSI", "${batchpath}\\Export\\Backup", "${toolsfolder}\\FtrPrivateKey"]

	$batch_imp_dirs_path = ["${batchpath}\\Import\\ISF"]
	$batch_imp_dirs_acl = $importuser

	# ------------------------------
	# Create all directories
	# ------------------------------
	
	# Create commons directories
	file { $common_dirs_path:
		ensure => 'directory',
		purge => false,
		recurse => false, 
	}

	# Create front application directories
	if ($::asset in ['FRONT','ALL']) {
		file { $front_web_dirs_path:
			ensure => 'directory',
			purge => false,
			recurse => false,
			require => File[$common_dirs_path],
		}
	}

	# Create batch (core) directories
	if ($::asset in ['BATCH','ALL']) {
		file { $batch_core_dirs_path:
			ensure => 'directory',
			purge => false,
			recurse => false,
			require => File[$common_dirs_path],
		}

		# Create batch (import) directories
		file { $batch_imp_dirs_path:
			ensure => 'directory',
			purge => false,
			recurse => false,
			require => File[$batch_core_dirs_path],
		}
	}

	# -----------------------------------------	
	# Add security rules to import directories
	# -----------------------------------------

	# Add access rights to front directories
	if ($::asset in ['FRONT','ALL']) {
		$app_pool_name = "Kota-ApplicationPool-${environment}"
		acl { $front_web_dirs_path:
			permissions => [
				{ identity => $front_web_dirs_acl1, rights => ['read','write','execute'] },
				{ identity => $front_web_dirs_acl2, rights => ['read','write','execute'] },
				{ identity => $front_web_dirs_acl3, rights => ['read','write','execute'] },
			],
			inherit_parent_permissions => true,
			require => [ File[$front_web_dirs_path], Iis::Manage_app_pool["$app_pool_name"] ],
		}
	
	}

	# Add access rights to batch import directories
	if ($::asset in ['BATCH','ALL']) {
		acl { $batch_imp_dirs_path:
			permissions => [
				{ identity => $batch_imp_dirs_acl, rights => ['read','write'] },
			],
			inherit_parent_permissions => true,
			require => File[$batch_imp_dirs_path],
		}

		# -----------------------------------------	
		# Create share folder
		# -----------------------------------------
		net_share { $batch_imp_dirs_path:
			name => "$import_share_name",
			ensure => 'present',
			maximumusers => 'unlimited',
			remark => 'Import folder for the application',
			path => "${batch_imp_dirs_path}",
			permissions => ["${importuser},change"],
			require => File["${batch_imp_dirs_path}"],
		}
	}
}
