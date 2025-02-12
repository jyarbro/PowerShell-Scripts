<#
.SYNOPSIS
    Configures a static IP address and gateway for the active network adapter.

.DESCRIPTION
    This function removes any existing IPv4 address and default gateway from the active network adapter,
    and then configures the specified IP address, default gateway, and DNS addresses. If DNS is not provided,
    it defaults to using the Gateway address.

.PARAMETER Help
    Displays this help information.

.PARAMETER IP
    The static IP address to configure. Defaults to "192.168.0.100".

.PARAMETER Gateway
    The default gateway to configure. Defaults to "192.168.0.1".

.PARAMETER DNS
    Optional DNS server addresses. If not provided, defaults to the Gateway address.

.EXAMPLE
    Set-StaticIPAndGateway -IP "192.168.0.100" -Gateway "192.168.0.1"
    Configures the IP address and gateway and sets DNS to the gateway.

.EXAMPLE
    Set-StaticIPAndGateway -IP "192.168.0.100" -Gateway "192.168.0.1" -DNS "8.8.8.8","8.8.4.4"
    Configures the IP address, gateway, and DNS server addresses as specified.
#>

function Set-StaticIPAndGateway {
    [CmdletBinding()]
    param(
        [Alias("?")]
        [switch]$Help,

        [Parameter(Position = 0)]
        [string]$IP = "192.168.0.100",

        [Parameter(Position = 1)]
        [string]$Gateway = "192.168.0.1",

        [Parameter(Position = 2)]
        [string[]]$DNS
    )

    if ($Help) {
        Get-Help -Detailed $MyInvocation.MyCommand.Name
        return
    }

    # If DNS is not provided, default it to the Gateway address.
    if (-not $DNS) {
        $DNS = $Gateway
    }

    # Retrieve the active network adapter.
    $adapter = Get-NetAdapter | Where-Object { $_.Status -eq "up" }
    if (-not $adapter) {
        Write-Warning "No active network adapter found."
        return
    }

    $ipConfig = $adapter | Get-NetIPConfiguration

    # Remove any existing IPv4 address if present.
    if ($ipConfig.IPv4Address.IPAddress) {
        $adapter | Remove-NetIPAddress -AddressFamily "IPv4" -Confirm:$false
    }

    # Remove any existing default gateway if present.
    if ($ipConfig.Ipv4DefaultGateway) {
        $adapter | Remove-NetRoute -AddressFamily "IPv4" -Confirm:$false
    }

    # Configure the IP address and default gateway.
    $adapter | New-NetIPAddress -AddressFamily "IPv4" -IPAddress $IP -PrefixLength 24 -DefaultGateway $Gateway

    # Configure the DNS client server IP addresses.
    $adapter | Set-DnsClientServerAddress -ServerAddresses $DNS
}
