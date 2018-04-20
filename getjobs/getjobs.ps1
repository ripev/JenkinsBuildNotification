# sensetive variables
$user = "#############"                                   # put here your Jenkins login
$pass = "################################"                # put here your Jenkins password
$jenkinsUri = "https://###############"                   # put here your Jenkins url
$jenkisnFolderOrView = "######"                           # put here your folder in Jenkins
$ScriptsFolderLocation = "$($env:USERPROFILE)\_bin"       # put here scripts folder

$currentLocation = Get-Location
Set-Location -Path $ScriptsFolderLocation

$logo = "$($ScriptsFolderLocation)\jenkinsLogo.png"
$JobsLogFile = "$($ScriptsFolderLocation)\JobsLog.log"
$dateSuffix = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")

$jobsJsonOutput = "jobs.json"
$buildNumberJsonOutput = "buildNumberJsonOutput.json"
$NoActiveJobsMessage = "NoActiveJobs"

$sh = "wget -q --no-check-certificate --auth-no-challenge --user $($user) --password $($pass) '$($jenkinsUri)/job/$($jenkisnFolderOrView)/view/All/api/json?tree=jobs[name,color]' -O $($jobsJsonOutput) > /dev/null"
if ((Test-Path $JobsLogFile -ErrorAction SilentlyContinue) -eq $false) {
	Write-Output "$($dateSuffix)`n$($NoActiveJobsMessage)" | Out-File $JobsLogFile -Append -Encoding utf8
}
$LastRunningJob = Get-Content -Path $JobsLogFile | Select-Object -Last 1
bash -c $sh
$jobsJson = Get-Content -Encoding UTF8 -Path $jobsJsonOutput | ConvertFrom-Json
$jobRunning = ($jobsJson.jobs | Where-Object {$_.color -match "_anime"} | Select-Object name,color).name
if ($jobRunning.count -gt 0 -and $jobRunning -notmatch $LastRunningJob) {
	$shBuildN = "wget -q --no-check-certificate --auth-no-challenge --user $($user) --password $($pass) '$($jenkinsUri)/job/$($jenkisnFolderOrView)/job/$($jobRunning)/api/json?tree=builds[number]' -O $($buildNumberJsonOutput) > /dev/null"
	bash -c $shBuildN
	$buildNumberJson = Get-Content -Encoding UTF8 -Path $buildNumberJsonOutput | ConvertFrom-Json
	$lastBuildNumber = ($buildNumberJson.builds | Sort-Object number -Descending | Select-Object -First 1).number
	$BlogButton = New-BTButton -Content 'View Log' -Arguments "$($jenkinsUri)/job/$($jenkisnFolderOrView)/job/$($jobRunning)/$($lastBuildNumber)/console"

	$shBuildStarter = "wget -q --no-check-certificate --auth-no-challenge --user $($user) --password $($pass) '$($jenkinsUri)/job/$($jenkisnFolderOrView)/job/$($jobRunning)/$($lastBuildNumber)/api/json?pretty=true' -O $($buildNumberJsonOutput) > /dev/null"
	bash -c $shBuildStarter
	$buildStarterJson = Get-Content -Encoding UTF8 -Path $buildNumberJsonOutput | ConvertFrom-Json
	$buildStarterName = (($buildStarterJson.actions | Where-Object {$_._class -eq "hudson.model.CauseAction"}).causes).shortDescription | Select-Object -First 1

	New-BurntToastNotification -Text $jobRunning,$buildStarterName -Button $BlogButton -AppLogo $logo
	Write-Output "`n$($dateSuffix)`n$($jobRunning)" | Out-File $JobsLogFile -Append -Encoding utf8
} else {
	if ($jobRunning.count -eq 0 -and $LastRunningJob -ne $NoActiveJobsMessage) {
		Write-Output "`n$($dateSuffix)`n$($NoActiveJobsMessage)" | Out-File $JobsLogFile -Append -Encoding utf8
	}
}
if ((Test-Path $jobsJsonOutput -ErrorAction SilentlyContinue) -eq $true) {Remove-Item $jobsJsonOutput -Force}
if ((Test-Path $buildNumberJsonOutput -ErrorAction SilentlyContinue) -eq $true) {Remove-Item $buildNumberJsonOutput -Force}
Set-Location -Path $currentLocation