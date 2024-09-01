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
[string]$enablemonitoring,

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
[string]$storage_account_connection_string,

[Parameter(Mandatory = $true)]
[string]$wk_environment_name,

[Parameter(Mandatory = $true)]
[string]$division_code,

[Parameter(Mandatory = $true)]
[string]$business_code,

[Parameter(Mandatory = $true)]
[string]$t_zone,

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

####################
function Add-DNSServer{
    param (
    [Parameter(Mandatory=$True)][string]$vmVnet        
    )
    try {
        $isDNSServer = "true"
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
####################
function Add-DCRRule{
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
        $DCRRule = $DCRRuleDetails.LinuxDCR
    }
    Write-Host "Selected Rule Name is: $DCRRule"
    #need to remove
    # if($RITMNumber -eq "None" -or $RITMNumber -eq $null){
    # $RITMNumber ="test"+ (Get-Random -Maximum 100)
    # }
    # $associationName = $VM + "_$RITMNumber"
    $associationName = $VM
    Write-Host "Trying to add VM in Data Colletion rule $(($DCRRule).split('/')[-1])"
    #ADDING RETRY LOGIC
    for ($count=1; $count -lt 3; $count++){
        try{
            write-host "Trying attempt: $($count)"
            $res = New-AzDataCollectionRuleAssociation -AssociationName $associationName -ResourceUri $osresourceid -DataCollectionRuleId $DCRRule
            Write-Host " Successfully added VM $($VM) to Rule: $(($DCRRule).split('/')[-1]) in attempt : $($count) with Association Name = $($associationName)"
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
    $extensionName = "CustomScript"
    $isRestart = "false"   
    $bucket= "ause1-as3-p1-vmagents"
    $vmPair = $vm_name_list.Split(",", [System.StringSplitOptions]::RemoveEmptyEntries); 
    $bigfixport= $true  
    foreach ($vm in $vmPair) {  
        $agentstatus = $null
        $errormsg = $null
        $arrayagent = @()
        $successarrayagent = @()
        $pipelineStatus = $null
        $buildID = "$env:BUILD_BUILDNUMBER"      
        $vms = Get-AzVM -Name $VM
        $vmRG = $vms.ResourceGroupName      
        $vmLocation = $vms.location
        $osresourceid = $vms.Id
        $vmPrivateIp = (Get-AzNetworkInterface -Name ($vms.NetworkProfile.NetworkInterfaces.Id.Split("/") | Select-Object -Last 1)).IpConfigurations.PrivateIpAddress
        $vmVnet= (((Get-AzNetworkInterface -Name ($vms.NetworkProfile.NetworkInterfaces.Id.Split("/") | Select-Object -Last 1)).IpConfigurations.subnet.id).Split('/'))[-3]
        $offer=$vms.StorageProfile.ImageReference.Offer
        $sku=$vms.StorageProfile.ImageReference.sku
        Write-Host $offer $sku $vmRG $vmlocation $vmPrivateIp $vmVnet       
        if($offer -match "ubuntu"){
          $ostypeimage = "ubuntu"
        }
        elseif($offer -match "sles-12")
        {
            $ostypeimage="SLES"
        }
        elseif($offer -match "rocky")
        {
            $ostypeimage="rocky"
        }
        elseif($offer -match "Oracle")
        {
            $ostypeimage="Oracle"
        }
        else
        {
            $ostypeimage="rhel"
        }              

        $extension = Get-AzVMExtension -ResourceGroupName $vmRG -VMName $VM -Name $extensionName -ErrorAction SilentlyContinue
        Write-Host "Extension Name"
        Write-Host $extension
        if ($extension -ne $null) {
            
            # Remove the custom script extension with force option
            Remove-AzVMExtension -ResourceGroupName $vmRG -VMName $VM -Name $extensionName -Force
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
        Write-Host $retryCount $installationSucceeded
        if ($ostypeimage -eq "rhel"){
            try {
                    Write-Host "######################  RhelUpdateBrokenRepo Update Starting for RHEL OS ######################" 
                    $scriptFile             = "$agent_S3_url/LinuxScript/updateRhelBrokenRepo.sh"                                              
                    $rhelUpdateBrokenRepo   = @{fileUris=@("$scriptFile");commandToExecute="./updateRhelBrokenRepo.sh"}
                    $result                 = Set-AzVMExtension -ResourceGroupName $vmRG -Location $vmLocation -VMName $VM -Name $extensionName -Publisher "Microsoft.Azure.Extensions" -ExtensionType $extensionName -TypeHandlerVersion "2.1" -ProtectedSettings $rhelUpdateBrokenRepo               
                    $status                 = Get-AzVMExtension -ResourceGroupName $vmRG -VMName $VM -Name $extensionName -Status
                    foreach ($vmStatus in $status.Statuses) { 
                        Write-Output $vmStatus.Message
                    }
                    $rhelUpdateBrokenRepo = $false
                    Write-Host "######################  RhelUpdateBrokenRepo Update Completed ######################"
            }
            catch {
                    Write-Host "########### Error in RhelUpdateBrokenRepo Update ###########"   
                    Write-Host $_
                    $installationfailed= "true"
                    $bigfixport = $true      
                    Write-Host "###########End  Error in RhelUpdateBrokenRepo Update ###########"        
                }             
            
        }

 

        if ($snow_agent -eq $true) {
            try {
                Write-Host "`n####################### Snow Agent Installation Process Starting ###################"  
                
                 if($ostypeimage -eq "ubuntu"){
                   $snow_pkg_name = "https://ause1-as3-p1-vmagents.s3.amazonaws.com/agents/snow/ubuntu/debian-x86_64/snow-agent-latestversion.deb"
                   Write-Host $snow_pkg_name
                 }
                else{
                    $snow_pkg_name="https://ause1-as3-p1-vmagents.s3.amazonaws.com/agents/snow/rhel/redhat-x86_64/snow-agent-latestversion.rpm"
                    Write-Host $snow_pkg_name        
                }
                $scriptFile = "$agent_S3_url/LinuxScript/snow.sh" 
###############################################               
    # Get the tags associated with the VM
    $tags = $vms.Tags
    $wk_application_bit_id = $tags['wk_application_bit_id']
    $wk_application_name=$tags['wk_application_name']
    $wk_resource_name=$tags['wk_resource_name']
    $wk_requestor=$tags['wk_requestor']
    $wk_environment_name=$tags['wk_environment_name']
    Write-Host $wk_application_bit_id, $wk_application_name, $wk_resource_name, $wk_requestor,$wk_environment_name
    $server="server" #device_type
    $logical="logical" #device_class
if ($wk_environment_name -eq "prd") {
    $environment_type = "Prod"
} else {
    $environment_type = "NonProd"
}

###################################################                                                
                $snowscript =@{fileUris=@("$scriptFile");commandToExecute="./snow.sh '$ostypeimage' '$snow_pkg_name' '$buildID' '$wk_resource_name' '$wk_environment_name' '$wk_requestor' '$vmLocation' '$business_code' '$division_code' '$server' '$logical' '$environment_type' '$wk_application_name' '$wk_application_bit_id'"}
                $result=Set-AzVMExtension -ResourceGroupName $vmRG -Location $vmLocation -VMName $VM  -Name $extensionName -Publisher "Microsoft.Azure.Extensions" -ExtensionType $extensionName -TypeHandlerVersion "2.1" -ProtectedSettings $snowscript

                $status =Get-AzVMExtension -ResourceGroupName $vmRG -VMName $VM -Name $extensionName -Status
                foreach ($vmStatus in $status.Statuses) { 
                         $snowSucAgent = "SNOW"
                        $successarrayagent = $successarrayagent + $snowSucAgent
                        Write-Output $vmStatus.Message
                }
                 $snow_agent = $false    
            }
 
            catch {
                Write-Host "`n################Error in snow installation#######################"
                $snowerrAgent = "SNOW"
                $arrayagent = $arrayagent + $snowerrAgent
                Write-Host $_ 
                $installationfailed= "true" 
                $snow_agent = $true             
            }
            finally {                                
               # Remove-AzVMExtension -ResourceGroupName $vmRG -VMName $VM -Name $extensionName -Force
                #Start-Sleep -Seconds 150
                Write-Host "##################### Snow Agent Installation Process Completed ######################`n`n"               
            }
        }

           if ($falcon_agent -eq $true) {
            try {
                Write-Host "################### Falcon Agent Installation Process Starting ######################"
               
                if($sku -match "8" -and $offer -eq "RHEL"){
                   $falcon_package_url = "https://ause1-as3-p1-vmagents.s3.amazonaws.com/agents/falcon/redhat-8/falcon-agent-latestversion.rpm"                   
                   Write-Host $falcon_package_url
                 }
                 elseif($sku -match "7" -and $offer -eq "RHEL"){
                  $falcon_package_url = "https://ause1-as3-p1-vmagents.s3.amazonaws.com/agents/falcon/redhat-7/falcon-agent-latestversion.rpm"                   
                   Write-Host $falcon_package_url              
                 }
                 elseif($sku -match "9" -and $offer -eq "RHEL"){
                   $falcon_package_url = "https://ause1-as3-p1-vmagents.s3.amazonaws.com/agents/falcon/redhat-9/falcon-agent-latestversion.rpm"                   
                   Write-Host $falcon_package_url
                 }
                 elseif($sku -match "9" -and $offer -eq "rockylinux-9"){
                   $falcon_package_url = "https://ause1-as3-p1-vmagents.s3.amazonaws.com/agents/falcon/redhat-9/falcon-agent-latestversion.rpm"                   
                   Write-Host $falcon_package_url
                 }
                 elseif($sku -match "gen2" -and $offer -eq "sles-12-sp5-basic"){
                   $falcon_package_url = "https://ause1-as3-p1-vmagents.s3.amazonaws.com/agents/falcon/suse-12/falcon-agent-latestversion.rpm"
                   Write-Host $falcon_package_url
                 }
                 elseif($sku -match "ol83"){
                   $falcon_package_url = "https://ause1-as3-p1-vmagents.s3.amazonaws.com/agents/falcon/redhat-8/falcon-agent-latestversion.rpm"                    
                   Write-Host $falcon_package_url             
                 }
                 elseif($sku -match "ol89"){
                   $falcon_package_url = "https://ause1-as3-p1-vmagents.s3.amazonaws.com/agents/falcon/redhat-8/falcon-agent-latestversion.rpm"                    
                   Write-Host $falcon_package_url             
                 }
                else{
                   $falcon_package_url = "https://ause1-as3-p1-vmagents.s3.amazonaws.com/agents/falcon/debian/falcon-agent-latestversion.deb"                                                             
                     Write-Host $falcon_package_url       
                }
                $scriptFile = "$agent_S3_url/LinuxScript/falcon.sh"                           
                Write-Host $scriptFile $ostypeimage $falcon_package_url $division_code $business_code $wk_environment_name               
                $falconscript =@{fileUris=@("$scriptFile");commandToExecute="./falcon.sh $ostypeimage $falcon_package_url $division_code $business_code $wk_environment_name $buildID"}
                $result=Set-AzVMExtension -ResourceGroupName $vmRG -Location $vmLocation -VMName $VM  -Name $extensionName -Publisher "Microsoft.Azure.Extensions" -ExtensionType $extensionName -TypeHandlerVersion "2.1" -ProtectedSettings $falconscript
                $status =Get-AzVMExtension -ResourceGroupName $vmRG -VMName $VM -Name $extensionName -Status
                foreach ($vmStatus in $status.Statuses) { 
                         $falconSucAgent = "FALCON"
                        $successarrayagent = $successarrayagent + $falconSucAgent
                        Write-Output $vmStatus.Message
                }
                 $falcon_agent = $false                                          
            }
            catch {
                Write-Host "########### Error in Falcon installation ###########"
                $falconerrAgent = "FALCON"
                $arrayagent = $arrayagent + $falconerrAgent
                Write-Host $_ 
                $installationfailed= "true"
                $falcon_agent = $true               
            }
            finally {                                
               # $rmExt = Remove-AzVMExtension -ResourceGroupName $vmRG -VMName $VM -Name $extensionName -Force
               
                Write-Host "###################### Falcon Agent Installation Process Completed ######################`n`n" 
            }
        }

        if ($big_fix -eq $true) {
            try {
                Write-Host "###################### Bigfix Agent Installation Process Starting ######################"                       
                $scriptFile = "$agent_S3_url/LinuxScript/bigfix.sh"      
                Write-Host $bucket $vmlocation $cloudprovider                 
               $bigfixscript =$script =@{fileUris=@("$scriptFile");commandToExecute="./bigfix.sh $bucket $vmlocation $cloudprovider $buildID"}
                $result=Set-AzVMExtension -ResourceGroupName $vmRG -Location $vmLocation -VMName $VM  -Name $extensionName -Publisher "Microsoft.Azure.Extensions" -ExtensionType $extensionName -TypeHandlerVersion "2.1" -ProtectedSettings $bigfixscript
                $status =Get-AzVMExtension -ResourceGroupName $vmRG -VMName $VM -Name $extensionName -Status
                foreach ($vmStatus in $status.Statuses) {                   
                    if ($vmStatus.Message) {
                        $bigfixSucagent = "BIGFIX"
                        $successarrayagent = $successarrayagent + $bigfixSucagent
                        Write-Output $vmStatus.Message
                    }                
                }
                $big_fix = $false 
                             
            }
            catch {
                Write-Host "########### Error in Bigfix installation ###########-"
                $bigfixErragent = "BIGFIX"
                $arrayagent = $arrayagent + $bigfixErragent
                Write-Host $_
                $installationfailed= "true"
                $big_fix = $true               
            }
            finally {                
              # $rmExt = Remove-AzVMCustomScriptExtension -ResourceGroupName $vmRG -VMName $vm -Name $extensionName -Force
                Write-Host "###################### Bigfix Agent Installation Process Completed ######################`n`n"

            }        
        }

          if ($opsramp_agent -eq $true) {
            try {                
                Write-Host "###################### opsramp Agent Installation Process Starting ######################"              
                $scriptFile = "$agent_S3_url/LinuxScript/opsramp.sh"
                $package_s3_url = "https://ause1-as3-p1-vmagents.s3.amazonaws.com/agents/opsramp-v16.0/azure/$opsramp_integration_id/Linux/opsramp_agent.sh"              
                $opsramp_api_server = "wk.api.opsramp.com"
                Write-Host $package_s3_url
                $opsrampscript =@{fileUris=@("$scriptFile");commandToExecute="./opsramp.sh $opsramp_api_server $opsramp_key_id $opsramp_secret_id $opsramp_integration_id $ostypeimage $buildID $package_s3_url"}
                $result=Set-AzVMExtension -ResourceGroupName $vmRG -Location $vmLocation -VMName $VM  -Name $extensionName -Publisher "Microsoft.Azure.Extensions" -ExtensionType $extensionName -TypeHandlerVersion "2.1" -ProtectedSettings $opsrampscript
                $status =Get-AzVMExtension -ResourceGroupName $vmRG -VMName $VM -Name $extensionName -Status

                foreach ($vmStatus in $status.Statuses) {                   
                    if ($vmStatus.Message) {
                        $opsrampSucagent = "OPSRAMP"
                        $successarrayagent = $successarrayagent + $opsrampSucagent
                        Write-Output $vmStatus.Message
                    }                
                }
                 $opsramp_agent = $false
            }
            catch {
                Write-Host "########### Error in opsramp installation ###########"
                $opsrampErragent = "OPSRAMP"
                $arrayagent = $arrayagent + $opsrampErragent
                Write-Host $_ 
                $installationfailed= "true"
                $opsramp_agent = $true               
            }
            finally {                                
              # $rmExt = Remove-AzVMCustomScriptExtension -ResourceGroupName $vmRG -VMName $vm -Name $extensionName -Force
                Write-Host "###################### opsramp Agent Installation Process Completed ######################`n`n"
            }
        }

       

        

    
  
       if ($centrify_agent -eq "true") {
            try {
                Write-Host "###################### centrify Agent Installation Process Starting ######################"
                
                #Adding DNS Server
                #$dnsServerValue = Add-DNSServer -vmVnet $vmVnet
                $scriptFile = "$agent_S3_url/LinuxScript/centrify.sh"
                $rhel_package="https://ause1-as3-p1-vmagents.s3.amazonaws.com/agents/centrify/redhat/centrify-agent-latestversion.tgz"
                $ubuntu_package="https://ause1-as3-p1-vmagents.s3.amazonaws.com/agents/centrify/debian/centrify-agent-latestversion.tgz"
                #Testing Link
                $suse_package="https://vm-agent-setups.s3.amazonaws.com/agents/centrify/delinea-server-suite-2023.1-suse12-x86_64.tgz" 
                #On Moving to prod, uncomment beolow Prod URL and remove above dev URL. 
                #PrductionLink:
                #$suse_package="https://ause1-as3-p1-vmagents.s3.amazonaws.com/agents/centrify/delinea-server-suite-2023.1-suse12-x86_64.tgz"              
                $domain_name = $domain_name.ToLower()
                $domain_users = $domain_users.Replace(' ','') 
                $centrifyscript =@{fileUris=@("$scriptFile");commandToExecute="bash ./centrify.sh $VM $service_account $service_account_password $domain_name $ostypeimage $rhel_package $ubuntu_package $suse_package $domain_users $buildID"}
                $result=Set-AzVMExtension -ResourceGroupName $vmRG -Location $vmLocation -VMName $VM  -Name $extensionName -Publisher "Microsoft.Azure.Extensions" -ExtensionType $extensionName -TypeHandlerVersion "2.1" -ProtectedSettings $centrifyscript
                $status =Get-AzVMExtension -ResourceGroupName $vmRG -VMName $VM -Name $extensionName -Status
                foreach ($vmStatus in $status.Statuses) {                   
                     if ($vmStatus.Message) {
                        $centrifySucagent = "CENTRIFY"
                        $successarrayagent = $successarrayagent + $centrifySucagent
                        Write-Output $vmStatus.Message                        
                    }                
                }
                

                #Centrify | Add sudoers to DC table
                Install-Module -Name AzTable -Scope CurrentUser -force
                $ctx = New-AzStorageContext -ConnectionString $storage_account_connection_string
                $storageTable = Get-AzStorageTable –Name centrify –Context $ctx
                $cloudTable = $storageTable.CloudTable
                foreach ($user in $domain_users.Split(",")) {                
                $rowKey = New-Guid
                Add-AzTableRow -Table $cloudTable -PartitionKey $domain_name -RowKey "$rowKey-$user" -property @{"UserGroup"="$user";"ComputerName"="$VM"}
                }
                # $isRestart = "true"
                $centrify_agent = $false
                Write-Output "=== Domain users are added to DC Table ==="
                #Get-AzTableRow -table $cloudTable |Where-Object { $_.ComputerName -eq $VM } | ft
            }
            catch {
                Write-Host "########### Error in centrify installation ###########-"
                $centrifyErragent = "CENTRIFY"
                $arrayagent = $arrayagent + $centrifyErragent
                # if($dnsServerValue -eq "false"){
                #     Write-Host "DNS Servers are not added to the vnet selected." 
                # }
                Write-Host $_  
                $installationfailed= "true"
                $centrify_agent = $true      
            }
            finally {                
               # $rmExt = Remove-AzVMCustomScriptExtension -ResourceGroupName $vmRG -VMName $vm -Name $extensionName -Force
                Write-Host "###################### Centrify Agent Installation Process Completed ######################`n`n"
            }
        }


if ($cis_agent -eq "true") {
            try {
                Write-Host "###################### CIS Hardening Agent Installation Process Starting ######################"
                $scriptFile = "$agent_S3_url/LinuxScript/cis.sh"
                if($sku -match "8" -and $offer -eq "RHEL"){
                   $cis_pkg_name="$agent_S3_url/LinuxScript/cis_l1_rhel8.sh"                   
                   Write-Host $cis_pkg_name
                 }
                 elseif($sku -match "7" -and $offer -eq "RHEL"){
                   $cis_pkg_name = "$agent_S3_url/LinuxScript/cis_l1_rhel7.sh"
                   Write-Host $cis_pkg_name              
                 }
                 elseif($sku -match "9" -and $offer -eq "RHEL"){
                   $cis_pkg_name= "$agent_S3_url/LinuxScript/cis_l1_rhel9.sh"
                   Write-Host $cis_pkg_name
                 }
                 elseif($sku -match "9" -and $offer -eq "rockylinux-9"){
                   $cis_pkg_name= "$agent_S3_url/LinuxScript/cis_l1_rockylinux9.sh"
                   Write-Host $cis_pkg_name
                 }
                 elseif($sku -match "gen2" -and $offer -eq "sles-12-sp5-basic"){
                   $cis_pkg_name= "$agent_S3_url/LinuxScript/cissuse12.sh"
                   Write-Host $cis_pkg_name
                 }
                 elseif($sku -match "ol83"){
                   $cis_pkg_name = "$agent_S3_url/LinuxScript/az_cis_l1_oracle.sh"                   
                   Write-Host $cis_pkg_name             
                 }
                 elseif($sku -match "ol89"){
                   $cis_pkg_name = "$agent_S3_url/LinuxScript/az_cis_oracle_linux8_9.sh"                   
                   Write-Host $cis_pkg_name             
                 }
                elseif($offer -eq "0001-com-ubuntu-server-focal")
                {
                    $cis_pkg_name = "$agent_S3_url/LinuxScript/cis_l1_ubuntu.sh" 
                    Write-Host $cis_pkg_name       
                }
                elseif($offer -eq "UbuntuServer")
                {
                    $cis_pkg_name = "$agent_S3_url/LinuxScript/cis_l1_ubuntu.sh"  
                    Write-Host $cis_pkg_name       
                }  
                else{
                    Write-host "Package is not found"
                }
                
                $cisscript =@{fileUris=@("$scriptFile");commandToExecute="./cis.sh $cis_pkg_name $buildID"}
                $result=Set-AzVMExtension -ResourceGroupName $vmRG -Location $vmLocation -VMName $VM  -Name $extensionName -Publisher "Microsoft.Azure.Extensions" -ExtensionType $extensionName -TypeHandlerVersion "2.1" -ProtectedSettings $cisscript
                $status =Get-AzVMExtension -ResourceGroupName $vmRG -VMName $VM -Name $extensionName -Status
                foreach ($vmStatus in $status.Statuses) {                   
                    if ($vmStatus.Message) {
                        $cisSucagent = "CIS Hardening"
                        $successarrayagent = $successarrayagent + $cisSucagent
                        Write-Output $vmStatus.Message
                    }                
                }
                $cis_agent = $false
                Write-Host "CIS Hardening configuration completed.."
            }
            catch {
                Write-Host "########### Error in CIS Hardening installation ###########"
                $cisErragent = "CIS Hardening"
                $arrayagent = $arrayagent + $cisErragent
                Write-Host $_
                $installationfailed= "true"
                $cis_agent = $true                 
            }
            finally {                
              # $rmExt = Remove-AzVMCustomScriptExtension -ResourceGroupName $vmRG -VMName $vm -Name $extensionName -Force
                Write-Host "###################### CIS Hardening Agent Installation Process Completed ######################`n`n"
            }
        }



           # BigFixport Enablement Port-53211
        if($bigfixport -eq "true"){
            try {
            $scriptFile = "$agent_S3_url/LinuxScript/BigFixPortInFirewall.sh"                                               
                $bigfixscript =@{fileUris=@("$scriptFile");commandToExecute="./BigFixPortInFirewall.sh"}
                $result=Set-AzVMExtension -ResourceGroupName $vmRG -Location $vmLocation -VMName $VM -Name $extensionName -Publisher "Microsoft.Azure.Extensions" -ExtensionType $extensionName -TypeHandlerVersion "2.1" -ProtectedSettings $bigfixscript               
                $status =Get-AzVMExtension -ResourceGroupName $vmRG -VMName $VM -Name $extensionName -Status
                foreach ($vmStatus in $status.Statuses) { 
                         $BigfixPortSucAgent = "BigFixPortEnablement"  
                         $successarrayagent = $successarrayagent + $BigfixPortSucAgent                      
                        Write-Output $vmStatus.Message
                }
                 $bigfixport = $false
                Write-Host "######################  BigFixport Enablement Port-53211 Completed ######################"
        }
        catch {
                Write-Host "########### Error in BigFixport Enablement Port-53211 ###########"   
                $BigfixPortErragent = "BigFixPortEnablement"
                $arrayagent = $arrayagent + $BigfixPortErragent        
                Write-Host $_
                $installationfailed= "true"
                $bigfixport = $true      
                Write-Host "###########End  Error in BigFixport Enablement Port-53211 ###########"        
            }             
        }

            if ($enableMonitoring -eq "true") {
            try { 
                Write-Host "############### Azure Monitor Agent Installation Process Starting ##########################"
                # Check identity
                if($vms.Identity.Type -ne "SystemAssigned") {
                    # Assign identity if needed
                    write-host "Enabling systemassigned Identity starting.....!"
                    $update = Update-AzVM -ResourceGroupName $vmRG -VM (get-AzVM -Name $VM -ResourceGroupName $vmRG) -IdentityType SystemAssigned
                    Write-Output "Assigned system managed identity"
                }
                #Installing Agent via Exception
                write-host "Azure Monitor agent installation Starting......."
                #check extension is there or not?
                $agentextension = Get-AzVMExtension -ResourceGroupName $vmRG -VMName $VM -Name "AzureMonitorLinuxAgent" -Status -ErrorAction SilentlyContinue
                if($agentextension -eq $null){
                    Write-Output "Setting VM Extensions AzureMonitorLinuxAgent started ...."
                    $result = Set-AzVMExtension -Name AzureMonitorLinuxAgent -ExtensionType AzureMonitorLinuxAgent -Publisher Microsoft.Azure.Monitor -ResourceGroupName $vmRG -VMName $vm_name_list -Location $vms.location -TypeHandlerVersion "1.1" -EnableAutomaticUpgrade $true
                    Write-Output "Setting VM Extensions AzureMonitorLinuxAgent Completed ...."
                }
                $status =Get-AzVMExtension -ResourceGroupName $vmRG -VMName $VM -Name AzureMonitorLinuxAgent -Status
                foreach ($vmStatus in $status.Statuses) { 
                    $AzureMonitoragent = "AzureMonitorLinuxAgent"  
                    $successarrayagent = $successarrayagent + $AzureMonitoragent                      
                    Write-Output $vmStatus.Message
                }
                $enableMonitoring = $false
                Write-Host "Successfully Installed linux agent"
                #Adding DCR Rule
                $AddDCRRule = Add-DCRRule -VM $VM -osresourceid $osresourceid -vmLocation $vmLocation
                Write-Host "######################  AzureMonitoragent Installtion is Completed ######################"
            } 
            catch {
                write-output "########  Error in installing Azure monitor Linux Agent!..... ########"
                Write-Host $_.Exception
                $AzureMonitoragent = "AzureMonitorLinuxAgent"
                $arrayagent = $arrayagent + $AzureMonitoragent        
                Write-Host $_
                $installationfailed= "true"
                $enableMonitoring = $true      
                Write-Host "###########End  Error in installing Azure monitor Linux Agent ###########" 
            }
        }
        # Enabling System Assigned Identity and Installing AMA AGent in VM. 
       

        Write-Host $installationSucceeded $installationfailed
        if ($installationfailed -eq "true") {
            $installationSucceeded = "false"            
            $retryCount++
            if($retryCount -ne $maxRetries){                
                foreach($i in $arrayagent){
                 Write-Host "$arrayagent[$i] agent is failed and set the flag to retry once."
                }               
                $arrayagent = @()
            }                          
            }
            else{
                $installationSucceeded = "true"
                 Write-Host "All Agent installation is successfull"
                break;
            }
    }
        $rainierMessage = $null         
        foreach ($err in $arrayagent) {
            $catchedError = $true
            if ($successarrayagent -contains $err) {
                $successarrayagent = $successarrayagent | Where-Object { $_ -ne $err }
            }
            if($err -eq "BigFixPortEnablement"){
                $rainierMessage += "$err is Failed.`n"
                continue 
            }
            $rainierMessage += "$err agent Installation is failed.`n" 
                           
        }
        foreach ($succ in $successarrayagent) {
            if($succ -eq "BigFixPortEnablement"){
                $rainierMessage += "$succ is successful.`n"
                continue 
            }
            $rainierMessage += "$succ agent Installation is successful.`n"             
        }
        Write-Host "`n################################# $($VM) Agent Status ########################################################`n"

        Write-Output $rainierMessage 

        Write-Host "`n##############################################################################################################`n"

         if($catchedError){
                    $body = @{}
                    $body.Add("pipelinestatus", "Agent Installation Failed")
                    $body.Add("pipelinestatusinfo", "Failed : Check below agent status because the pipeline has failed.`n`n $rainierMessage")
                throw  "Check all agent status and logs because the pipeline has failed.`n`n $rainierMessage`n"            
            }
            else{
                    $body = @{}
                    $body.Add("pipelinestatus", "Success")
                    $body.Add("pipelinestatusinfo", "Success: Pipeline is successful and agent status below `n`n$rainierMessage`n"+"Pipeline status: Success. Project name: $($env:SYSTEM_TEAMPROJECT). Pipeline name: $($env:BUILD_DEFINITIONNAME). Build number: $($env:BUILD_BUILDNUMBER). Definition ID: $($env:SYSTEM_DEFINITIONID).")
                            
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
                $rmExt=Remove-AzVMExtension -ResourceGroupName $vmRGs -VMName $VM -Name $extensionName -Force
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
