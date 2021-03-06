function Import-DataTable
{
    <#
    .Synopsis
        Imports a datatable
    .Description
        Imports a datatable from a file on disk.  The datatable must be exported with Export-Datatable
    .Link
        Export-DataTable
    .Link
        ConvertTo-DataTable
    .Example
        dir | Select Name, LastWriteTime, CreationTime | Export-DataTable -OutputPath $home\FileInfo.dat

        Import-DataTable $home\FileInfo.dat
    #>
    [OutputType([Data.Datatable])]
    param(
    # The path to the data table.
    [Parameter(Mandatory=$true,Position=0,ValueFromPipelineByPropertyName=$true)]
    [Alias('FullName')]
    $FilePath
    )

    process {
        #region Resolve absolute path
        $resolvedPath = $ExecutionContext.SessionState.Path.GetResolvedPSPathFromPSPath($FilePath)
        if (-not $resolvedPath) { return } 
        #endregion Resolve absolute path

        #region Open file and compressed stream
        $fileStream = New-Object IO.FileStream "$resolvedPath", Open
        $cs = New-Object System.IO.Compression.GZipStream($fileStream, [IO.Compression.CompressionMode]"Decompress")
        #endregion Open file and compressed stream

        # Deserialize the data
        ,(New-Object System.Runtime.Serialization.Formatters.Binary.BinaryFormatter).Deserialize($cs) 
        
        
        #region Close compressed stream and file
        $cs.Close()
        $fileStream.Close()
        #endregion Close compressed stream and file
        
    }
}  
