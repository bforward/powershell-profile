# powershell-profile
Personal Powershell profile, scripts and modules


#### Function Get-Domain:

    PS C:\> Get-Domain "test@microsoft.com
    microsoft.com``

#### Function Get-MXConfig:

    PS C:\> mxconf test@microsoft.com | fl

    Domain : microsoft.com
    MX     : @{Host=microsoft-com.mail.protection.outlook.com; Preference=10}
    SPF    : v=spf1 include:_spf-a.microsoft.com include:_spf-b.microsoft.com include:_spf-c.microsoft.com include:_spf-ssg-a.microsoft.com include:spf-a.hotmail.com include:_spf1-meo.microsoft.com -all
    DMARC  : v=DMARC1; p=reject; pct=100; rua=mailto:d@rua.agari.com; ruf=mailto:d@ruf.agari.com; fo=1

https://xkln.net/blog/getting-mx-spf-dmarc-dkim-and-smtp-banners-with-powershell/