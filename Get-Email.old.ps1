function Get-Email
{
    <#
    .Synopsis
        Gets email from exchange
    .Description
        Gets email in an inbox using exchange web services.
    
    #>
    param(
    # If set, will only show the first N items
    [Parameter(ValueFromPipelineByPropertyName=$true)]
    [int]$First,
    
    # If set, will not get detail
    [Parameter(ValueFromPipelineByPropertyName=$true)]
    [switch]$DoNotGetDetail,
    
    # If set, will download attachments
    [Parameter(ValueFromPipelineByPropertyName=$true)]
    [Switch]$DownloadAttachment,
      
    # If set, will include only the content from this message, not the whole thread  
    [Parameter(ValueFromPipelineByPropertyName=$true)]
    [switch]$ExcludeThread,
    
    # A search term.  By default, the searchterm will search for the From field
    [Parameter(ValueFromPipelineByPropertyName=$true)]
    [string]$SearchTerm,
    
    [Parameter(ValueFromPipelineByPropertyName=$true)]
    [ValidateScript({
        if (-not $script:ExchangeWebService) {
            return $true
            # throw "Must Be Connected To Exchange"
        } 
        
        $namespace = $script:exchangeWebService.GetType().Namespace        
        
        $values = [Enum]::GetValues(("$namespace.UnindexedFieldURIType" -as [type]))
        
        if ($Values -notcontains $_) {
            throw "Search Terms Must Use On of the Following ItemTypes: $($values -join ([Environment]::NewLine))" 
        }
        return $true
    })]
    [string]$SearchField = "messageFrom",
        
    # The exchange server
    [Parameter(ValueFromPipelineByPropertyName=$true)]
    [string]$ExchangeServer,
    
    # The credential used to connect
    [Parameter(ValueFromPipelineByPropertyName=$true)]
    [Management.Automation.PSCredential]
    $Credential,
    
    # If set, will treat the account as an Office365 account
    [Parameter(ValueFromPipelineByPropertyName=$true)]
    [Switch]$IsOffice365Account,
    
    # If set, gets email in a background job
    [Parameter(ValueFromPipelineByPropertyName=$true)]
    [Switch]$AsJob    
    ) 
        
    begin {
        $getExchangeItemProgressId = Get-Random
function Connect-Exchange
{
    [CmdletBinding(DefaultParameterSetName='ExchangeServer')]
    param(        
    [Parameter(Mandatory=$true,Position=0,ParameterSetName='ExchangeServer')]
    [Parameter(Mandatory=$true,Position=0,ParameterSetName='Office365')]
    [Management.Automation.PSCredential]
    $Account,
    
    [Parameter(Mandatory=$true,Position=1,ParameterSetName='ExchangeServer')]
    [Parameter(Mandatory=$true,Position=1,ParameterSetName='UseDefaultCredential')]    
    [string]
    $ServerName,
        
    [Parameter(Mandatory=$true,Position=1,ParameterSetName='Office365')]
    [Switch]
    $IsOffice365Account,
    
    [Parameter(Mandatory=$true,Position=1,ParameterSetName='UseDefaultCredential')]
    [Switch]
    $UseDefaultCredential,
    
    # If set, will attempt to connect to a remote powershell session as well as exchange web services 
    [Switch]
    $ForAdministration
    )
    
    
    process {
        
        
        if (-not $UseDefaultCredential) {
            if ($account.username -match "(.+)@(.+)") 
            {
                $username = $matches[1]
                $script:hostedExchangeEmail = $account.UserName
            }
            else
            {
                $username = $account.username
            }
        }
        
        if ($psCmdlet.ParameterSetName -eq 'Office365') {
            if ($script:ExchangeWebService -and $script:CachedCredential.Username -eq $script:CachedCredential) {
                return
            }    
            $ExchangeServer = "https://ps.outlook.com/"
            Write-Progress "Connecting to Office365" "$exchangeServer"
            $script:CachedCredential = $Account
            
            
            $MbMailbox = $account.Username  
            $AutoDiscoURL = "https://ps.outlook.com/autodiscover/autodiscover.xml"
            
            $ncCred = New-Object Net.NetworkCredential $account.UserName,$account.GetNetworkCredential().Password
  
            $autoDiscoverXML = @"
<Autodiscover xmlns="http://schemas.microsoft.com/exchange/autodiscover/outlook/requestschema/2006">
    <Request>
        <EMailAddress>$MbMailbox</EMailAddress>
        <AcceptableResponseSchema>http://schemas.microsoft.com/exchange/autodiscover/outlook/responseschema/2006a</AcceptableResponseSchema>
    </Request>
</Autodiscover>
"@;  
        

            $adAutoDiscoRequest = [Net.HttpWebRequest]::Create($AutoDiscoURL)  
  
              
            $bytes = [Text.Encoding]::UTF8.GetBytes($autoDiscoverXML )
            $adAutoDiscoRequest.ContentLength = $bytes.Length
            $adAutoDiscoRequest.ContentType = "text/xml"  
            $adAutoDiscoRequest.Headers.Add("Translate", "F")  
            $adAutoDiscoRequest.Method = "POST" 
            $adAutoDiscoRequest.Credentials = $ncCred  
              
            $rsRequestStream = $adAutoDiscoRequest.GetRequestStream();  
            $rsRequestStream.Write($bytes, 0, $bytes.Length);  
            $rsRequestStream.Close();  
            $adAutoDiscoRequest.AllowAutoRedirect = $false;  
            $adResponse = $adAutoDiscoRequest.GetResponse();  
            $Redirect = $adResponse.Headers.Get("Location");  
            if ($Redirect)  
            {  
                $adAutoDiscoRequest = [Net.HttpWebRequest]::Create($Redirect);  
                $adAutoDiscoRequest.ContentLength = $bytes.Length;  
                $adAutoDiscoRequest.ContentType = "text/xml";  
                $adAutoDiscoRequest.Headers.Add("Translate", "F");  
                $adAutoDiscoRequest.Method = "POST";  
                $adAutoDiscoRequest.Credentials = $ncCred;  
                $rsRequestStream = $adAutoDiscoRequest.GetRequestStream();  
            }  
            $rsRequestStream.Write($bytes, 0, $bytes.Length);  
            $rsRequestStream.Close();  
            $adResponse = $adAutoDiscoRequest.GetResponse();  
            $rsResponseStream = $adResponse.GetResponseStream();  
            $reResponseDoc = new-object Xml.XmlDocument;  
            $reResponseDoc.Load($rsResponseStream);  
            $pfProtocolNodes = $reResponseDoc.GetElementsByTagName("Protocol");  
            
            $finalUri = $reResponseDoc | 
                Select-Xml //* | 
                Where-Object {$_.Node.Name -eq 'OWAUrl' -and $_.Node.SelectSingleNode("..").Name -eq 'External' }  |
                ForEach-Object {
                    $_.Node.InnerText
                }
                            
            $finalUri = $finalUri.Substring(0, $finalUri.IndexOf("/owa"))
            $finalUri = $finalUri + "/ews/exchange.asmx"
            $exchangeServer = $finalUri
        } else { 
            $ExchangeServer = $ServerName
        }
               
        
        Write-Progress "Exchange Server Discovered" "$exchangeServer"
        $uri = "$ExchangeServer".TrimEnd('/') + '/ews/exchange.asmx'
        $wsdl = "$ExchangeServer".TrimEnd('/') + '/ews/services.wsdl'
        $script:ExchangeWebService  = $null
        $script:ExchangeWebServiceNamespace = $null
        
        
        if ($finaluri) { 
            $wsdl = "$finalUri".Replace('/ews/exchange.asmx', '/ews/services.wsdl')
        } 
                
        if ($Account) {
            $script:ExchangeWebService = New-WebServiceProxy -Uri $wsdl -Credential $Account 
        } else {
            $script:ExchangeWebService= New-WebServiceProxy -Uri $wsdl -UseDefaultCredential 
        }
        
        if (-not $script:ExchangeWebService) {             
            return 
        }             
        
        Write-Progress "Connected to Exchange!" "$exchangeServer"
        
        $script:ExchangeWebServiceNamespace = $exchangeWebService.GetType().Namespace

        $script:exchangeWebService.RequestServerVersionValue = New-object "$ExchangeWebServiceNamespace.RequestServerVersion"
        if (-not $exchangeVersion) {
            $exchangeVersion = ([int[]][Enum]::GetValues(("$ExchangeWebServiceNamespace.ExchangeVersionType" -as [Type]))) | 
                Sort-Object | 
                Select-Object -Last 1 
        }
        $script:exchangeWebService.RequestServerVersionValue.Version = 
            ("$ExchangeWebServiceNamespace.ExchangeVersionType" -as [Type])::$exchangeVersion
        
        if ($FinalUri) {
            $script:exchangeWebService.Url = $finalUri
        } else {
            $script:exchangeWebService.Url = $uri                   
        }
        
        # If an account was set, make sure the web service has the credential information
        if ($Account) {
            $script:exchangeWebService.Credentials = $Account.GetNetworkCredential()
        }        
        
        
        # Find the correct time zone and set it, otherwise everything comes from UTC
        $tzRequestType = New-Object "$ExchangeWebServiceNamespace.GetServerTimeZonesType" -Property @{
            ReturnFullTimeZoneData=$true;
            ReturnFullTimeZoneDataSpecified=$true
        }
        $tzRequestType.Ids = "$([Timezone]::CurrentTimeZone.StandardName)"        
        $response = $script:exchangeWebService.GetServerTimeZones($tzRequestType)        
        # If the time zone was found, change the web service's time zone context.
              
        if ($response.responsemessages.items[0].ResponseClass -eq 'Success'){
            $tzd =    $response.responsemessages.items[0].timezonedefinitions
            $script:MyTimeZone = $tzd.TimeZoneDefinition
            $tzContext = New-Object "$ExchangeWebServiceNamespace.TimeZoneContextType"
            $tzContext.TimeZoneDefinition = $tzd.TimeZoneDefinition[0]
            $script:exchangeWebService.TimeZoneContext = $tzContext
        }
        
        
        if ($ForAdministration -and -not $script:administrationSession) {        
            $newSessionParameters = @{
                ConnectionUri='https://$exchangeServer/powershell'
                ConfigurationName='Microsoft.Exchange'
                Authentication='Basic'           
                Credential=$Account
                AllowRedirection=$true
                WarningAction = "silentlycontinue"
                SessionOption=(New-Object Management.Automation.Remoting.PSSessionOption -Property @{OpenTimeout="00:30:00"})
            }
            
            $Session = New-PSSession @newSessionParameters -WarningVariable warning         
        }
        
        
        
        if ($PassThru) {
            New-Object PSObject | 
                Add-Member NoteProperty ExchangeWebService $script:exchangeWebService -PassThru |
                Add-Member NoteProperty ExchangeWebService $script:administrationSession -PassThru # |            
        }
    }
}                       
        
        $script:getExchangeItem = { 
            param($findItem, $first, [switch]$DoNotGetDetail, [switch]$HideProgress) 
    $foundItems = New-Object Collections.ArrayList
    
    $findItem.Item = New-Object "$namespace.IndexedPageViewType" -Property @{
        MaxEntriesReturned = 120
        MaxEntriesReturnedSpecified = $true
    }

    $totalItems = 0
    
    do {
        if (-not $totalItems) {
            if (-not $hideProgress) {
                Write-Progress "Finding Items" "$($findItem.Item.Offset) - $($findItem.Item.Offset + $findItem.Item.MaxEntriesReturned)" -Id $getExchangeItemProgressId
            }
        } else {
            $percent = $findItem.Item.Offset * 100 / $totalItems
            if (-not $hideProgress) {
                Write-Progress "Finding Items" "$($findItem.Item.Offset) - $($findItem.Item.Offset + $findItem.Item.MaxEntriesReturned)" -Id $getExchangeItemProgressId -PercentComplete $percent
            }
        }
        
        $finditemresponses = $script:exchangeWebService.FindItem($findItem)
        $finditemresponses.ResponseMessages.Items | 
            Where-Object {$_.ResponseClass -eq 'Error' } |
            ForEach-Object {
                Write-Error -Message $_.MessageText
            }                                
    
        $noError = $finditemresponses.ResponseMessages.Items | 
            Where-Object { $_.ResponseCode -eq 'NoError' }
        $totalItems = $noError.RootFolder.TotalItemsInView
        $newItemIds = foreach ($ne in $noError) {
            foreach ($item in $ne.RootFolder.Item.Items) {
                if (-not $item) {continue }
                $item.ItemId.Id
                $null = $foundItems.Add((
                    New-Object PSObject -Property @{
                        Id = $item.ItemId.Id
                        Subject=  $item.Subject
                        Item = $item
                    }))
                
            }
        } 
        if ($first -and $foundItems.Count -ge $first)  { break }    
        $findItem.Item.Offset += 120            
    } while ($newItemIds -and $findItem.Item.Offset -lt $totalItems) 
    
    if ($DoNotGetDetail) { 
        if ($First)  {
            return $foundItems | Select-Object -First $first -ExpandProperty Item
        } else {
            return $foundItems | Select-Object -ExpandProperty Item
        }
    } 

    
    if ($foundItems) {                
        for ($itemNumber=  0; $itemNumber -lt $foundItems.Count;$itemNumber++) {
            $item = $foundItems[$itemNumber]
            $perc  = ($itemNumber / $foundItems.count) * 100
            Write-Progress "Getting Details" "$($item.Subject) " -PercentComplete $perc -Id $getExchangeItemProgressId
        
            $additionalItemsDetails = New-Object "$($script:exchangeWebService.GetType().Namespace).PathToUnindexedFieldType[]" 1
            $pathToUnindexedFileType = New-Object "$($script:exchangeWebService.GetType().Namespace).PathToUnindexedFieldType" -Property @{
                FieldURI = 'itemUniqueBody' -as ("$($script:exchangeWebService.GetType().Namespace).UnindexedFieldURIType" -as [type])
            }
            $additionalItemsDetails[0] = $pathToUnindexedFileType
            $getItemType = New-Object "$($script:exchangeWebService.GetType().Namespace).GetItemType" -Property @{
                ItemShape = New-Object "$($script:exchangeWebService.GetType().Namespace).ItemResponseShapeType" -Property @{
                    BaseShape = "AllProperties"
                    AdditionalProperties = $additionalItemsDetails
                }
                ItemIds = New-Object "$($script:exchangeWebService.GetType().Namespace).ItemIdType" -Property @{Id=$item.Id}
            }            
            try {
                $script:exchangeWebService.GetItem($getItemType)
            } catch {
                try {
                    $script:exchangeWebService.GetItem($getItemType)
                } catch {
                    Write-Error $_
                }
            }
            if ($first -and ($itemNumber  + 1) -ge $first)  { break }                 
            
        }                                
    }
    
    if (-not $hideProgress) {
        Write-Progress "Complete" " " -Id $getExchangeItemProgressId -Completed 
    }
}

$getBuriedItemDetail = {
    param($item, $property, $subProperty) 
    foreach ($i in $item.$property) { 
        if (-not $i) { continue } 
        $i.$subProperty
    }
}
        
    }
    
    
    process {   
        if ($AsJob) {
            $myDefinition = [ScriptBLock]::Create("function Get-Email {
$(Get-Command Get-Email | Select-Object -ExpandProperty Definition)
}
")
            $null = $psBoundParameters.Remove('AsJob')            
            $myJob= [ScriptBLock]::Create("" + {
                param([Hashtable]$parameter) 
                
            } + $myDefinition + {
                
                Get-Email @parameter
            }) 
            
            Start-Job -ScriptBlock $myJob -ArgumentList $psBoundParameters 
            return
        }
        
        if (-not $exchangeServer) { $isOffice365Account = $true } 
        if ($Credential -and ($ExchangeServer -or $IsOffice365Account)) {
            $connectParams = @{Account=$credential}
            
            if (-not $IsOffice365Account) {
                $connectParams += @{ServerName=$ExchangeServer}
            } else {
                $connectParams += @{IsOffice365Account=$IsOffice365Account}
            }
            $finalUrl = Connect-Exchange @connectParams
        }
        if (-not $script:ExchangeWebService) {
            #throw "Must be connected to exchange to Get-Email"
            #return                                                
        }
        
        
        
        
          
                 
        $namespace = $script:exchangeWebService.GetType().Namespace
    
        ## Create and Populate the Parent Folder ID Collection
        $parentfolderid = New-Object "$namespace.DistinguishedFolderIdType" -Property @{
            Id = ("$namespace.DistinguishedFolderIdNameType" -as [Type])::Inbox
        }        
        $parentFolderIds = $parentfolderid -as "$namespace.BaseFolderIdType[]"

        ## Create an ItemShape and set it to return All Properties
        $itemshape = New-Object "$namespace.ItemResponseShapeType"
        $itemshape.BaseShape = ("$namespace.DefaultShapeNamesType" -as [Type])::AllProperties

        ## Create the FindItemType object and populate with the Parent Folder Ids and Item Shape
        . ([ScriptBlock]::Create("[$namespace.FindItemType]`$finditemtype = New-Object `"$namespace.FindItemType`""))

        $finditemtype.ParentFolderIds = $parentfolderids
        $finditemtype.ItemShape = $itemshape
        
        if ($SearchTerm) {            
            $finditemtype.Restriction = 
                
                New-Object "$namespace.RestrictionType" -Property @{
                    "Item" = New-Object "$namespace.ContainsExpressionType" -Property @{
                        Item = New-Object "$namespace.PathToUnindexedFieldType" -Property @{
                            FieldURI = ("$namespace.UnindexedFieldURIType" -as [type])::$SearchField
                        }
                        ContainmentModeSpecified = $true
                        ContainmentMode = "FullString"
                        ContainmentComparison = "LooseAndIgnoreCase"
                        ContainmentComparisonSpecified = $true
                        Constant = New-Object "$namespace.ConstantValueType" -Property @{
                            Value =  "$SearchTerm"              
                        }
                    }
                }
            
            

        }
        
        & $getExchangeItem $findItemType -first $first -DoNotGetDetail:$DoNotGetDetail | 
            ForEach-Object {
                if ($_.ResponseMessages) { 
                    $item = $_.ResponseMessages.Items[0].Items.Items[0]
                } else {
                    $item = $_                
                }
                $To = & $getBuriedItemDetail $item "ToRecipients", "EmailAddress"                
                $from = & $getBuriedItemDetail $item "Sender", "EmailAddress"
                $cc = & $getBuriedItemDetail $item "CcRecipients", "EmailAddress"
                $bcc = & $getBuriedItemDetail $item "BccRecipients", "EmailAddress"
                if ($ExcludeThread) {
                    $body = $item.UniqueBody.Value            
                    $BodyAsHtml = ($item.UniqueBody.BodyType1 -eq "HTML")                    
                } else {
                    $body = $item.Body.Value            
                    $BodyAsHtml = ($item.Body.BodyType1 -eq "HTML")                    
                }
                $attachments = $null
                if ($item.hasattachments -and $DownloadAttachment) {                    
                    $attachments = 
                        foreach ($attachment in $item.Attachments) {
                            $getAttachmentType = 
                                New-Object "$($script:exchangeWebService.GetType().Namespace).GetAttachmentType" -Property  @{
                                    AttachmentShape = 
                                        New-Object "$($script:exchangeWebService.GetType().Namespace).AttachmentResponseShapeType"             
                                    AttachmentIds  = 
                                        New-Object "$($script:exchangeWebService.GetType().Namespace).RequestAttachmentIdType" -Property @{
                                            Id = $attachment.AttachmentId.Id
                                        }
                                }                
                            $attachmentDetails = $script:exchangeWebService.GetAttachment($getAttachmentType)  
                            $attachmentdetails.ResponseMessages.Items[0].Attachments |
                                ForEach-Object {
                                    $path = $env:Temp + ([IO.Path]::GetRandomFileName()) + $_.Name
                                    [IO.File]::WriteAllBytes($path, $_.Content)
                                    New-Object PSObject -Property @{
                                        Path = $path
                                        Name = $_.name
                                    }
                                }              
                        }                
                }   
                if ($item) {                 
                    $null = $item.pstypenames.add('Email')
                    $item | 
                        Add-Member NoteProperty To $to -Force -PassThru |
                        Add-Member NoteProperty Cc $cc -Force -PassThru | 
                        Add-Member NoteProperty Bcc $Bcc -Force -PassThru |
                        Add-Member NoteProperty From $From -Force -PassThru |
                        Add-Member Noteproperty Body $body -Force -PassThru |                
                        Add-Member Noteproperty BodyASHtml $BodyASHtml -Force -PassThru | 
                        Add-Member Noteproperty CalenderId $calenderId -Force -PassThru | 
                        Add-Member Noteproperty Attachment $attachments -Force -PassThru |
                        Add-Member ScriptMethod GetAttachment -Force -PassThru {
                            param([string]$Name)
                            $getAttachmentType = 
                                New-Object "$($script:exchangeWebService.GetType().Namespace).GetAttachmentType" -Property  @{
                                    AttachmentShape = 
                                        New-Object "$($script:exchangeWebService.GetType().Namespace).AttachmentResponseShapeType"             
                                    AttachmentIds  = 
                                        New-Object "$($script:exchangeWebService.GetType().Namespace).RequestAttachmentIdType" -Property @{
                                            Id = $attachment.AttachmentId.Id
                                        }
                                }    
                            $attachmentDetails = $script:exchangeWebService.GetAttachment($getAttachmentType)  
                            $attachmentdetails.ResponseMessages.Items[0].Attachments |
                                ForEach-Object {
                                    New-Object PSObject -Property @{
                                        Name = $_.Name
                                        Bytes = $_.Content
                                        ContentType = $_.ContentType
                                    }                                    
                                }    
                        }
                    
                }
                
            }
        }   
}