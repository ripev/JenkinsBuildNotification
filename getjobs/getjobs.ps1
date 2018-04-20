$currentLocation = Get-Location

# personalised variables to change
# Here is ScriptsFolderLocation is $env:USERPROFILE\_bin
$ScriptsFolderLocation = "$($env:USERPROFILE)\_bin" # enter here location for scripts
$user = "YOUR-JENKINS-LOGIN-NAME-HERE"    # enter your Jenkins login
$pass = "YOUR-JENKINS-API-KEY-HERE"       # enter here your Jenkins API key
$jenkinsUrl = "https://your-jenkins-url"  # enter here your Jenkins url

Set-Location "$($ScriptsFolderLocation)"

$jobsJsonOutput = "jobs.json"
$buildNumberJsonOutput = "buildNumberJsonOutput.json"
$NoActiveJobsMessage = "NoActiveJobs"
$logo = "$($ScriptsFolderLocation)\jenkinsLogo.png"
$JobsLogFile = "$($ScriptsFolderLocation)\JobsLog.log"

$sh = "wget -q --no-check-certificate --auth-no-challenge --user $($user) --password $($pass) '$($jenkinsUrl)/job/comdep/view/All/api/json?tree=jobs[name,color]' -O $($jobsJsonOutput) > /dev/null"

if ((Test-Path $JobsLogFile -ErrorAction SilentlyContinue) -eq $false) {Write-Output $NoActiveJobsMessage | Out-File $JobsLogFile -Append -Encoding utf8}
$LastRunningJob = Get-Content -Path $JobsLogFile | Select-Object -Last 1
bash -c $sh
$jobsJson = Get-Content -Encoding UTF8 -Path $jobsJsonOutput | ConvertFrom-Json
$jobRunning = ($jobsJson.jobs | Where-Object {$_.color -match "_anime"} | Select-Object name,color).name
if ($jobRunning.count -gt 0 -and $jobRunning -notmatch $LastRunningJob) {
	$shBuildN = "wget -q --no-check-certificate --auth-no-challenge --user $($user) --password $($pass) '$($jenkinsUrl)/job/comdep/job/$($jobRunning)/api/json?tree=builds[number]' -O $($buildNumberJsonOutput) > /dev/null"
	bash -c $shBuildN
	$buildNumberJson = Get-Content -Encoding UTF8 -Path $buildNumberJsonOutput | ConvertFrom-Json
	$lastBuildNumber = ($buildNumberJson.builds | Sort-Object number -Descending | Select-Object -First 1).number
	$BlogButton = New-BTButton -Content 'View Log' -Arguments "$($jenkinsUrl)/job/comdep/job/$($jobRunning)/$($lastBuildNumber)/console"
	New-BurntToastNotification -Text "Job '$($jobRunning)' started" -Button $BlogButton -AppLogo $logo
	Write-Output $jobRunning | Out-File $JobsLogFile -Append -Encoding utf8
} else {
	if ($jobRunning.count -eq 0 -and $LastRunningJob -ne $NoActiveJobsMessage) {
		Write-Output $NoActiveJobsMessage | Out-File $JobsLogFile -Append -Encoding utf8
	}
}
if ((Test-Path $jobsJsonOutput -ErrorAction SilentlyContinue) -eq $true) {Remove-Item $jobsJsonOutput -Force}
if ((Test-Path $buildNumberJsonOutput -ErrorAction SilentlyContinue) -eq $true) {Remove-Item $buildNumberJsonOutput -Force}
Set-Location $currentLocation