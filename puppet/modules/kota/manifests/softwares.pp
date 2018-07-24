
class kota::softwares ( $environment, $sourcepath, $destinationpath ) {
	
	# ------------------------------
	# Set ressources path
	# ------------------------------
	$soft_source_path = $sourcepath
	$res_dest = $destinationpath


	# ------------------------------
	# Set all softwares to install
	# ------------------------------
		
	$soft_npp = 'npp-6.5.3.exe'
	
	# -----------------------------------------	
	# Add softwares 
	# -----------------------------------------

	exec { $soft_npp:
		command => "$soft_source_path\\$soft_npp /S",
		path    => ['C:\Windows\System32'],
	}
}

