param (
	[Parameter(Mandatory=$true)][string]$IP = "192.168.7.100",
	[Parameter(Mandatory=$true)][string]$Gateway = "192.168.7.1"
)

# Retrieve the network adapter that you want to configure
$adapter = Get-NetAdapter | ? {$_.Status -eq "up"}

# Remove any existing IP, gateway from our ipv4 adapter
If (($adapter | Get-NetIPConfiguration).IPv4Address.IPAddress) {
	$adapter | Remove-NetIPAddress -AddressFamily "IPv4" -Confirm:$false
}

If (($adapter | Get-NetIPConfiguration).Ipv4DefaultGateway) {
	$adapter | Remove-NetRoute -AddressFamily "IPv4" -Confirm:$false
}

 # Configure the IP address and default gateway
$adapter | New-NetIPAddress -AddressFamily "IPv4" -IPAddress $IP -PrefixLength 24 -DefaultGateway $Gateway

# Configure the DNS client server IP addresses
$adapter | Set-DnsClientServerAddress -ServerAddresses $DNS