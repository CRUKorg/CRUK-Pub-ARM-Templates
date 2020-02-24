#Powershell script to set up NIC on Azure VM
#Region IP settings
#Vars
$nicToSet = Get-NetIPAddress -AddressFamily IPv4 -InterfaceAlias 'Ethernet'
$nicAlias = ($nicToSet).InterfaceAlias
$newIP = ((Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.IPAddress -match '10.' }).IPAddress)
$newSubnet = ((Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.IPAddress -match '10.' }).PrefixLength)
$newGateway = ((Get-NetIPConfiguration).IPv4DefaultGateway).nexthop
#endregion

#Region DNS Settings
#Vars
$dnsIndex = (Get-NetAdapter).ifIndex
$DNSServers = ((Get-NetIPConfiguration).dnsserver ).serveraddresses | Where-Object { $_ -match '10.' } 
$newDNSServers = $DNSServers -join ','
#endregion

#Remove Current
Remove-NetIPAddress -InterfaceAlias $nicAlias -Confirm:$false
Remove-NetRoute -InterfaceAlias $nicAlias -Confirm:$false

#Set New
try{
New-NetIPAddress -InterfaceAlias $nicAlias -IPAddress $newIP -PrefixLength $newSubnet -DefaultGateway $newGateway
Set-DnsClientServerAddress -InterfaceIndex $dnsIndex -ServerAddresses $newDNSServers

$out =@()
$out = New-Object customObject @{
    NewIP = $newIP
    $newSubnet = $newSubnet
    Info = "Success"
}
$out | Export-Csv C:\info.csv
}
catch{
    $out = "Operation has failed"
    $out | Out-File C:\fail.txt
}

#endregion
