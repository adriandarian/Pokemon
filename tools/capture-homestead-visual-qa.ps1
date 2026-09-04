#Requires -Version 5.1

<#
.SYNOPSIS
Captures the four canonical homestead visual-QA views with the installed Godot executable.

.DESCRIPTION
Runs the project-owned PNG capture path in hidden Godot processes, validates each
exit code and PNG size, and records logs, SHA256 hashes, and a JSON manifest in a
new output directory. Source images are read-only. With -ComposeComparison, the
443x779 overview is placed beside -TargetPath in a separate System.Drawing PNG.

.EXAMPLE
.\tools\capture-homestead-visual-qa.ps1 -DryRun

.EXAMPLE
.\tools\capture-homestead-visual-qa.ps1 `
    -OutputDirectory .\output\visual_qa_harness\review-01 `
    -TargetPath .\output\homestead_visual_audit\72-target-left-crop.png `
    -ComposeComparison
#>

[CmdletBinding()]
param(
    [string]$OutputDirectory,
    [string]$GodotPath,
    [ValidateRange(1, 600)]
    [int]$CaptureDelayFrames = 18,
    [ValidateRange(10, 600)]
    [int]$TimeoutSeconds = 120,
    [string]$TargetPath,
    [switch]$ComposeComparison,
    [switch]$DryRun
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$projectRoot = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot ".."))

function Resolve-GodotPath {
    param([string]$RequestedPath)

    if (-not [string]::IsNullOrWhiteSpace($RequestedPath)) {
        $resolvedRequestedPath = [System.IO.Path]::GetFullPath($RequestedPath)
        if (-not (Test-Path -LiteralPath $resolvedRequestedPath -PathType Leaf)) {
            throw "Godot executable was not found at '$resolvedRequestedPath'."
        }
        return $resolvedRequestedPath
    }

    foreach ($commandName in @(
        "Godot_v4.5.1-stable_win64_console.exe",
        "godot4",
        "godot"
    )) {
        $command = Get-Command $commandName -CommandType Application -ErrorAction SilentlyContinue |
            Select-Object -First 1
        if ($null -eq $command) {
            continue
        }

        $candidate = $command.Source
        if ([System.IO.Path]::GetExtension($candidate) -in @(".bat", ".cmd")) {
            $commandDirectory = Split-Path -Parent $candidate
            $siblingConsoleExe = Get-ChildItem -LiteralPath $commandDirectory -File -Filter "Godot*_console.exe" -ErrorAction SilentlyContinue |
                Sort-Object Name -Descending |
                Select-Object -First 1
            if ($null -ne $siblingConsoleExe) {
                return $siblingConsoleExe.FullName
            }
        }
        return $candidate
    }

    $knownFallbacks = @()
    if (-not [string]::IsNullOrWhiteSpace($env:USERPROFILE)) {
        $knownFallbacks += Join-Path $env:USERPROFILE "Downloads\Godot_v4.5.1-stable_win64.exe\Godot_v4.5.1-stable_win64_console.exe"
    }
    if (-not [string]::IsNullOrWhiteSpace($env:LOCALAPPDATA)) {
        $knownFallbacks += Join-Path $env:LOCALAPPDATA "Programs\Godot\Godot_v4.5.1-stable_win64_console.exe"
    }

    foreach ($candidate in $knownFallbacks) {
        if (Test-Path -LiteralPath $candidate -PathType Leaf) {
            return [System.IO.Path]::GetFullPath($candidate)
        }
    }

    throw "Godot was not found. Add it to PATH or pass -GodotPath with the installed executable."
}

function ConvertTo-ProcessArgument {
    param([Parameter(Mandatory = $true)][string]$Value)

    if ($Value -notmatch '[\s"]') {
        return $Value
    }

    # Quote according to the Windows CommandLineToArgvW escaping rules used by
    # Godot. Start-Process joins ArgumentList entries, so quoting is explicit.
    $builder = [System.Text.StringBuilder]::new()
    [void]$builder.Append('"')
    $backslashCount = 0
    foreach ($character in $Value.ToCharArray()) {
        if ($character -eq '\') {
            $backslashCount += 1
            continue
        }
        if ($character -eq '"') {
            [void]$builder.Append(('\' * (($backslashCount * 2) + 1)))
            [void]$builder.Append('"')
            $backslashCount = 0
            continue
        }
        if ($backslashCount -gt 0) {
            [void]$builder.Append(('\' * $backslashCount))
            $backslashCount = 0
        }
        [void]$builder.Append($character)
    }
    if ($backslashCount -gt 0) {
        [void]$builder.Append(('\' * ($backslashCount * 2)))
    }
    [void]$builder.Append('"')
    return $builder.ToString()
}

function Get-PngDimensions {
    param([Parameter(Mandatory = $true)][string]$Path)

    $stream = [System.IO.File]::OpenRead($Path)
    try {
        $header = New-Object byte[] 24
        if ($stream.Read($header, 0, $header.Length) -ne $header.Length) {
            throw "'$Path' is too short to be a valid PNG."
        }
    }
    finally {
        $stream.Dispose()
    }

    $expectedSignature = [byte[]](137, 80, 78, 71, 13, 10, 26, 10)
    for ($index = 0; $index -lt $expectedSignature.Length; $index += 1) {
        if ($header[$index] -ne $expectedSignature[$index]) {
            throw "'$Path' does not have a valid PNG signature."
        }
    }
    if ([System.Text.Encoding]::ASCII.GetString($header, 12, 4) -ne "IHDR") {
        throw "'$Path' does not begin with a PNG IHDR chunk."
    }

    $width = (([int]$header[16] -shl 24) -bor ([int]$header[17] -shl 16) -bor ([int]$header[18] -shl 8) -bor [int]$header[19])
    $height = (([int]$header[20] -shl 24) -bor ([int]$header[21] -shl 16) -bor ([int]$header[22] -shl 8) -bor [int]$header[23])
    return [pscustomobject]@{
        Width = [int]$width
        Height = [int]$height
    }
}

function Invoke-GodotCapture {
    param(
        [Parameter(Mandatory = $true)]$Scenario,
        [Parameter(Mandatory = $true)][string]$Executable,
        [Parameter(Mandatory = $true)][string]$DestinationDirectory
    )

    $capturePath = Join-Path $DestinationDirectory $Scenario.FileName
    $stdoutPath = Join-Path $DestinationDirectory ("{0}.stdout.log" -f $Scenario.Name)
    $stderrPath = Join-Path $DestinationDirectory ("{0}.stderr.log" -f $Scenario.Name)

    foreach ($freshPath in @($capturePath, $stdoutPath, $stderrPath)) {
        if (Test-Path -LiteralPath $freshPath) {
            throw "Refusing to reuse stale visual-QA output '$freshPath'. Choose a new -OutputDirectory."
        }
    }

    $arguments = @(
        "--path",
        $projectRoot,
        "--resolution",
        ("{0}x{1}" -f $Scenario.Width, $Scenario.Height),
        "--"
    )
    if (-not [string]::IsNullOrWhiteSpace($Scenario.PreviewArgument)) {
        $arguments += $Scenario.PreviewArgument
    }
    $arguments += "--capture-delay-frames=$CaptureDelayFrames"
    $arguments += "--capture-preview=$capturePath"

    $argumentLine = ($arguments | ForEach-Object { ConvertTo-ProcessArgument $_ }) -join " "
    $displayCommand = "{0} {1}" -f (ConvertTo-ProcessArgument $Executable), $argumentLine

    if ($DryRun) {
        Write-Host ("DRY-RUN [{0}] {1}" -f $Scenario.Name, $displayCommand)
        return [pscustomobject]@{
            Name = $Scenario.Name
            Width = $Scenario.Width
            Height = $Scenario.Height
            PreviewArgument = $Scenario.PreviewArgument
            File = $capturePath
            Stdout = $stdoutPath
            Stderr = $stderrPath
            Command = $displayCommand
            ExitCode = $null
            Sha256 = $null
        }
    }

    Write-Host ("Capturing {0} ({1}x{2})..." -f $Scenario.Name, $Scenario.Width, $Scenario.Height)
    $startParameters = @{
        FilePath = $Executable
        ArgumentList = $argumentLine
        WorkingDirectory = $projectRoot
        WindowStyle = "Hidden"
        RedirectStandardOutput = $stdoutPath
        RedirectStandardError = $stderrPath
        PassThru = $true
    }
    $process = Start-Process @startParameters

    $finished = $process.WaitForExit($TimeoutSeconds * 1000)
    if (-not $finished) {
        Stop-Process -Id $process.Id -Force -ErrorAction SilentlyContinue
        throw "Godot timed out after $TimeoutSeconds seconds while capturing '$($Scenario.Name)'. See '$stderrPath'."
    }
    $process.WaitForExit()
    $process.Refresh()
    if ($process.ExitCode -ne 0) {
        $stderrTail = if (Test-Path -LiteralPath $stderrPath) {
            (Get-Content -LiteralPath $stderrPath -Tail 20) -join [Environment]::NewLine
        }
        else {
            "<no stderr log was created>"
        }
        throw "Godot exited with code $($process.ExitCode) while capturing '$($Scenario.Name)'.`n$stderrTail"
    }
    if (-not (Test-Path -LiteralPath $capturePath -PathType Leaf)) {
        throw "Godot reported success but '$capturePath' was not created. See '$stdoutPath' and '$stderrPath'."
    }

    $captureInfo = Get-Item -LiteralPath $capturePath
    if ($captureInfo.Length -le 0) {
        throw "Godot created an empty capture at '$capturePath'."
    }
    $dimensions = Get-PngDimensions -Path $capturePath
    if ($dimensions.Width -ne $Scenario.Width -or $dimensions.Height -ne $Scenario.Height) {
        throw "Capture '$capturePath' is $($dimensions.Width)x$($dimensions.Height), expected $($Scenario.Width)x$($Scenario.Height)."
    }

    $hash = (Get-FileHash -LiteralPath $capturePath -Algorithm SHA256).Hash
    return [pscustomobject]@{
        Name = $Scenario.Name
        Width = $dimensions.Width
        Height = $dimensions.Height
        PreviewArgument = $Scenario.PreviewArgument
        File = $capturePath
        Bytes = $captureInfo.Length
        Stdout = $stdoutPath
        Stderr = $stderrPath
        Command = $displayCommand
        ExitCode = $process.ExitCode
        Sha256 = $hash
    }
}

