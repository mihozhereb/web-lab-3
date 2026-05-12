param(
    [string]$AntCmd = "./ant.bat",
    [string]$ResultDir = "build-ant/team"
)

$ErrorActionPreference = "Stop"

chcp 65001 > $null

[Console]::OutputEncoding = [System.Text.UTF8Encoding]::new()
$OutputEncoding = [System.Text.UTF8Encoding]::new()

$env:ANT_OPTS = "-Dfile.encoding=UTF-8 -Dsun.stdout.encoding=UTF-8 -Dsun.stderr.encoding=UTF-8 " + $env:ANT_OPTS

$projectRoot = (Get-Location).Path
$resultPath = Join-Path $projectRoot $ResultDir
$warsPath = Join-Path $resultPath "wars"

New-Item -ItemType Directory -Force -Path $resultPath | Out-Null
New-Item -ItemType Directory -Force -Path $warsPath | Out-Null

$commits = git rev-list --first-parent --max-count=2 --skip=1 HEAD

if ($commits.Count -lt 2) {
    throw "Need at least two previous revisions. Make at least 3 commits in the repository."
}

foreach ($commit in $commits) {
    $short = $commit.Substring(0, 7)

    Write-Host "Building previous revision $short..."

    $tempDir = Join-Path $resultPath "rev-$short"
    $zipFile = Join-Path $resultPath "rev-$short.zip"

    Remove-Item -Recurse -Force $tempDir -ErrorAction SilentlyContinue
    Remove-Item -Force $zipFile -ErrorAction SilentlyContinue

    git archive --format=zip -o $zipFile $commit
    Expand-Archive -Path $zipFile -DestinationPath $tempDir -Force

    Copy-Item -Force (Join-Path $projectRoot "build.xml") (Join-Path $tempDir "build.xml")
    Copy-Item -Force (Join-Path $projectRoot "build.properties") (Join-Path $tempDir "build.properties")
    Copy-Item -Force (Join-Path $projectRoot "MANIFEST.MF") (Join-Path $tempDir "MANIFEST.MF")

    Push-Location $tempDir

    & (Join-Path $projectRoot $AntCmd) -f (Join-Path $tempDir "build.xml") clean build

    if ($LASTEXITCODE -ne 0) {
        Pop-Location
        throw "Revision $short failed to build."
    }

    Pop-Location

    $warSource = Join-Path $tempDir "build-ant/dist/web-lab-3.war"
    $warDest = Join-Path $warsPath "web-lab-3-$short.war"

    if (-not (Test-Path $warSource)) {
        throw "WAR file was not created for revision $short."
    }

    Copy-Item -Force $warSource $warDest
}

$zipResult = Join-Path $resultPath "team-revisions.zip"

Remove-Item -Force $zipResult -ErrorAction SilentlyContinue
Compress-Archive -Path (Join-Path $warsPath "*.war") -DestinationPath $zipResult

Write-Host "Created archive: $zipResult"