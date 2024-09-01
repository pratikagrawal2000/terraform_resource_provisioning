[CmdletBinding()]
Param
( 

[Parameter(Mandatory = $true)]
[string]$subscriptionID,

[Parameter(Mandatory = $true)]
[string]$vm_name_list,

[Parameter(Mandatory = $true)]
[string]$snow_agent,

[Parameter(Mandatory = $true)]
[string]$falcon_agent,

[Parameter(Mandatory = $true)]
[string]$cis_agent,

[Parameter(Mandatory = $true)]
[string]$opsramp_agent,

[Parameter(Mandatory = $true)]
[string]$centrify_agent,


[Parameter(Mandatory = $true)]
[string]$big_fix,

[Parameter(Mandatory = $true)]
[string]$domain_name,

[Parameter(Mandatory = $true)]
[string]$domain_users,

[Parameter(Mandatory = $true)]
[string]$enablemonitoring,

[Parameter(Mandatory = $true)]
[string]$wk_environment_name,

[Parameter(Mandatory = $true)]
[string]$division_code,

[Parameter(Mandatory = $true)]
[string]$business_code,

[Parameter(Mandatory = $true)]
[string]$t_zone,

[Parameter(Mandatory = $true)]
[string]$aws_access_key,

[Parameter(Mandatory = $true)]
[string]$aws_secret_key,

[Parameter(Mandatory = $true)]
[string]$cloudprovider,

[Parameter(Mandatory = $true)]
[string]$opsramp_function_name,

[Parameter(Mandatory = $true)]
[string]$opsramp_integration_id,

[Parameter(Mandatory = $true)]
[string]$opsramp_function_code,

[Parameter(Mandatory = $true)]
[string]$opsramp_key_id,

[Parameter(Mandatory = $true)]
[string]$opsramp_secret_id,

[Parameter(Mandatory = $true)]
[string]$service_account,

[Parameter(Mandatory = $true)]
[string]$service_account_password,

[Parameter(Mandatory = $true)]
[string]$agent_S3_url
)
#   
# Description: Add required DNS Server address to VNET
#
#######################################################################################
function Add-DNSServer{
    param (
    [Parameter(Mandatory=$True)][string]$vmVnet        
    )
    
    $isDNSServer = $null
    try {
        $Region = (Get-AzResource -ResourceType "Microsoft.Network/virtualNetworks" -Name $vmVnet).Location 
        $dnsServerDictionary = Get-Content -Raw -Path $PSScriptRoot\DNSServerList.json | ConvertFrom-Json
        $dnsServerDetails = $dnsServerDictionary | Where-Object {($_.Locations.ToLower().Replace(' ','').IndexOf($Region.ToLower().Replace(' ',''))) -ge 0}
        if($dnsServerDetails -ne $null){
            $dnsServerIPs = $dnsServerDetails.dnsServerIP
            $isDNSServer = "true"
            }
        else{
            Write-Host "DNS Servers are not present for region $($Region)"
            $isDNSServer = "false"
        }
      }
    catch {
        Write-Host $_
    }
    if($isDNSServer -eq "true"){
    $vnet = Get-AzVirtualNetwork -name $vmVnet
    $dnsServerIP=$dnsServerIPs.split(",",[System.StringSplitOptions]::RemoveEmptyEntries)
    if($null -eq $vnet.DhcpOptions.DnsServers){
        $newObject = New-Object -type PSObject -Property @{"DnsServers" = $null}
        $vNet.DhcpOptions = $newObject
            ForEach($IP in $dnsServerIP)
            {
                $vnet.DhcpOptions.DnsServers += $IP 
            }
    }

    else{
        $vnetDNSservers=$($vnet.DhcpOptions.DnsServers).split(" ",[System.StringSplitOptions]::RemoveEmptyEntries)
        ForEach($IP in $dnsServerIP)
        {
        if(($vnetDNSservers -notcontains $IP)){
            $vnet.DhcpOptions.DnsServers += $IP 
        }
        }
    } 
    $null=Set-AzVirtualNetwork -VirtualNetwork $vnet
    }
    else{
        Write-Host "DNS Servers are not added for region $($Region)"
     } 
    return $isDNSServer
}

