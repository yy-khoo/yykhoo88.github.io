# Run: .\publish.ps1 [-RepositoryUrl https://github.com/USER/REPO.git]
[CmdletBinding()]
param([string]$RepositoryUrl)

$ErrorActionPreference = 'Stop'

function Invoke-Git {
    param([string[]]$GitArgs)
    & git @GitArgs
    if ($LASTEXITCODE -ne 0) { throw "git $($GitArgs -join ' ') failed." }
}

Push-Location $PSScriptRoot
$previousPython = $env:QUARTO_PYTHON
try {
    if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
        throw 'Install Git for Windows, then reopen PowerShell.'
    }
    $quarto = Join-Path $PSScriptRoot '.tools/quarto/bin/quarto.cmd'
    if (-not (Test-Path $quarto)) {
        $command = Get-Command quarto -ErrorAction SilentlyContinue
        if (-not $command) { throw 'Install Quarto: https://quarto.org/docs/get-started/' }
        $quarto = $command.Source
    }
    $python = Join-Path $PSScriptRoot '.venv/Scripts/python.exe'
    if (-not (Test-Path $python)) {
        throw 'Create .venv and install requirements.txt first (see README.md).'
    }
    $env:QUARTO_PYTHON = $python
    $branch = & git branch --show-current
    if ($LASTEXITCODE -ne 0 -or -not $branch -or $branch -eq 'gh-pages') {
        throw 'Run this script from a source branch, such as main.'
    }
    $sources = @('README.md', '.gitignore', '_quarto.yml', 'index.qmd', 'about.qmd',
        'assets', 'notes', 'projects.qmd', 'src', 'requirements.txt', 'publish.ps1')
    $staged = @(& git -c core.quotepath=false diff --cached --name-only --no-renames)
    if ($LASTEXITCODE -ne 0) { throw 'Unable to inspect staged sources.' }
    $unrelated = @($staged | Where-Object {
        $path = $_
        -not @($sources | Where-Object {
            $path -ceq $_ -or $path.StartsWith("$_/", [System.StringComparison]::Ordinal)
        }).Count
    })
    if ($unrelated.Count) {
        throw "Unrelated files are staged. Commit or unstage these before publishing: $($unrelated -join ', ')"
    }

    $origin = & git config --get remote.origin.url
    if (-not $origin) {
        if (-not $RepositoryUrl) {
            $RepositoryUrl = Read-Host 'Paste the URL of your empty GitHub repository (https://github.com/USER/REPO.git)'
        }
        if ($RepositoryUrl -notmatch '^https://github\.com/[A-Za-z0-9-]+/[A-Za-z0-9_.-]+(?:\.git)?/?$') {
            throw 'Enter an HTTPS GitHub repository URL.'
        }
        Invoke-Git -GitArgs @('remote', 'add', 'origin', $RepositoryUrl)
        $origin = $RepositoryUrl
    } elseif ($RepositoryUrl -and $RepositoryUrl -ne $origin) {
        throw "origin is already $origin. Update it yourself before publishing to another repository."
    }
    if ($origin -notmatch '^(https://github\.com/|git@github\.com:)([A-Za-z0-9-]+)/([A-Za-z0-9_.-]+)/?$') {
        throw "origin must point to GitHub. Current origin: $origin"
    }
    $owner = $Matches[2]
    $repo = $Matches[3] -replace '\.git$', ''
    Write-Host "Publishing to $owner/$repo"

    # A preview watcher can race with the publisher when both move rendered HTML.
    $projectPath = [System.IO.Path]::GetFullPath($PSScriptRoot)
    $previews = @(Get-CimInstance Win32_Process -ErrorAction SilentlyContinue |
        Where-Object {
            $_.Name -match '^(deno|quarto)\.exe$' -and
            $_.CommandLine -and
            $_.CommandLine.IndexOf($projectPath, [System.StringComparison]::OrdinalIgnoreCase) -ge 0 -and
            $_.CommandLine -match '\bpreview\b'
        })
    if ($previews.Count) {
        throw 'A Quarto preview is running for this project. Stop it with Ctrl+C in its terminal, then rerun publish.ps1.'
    }

    # Commit website sources only; local environments and rendered output stay excluded.
    Invoke-Git -GitArgs (@('add', '--') + $sources)
    & git diff --cached --quiet
    if ($LASTEXITCODE -eq 1) {
        Invoke-Git -GitArgs @('commit', '-m', 'Update website sources')
    } elseif ($LASTEXITCODE -ne 0) { throw 'Unable to inspect staged sources.' }
    Invoke-Git -GitArgs @('push', '-u', 'origin', $branch)

    & $quarto publish gh-pages --no-browser
    if ($LASTEXITCODE -ne 0) { throw 'Quarto publishing failed. See the output above.' }

    Write-Host ''
    Write-Host "Pages settings: https://github.com/$owner/$repo/settings/pages"
    Write-Host 'First run: select Deploy from a branch > gh-pages > / (root), then Save.'
    if ($repo -ieq "$owner.github.io") {
        Write-Host "Website: https://$owner.github.io/"
    } else {
        Write-Host "Website: https://$owner.github.io/$repo/"
    }
} finally {
    $env:QUARTO_PYTHON = $previousPython
    Pop-Location
}
