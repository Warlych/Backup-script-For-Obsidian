$source = "your_source"
$destination = "your_destination"

$delay = 2000

function Sync-WithDelay {
    Start-Sleep -Seconds $delay 
    robocopy $source $destination /MIR /FFT
}

$watcher = New-Object System.IO.FileSystemWatcher
$watcher.IncludeSubdirectories = $true
$watcher.Path = $source
$watcher.EnableRaisingEvents = $true

Register-ObjectEvent $watcher 'Changed' -SourceIdentifier FileChanged
Register-ObjectEvent $watcher 'Created' -SourceIdentifier FileCreated
Register-ObjectEvent $watcher 'Deleted' -SourceIdentifier FileDeleted
Register-ObjectEvent $watcher 'Renamed' -SourceIdentifier FileRenamed

try {

	while ($true) {
		
		$event = Get-Event | Where-Object {
            $_.SourceIdentifier -in ('FileChanged', 'FileCreated', 'FileDeleted', 'FileRenamed')
        }
		
		if ($event) {
			Write-Host "File $name at path $path was $changetype at $(Get-Date)"
			Sync-WithDelay
			$event | Remove-Event 
		} else {
			Start-Sleep -Milliseconds $delay
		}
	}

} finally {
	Unregister-Event -SourceIdentifier FileChanged
    Unregister-Event -SourceIdentifier FileDeleted
    Unregister-Event -SourceIdentifier FileRenamed
	Unregister-Event -SourceIdentifier FileCreated
    $watcher.Dispose()
}