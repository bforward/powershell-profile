oh-my-posh --init --shell pwsh --config ~/Documents/PowerShell/terminal.omp.json | Invoke-Expression
$scripts = "$(split-path $profile)\Scripts"
$modules = "$(split-path $profile)\Modules"
$docs    =  $(resolve-path "$Env:userprofile\documents")
$desktop =  $(resolve-path "$Env:userprofile\desktop")


function Get-Domain {

    [CmdletBinding()]
    Param (
        [Parameter(Mandatory,ValueFromPipeline)]
        [string]$InputString
    )

    try {
        $Domain = ([Net.Mail.MailAddress]$InputString).Host
    }
    catch {
        $Domain = ([System.Uri]$InputString).Host
    }

    if (($null -eq $Domain) -or ($Domain -eq "")) {$Domain = $InputString}
    $Domain = $Domain -replace '^www\.',''

    Write-Output $Domain
}

function Get-MXConfig {
    [CmdletBinding()]

    Param (
        [Parameter(Mandatory,ValueFromPipeline)]
        [string]$DomainRequest,
        [string]$DKIMSelector,
        [string]$Server,
        [switch]$GetMXBanner
    )

    $Domain = Get-Domain $DomainRequest
    
    if ($Server) {
        $MX = Resolve-DnsName -Server $Server -Type MX -Name $Domain | ? Type -eq MX | Select @{L="Host"; E={$_.NameExchange}}, Preference | Sort-Object Preference 
        $SPF = Resolve-DnsName -Server $Server -Name $Domain -Type TXT -Erroraction SilentlyContinue | ? {$_.Strings -match "v=spf1"} | Select -ExpandProperty Strings
        $DMARC = Resolve-DnsName -Server $Server -Name "_dmarc.$Domain" -Type TXT -Erroraction SilentlyContinue | ? {$_.Strings -match "v=DMARC1"} | Select -ExpandProperty Strings
    } else {
        $MX = Resolve-DnsName -Type MX -Name $Domain | ? Type -eq MX | Select @{L="Host"; E={$_.NameExchange}}, Preference | Sort-Object Preference 
        $SPF = Resolve-DnsName -Name $Domain -Type TXT -Erroraction SilentlyContinue | ? {$_.Strings -match "v=spf1"} | Select -ExpandProperty Strings
        $DMARC = Resolve-DnsName -Name "_dmarc.$Domain" -Type TXT -Erroraction SilentlyContinue | ? {$_.Strings -match "v=DMARC1"} | Select -ExpandProperty Strings
    }

    $MXDiag = [PSCustomObject]@{
        Domain = $Domain
        MX = $MX
        SPF = $SPF
        DMARC = $DMARC
    }

    if ($DKIMSelector) {
        $DKIM = Resolve-DnsName -Name "$DKIMSelector._domainkey.$Domain" -Type TXT -Erroraction SilentlyContinue | ? Type -eq TXT
        $DKIM = $DKIM | % {$_.Strings -join ""}
        $MXDiag | Add-Member -MemberType NoteProperty -Name DKIM -Value $DKIM
    }

    if (($GetMXBanner) -and ($null -ne $MXDiag.MX)) {
        $MXDiag.MX | % {
            try {
                $TCPClient = [System.Net.Sockets.TcpClient]::new($_.Host,25)
                $Stream = $TCPClient.GetStream() 
                $Data = [System.Byte[]]::new(2048) 
                $Stream.Read($Data,0,$Data.Length) | Out-Null
                $Banner = ([System.Text.Encoding]::ASCII.GetString($Data)).Trim([char]$null)
                $_ | Add-Member -MemberType NoteProperty -Name Banner -Value $Banner
                $Stream.Dispose()
                $TCPClient.Dispose()
            }
            catch {
                Write-warning $_.Exception.Message
            }
        }
    }
    
    Write-Output $MXDiag
}