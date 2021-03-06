function Remove-EC2KeyPair
{
    <#
    .Synopsis
        Removes EC2 Key pairs
    .Description
        Removes EC2 Key pairs.  Key pairs are used to access secure information
    .Link
        Get-EC2KeyPair
    .Link
        Remove-SecureSetting
    .Example
        Get-EC2KeyPair | 
            Remove-EC2KeyPair
    #>
    [CmdletBinding(SupportsShouldProcess='true', ConfirmImpact='High')]
    param(
    # The name of the key that will be removed
    [Parameter(Mandatory=$true,ValueFromPipelineByPropertyName=$true,Position=0)]
    [string]
    $KeyName
    )
    
    process {
        $toTerminate = (New-Object Amazon.EC2.Model.DeleteKeyPairRequest).WithKeyName($KeyName)
        if ($psCmdlet.ShouldProcess($KeyName)) {
            $AwsConnections.EC2.DeleteKeyPair($toTerminate)  | Out-Null
            Remove-SecureSetting -Name $keyName 
        }
        
        
        
    }
} 