function Add-DCRRule{
    param (
        
        [Parameter(Mandatory=$True)][string]$VM,
        [Parameter(Mandatory=$True)][string]$osresourceid,
        [Parameter(Mandatory=$True)][string]$vmLocation
        )
    try{
    #Adding servers to sentinel workspace
    #Creating association in Data Collection Rule 
    Write-Output "$vmLocation"
    #fetching rules details from DCRRulelist.json file based on Location                
    $RuleDictionary = Get-Content -Raw -Path $PSScriptRoot/DCRRuleList.json  | ConvertFrom-Json         
    $DCRRuleDetails = $RuleDictionary | Where-Object {($_.Locations.ToLower().Replace(' ','').IndexOf($vmLocation.ToLower().Replace(' ',''))) -ge 0}
    Write-Host "$DCRRuleDetails"
    #Fetching DCR rule based on OS Type
    if($null -ne $DCRRuleDetails ){
        $DCRRule = $DCRRuleDetails.WindowsDCR
    }
    Write-Host "Selected Rule Name is: $DCRRule"
    #need to remove
     $associationName = $VM
   
    Write-Host "Trying to add VM in Data Colletion rule $(($DCRRule).split('/')[-1])"
    #ADDING RETRY LOGIC
    for ($count=1; $count -lt 3; $count++){
        try{
            write-host "Trying attempt: $($count)"
            $res = New-AzDataCollectionRuleAssociation -AssociationName $associationName -ResourceUri $osresourceid -DataCollectionRuleId $DCRRule
            Write-Host " Successfully added VM $($VM) to Rule: $(($DCRRule).split('/')[-1]) in attempt : $($count) with the Association Name = $($associationName)"
            break
        }
        catch
        {
            Write-Host $_ 
            write-host "retring to add association"
            continue 
        }
    }
    }
    catch{
        Write-Host "Error in Adding DCR Rule"
        Write-Host $_
    }
    return $res
}

