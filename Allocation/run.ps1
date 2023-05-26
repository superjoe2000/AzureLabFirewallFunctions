# namespace for Azure Function execution
using namespace System.Net

# Input bindings are passed in via param block.
param($Request, $TriggerMetadata)

# Write to the Azure Functions log stream.
Write-Host "PowerShell HTTP trigger function processed a request."
# Start the Web Response body
$body = "This HTTP triggered function executed successfully."
$body += "`n"
    
# Get User Assigned Managed Identity
Connect-AzAccount -Identity 

# Get all Resource Groups associated with the subscription
$rgs = Get-AzResourceGroup

# Process each Resource Group
foreach ($rg in $rgs) {
    # Get all Firewalls in the Resource Group
    $fws = Get-AzFirewall -ResourceGroupName $rg.ResourceGroupName
    # Process each Firewall
    foreach ($fw in $fws) {
        Write-Host "Resource Group: "$rg.ResourceGroupName
        $body += "Resource Group: "
        $body += $rg.ResourceGroupName
        $body += "`n"
        Write-Host "  Firewall: "$fw.Name
        $body += "Firewall: "
        $body += $fw.Name
        $body += "`n"
        if ($fw.provisioningState -eq "Succeeded") {
            Write-Host "  Firewall in Succeeded state."
            $body += "  Firewall in Succeeded state."
            $body += "`n"
            $properState = $true
        }
        else {
            Write-Host "  Firewall not in Succeeded state."
            $body += "  Firewall not in Succeeded state."
            $body += "`n"
            $body += "    State: "
            $body += $fw.provisioningState
            $body += "`n"
            $properState = $false
        }
        if ($properState) {
            if ($fw.IpConfigurations.PrivateIpAddress) {
                Write-Host "    Firewall has Private IP"
                Write-Host "      Deallocating Firewall"
                $body += "    Firewall has Private IP.  Deallocating FW"
                $body += "`n"
                $fw.Deallocate()

                # Push Web Response
                Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
                        StatusCode = [HttpStatusCode]::OK
                        Body       = $body
                    })          
            }
            else {
                Write-Host "    Firewall does not have Private IP"
                Write-Host "      Allocating Firewall"
                $body += "    Firewall does not have Private IP.  Allocating FW"
                $body += "`n"
                $vnets = Get-AzVirtualNetwork -ResourceGroupName $rg.ResourceGroupName
                foreach ($vnet in $vnets) {
                    Write-Host "        VNet: "$vnet.Name
                    $body += "        VNet: "
                    $body += $vnet.Name
                    $body += "`n"
                    $pips = Get-AzPublicIpAddress -ResourceGroupName $rg.ResourceGroupName
                    foreach ($pip in $pips) {
                        if ($pip.Name -match $fw.Name) {
                            if ($pip.Name -match "mgmt") {
                                $manip = $pip
                            }
                            else {
                                $ip = $pip
                            }
                        }
                    }
                }
                Write-Host "        ip: "$ip.Name
                Write-Host "        manip: "$manip.Name
                $body += "        ip: "
                $body += $ip.Name
                $body += "`n"
                $body += "        manip: "
                $body += $manip.Name
                $body += "`n"
            
                $fw.Allocate($vnet, $ip, $manip)

                # Push Web Response
                Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
                        StatusCode = [HttpStatusCode]::OK
                        Body       = $body
                    })          
            }

            # Perform write to Firewall after Web Response to avoid timeout
            Write-Host "Write change to Firewall"
            $fw | Set-AzFirewall
            Write-Host "  Firewall updated"
        }
        else {
            # Push Web Response
            Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
                StatusCode = [HttpStatusCode]::OK
                Body       = $body
            })          
        }
    }
}



