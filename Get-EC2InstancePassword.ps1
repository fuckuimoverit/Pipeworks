function Get-EC2InstancePassword
{
    <#
    .Synopsis
        Gets an instance password from EC2
    .Description
        Gets and decrypts a password from an EC2 instance
    .Example
        Get-EC2 |
             Get-EC2InstancePassword
    .Link
        Get-EC2
    .Link
        Get-SecureSetting
    #>
    [OutputType([string],[MAnagement.Automation.pscredential])]
    param(
    # The EC2 Instance ID
    [Parameter(Mandatory=$true,ValueFromPipelineByPropertyName=$true)]
    [Alias('InstanceId', 'EC2InstanceId')]
    [string]
    $EC2,
    
    # If set, will return the password as a credential
    [Switch]
    $AsCredential
    )
    
    process {
        $dr=  New-Object Amazon.EC2.Model.GetPasswordDataRequest
        $null = $dr.WithInstanceId($EC2)
        
        $ec2Instance = Get-EC2 -InstanceId $EC2
        $rsaKey = Get-SecureSetting -Name $ec2Instance.KeyName -ValueOnly
        
        $passwordResult = $AwsConnections.EC2.GetPasswordData($dr).GetPasswordDataResult
        if ($passwordResult.PasswordData.Data)  {
            $password=  $passwordResult.GetDecryptedPassword($rsaKey) 
            
            if ($asCredential) {
                New-Object Management.Automation.PSCredential "Administrator", ($password | ConvertTo-SecureString -AsPlainText -Force)
            } else {
                New-Object PSObject |
                    Add-Member NoteProperty InstanceId $EC2 -PassThru |
                    Add-Member NoteProperty Password $Password -PassThru                
            }
            

        } else {
            $warningMsg = @"
Password not available yet for instance $ec2. 
Password generation and encryption can sometimes take more than 30 minutes. 
Please wait at least 15 minutes after launching an instance before trying to retrieve the generated password. 

"@        
            Write-Warning $warningMsg
        }
        
    }
} 