function New-SideBySideComparison {
    param(
        [Parameter(Mandatory = $true)][string]$ReferencePath,
        [Parameter(Mandatory = $true)][string]$CurrentPath,
        [Parameter(Mandatory = $true)][string]$DestinationPath
    )

    try {
        Add-Type -AssemblyName System.Drawing -ErrorAction Stop
    }
    catch {
        Write-Warning "System.Drawing is unavailable; comparison composition was skipped. $($_.Exception.Message)"
        return $null
    }

    $reference = $null
    $current = $null
    $canvas = $null
    $graphics = $null
    try {
        $reference = [System.Drawing.Image]::FromFile($ReferencePath)
        $current = [System.Drawing.Image]::FromFile($CurrentPath)
        $referenceWidth = [Math]::Max(1, [int][Math]::Round($reference.Width * ($current.Height / [double]$reference.Height)))
        $gutter = 8
        $canvas = New-Object System.Drawing.Bitmap ($referenceWidth + $gutter + $current.Width), $current.Height
        $graphics = [System.Drawing.Graphics]::FromImage($canvas)
        $graphics.Clear([System.Drawing.Color]::FromArgb(28, 31, 25))
        $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
        $graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
        $graphics.DrawImage($reference, 0, 0, $referenceWidth, $current.Height)
        $graphics.DrawImage($current, $referenceWidth + $gutter, 0, $current.Width, $current.Height)
        $canvas.Save($DestinationPath, [System.Drawing.Imaging.ImageFormat]::Png)
    }
    finally {
        if ($null -ne $graphics) { $graphics.Dispose() }
        if ($null -ne $canvas) { $canvas.Dispose() }
        if ($null -ne $current) { $current.Dispose() }
        if ($null -ne $reference) { $reference.Dispose() }
    }

    if (-not (Test-Path -LiteralPath $DestinationPath -PathType Leaf)) {
        throw "System.Drawing did not create '$DestinationPath'."
    }
    return $DestinationPath
}

