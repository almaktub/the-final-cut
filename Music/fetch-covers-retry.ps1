<#
  fetch-covers-retry.ps1
  Retry pass for the 28 albums the first script (fetch-covers.ps1) missed.
  24 of those were plain iTunes rate-limiting (429 Too Many Requests) from
  hitting the API too fast, so this version waits much longer between calls
  (2.5s) and retries with backoff (5s / 10s / 20s) if it gets rate-limited again.
  The 4 genuine "no result" albums get a second fallback search (album title
  only, no artist) in case the combined term was the problem.

  USAGE: same as before.
    1. cd to this script's folder (Final Cut/Music).
    2. .\fetch-covers-retry.ps1
    3. New covers land in covers-output\ alongside the ones you already have.
    4. Anything still missing gets logged to covers-output\MISSES-RETRY.txt.
#>

$ErrorActionPreference = 'Stop'
$outDir = Join-Path $PSScriptRoot "covers-output"
New-Item -ItemType Directory -Force -Path $outDir | Out-Null

$albums = @(
    [PSCustomObject]@{ Slug='fetch-the-bolt-cutters'; Artist='Fiona Apple'; Album='Fetch the Bolt Cutters' }
    [PSCustomObject]@{ Slug='hell-hath-no-fury'; Artist='Clipse'; Album='Hell Hath No Fury' }
    [PSCustomObject]@{ Slug='is-this-it'; Artist='The Strokes'; Album='Is This It' }
    [PSCustomObject]@{ Slug='love-and-hate-kiwanuka'; Artist='Kiwanuka'; Album='Love & Hate' }
    [PSCustomObject]@{ Slug='low-end-theory'; Artist='A Tribe Called Quest'; Album='The Low End Theory' }
    [PSCustomObject]@{ Slug='madvillainy'; Artist='Madvillain'; Album='Madvillainy' }
    [PSCustomObject]@{ Slug='maps-billy-woods'; Artist='billy woods & Kenny Segel'; Album='Maps' }
    [PSCustomObject]@{ Slug='mbdtf'; Artist='Kanye West'; Album='My Beautiful Dark Twisted Fantasy' }
    [PSCustomObject]@{ Slug='melodrama'; Artist='Lorde'; Album='Melodrama' }
    [PSCustomObject]@{ Slug='motomami'; Artist='Rosalia'; Album='MOTOMAMI' }
    [PSCustomObject]@{ Slug='mr-morale'; Artist='Kendrick Lamar'; Album='Mr. Morale & the Big Steppers' }
    [PSCustomObject]@{ Slug='no-thank-you'; Artist='Little Simz'; Album='No Thank You' }
    [PSCustomObject]@{ Slug='ok-computer'; Artist='Radiohead'; Album='OK Computer' }
    [PSCustomObject]@{ Slug='saint-cloud'; Artist='Waxahatchee'; Album='Saint Cloud' }
    [PSCustomObject]@{ Slug='sometimes-i-might-be-introvert'; Artist='Little Simz'; Album='Sometimes I Might Be Introvert' }
    [PSCustomObject]@{ Slug='songs-key-of-life'; Artist='Stevie Wonder'; Album='Songs in the Key of Life' }
    [PSCustomObject]@{ Slug='sos-sza'; Artist='SZA'; Album='SOS' }
    [PSCustomObject]@{ Slug='the-bends'; Artist='Radiohead'; Album='The Bends' }
    [PSCustomObject]@{ Slug='the-fall-off'; Artist='J. Cole'; Album='The Fall-Off' }
    [PSCustomObject]@{ Slug='the-infamous'; Artist='Mobb Deep'; Album='The Infamous' }
    [PSCustomObject]@{ Slug='the-wall'; Artist='Pink Floyd'; Album='The Wall' }
    [PSCustomObject]@{ Slug='thriller'; Artist='Michael Jackson'; Album='Thriller' }
    [PSCustomObject]@{ Slug='torches'; Artist='Foster the People'; Album='Torches' }
    [PSCustomObject]@{ Slug='tpab'; Artist='Kendrick Lamar'; Album='To Pimp a Butterfly' }
    [PSCustomObject]@{ Slug='utopia'; Artist='Travis Scott'; Album='Utopia' }
    [PSCustomObject]@{ Slug='velvet-underground-and-nico'; Artist='The Velvet Underground'; Album='The Velvet Underground & Nico' }
    [PSCustomObject]@{ Slug='whats-going-on'; Artist='Marvin Gaye'; Album="What's Going On" }
    [PSCustomObject]@{ Slug='white-album'; Artist='The Beatles'; Album='The Beatles (White Album)' }
)

function Get-iTunesArtwork {
    param([string]$SearchTerm)

    $term = [Uri]::EscapeDataString($SearchTerm)
    $searchUrl = "https://itunes.apple.com/search?term=$term&entity=album&limit=1"

    $maxAttempts = 4
    $waitSeconds = 5
    for ($attempt = 1; $attempt -le $maxAttempts; $attempt++) {
        try {
            $result = Invoke-RestMethod -Uri $searchUrl -UserAgent "Mozilla/5.0"
            return $result
        }
        catch {
            $isRateLimit = $_.Exception.Message -match '429'
            if ($isRateLimit -and $attempt -lt $maxAttempts) {
                Write-Host " [rate-limited, waiting ${waitSeconds}s...]" -NoNewline -ForegroundColor DarkYellow
                Start-Sleep -Seconds $waitSeconds
                $waitSeconds = $waitSeconds * 2
                continue
            }
            throw
        }
    }
}

$misses = New-Object System.Collections.Generic.List[string]
$i = 0

foreach ($a in $albums) {
    $i++
    Write-Host "[$i/$($albums.Count)] $($a.Artist) - $($a.Album)..." -NoNewline

    try {
        $result = Get-iTunesArtwork -SearchTerm "$($a.Artist) $($a.Album)"

        if ($result.resultCount -lt 1) {
            # Fallback: try album title alone, in case the artist name was throwing off the match.
            Write-Host " [no match, trying album title alone...]" -NoNewline -ForegroundColor DarkYellow
            Start-Sleep -Seconds 2
            $result = Get-iTunesArtwork -SearchTerm $a.Album
        }

        if ($result.resultCount -lt 1) {
            Write-Host " NO MATCH" -ForegroundColor Yellow
            $misses.Add("$($a.Slug) - $($a.Artist) - $($a.Album) (no search result even with fallback)")
            continue
        }

        $artUrl = $result.results[0].artworkUrl100 -replace '100x100bb', '1000x1000bb'
        $outFile = Join-Path $outDir "$($a.Slug).jpg"

        Invoke-WebRequest -Uri $artUrl -OutFile $outFile -UserAgent "Mozilla/5.0"
        Write-Host " done" -ForegroundColor Green
    }
    catch {
        Write-Host " FAILED: $($_.Exception.Message)" -ForegroundColor Red
        $misses.Add("$($a.Slug) - $($a.Artist) - $($a.Album) (error: $($_.Exception.Message))")
    }

    Start-Sleep -Seconds 2.5
}

Write-Host "`nDone. Saved to: $outDir"
if ($misses.Count -gt 0) {
    Write-Host "`n$($misses.Count) album(s) still need manual attention:" -ForegroundColor Yellow
    $misses | ForEach-Object { Write-Host "  - $_" }
    $misses | Out-File (Join-Path $outDir "MISSES-RETRY.txt")
} else {
    Write-Host "`nAll albums resolved." -ForegroundColor Green
}
