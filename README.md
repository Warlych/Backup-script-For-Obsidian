## About the project
This project is my interpretation of a script that creates a backup of my notes in obsidian.

## Script review
The script is divided into several parts:
### Hardcoded variable
```bash
$source = "your_source"
$destination = "your_destination"

$delay = 2000
```
### File synchronization function:
```bash
function Sync-WithDelay {
    Start-Sleep -Seconds $delay # pre-start delay
    robocopy $source $destination /MIR /FFT # synchronize files
}
```
### Creating watcher for source directory and resolve events
```bash
$watcher = New-Object System.IO.FileSystemWatcher
$watcher.IncludeSubdirectories = $true
$watcher.Path = $source
$watcher.EnableRaisingEvents = $true # handle events flag

Register-ObjectEvent $watcher 'Changed' -SourceIdentifier FileChanged
Register-ObjectEvent $watcher 'Created' -SourceIdentifier FileCreated
Register-ObjectEvent $watcher 'Deleted' -SourceIdentifier FileDeleted
Register-ObjectEvent $watcher 'Renamed' -SourceIdentifier FileRenamed
```

### Main cycle function
```bash
try {
     while ($true) {
     # true when the event is one of the ones I'm tracking
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
    # delete resolve events and dispose watcher
    Unregister-Event -SourceIdentifier FileChanged
    Unregister-Event -SourceIdentifier FileDeleted
    Unregister-Event -SourceIdentifier FileRenamed
    Unregister-Event -SourceIdentifier FileCreated
    $watcher.Dispose()
}
```

### Bat file
```bash
@echo off
rem powershell start script commands
powershell -Command "Set-ExecutionPolicy Bypass -Scope Process -Force"
cd path_to_your_script
start /min powershell -NoExit -Command ".\backup_script.ps1" 

:CHECK_PROCESS rem function that tracks the Obsidian.exe process
tasklist /FI "IMAGENAME eq obsidian.exe" 2>NUL | find /I /N "obsidian.exe">NUL
if "%ERRORLEVEL%"=="0" (
    timeout /T 100 /NOBREAK > NUL
    goto CHECK_PROCESS
)

taskkill /IM powershell.exe /F rem killing powershell script

exit
```

## About the launch
First, we need to prepare the logs, to go to their configuration use Win + R and secpol.msc. Go to **Local Policies/Audit Policy** and enable **Audit process tracking**.

Now let's configure automatic startup by going to task scheduler - **Win + R** and **taskschd.msc**. Go to **Action/Create Task**, in the window that appears in the Triggers tab create a new event trigger, then select **custom - edit event filter - xml** and check the **edit query manually** box. 

Add the following text to the window:
```bash
<QueryList>
  <Query Id=“0” Path=“Security”>
    <Select Path=“Security”>
     *[System[Provider[@Name='Microsoft-Windows-Security-Auditing'] and Task = 13312 and (band(Keywords,9007199254740992)) and (EventID=4688)]] 
   and
     *[EventData[Data[@Name='NewProcessName'] and (Data='your_path_to\Obsidian.exe')]]
    </Select>
  </Query>
</QueryList>
```

Next, in the action window, select start program and select the .bat file we created earlier with the **start in (option): /min** setting.

**That's all, good job**

## Future
- Creating variability for different operating systems
- Embedding hardcoded variables in script startup variables