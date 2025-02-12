function Enable-Dhcp {
    param(
        [string]$IPType = "IPv4"
    )

    # Get an active network adapter
    $adapter = Get-NetAdapter | Where-Object { $_.Status -eq "up" }
    if (-not $adapter) {
        Write-Warning "No active network adapter found."
        return
    }

    # Get the corresponding network interface for the adapter
    $interface = $adapter | Get-NetIPInterface -AddressFamily $IPType

    if ($interface.Dhcp -eq "Disabled") {
        # Remove existing default gateway if it exists
        $ipConfig = $interface | Get-NetIPConfiguration
        if ($ipConfig.Ipv4DefaultGateway) {
            $interface | Remove-NetRoute -Confirm:$false
        }

        # Enable DHCP on the interface
        $interface | Set-NetIPInterface -DHCP Enabled

        # Configure the DNS Servers automatically by resetting to defaults
        $interface | Set-DnsClientServerAddress -ResetServerAddresses
    }
}
