function Get-TargetResource
{
	[CmdletBinding()]
	[OutputType([System.Collections.Hashtable])]
	param
	(
		[parameter(Mandatory = $true)]
		[System.String]
		$SourcePath,
		
		[parameter(Mandatory = $true)]
		[System.String]
		$FileName,

        [parameter(Mandatory = $true)]
		[System.String]
		$DestinationDirectoryPath
	)

	#Write-Verbose "Use this cmdlet to deliver information about command processing."

	#Write-Debug "Use this cmdlet to write debug information while troubleshooting."

	$returnValue = @{
		SourcePath = $SourcePath
		FileName  = $FileName
        DestinationDirectoryPath = $DestinationDirectoryPath
	}
    $returnValue
}


function Set-TargetResource
{
	[CmdletBinding()]
	param
	(
		[parameter(Mandatory = $true)]
		[System.String]
		$SourcePath,
		
		[parameter(Mandatory = $true)]
		[System.String]
		$FileName,

        [parameter(Mandatory = $true)]
		[System.String]
		$DestinationDirectoryPath
	)

    Write-Verbose "Create Destination Directory"
	if(!(Test-Path $DestinationDirectoryPath))
	{
		New-Item -Path $DestinationDirectoryPath -ItemType Directory -Force
	}
	
    $output = Join-Path $DestinationDirectoryPath $FileName
	$startTime = Get-Date
    Write-Verbose "Start to download file from $SourcePath"
    Get-BitsTransfer | Remove-BitsTransfer
    $downloadJob = Start-BitsTransfer -Source $SourcePath -Destination $output -DisplayName "Download" -Asynchronous -RetryInterval 60 -Priority Foreground

    $result = Get-BitsTransfer -JobId $downloadJob.JobId
    # Possible JobState values: https://docs.microsoft.com/en-us/windows/desktop/api/Bits/ne-bits-__midl_ibackgroundcopyjob_0002
	while ($result.JobState -notin @("Transferred", "Error"))
	{
		Start-Sleep -Seconds 20
		Write-Verbose -Message ("Waiting for $SourcePath, time taken: {0:N0} seconds" -f ((Get-Date) - $startTime).TotalSeconds)
        Write-Verbose -Message ("Current JobState: {0} - Bytes Transferred: {1:N2} of {2:N2}" -f $result.JobState, $result.BytesTransferred, $result.BytesTotal)
        $result = Get-BitsTransfer -JobId $downloadJob.JobId
	}

    if ($result.JobState -eq "Error")
    {
        Write-Verbose -Message "[ERROR] An error occured while downloading $SourcePath"
        Write-Verbose -Message "        Error details: $($result.ErrorDescription)"
        throw "Error while downloading $SourcePath"
    }
    else
    {
        Complete-BitsTransfer -BitsJob $downloadJob
        Write-Verbose "Complete download file from $SourcePath"
    }
}


function Test-TargetResource
{
	[CmdletBinding()]
	[OutputType([System.Boolean])]
	param
	(
		[parameter(Mandatory = $true)]
		[System.String]
		$SourcePath,
		
		[parameter(Mandatory = $true)]
		[System.String]
		$FileName,

        [parameter(Mandatory = $true)]
		[System.String]
		$DestinationDirectoryPath
	)
	$output = Join-Path -Path $DestinationDirectoryPath -ChildPath $FileName
	return Test-Path $output
}


Export-ModuleMember -Function *-TargetResource

