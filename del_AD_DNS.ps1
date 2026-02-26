# Requires the ActiveDirectory and DnsServer modules
Import-Module ActiveDirectory, DnsServer

# Connect to AD DC
Add-Computer -DomainName "corp.usbakery.com" -Credential (Get-Credential) -Restart

function Remove-ADComputerAndDns($ComputerName, $DnsZoneName) {
    Write-Host "Attempting to remove $ComputerName from Active Directory and DNS..." -ForegroundColor Cyan

    # 1. Remove from Active Directory
    try {
        $adComputer = Get-ADComputer -Identity $ComputerName -ErrorAction Stop
        Remove-ADComputer -Identity $adComputer -Confirm:$false
        Write-Host "Successfully removed AD computer object: $ComputerName" -ForegroundColor Green
    }
    catch {
        Write-Host "Error removing AD computer object for $ComputerName: $_" -ForegroundColor Red
    }

    # 2. Remove associated DNS records (A and PTR records)
    # Note: DNS record removal requires the DnsServer module and appropriate permissions
    try {
        # Remove A (Host) records
        $aRecords = Get-DnsServerResourceRecord -ZoneName $DnsZoneName -Name $ComputerName -RecordType A -ErrorAction SilentlyContinue
        if ($aRecords) {
            foreach ($record in $aRecords) {
                Remove-DnsServerResourceRecord -ZoneName $DnsZoneName -Name $ComputerName -RecordType A -Force -Confirm:$false
                Write-Host "Successfully removed DNS A record for $ComputerName" -ForegroundColor Green
            }
        }
        else {
            Write-Host "No DNS A record found for $ComputerName in zone $DnsZoneName" -ForegroundColor Yellow
        }

        # Remove PTR (Pointer) records (Reverse Lookup)
        # This part requires the reverse lookup zone name, which is more complex to generalize. 
        # Manual deletion might be necessary if reverse zones are not consistently named.
        # The script below assumes a standard reverse lookup zone.
        
        # Example for a 10.x.x.x network (10.in-addr.arpa)
        # To make this dynamic, you'd need the IP and to calculate the reverse zone name.
        # As an alternative, rely on DNS scavenging to clean up PTR records automatically.

    }
    catch {
        Write-Host "Error removing DNS records for $ComputerName: $_" -ForegroundColor Red
    }
}

# --- Example Usage ---
# Replace 'ComputerNameToRemove' with the actual name of the computer
# Replace 'yourdomain.com' with your actual forward lookup DNS zone name
Remove-ADComputerAndDns -ComputerName 'ComputerNameToRemove' -DnsZoneName 'yourdomain.com'
