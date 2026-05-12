param(
    [string]$AntCmd = "./ant.bat",
    [string]$ResultDir = "build-ant/history"
)

$ErrorActionPreference = "Stop"

chcp 65001 > $null

[Console]::OutputEncoding = [System.Text.UTF8Encoding]::new()
$OutputEncoding = [System.Text.UTF8Encoding]::new()

$env:ANT_OPTS = "-Dfile.encoding=UTF-8 -Dsun.stdout.encoding=UTF-8 -Dsun.stderr.encoding=UTF-8 " + $env:ANT_OPTS

$projectRoot = (Get-Location).Path
$resultPath = Join-Path $projectRoot $ResultDir

New-Item -ItemType Directory -Force -Path $resultPath | Out-Null

$commits = git rev-list --first-parent HEAD

if (-not $commits) {
    throw "Git history is empty."
}

$goodCommit = $null
$goodIndex = -1

for ($i = 0; $i -lt $commits.Count; $i++) {
    $commit = $commits[$i]
    $short = $commit.Substring(0, 7)

    Write-Host "Checking revision $short..."

    $tempDir = Join-Path $resultPath "check-$short"
    $zipFile = Join-Path $resultPath "check-$short.zip"

    Remove-Item -Recurse -Force $tempDir -ErrorAction SilentlyContinue
    Remove-Item -Force $zipFile -ErrorAction SilentlyContinue

    git archive --format=zip -o $zipFile $commit
    Expand-Archive -Path $zipFile -DestinationPath $tempDir -Force

    Copy-Item -Force (Join-Path $projectRoot "build.xml") (Join-Path $tempDir "build.xml")
    Copy-Item -Force (Join-Path $projectRoot "build.properties") (Join-Path $tempDir "build.properties")
    Copy-Item -Force (Join-Path $projectRoot "MANIFEST.MF") (Join-Path $tempDir "MANIFEST.MF")

    Push-Location $tempDir

    try {
        & (Join-Path $projectRoot $AntCmd) -f (Join-Path $tempDir "build.xml") clean compile

        if ($LASTEXITCODE -eq 0) {
            $goodCommit = $commit
            $goodIndex = $i
            Pop-Location
            break
        }
    }
    catch {
        Write-Host "Revision $short does not compile."
    }

    Pop-Location
}

if ($null -eq $goodCommit) {
    throw "No compilable revision was found."
}

$goodShort = $goodCommit.Substring(0, 7)
Write-Host "Last compilable revision: $goodShort"

Set-Content -Path (Join-Path $resultPath "last-working.txt") -Value $goodCommit

if ($goodIndex -eq 0) {
    Write-Host "Current revision compiles. Diff is not needed."
    Set-Content -Path (Join-Path $resultPath "history-result.txt") -Value "Current revision compiles: $goodCommit"
}
else {
    $badCommit = $commits[$goodIndex - 1]
    $badShort = $badCommit.Substring(0, 7)

    Write-Host "Creating diff between $goodShort and next revision $badShort..."

    git diff $goodCommit $badCommit | Out-File -Encoding UTF8 (Join-Path $resultPath "history.diff")

    Set-Content -Path (Join-Path $resultPath "history-result.txt") -Value "Last working: $goodCommit`nNext revision: $badCommit`nDiff: history.diff"
}