try {
    #set subscription
    Set-AzContext -SubscriptionId $subscriptionID
    $extensionName = "windowAgentInstall"
    $bucket= "ause1-as3-p1-vmagents"
    $s3_region= "us-east-1"
    $isRestart = "false"
    $vmPair = $vm_name_list.Split(",", [System.StringSplitOptions]::RemoveEmptyEntries);  
    $WindowsDefender= $true
    $validdomainuser=""
    foreach ($vm in $vmPair) {  
        $agentstatus = $null
        $errormsg = $null
        $failureagent = @()
        $successarrayagent = @()
        $pipelineStatus = $null      
        $vms = Get-AzVM -Name $VM
        $vmRG = $vms.ResourceGroupName      
        $vmLocation = $vms.location
        $osresourceid = $vms.Id
        $vmPrivateIp = (Get-AzNetworkInterface -Name ($vms.NetworkProfile.NetworkInterfaces.Id.Split("/") | Select-Object -Last 1)).IpConfigurations.PrivateIpAddress
        $vmVnet= (((Get-AzNetworkInterface -Name ($vms.NetworkProfile.NetworkInterfaces.Id.Split("/") | Select-Object -Last 1)).IpConfigurations.subnet.id).Split('/'))[-3]
        $offer=$vms.StorageProfile.ImageReference.Offer
        $sku=$vms.StorageProfile.ImageReference.sku
        Write-Host $offer $sku $vmlocation $vmPrivateIp $vmVnet
        $extension = Get-AzVMCustomScriptExtension -ResourceGroupName $vmRG -VMName $vm -Name $extensionName -ErrorAction SilentlyContinue
        if ($extension -ne $null) {
            # Remove the custom script extension with force option
            Remove-AzVMCustomScriptExtension -ResourceGroupName $vmRG -VMName $vm -Name $extensionName -Force
            Write-Output "Custom script extension '$extensionName' has been removed from VM '$vm' in resource group '$vmRG'."
        }
        else {
            Write-Output "Custom script extension '$extensionName' does not exist on VM '$vm' in resource group '$vmRG'.`n"
        }

    $retryCount = 0
    $installationSucceeded = "false"
    $installationfailed= "false"
    $maxRetries = 2

    while ($retryCount -lt $maxRetries -and $installationSucceeded -eq "false") {      

            if ($snow_agent -eq $true) {
            try {
                Write-Host "`n####################### Snow Agent Installation Process Starting ###################"
                $scriptFile = "$agent_S3_url/WindowsScript/az_snow.ps1"               

                #Fetching Azure VM Tags
                $tags = $vms.Tags                
                # Store the value of 'wk_application_bit_id' in a separate variable
                $wk_application_bit_id = $tags['wk_application_bit_id']
                $wk_application_name=$tags['wk_application_name']
                $wk_resource_name=$tags['wk_resource_name']
                $wk_requestor=$tags['wk_requestor']
                $wk_environment_name=$tags['wk_environment_name']
                $server="server" #device_type
                $logical="logical" #device_class

                if ($wk_environment_name -eq "prd") {
                    $environment_type = "Prod"
                } else {
                    $environment_type = "NonProd"
                }
                $arguments = "-buildID $env:BUILD_BUILDNUMBER -bucket $bucket -s3_region $s3_region -awsAccessKey $aws_access_key -awsSecretKey $aws_secret_key -division $division_code -business_unit $business_code -location $vmLocation -device_type $server -device_class $logical -application_id $wk_application_bit_id -application_name `"$wk_application_name`" -environment_name $wk_environment_name -environment_type $environment_type -resource_name $wk_resource_name -requestor $wk_requestor"
                $status = Set-AzVMCustomScriptExtension -ResourceGroupName $vmRG -VMName $vm -Name $extensionName -Location $vmLocation -TypeHandlerVersion "1.10" `
                    -FileUri $scriptFile -Argument $arguments -Run "az_snow.ps1"  
                $vmCustomScriptExtension = Get-AzVMCustomScriptExtension -ResourceGroupName $vmRG -VMName $vm  -Name $extensionName -Status
                Write-Host $arguments
                foreach ($vmStatus in $vmCustomScriptExtension.SubStatuses) {                    
                    if ($vmStatus.Message) {                        
                        $snowSucAgent = "SNOW"
                        $successarrayagent = $successarrayagent + $snowSucAgent
                        Write-Output $vmStatus.Message
                    }                
                }
                $snow_agent = $false  
                Write-Host "##################### Snow Agent Installation Process Completed ######################`n`n"  

            }
            catch {
                Write-Host "`n################Error in snow installation#######################"
                $snowerrAgent = "SNOW"
                $failureagent = $failureagent + $snowerrAgent
                Write-Host $_                 
                $installationfailed= "true"
                $snow_agent = $true
                Write-Host "`################End Error in snow installation#######################"
            }            
        }

        if ($falcon_agent -eq $true) {
            try {
                Write-Host "################### Falcon Agent Installation Process Starting ######################"
                $scriptFile = "$agent_S3_url/WindowsScript/az_falcon.ps1"                
                $arguments = "-falcon_pkg_name https://ause1-as3-p1-vmagents.s3.amazonaws.com/agents/falcon/windows/falcon-sensor-latestversion.exe -divisionCode $division_code -businessUnit $business_code -group $wk_environment_name  -buildID $env:BUILD_BUILDNUMBER -bucket $bucket -s3_region $s3_region -awsAccessKey $aws_access_key -awsSecretKey $aws_secret_key"               

                $status = Set-AzVMCustomScriptExtension -ResourceGroupName $vmRG -VMName $vm -Name $extensionName -Location $vmLocation -TypeHandlerVersion "1.10" `
                    -FileUri $scriptFile -Argument $arguments -Run "az_falcon.ps1"
                $vmCustomScriptExtension = Get-AzVMCustomScriptExtension -ResourceGroupName $vmRG -VMName $vm  -Name $extensionName -Status
                foreach ($vmStatus in $vmCustomScriptExtension.SubStatuses) {                   
                  if ($vmStatus.Message) {
                        $falconSucagent = "FALCON"
                        $successarrayagent = $successarrayagent + $falconSucagent
                        Write-Output $vmStatus.Message
                    }                
                }
                $falcon_agent = $false 
                Write-Host "###################### Falcon Agent Installation Process Completed ######################`n`n"                           
            }
            catch {
                Write-Host "########### Error in Falcon installation ###########"
                $falconerrAgent = "FALCON"
                $failureagent = $failureagent + $falconerrAgent
                Write-Host $_ 
                $installationfailed= "true" 
                $falcon_agent = $true 
                Write-Host "###########End Error in Falcon installation ###########"             
            }           
        }
        if ($big_fix -eq $true) {
            try {
                Write-Host "###################### Bigfix Agent Installation Process Starting ######################"
             
                $scriptFile = "$agent_S3_url/WindowsScript/bigfix.ps1"                
                $arguments = "-bucket $bucket -region $vmlocation -s3_region $s3_region -awsAccessKey $aws_access_key -awsSecretKey $aws_secret_key -cloudProvider $cloudprovider -buildID $env:BUILD_BUILDNUMBER"

                $status = Set-AzVMCustomScriptExtension -ResourceGroupName $vmRG -VMName $vm -Name $extensionName -Location $vmlocation -TypeHandlerVersion "1.10" `
                    -FileUri $scriptFile -Argument $arguments -Run "bigfix.ps1"
                $vmCustomScriptExtension = Get-AzVMCustomScriptExtension -ResourceGroupName $vmRG -VMName $vm  -Name $extensionName -Status
                foreach ($vmStatus in $vmCustomScriptExtension.SubStatuses) {                   
                    if ($vmStatus.Message) {
                        $bigfixSucagent = "BIGFIX"
                        $successarrayagent = $successarrayagent + $bigfixSucagent
                        Write-Output $vmStatus.Message
                    }                
                }
                $big_fix = $false
                Write-Host "###################### Bigfix Agent Installation Process Completed ######################`n`n"                             
            }
            catch {
                Write-Host "########### Error in Bigfix installation ###########-"
                $bigfixErragent = "BIGFIX"
                $failureagent = $failureagent + $bigfixErragent
                Write-Host $_  
                $installationfailed= "true"
                $big_fix = $true             
                Write-Host "########### End Error in Bigfix installation ###########-"
            }                   
        }

       if ($opsramp_agent -eq $true) {
            try {                
                Write-Host "###################### opsramp Agent Installation Process Starting ######################"                              
                $scriptFile = "https://vm-agent-setups.s3.amazonaws.com/AgentScript/Dev-Branch/WindowsScript/opsrampagent_before_24thAug_release.ps1"
                $package_s3_url = "https://ause1-as3-p1-vmagents.s3.amazonaws.com/agents/opsramp-v16.0/azure/$opsramp_integration_id/Windows/opsramp_agent.exe"                                                    
                Write-Host $package_s3_url
                $tenantid = "8ac76c91-e7f1-41ff-a89c-3553b2da2c17"
                $arguments = "-opsramp_function_name $opsramp_function_name -opsramp_integration_id $opsramp_integration_id -opsramp_function_code $opsramp_function_code -opsramp_key_id $opsramp_key_id -opsramp_secret_id $opsramp_secret_id -buildID $env:BUILD_BUILDNUMBER -package_s3_url $package_s3_url -tenantid $tenantid"
                $status = Set-AzVMCustomScriptExtension -ResourceGroupName $vmRG -VMName $vm -Name $extensionName -Location $vmlocation -TypeHandlerVersion "1.10" `
                -FileUri $scriptFile -Argument $arguments -Run "opsrampagent_before_24thAug_release.ps1" 
                $vmCustomScriptExtension = Get-AzVMCustomScriptExtension -ResourceGroupName $vmRG -VMName $vm  -Name $extensionName -Status
                foreach ($vmStatus in $vmCustomScriptExtension.SubStatuses) {                   
                    if ($vmStatus.Message) {
                        $opsrampSucagent = "OPSRAMP"
                        $successarrayagent = $successarrayagent + $opsrampSucagent
                        Write-Output $vmStatus.Message
                    }                
                }
                $opsramp_agent = $false
                Write-Host "###################### opsramp Agent Installation Process Completed ######################`n`n"
            }
            catch {
                Write-Host "########### Error in opsramp installation ###########"
                $opsrampErragent = "OPSRAMP"
                $failureagent = $failureagent + $opsrampErragent
                Write-Host $_
                $installationfailed= "true"
                $opsramp_agent = $true                
                Write-Host "###########End Error in opsramp installation ###########"
            }            
        }
 
        if ($cis_agent -eq "true") {
            try {
                Write-Host "###################### CIS Hardening Agent Installation Process Starting ######################"               
                $scriptFile = "$agent_S3_url/WindowsScript/az_cis.ps1"
                $arguments = "-cis_pkg_name https://ause1-as3-p1-vmagents.s3.amazonaws.com/agents/cis/Server16_19_22_cis.zip -buildID $env:BUILD_BUILDNUMBER -bucket $bucket -s3_region $s3_region -awsAccessKey $aws_access_key -awsSecretKey $aws_secret_key"                
                
                
                $status = Set-AzVMCustomScriptExtension -ResourceGroupName $vmRG -VMName $vm -Name $extensionName -Location $vmlocation -TypeHandlerVersion "1.10" `
                    -FileUri $scriptFile -Argument $arguments -Run "az_cis.ps1"
                $vmCustomScriptExtension = Get-AzVMCustomScriptExtension -ResourceGroupName $vmRG -VMName $vm  -Name $extensionName -Status
                foreach ($vmStatus in $vmCustomScriptExtension.SubStatuses) {                   
                    if ($vmStatus.Message) {
                        $cisSucagent = "CIS Hardening"
                        $successarrayagent = $successarrayagent + $cisSucagent
                        Write-Output $vmStatus.Message
                    }                
                }
                $cis_agent = $false                
                Write-Host "###################### CIS Hardening Agent Installation Process Completed ######################`n`n"
            }
            catch {
                Write-Host "########### Error in CIS Hardening installation ###########"
                $cisErragent = "CIS Hardening"
                $failureagent = $failureagent + $cisErragent
                Write-Host $_ 
                $installationfailed= "true"
                $cis_agent = $true      
                 Write-Host "########### End Error in CIS Hardening installation ###########"        
            }            
        }
       if ($centrify_agent -eq "true") {
            try {
                Write-Host "###################### centrify Agent Installation Process Starting ######################"                
                #Adding DNS Server
                #$dnsServerValue = Add-DNSServer -vmVnet $vmVnet             
                $scriptFile = "$agent_S3_url/WindowsScript/Centrify_domain.ps1"
                $domain_users = $domain_users.Replace(' ','')             
                $arguments = "-RainierServiceAcc $service_account -RainierServiceAccPassword $service_account_password -userNameList $domain_users -domain $domain_name -buildID $env:BUILD_BUILDNUMBER"
                $rmExt = Remove-AzVMCustomScriptExtension -ResourceGroupName $vmRG -VMName $VM -Name $extensionName -Force
                $status = Set-AzVMCustomScriptExtension -ResourceGroupName $vmRG -VMName $vm -Name $extensionName -Location $vmLocation -TypeHandlerVersion "1.10" `
                    -FileUri $scriptFile -Argument $arguments -Run "Centrify_domain.ps1"
                $vmCustomScriptExtension = Get-AzVMCustomScriptExtension -ResourceGroupName $vmRG -VMName $vm  -Name $extensionName -Status
                foreach ($vmStatus in $vmCustomScriptExtension.SubStatuses) {                   
                     if ($vmStatus.Message) {
                        $centrifySucagent = "CENTRIFY"
                        $successarrayagent = $successarrayagent + $centrifySucagent
                        Write-Output $vmStatus.Message                                              
                    }                
                }
                $centrify_agent = $false
                $domainusers_agent = $true
                Write-Host "###################### Centrify Agent Installation Process Completed ######################`n`n"
            }
            catch {
                Write-Host "########### Error in centrify installation ###########"
                Write-Host $_
                $centrifyErragent = "CENTRIFY"
                $failureagent = $failureagent + $centrifyErragent
                $installationfailed= "true"               
                $centrify_agent = $true
                 $domainusers_agent = $false
                # if($dnsServerValue -eq "false"){
                #     Write-Host "DNS Servers are not added to the vnet selected." 
                # }  
                Write-Host "########### Error  End in centrify installation ###########"   
            }            
        }
        # Enabling System Assigned Identity and Installing AMA AGent in VM. 
        if ($enableMonitoring -eq "true") {
            try { 
                Write-Host "############### Azure Monitor Agent Installation Process Starting ##########################"
                # Check identity
                if($vms.Identity.Type -ne "SystemAssigned") {
                    # Assign identity if needed
                    write-host "Enabling systemassigned Identity starting.....!"
                    Write-Host "$vm"
                    Write-Host "$VM"
                    $update = Update-AzVM -ResourceGroupName $vmRG -VM (get-AzVM -Name $VM -ResourceGroupName $vmRG) -IdentityType SystemAssigned
                    Write-Output "Assigned system managed identity"
                }
                #Installing Agent via Exception
                write-host "Azure Monitor agent installation Starting......."
                #check extension is there or not?
                Write-Host "vm:$vm"
                Write-Host "VM:$vmRG"
                $agentextension = Get-AzVMExtension -ResourceGroupName $vmRG -VMName $VM -Name "AzureMonitorWindowsAgent" -Status -ErrorAction SilentlyContinue
                if($agentextension -eq $null){
                    Write-Output "Setting VM Extensions AzureMonitorWindowsgent started ...."
                    $result = Set-AzVMExtension -Name AzureMonitorWindowsAgent -ExtensionType AzureMonitorWindowsAgent -Publisher Microsoft.Azure.Monitor -ResourceGroupName $vmRG -VMName $vm_name_list -Location $vms.location -TypeHandlerVersion "1.1" -EnableAutomaticUpgrade $true
                    Write-Output "Setting VM Extensions AzureMonitorWindowsAgent Completed ...."
                }
                $status =Get-AzVMExtension -ResourceGroupName $vmRG -VMName $VM -Name AzureMonitorWindowsAgent -Status
                foreach ($vmStatus in $status.Statuses) { 
                    $AzureMonitoragent = "AzureMonitorWindowsAgent"  
                    $successarrayagent = $successarrayagent + $AzureMonitoragent                      
                    Write-Output $vmStatus.Message
                }
                $enableMonitoring = $false
                Write-Host "Successfully Installed Windows agent"
                #Adding DCR Rule
                $AddDCRRule = Add-DCRRule -VM $VM -osresourceid $osresourceid -vmLocation $vmLocation
                Write-Host "######################  AzureMonitoragent Installtion is Completed ######################"
            } 
            catch {
                write-output "########  Error in installing Azure monitor Windows Agent!..... ########"
                Write-Host $_.Exception
                $AzureMonitoragent = "AzureMonitorWindowsAgent"
                $arrayagent = $arrayagent + $AzureMonitoragent        
                Write-Host $_
                $installationfailed= "true"
                $enableMonitoring = $true      
                Write-Host "###########End  Error in installing Azure monitor Windows Agent ###########" 
            }
        }  
        if ($domainusers_agent -eq "true") {
            try {
                Write-Host "###################### Domain user centrify  Installation Process Starting ######################"               
                           
                $scriptFile = "$agent_S3_url/WindowsScript/Centrify_domainuser.ps1"
                $domain_users = $domain_users.Replace(' ','')             
                $arguments = "-userNameList $domain_users -domain $domain_name -buildID $env:BUILD_BUILDNUMBER"
                $status = Set-AzVMCustomScriptExtension -ResourceGroupName $vmRG -VMName $vm -Name $extensionName -Location $vmLocation -TypeHandlerVersion "1.10" `
                    -FileUri $scriptFile -Argument $arguments -Run "Centrify_domainuser.ps1"
                $vmCustomScriptExtension = Get-AzVMCustomScriptExtension -ResourceGroupName $vmRG -VMName $vm  -Name $extensionName -Status
                foreach ($vmStatus in $vmCustomScriptExtension.SubStatuses) {
                     if ($vmStatus.Message) {
                        Write-Output $vmStatus.Message
                        $domainSucagent = "DomainUser"
                        $successarrayagent = $successarrayagent + $domainSucagent                        
                    }                
                }
                $domainusers_agent = $false
                $validdomainuser = "true"
                
                Write-Host "###################### Domain user centrify  Installation completed ######################" 
            }
            catch {
                Write-Host "########### Error in adding domainuser installation ###########-"                
                $validdomainuser = "false"                
                Write-Host $_
                $domainusers_agent = $true                                 
                Write-Host "########### Error End in adding domainuser installation ###########"              
            }            
        }

        
if ($WindowsDefender -eq "true") {
        try {                
                Write-Host "###################### Uninstall windows defender Process Starting ######################"
                $scriptFile = "$agent_S3_url/WindowsScript/UninstallWindowsDefender.ps1"
                $arguments = "-buildID $env:BUILD_BUILDNUMBER"
                $status = Set-AzVMCustomScriptExtension -ResourceGroupName $vmRG -VMName $vm -Name $extensionName -Location $vmlocation -TypeHandlerVersion "1.10" `
                    -FileUri $scriptFile -Argument $arguments -Run "UninstallWindowsDefender.ps1"
                $vmCustomScriptExtension = Get-AzVMCustomScriptExtension -ResourceGroupName $vmRG -VMName $vm  -Name $extensionName -Status
                $isRestart = "true"
                $uninstallDefeSucagent=$null
                $uninstallDefeFailagent=$null
                foreach ($vmStatus in $vmCustomScriptExtension.SubStatuses) {                   
                    if ($vmStatus.Message) {                                                
                        $uninstallDefeSucagent = "WINDOWSDEFENDER is Uninstalled successfully"                        
                        Write-Output $vmStatus.Message                        
                    }                
                }
                $WindowsDefender = $false
                $catchedError= $false
                Write-Host "###################### Uninstalling windows defender Process Completed ######################"
        }
        catch {
                Write-Host "########### Error in Uninstalling windows defender ###########"
                $uninstallDefeFailagent = "WINDOWSDEFENDER Uninstallation Failed"  
                $catchedError = $true              
                Write-Host $_
                $installationfailed= "true"
                $WindowsDefender = $true      
                Write-Host "###########End  Error in Uninstalling windows defender ###########"        
            }
            
}


   Write-Host $installationSucceeded $installationfailed
        if ($installationfailed -eq "true") {
            $installationSucceeded = "false"
            $installationfailed = "false"          
            $retryCount++            
            if($retryCount -ne $maxRetries){ 
            Stop-AzVM -ResourceGroupName $vmRG -Name $vm -force                     
            Start-Sleep -Seconds 100
            Write-Host "Starting $vm VM..."                                       
            Start-AzVM -ResourceGroupName $vmRG -Name $vm           
            foreach($i in $failureagent){
            Write-Host "$failureagent agent is failed and set the flag to retry once."            
            }  
            $failureagent = @()
            }}
            else{
                $installationSucceeded = "true"
                Write-Host "All Agent installation is successfull"
                break;
            }
        }

        $rainierMessage = $null         
        foreach ($err in $failureagent) {
            $catchedError = $true
            if ($successarrayagent -contains $err) {
                $successarrayagent = $successarrayagent | Where-Object { $_ -ne $err }
            }
            $rainierMessage += "$err agent Installation is failed.`n"                            
        }
        foreach ($succ in $successarrayagent) {
            $rainierMessage += "$succ agent Installation is successful.`n"             
        }

        if($null -ne $uninstallDefeSucagent)
        {
            $rainierMessage += "$uninstallDefeSucagent.`n"
        }
        else{
            $rainierMessage += "$uninstallDefeFailagent.`n"
        }
        Write-Host "`n################################# $($VM) Agent Status ########################################################`n"

        Write-Output $rainierMessage 

        Write-Host "`n##############################################################################################################`n"

         if($catchedError){
                    Write-Host $_.Exception.Message
                    $log = $_.Exception.Message
                    $body = @{}
                    $body.Add("pipelinestatus", "Agent Installation Failed")
                    $body.Add("pipelinestatusinfo", "Failed : Check below agent status because the pipeline has failed.`n`n $rainierMessage Error Message: $log ")                
                throw  "Check all agent status and logs because the pipeline has failed.`n`n $rainierMessage`n"            
            }
            else{
                Write-Host $validdomainuser
               if(($validdomainuser -ne "") -and ($validdomainuser -eq "false")){
                    $body = @{}
                    $body.Add("pipelinestatus", "Success_with_exception")
                    $body.Add("pipelinestatusinfo", "Success: Pipeline is successful with exception while adding domain user's and agent status below `n`n$rainierMessage`n"+"Pipeline status: Success. Project name: $($env:SYSTEM_TEAMPROJECT). Pipeline name: $($env:BUILD_DEFINITIONNAME). Build number: $($env:BUILD_BUILDNUMBER). Definition ID: $($env:SYSTEM_DEFINITIONID).")
                }
                else{
                    $body = @{}
                    $body.Add("pipelinestatus", "Success")
                    $body.Add("pipelinestatusinfo", "Success: Pipeline is successful and agent status below `n`n$rainierMessage`n"+"Pipeline status: Success. Project name: $($env:SYSTEM_TEAMPROJECT). Pipeline name: $($env:BUILD_DEFINITIONNAME). Build number: $($env:BUILD_BUILDNUMBER). Definition ID: $($env:SYSTEM_DEFINITIONID).")
                }
                # Write-Output $rainierMessage             
            }       
    }
}
catch {    
     $pipelinedetails = "Pipeline status: Failed. Project name: $($env:SYSTEM_TEAMPROJECT). Pipeline name: $($env:BUILD_DEFINITIONNAME). Build number: $($env:BUILD_BUILDNUMBER). Definition ID: $($env:SYSTEM_DEFINITIONID)."
        $log = $_   
        $errormsg = $log.Exception.MESSAGE
        $errormsg += $pipelinedetails
                $body = @{}
                $body.Add("pipelinestatus", "Agent Installation Failed")
                $body.Add("pipelinestatusinfo",$errormsg)              
        throw $errormsg
}
finally {                    
                foreach ($vm in $vmPair) {
                $vms = Get-AzVM -Name $VM
                $vmRGs = $vms.ResourceGroupName    
                $rmExt=Remove-AzVMCustomScriptExtension -ResourceGroupName $vmRGs -VMName $VM -Name $extensionName -Force
                 Write-Host "###################### $($VM) Agent Installation Process Completed ######################"                 
                 if($isRestart -eq "true"){                       
                     Write-Host "Stopping $vm VM..."                                       
                     Stop-AzVM -ResourceGroupName $vmRGs -Name $vm -force                     
                     Start-Sleep -Seconds 100
                     Write-Host "Starting $vm VM..."                                       
                     Start-AzVM -ResourceGroupName $vmRGs -Name $vm
                 }
                }
        }