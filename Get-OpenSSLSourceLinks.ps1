#
# Get-OpenSSLSourceLinks
# Krzysztof Cieślak K!2018
# 2018-02-26
#
#
param (
    [parameter()]
    [switch]$WithoutFips,

    [parameter()]
    [switch]$WithoutPre
)

function GetLinksFromWebPage {
    param (
        $address = "https://www.openssl.org/source/"
    )

    $openssl_webpage = wget $address
    $source_table = $openssl_webpage.ParsedHtml.IHTMLDocument2_body.getElementsByTagName("TABLE")[0];
    $result = @();
    $source_table.getElementsByTagName("TR") | select -Skip 1 | % {
        $row = "" | select Date, Name, Link
        $_.getElementsByTagName("TD") | select -Skip 1 | % {
            $links = $_.getElementsByTagName("A")
            if ($links.Length -eq 0) {  
                $row.Date = [datetime]$_.outerText
            } else {
                $row.Name = $links[0].outerText -replace ".tar.gz",""
                $row.Link = $address+$links[0].outerText
            }
        }
        $result += $row
    }
    $result;
}

$links = GetLinksFromWebPage | 
    ? {  ($_.Name -notlike "*fips*" -or -not $WithoutFips) } | 
    ? {  ($_.Name -notlike "*pre*" -or -not $WithoutPre) }
$links; 
