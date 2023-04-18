function Find-LongPaths {
    param (
		[parameter(mandatory=$false, valueFromPipeline=$true, valueFromPipelinebyPropertyName=$true)]
        [PSDefaultValue(Help='Specifies the maximum path length')]
        [int]$length=255
    )

	begin{}

	process {
		cmd /c dir /s /b | Where-Object {$_.length -gt $length}
	}

	end{}
}
