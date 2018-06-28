# sensetive variables
$user = "#############"                                   # put here your Jenkins login
$pass = "################################"                # put here your Jenkins password
$jenkinsUri = "https://###############"                   # put here your Jenkins url
$jenkisnFolderOrView = "######"                           # put here your folder in Jenkins
$ScriptsFolderLocation = "$($env:USERPROFILE)\_bin"       # put here scripts folder

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8  # for correct output cyrillic messages

$lockscreen = $null
$lockscreen = (Get-Process | Where-Object {$_.Name -match "logonui"})
if ($null -ne $lockscreen) {Exit 0}

$currentLocation = Get-Location
Set-Location -Path $ScriptsFolderLocation

$logo = "$($ScriptsFolderLocation)\jenkinsLogo.png"
$JobsLogFile = "$($ScriptsFolderLocation)\JobsLog.log"
$dateSuffix = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")

$NoActiveJobsMessage = "NoActiveJobs"

$sh = "curl -g -s -u $($user):$($pass) -k '$($jenkinsUri)/job/$($jenkisnFolderOrView)/view/All/api/json?tree=jobs[name,color]'"
if ((Test-Path $JobsLogFile -ErrorAction SilentlyContinue) -eq $false) {
	Write-Output "$($dateSuffix)`n$($NoActiveJobsMessage)" | Out-File $JobsLogFile -Append -Encoding utf8
}
$LastRunningJob = Get-Content -Path $JobsLogFile | Select-Object -Last 1
$output = bash -c $sh
$jobsJson = $output | ConvertFrom-Json
$jobRunning = ($jobsJson.jobs | Where-Object {$_.color -match "_anime"}).name
if ($jobRunning.count -gt 0 -and $jobRunning -notmatch $LastRunningJob) {
	$shBuildN = "curl -g -s -u $($user):$($pass) -k '$($jenkinsUri)/job/$($jenkisnFolderOrView)/job/$($jobRunning)/api/json?tree=builds[number]{0,5}'"
	$output = bash -c $shBuildN
	$buildNumberJson = $output | ConvertFrom-Json
	$lastBuildNumber = ($buildNumberJson.builds | Sort-Object number -Descending | Select-Object -First 1).number
	$BlogButton = New-BTButton -Content 'View Log' -Arguments "$($jenkinsUri)/job/$($jenkisnFolderOrView)/job/$($jobRunning)/$($lastBuildNumber)/console"

	$shBuildStarter = "curl -g -s -u $($user):$($pass) -k '$($jenkinsUri)/job/$($jenkisnFolderOrView)/job/$($jobRunning)/$($lastBuildNumber)/api/json?tree=actions[causes[shortDescription]]'"
	$output = bash -c $shBuildStarter
	$buildStarterJson = $output | ConvertFrom-Json
	$buildStarterName = (($buildStarterJson.actions | Where-Object {$_._class -eq "hudson.model.CauseAction"}).causes).shortDescription | Select-Object -First 1

	New-BurntToastNotification -Text $jobRunning,$buildStarterName -Button $BlogButton -AppLogo $logo
	Write-Output "`n$($dateSuffix)`n$($jobRunning)" | Out-File $JobsLogFile -Append -Encoding utf8
} else {
	if ($jobRunning.count -eq 0 -and $LastRunningJob -ne $NoActiveJobsMessage) {
		Write-Output "`n$($dateSuffix)`n$($NoActiveJobsMessage)" | Out-File $JobsLogFile -Append -Encoding utf8
	}
}

Set-Location -Path $currentLocation