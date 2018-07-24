

class kota::features {


	# -----------------------------------------
	# Configure Windows features (IIS)
	# -----------------------------------------
	if ($::asset in ['FRONT','ALL']) {

		# Install IIS core application server
		# -----------------------------------
		dism { 'IIS-WebServerRole':
			ensure => present,
		}
		dism { 'IIS-WebServer':
			ensure => present,
			require => Dism['IIS-WebServerRole'],
		}

		# Install IIS Common HTTP features 
		# --------------------------------
		
		dism { 'IIS-CommonHttpFeatures':
			ensure => present,
			require => Dism['IIS-WebServerRole'],
		}
		
		dism { 'IIS-DefaultDocument':
			ensure => present,
			require => Dism['IIS-CommonHttpFeatures'],
		}
		
		dism { 'IIS-HttpErrors':
			ensure => present,
			require => Dism['IIS-CommonHttpFeatures'],
		}

		dism { 'IIS-StaticContent':
			ensure => present,
			require => Dism['IIS-CommonHttpFeatures'],
		}

		dism { 'IIS-HttpRedirect':
			ensure => present,
			require => Dism['IIS-CommonHttpFeatures'],
		}


		# Install IIS Health & Diagnostics features 
		# ------------------------------------------

		dism { 'IIS-HealthAndDiagnostics':
			ensure => present,
			require => Dism['IIS-WebServerRole'],
		}

		dism { 'IIS-HttpLogging':
			ensure => present,
			require => Dism['IIS-HealthAndDiagnostics'],
		}

		dism { 'IIS-LoggingLibraries':
			ensure => present,
			require => Dism['IIS-HealthAndDiagnostics'],
		}

		dism { 'IIS-RequestMonitor':
			ensure => present,
			require => Dism['IIS-HealthAndDiagnostics'],
		}

		dism { 'IIS-HttpTracing':
			ensure => present,
			require => Dism['IIS-HealthAndDiagnostics'],
		}


		# Install IIS Preformance features 
		# ---------------------------------

		dism { 'IIS-Performance':
			ensure => present,
			require => Dism['IIS-WebServerRole'],
		}

		dism { 'IIS-HttpCompressionStatic':
			ensure => present,
			require => Dism['IIS-Performance'],
		}

		dism { 'IIS-HttpCompressionDynamic':
			ensure => present,
			require => Dism['IIS-Performance'],
		}



		# Install IIS Security features 
		# ---------------------------------
		
		dism { 'IIS-Security':
			ensure => present,
			require => Dism['IIS-WebServerRole'],
		}

		dism { 'IIS-RequestFiltering':
			ensure => present,
			require => Dism['IIS-Security'],
		}

		dism { 'IIS-URLAuthorization':
			ensure => present,
			require => Dism['IIS-Security'],
		}

		dism { 'IIS-WindowsAuthentication':
			ensure => present,
			require => Dism['IIS-Security'],
		}


		# Install .NET 4.5 Framework Features
		# -------------------------------------
		dism { 'NetFx4Extended-ASPNET45':
			ensure => present,
			require => Dism['IIS-WebServer'],
		}


		# Install WCF Services
		# ---------------------------

		dism { 'WAS-WindowsActivationService':
			ensure => present,
			require => Dism['IIS-WebServer'],
		}

		dism { 'WAS-ConfigurationAPI':
			ensure => present,
			require => Dism['WAS-WindowsActivationService'],
		}
		
		dism { 'WAS-ProcessModel':
			ensure => present,
			require => Dism['WAS-ConfigurationAPI'],
		}

		dism { 'WCF-Services45':
			ensure => present,
			require => Dism['WAS-ProcessModel'],
		}

		dism { 'WCF-HTTP-Activation45':
			ensure => present,
			require => Dism['WCF-Services45'],
		}


		# Install IIS Application Development features 
		# ---------------------------------------------
		
		dism { 'IIS-ApplicationDevelopment':
			ensure => present,
			require => [ Dism['IIS-WebServerRole'], Dism['NetFx4Extended-ASPNET45'] ],
		}

		dism { 'IIS-NetFxExtensibility':
			ensure => present,
			require => Dism['IIS-ApplicationDevelopment'],
		}

		dism { 'IIS-NetFxExtensibility45':
			ensure => present,
			require => Dism['IIS-ApplicationDevelopment'],
		}

		dism { 'IIS-ApplicationInit':
			ensure => present,
			require => Dism['IIS-ApplicationDevelopment'],
		}

		dism { 'IIS-ASP':
			ensure => present,
			require => Dism['IIS-ApplicationDevelopment'],
		}

		dism { 'IIS-ASPNET45':
			ensure => present,
			require => Dism['IIS-NetFxExtensibility45'],
		}

		dism { 'IIS-CGI':
			ensure => present,
			require => Dism['IIS-ApplicationDevelopment'],
		}

		dism { 'IIS-ISAPIExtensions':
			ensure => present,
			require => Dism['IIS-ApplicationDevelopment'],
		}

		dism { 'IIS-ISAPIFilter':
			ensure => present,
			require => Dism['IIS-ApplicationDevelopment'],
		}

		dism { 'IIS-ASPNET':
			ensure => present,
			require => Dism['IIS-NetFxExtensibility', 'IIS-ISAPIFilter', 'IIS-ISAPIExtensions'],
		}

		dism { 'IIS-WebSockets':
			ensure => present,
			require => Dism['IIS-ApplicationDevelopment'],
		}
		

		# Install IIS Management tool
		# ---------------------------
		dism { 'IIS-WebServerManagementTools':
			ensure => present,
			require => Dism['IIS-WebServer'],
		}
		dism { 'IIS-ManagementConsole':
			ensure => present,
			require => Dism['IIS-WebServerManagementTools'],
		}
		dism { 'IIS-ManagementScriptingTools':
			ensure => present,
			require => Dism['IIS-WebServerManagementTools'],
		}
		dism { 'IIS-ManagementService':
			ensure => present,
			require => Dism['IIS-WebServerManagementTools'],
		}

		dism { 'IIS-IIS6ManagementCompatibility':
			ensure => present,
			require => Dism['IIS-WebServerManagementTools'],
		}
		dism { 'IIS-WMICompatibility':
			ensure => present,
			require => Dism['IIS-WebServerManagementTools'],
		}
		dism { 'IIS-Metabase':
			ensure => present,
			require => Dism['IIS-WebServerManagementTools'],
		}
		dism { 'IIS-LegacyScripts':
			ensure => present,
			require => Dism['IIS-IIS6ManagementCompatibility', 'IIS-Metabase', 'IIS-WMICompatibility'],
		}
	}
}

