
class kota::groups ($deployment_users, $batch_users, $iis_users) {

	# ------------------------------
	# Set all users
	# ------------------------------

	$admin_users_Deployment = $deployment_users
	$admin_users_Batch = $batch_users
	$admin_users_IIS = $iis_users


	# -----------------------------------------	
	# Add users to 'Administrators' group
	# -----------------------------------------

	if ($::asset == 'FRONT') {
		$administrator_members_array = concat($admin_users_Deployment, $admin_users_IIS)
	}
	elsif ($::asset == 'BATCH') {
		$administrator_members_array = concat($admin_users_Deployment, $admin_users_Batch)
	}
	elsif ($::asset == 'ALL') {
		$administrator_members_array = concat($admin_users_Deployment, $admin_users_Batch, $admin_users_IIS)
	}

	group { 'Admin':
		name => 'Administrators',
		ensure   => present,
		auth_membership => false,
		members  => [$administrator_members_array],
	}
}
