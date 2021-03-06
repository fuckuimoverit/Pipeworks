@{                         
    SecureSetting = 'AzureStorageAccountName', 'AzureStorageAccountKey'
    
    Blog = @{
        Name = "Update-Web"
        Description = "PowerShell, Pipeworks and the Semantic Web"        
        Keywords = 'Azure', 'JQuery', 'PowerShell'
        Posts = '*'
    }
    
    GoogleSiteVerification  = 'xjCcGADm2Pnu7fF3WZnPj5UYND9SVqB3qzJuvhe0k1o'
    BingValidationKey = '7B94933EC8C374B455E8263FCD4FE5EF'
    
    Table = @{
        Name = 'Pipeworks'
        StorageAccountSetting = 'AzureStorageAccountName'
        StorageKeySetting = 'AzureStorageAccountKey'
    }
    
    Logo = "/Assets/PowershellPipeworks_150.png"

    ShowTweet = $true
        
    ModuleTemplate = 'Module-InvertedHeader'
    CommandTemplate = 'Command-InvertedHeader'    
    TopicTemplate = 'Topic-InvertedHeader'    
    
    Style = @{
        body = @{
            "font-family" = "'Segoe UI', 'Segoe UI Symbol', Helvetica, Arial, sans-serif"            
            'font-size' = "1.1em"
            'color' = '#0248B2'
            'background-color' = '#F6FBF6'
        }
        'a' = @{
            'color' = '#012456'            
        }
        
        '.MajorMenuItem' = @{
            'font-size' = 'large'
        }
        '.MinorMenuItem' = @{
            'font-size' = 'medium'            
        }
        '.ExplanationParagraph' = @{
            'font-size' = 'medium'
            'text-indent' = '-10px'
        }
        '.ModuleWalkthruExplanation' = @{
            'font-size' = 'medium'       
            'margin-right' = '3%'       
        }

        '.ModuleWalkthruOutput' = @{
            'font-size' = 'medium'           
        }
        '.PowerShellColorizedScript' = @{
            'font-size' = 'medium'
        }
        
    }    
    WebCommand = @{
        "Write-Link" = @{
            HideParameter = "AmazonAccessKey", "AmazonSecretKey", "AmazonReturnUrl",  "AmazonInputUrl", 
                "AmazonIpnUrl", "UseOAth", "CollectShippingAddress", "AmazonAbandonUrl", "ToFacebookLogin", 
                "FacebookAppId", "ModuleServiceUrl", "FacebookLoginScope", "AmazonPaymentsAccountID", "GoogleCheckoutMerchantID", "SortedLinkTable"
            PlainOutput = $true
            
        }        
        "New-PipeworksManifest" = @{
            ContentType = 'text/plain'
        }
        
        
        "ConvertFrom-Markdown" = @{                        
            ParameterAlias = @{
                'm' = 'Markdown'
                'md' = 'Markdown'
            }
            FriendlyName = "Mess With Markdown"                        
            HideParameter = 'Splat'
        }
               
        "Write-ScriptHTML" = @{
            
            PlainOutput = $true
            HideParameter = @('Palette', 'Start', 'End', 'Script')
            ParameterOrder = 'Text'
            ParameterAlias = @{
                't'= 'Text'
                
            }
            FriendlyName = "Show Scripts as HTML"                        
        }
        "Write-ASPDotNetScriptPage" = @{
            
            ContentType = "text/plain"         
            HideParameter = @('MasterPage', 'CodeFile',  'Inherit', 'RunScriptMethod', 'FileName')            
            FriendlyName = "PowerShell in ASP.NET"                        
        }

        "Write-Crud" = @{
            ContentType = "text/plain"         
            PlainOutput = $true
        }
        
        
        
    }
    
    Group = @{
        "Getting Started" = "About PowerShell Pipeworks", "Pipeworks Quickstart", "The Pipeworks Manifest", 'From Script To Software Service', "What Pipeworks Does", "Scripting Securely with SecureSettings", "NOHtml Sites"
    }, @{
        "Play with Pipeworks" = "Write-ASPDotNetScriptPage", "ConvertFrom-Markdown", "Making Editing Easier With Markdown", "Write-ScriptHTML", "Making Tables with Out-HTML", "Working with Write-Link"
    }, @{
        "Connecting the Clouds" = "Get-Paid with Stripe", "Getting GitIt", "Get-Web Content From Anywhere", "Pick up the Phone with Pipeworks", "Implicit Texting with Twilio", "The Wonders of Wolfram Alpha", "Using Azure Table Storage in Pipeworks", "Simplified SQL", "Building with Blob Storage", "Publishing Pipeworks to Azure", 'Looking Up Locations With Resolve-Location'
    }, @{
        "Join Windows and Web" = "Why Windows", "Scripting with Superglue", "Integrated Intranet", "Simpler SEO"
    }


    TrustedWalkthrus = 'New-Region Billboard','Making Tables With Out-HTML', 'New-Region And JQueryUI','Working with Write-Link', 'Making Editing Easier with Markdown', 'From Script To Software Service'
    WebWalkthrus = 'New-Region Billboard','Making Tables With Out-HTML', 'Using Write-Link', 
        'New-Region And JQueryUI', 'Working with Write-Link', 'Making Editing Easier with Markdown'
        
    
    AnalyticsId = 'UA-24591838-13'
    
   
    Facebook = @{
        AppId = '250363831747570'
    }
    
    DomainSchematics = @{
        "PowerShellPipeworks.com | www.PowerShellPipeworks.com" = "Default"
    }
    
    AllowDownload = $true

    
    MainRegion = @{
        AsNewspaper = $true
        NewspaperColumn = .5, .5, .5, .5, 1        
        UseButtonForNewspaperHeadline = $true
        NewspaperHeadingAlignment = 'center'
    }

    Win8 = @{
        Identity = @{
            Name="Start-Automating.PowerShellPipeworks"
            Publisher="CN=3B09501A-BEC0-4A17-8A3D-3DAACB2346F3"
            Version="1.0.0.0"
        }
        Assets = @{
            "splash.png" = "/PowerShellPipeworks_Splash.png"
            "smallTile.png" = "/PowerShellPipeworks_Small.png"
            "wideTile.png" = "/PowerShellPipeworks_Wide.png"
            "storeLogo.png" = "/PowerShellPipeworks_Store.png"
            "squaretile.png" = "/PowerShellPipeworks_Tile.png"
        }
        ServiceUrl = "http://PowerShellPipeworks.com"

        Name = "PowerShell Pipeworks"

    }

    HideUngrouped = $true
    HideDataInTopic = $true


    Technet = @{
        Category="Windows Azure"
        Subcategory="Cloud Services"
        OperatingSystem="Windows 7", "Windows Server 2008", "Windows Server 2008 R2", "Windows Vista", "Windows Server 2012", "Windows 8"
        Tag ='Pipeworks', 'Start-Automating', 'Azure', 'SQL', 'SecureSettings', 'Web Pages', 'Software Services'
        MSLPL=$true
        Summary="
PowerShell Pipeworks is a platform for writing web sites and software services in PowerShell.  It lets you turn any module into a software service, script cloud services, deal with data, and automate backend processing.  In short, it lets you put it all together with PowerShell.
"
        Url = 'http://gallery.technet.microsoft.com/Pipeworks-c0560540'
    }    


    GitHub = @{
        Owner = "StartAutomating"
        Project = "Pipeworks"
        Url = 'https://github.com/StartAutomating/Pipeworks'
    }
    #Inline = '*'
} 
