function Use-Less
{
    <#
    .Synopsis
        Creates a .CSS file from a .LESS file
    .Description
        Uses DotLess to create a .CSS file from a .LESS file. 
    .Link
        http://lesscss.org/
    .Link
        http://www.dotlesscss.org/
    .Example
        Use-Less -LessCss ".example {width: 10 + 10 px}"
    #>
    [OutputType([string])]
    param(
    # The Less CSS content.  To learn how to use LessCSS, visit the [LessCSS website](http://lesscss.org/)
    #|LinesForInput 50
    [Parameter(Mandatory=$true,Position=0,ValueFromPipelineByPropertyName=$true)]
    [string]
    $LessCss,
    
    # If provided, will change variables in the LESS CSS file prior to compiling it.
    [Parameter(Position=1,ValueFromPipelineByPropertyName=$true)]
    [Hashtable]
    $Option            
    )

    process {
        if (-not ('Dotless.core.less' -as [type])) {

            # Find the less tool
            $lessTool = Get-ChildItem -Path $env:Temp\DotLess\dotless.Core.dll -ErrorAction SilentlyContinue
        
            # If it's not found, download it
            if (-not $lessTool) {
                # Get the downlaods page
                $dotLessLinks = Get-Web -Url "https://github.com/dotless/dotless/downloads" -UseWebRequest -Tag 'a' 
                # Find the latest build
                $dotLessLink = $dotLessLinks | 
                    Where-Object { $_.Xml.Href -like "*.zip" -and $_.Xml.InnerText -like "*dotless*" }| 
                    Select-Object -First 1  

                # Download it
                $zipContent = Get-Web -Url ("https://github.com" + $dotLessLink.Xml.Href) -UseWebRequest -AsByte 
            
                # Save it
                [IO.File]::WriteAllBytes("$env:Temp\dotless.zip", $zipContent)

                # Expand it
                Expand-Zip -ZipPath "$env:Temp\dotless.zip" -OutputPath "$env:Temp\DotLess"          
            }

        }

        

        if ($Option) {
            $lessLines = $LessCss -split "[$([Environment]::NewLine)]" -ne ''

            $newLess = foreach ($line in $lessLines) {
                if ($line -like "@*:*" -and $line -notlike "@*:*@*") {
                    $optionName = ($line -split ":")[0].TrimStart('@')
                    if ($option.$optionName) {
                        "@${optionName}:$($Option.$optionName);"
                    } else {
                        $line 
                    }
                } else {
                    $line
                }
            }

            $LessCss = $newLess -join ([Environment]::NewLine)
        }

        
        # Get the less tool again
        $lessTool = Get-ChildItem -Path $env:Temp\DotLess\dotless.core.dll

        # Quit if we can't
        if (-not $lessTool) { return } 
        

        $null = [Reflection.Assembly]::LoadFrom($lessTool.Fullname)

        # Run it
        $lessResult = [dotless.Core.less]::Parse($LessCss)

        $lessResult
        
        
        

    }
}




 
 