$godotExecutable = Resolve-GodotPath -RequestedPath $GodotPath
if ([string]::IsNullOrWhiteSpace($OutputDirectory)) {
    $stamp = [DateTime]::UtcNow.ToString("yyyyMMdd-HHmmssZ")
    $OutputDirectory = Join-Path $projectRoot ("output\visual_qa_harness\homestead-$stamp")
}
$resolvedOutputDirectory = [System.IO.Path]::GetFullPath($OutputDirectory)

if ($ComposeComparison -and [string]::IsNullOrWhiteSpace($TargetPath)) {
    throw "-ComposeComparison requires -TargetPath."
}
if (-not [string]::IsNullOrWhiteSpace($TargetPath)) {
    $TargetPath = [System.IO.Path]::GetFullPath($TargetPath)
    if (-not (Test-Path -LiteralPath $TargetPath -PathType Leaf)) {
        throw "Target image was not found at '$TargetPath'."
    }
}

$scenarios = @(
    [pscustomobject]@{ Name = "desktop"; Width = 1280; Height = 720; PreviewArgument = ""; FileName = "desktop-1280x720.png" },
    [pscustomobject]@{ Name = "narrow-stairs"; Width = 640; Height = 1000; PreviewArgument = "--preview-stairs"; FileName = "narrow-stairs-640x1000.png" },
    [pscustomobject]@{ Name = "orbit"; Width = 1000; Height = 1000; PreviewArgument = "--preview-homestead-orbit"; FileName = "orbit-1000x1000.png" },
    [pscustomobject]@{ Name = "overview"; Width = 443; Height = 779; PreviewArgument = "--preview-homestead-overview"; FileName = "overview-443x779.png" }
)

