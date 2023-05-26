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
                Write-Host "    Firewall has Private IP.  Firewall is Allocated"
                $body += "    Firewall has Private IP.  Firewall is Allocated"
                $body += "`n"
            }
            else {
                Write-Host "    Firewall does not have Private IP.  Firewall is Deallocated"
                $body += "    Firewall does not have Private IP.  Firewall is Deallocated"
                $body += "`n"
            }
        }
        # Push Web Response
        Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
                StatusCode = [HttpStatusCode]::OK
                Body       = $body
            })          
    }
}



