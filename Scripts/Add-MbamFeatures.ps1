# Enable compliance and audit database
Enable-MbamDatabase -AccessAccount "VIAMONSTRA\MBAM_DB_RW" -ComplianceAndAudit -ConnectionString "Data Source=MBAM01.corp.viamonstra.com;Integrated Security=True" -DatabaseName "MBAM Compliance Status" -ReportAccount "VIAMONSTRA\MBAM_DB_RO"

# Enable recovery database
Enable-MbamDatabase -AccessAccount "VIAMONSTRA\MBAM_DB_RW" -ConnectionString "Data Source=MBAM01.corp.viamonstra.com;Integrated Security=True" -DatabaseName "MBAM Recovery and Hardware" -Recovery

# Enable report feature
Enable-MbamReport -ComplianceAndAuditDBConnectionString "Data Source=MBAM01.corp.viamonstra.com;Initial Catalog=`"MBAM Compliance Status`";Integrated Security=True" -ComplianceAndAuditDBCredential (Get-Credential -UserName "VIAMONSTRA\MBAM_Reports_Compl" -Message ComplianceAndAuditDBCredential) -ReportsReadOnlyAccessGroup "VIAMONSTRA\MBAM_HD_Report"

# Enable administration web portal feature
Enable-MbamWebApplication -AdministrationPortal -AdvancedHelpdeskAccessGroup "VIAMONSTRA\MBAM_HD_Adv" -CMIntegrationMode -ComplianceAndAuditDBConnectionString "Data Source=MBAM01.corp.viamonstra.com;Initial Catalog=`"MBAM Compliance Status`";Integrated Security=True" -HelpdeskAccessGroup "VIAMONSTRA\MBAM_HD" -HostName "MBAM01.corp.viamonstra.com" -InstallationPath "C:\inetpub" -Port 80 -RecoveryDBConnectionString "Data Source=MBAM01.corp.viamonstra.com;Initial Catalog=`"MBAM Recovery and Hardware`";Integrated Security=True" -ReportsReadOnlyAccessGroup "VIAMONSTRA\MBAM_HD_Report" -ReportUrl http://mbam01/ReportServer -VirtualDirectory "HelpDesk" -WebServiceApplicationPoolCredential (Get-Credential -UserName "VIAMONSTRA\MBAM_HD_AppPool" -Message WebServiceApplicationPoolCredential)

# Enable agent service feature
Enable-MbamWebApplication -AgentService -CMIntegrationMode -ComplianceAndAuditDBConnectionString "Data Source=MBAM01.corp.viamonstra.com;Initial Catalog=`"MBAM Compliance Status`";Integrated Security=True" -HostName "MBAM01.corp.viamonstra.com" -InstallationPath "C:\inetpub" -Port 80 -RecoveryDBConnectionString "Data Source=MBAM01.corp.viamonstra.com;Initial Catalog=`"MBAM Recovery and Hardware`";Integrated Security=True" -WebServiceApplicationPoolCredential (Get-Credential -UserName "VIAMONSTRA\MBAM_HD_AppPool" -Message WebServiceApplicationPoolCredential)

# Enable self service web portal feature
Enable-MbamWebApplication -ComplianceAndAuditDBConnectionString "Data Source=MBAM01.corp.viamonstra.com;Initial Catalog=`"MBAM Compliance Status`";Integrated Security=True" -HostName "MBAM01.corp.viamonstra.com" -InstallationPath "C:\inetpub" -Port 80 -RecoveryDBConnectionString "Data Source=MBAM01.corp.viamonstra.com;Initial Catalog=`"MBAM Recovery and Hardware`";Integrated Security=True" -SelfServicePortal -VirtualDirectory "SelfService" -WebServiceApplicationPoolCredential (Get-Credential -UserName "VIAMONSTRA\MBAM_HD_AppPool" -Message WebServiceApplicationPoolCredential)