Write-Output "Project: $projectRoot"
Write-Output "Godot: $godotExecutable"
Write-Output "Output: $resolvedOutputDirectory"

if (-not $DryRun) {
    if (Test-Path -LiteralPath $resolvedOutputDirectory -PathType Leaf) {
        throw "Output destination '$resolvedOutputDirectory' is a file."
    }
    if (Test-Path -LiteralPath $resolvedOutputDirectory -PathType Container) {
        $existingEntry = Get-ChildItem -LiteralPath $resolvedOutputDirectory -Force |
            Select-Object -First 1
        if ($null -ne $existingEntry) {
            throw "Output directory '$resolvedOutputDirectory' is not empty. Choose a new directory so prior evidence is preserved."
        }
    }
    else {
        [void](New-Item -ItemType Directory -Path $resolvedOutputDirectory)
    }
}

$results = @()
foreach ($scenario in $scenarios) {
    $captureParameters = @{
        Scenario = $scenario
        Executable = $godotExecutable
        DestinationDirectory = $resolvedOutputDirectory
    }
    $results += Invoke-GodotCapture @captureParameters
}

if ($DryRun) {
    Write-Output "Dry run complete; no process was started and no output was written."
    return
}

$comparisonPath = $null
if ($ComposeComparison) {
    $comparisonPath = Join-Path $resolvedOutputDirectory "target-vs-current-overview.png"
    if (Test-Path -LiteralPath $comparisonPath) {
        throw "Refusing to overwrite comparison '$comparisonPath'."
    }
    $currentOverview = ($results | Where-Object Name -eq "overview" | Select-Object -First 1).File
    $comparisonParameters = @{
        ReferencePath = $TargetPath
        CurrentPath = $currentOverview
        DestinationPath = $comparisonPath
    }
    $comparisonPath = New-SideBySideComparison @comparisonParameters
}

$manifestPath = Join-Path $resolvedOutputDirectory "capture-manifest.json"
$manifest = [ordered]@{
    schemaVersion = 1
    capturedAtUtc = [DateTime]::UtcNow.ToString("o")
    projectRoot = $projectRoot
    godotExecutable = $godotExecutable
    captureDelayFrames = $CaptureDelayFrames
    timeoutSeconds = $TimeoutSeconds
    targetPath = $TargetPath
    comparisonPath = $comparisonPath
    captures = $results
}
$manifest | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $manifestPath -Encoding UTF8

Write-Output "Visual-QA capture complete."
Write-Output "Manifest: $manifestPath"
foreach ($result in $results) {
    Write-Output ("{0}: {1} ({2} bytes, SHA256 {3})" -f $result.Name, $result.File, $result.Bytes, $result.Sha256)
}
if ($null -ne $comparisonPath) {
    Write-Output "Comparison: $comparisonPath"
}
