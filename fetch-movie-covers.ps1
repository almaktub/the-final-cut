<#
  fetch-movie-covers.ps1
  Downloads official movie poster art (via the free iTunes Search API) for all
  62 Cinema entries on the Final Cut site, saved named to match each page's
  slug, ready to drop into Final Cut/img/ (the same folder that already has
  parasite.jpg and spotlight.jpg).

  Improvements over the first album-art script based on what broke last time:
    - Paces requests at 2.5s apart from the start (not just on retry).
    - Retries with backoff (5s / 10s / 20s) if iTunes rate-limits (429).
    - Pulls up to 5 search results per movie and picks the one whose release
      year matches the year on your page, instead of blindly taking result #1
      (movies get remade/rebooted way more often than albums get re-released).

  USAGE:
    1. Open PowerShell.
    2. cd to wherever you saved this script.
    3. Run:  .\fetch-movie-covers.ps1
    4. Posters land in a new "covers-output" folder next to the script.
    5. Spot-check them, then copy the whole folder's contents into:
         E:\Claudius\Personal\Projects\Final Cut\img\
  Needs an internet connection. No installs required. Takes roughly 3 minutes
  for 62 movies given the pacing above.
#>

$ErrorActionPreference = 'Stop'
$outDir = Join-Path $PSScriptRoot "covers-output"
New-Item -ItemType Directory -Force -Path $outDir | Out-Null

$films = @(
    [PSCustomObject]@{ Slug='12-angry-men'; Title='12 Angry Men'; Year='1957' }
    [PSCustomObject]@{ Slug='2001-a-space-odyssey'; Title='2001: A Space Odyssey'; Year='1968' }
    [PSCustomObject]@{ Slug='3-idiots'; Title='3 Idiots'; Year='2009' }
    [PSCustomObject]@{ Slug='a-separation'; Title='A Separation'; Year='2011' }
    [PSCustomObject]@{ Slug='across-the-spider-verse'; Title='Spider-Man: Across the Spider-Verse'; Year='2023' }
    [PSCustomObject]@{ Slug='alien'; Title='Alien'; Year='1979' }
    [PSCustomObject]@{ Slug='american-history-x'; Title='American History X'; Year='1998' }
    [PSCustomObject]@{ Slug='apocalypse-now'; Title='Apocalypse Now'; Year='1979' }
    [PSCustomObject]@{ Slug='avengers-endgame'; Title='Avengers: Endgame'; Year='2019' }
    [PSCustomObject]@{ Slug='avengers-infinity-war'; Title='Avengers: Infinity War'; Year='2018' }
    [PSCustomObject]@{ Slug='casablanca'; Title='Casablanca'; Year='1942' }
    [PSCustomObject]@{ Slug='chinatown'; Title='Chinatown'; Year='1974' }
    [PSCustomObject]@{ Slug='city-of-god'; Title='City of God'; Year='2002' }
    [PSCustomObject]@{ Slug='dark-knight'; Title='The Dark Knight'; Year='2008' }
    [PSCustomObject]@{ Slug='dark-knight-rises'; Title='The Dark Knight Rises'; Year='2012' }
    [PSCustomObject]@{ Slug='django-unchained'; Title='Django Unchained'; Year='2012' }
    [PSCustomObject]@{ Slug='dune-part-two'; Title='Dune: Part Two'; Year='2024' }
    [PSCustomObject]@{ Slug='eternal-sunshine'; Title='Eternal Sunshine of the Spotless Mind'; Year='2004' }
    [PSCustomObject]@{ Slug='fellowship-of-the-ring'; Title='The Fellowship of the Ring'; Year='2001' }
    [PSCustomObject]@{ Slug='fight-club'; Title='Fight Club'; Year='1999' }
    [PSCustomObject]@{ Slug='forrest-gump'; Title='Forrest Gump'; Year='1994' }
    [PSCustomObject]@{ Slug='gladiator'; Title='Gladiator'; Year='2000' }
    [PSCustomObject]@{ Slug='godfather'; Title='The Godfather'; Year='1972' }
    [PSCustomObject]@{ Slug='good-bad-ugly'; Title='The Good, The Bad and The Ugly'; Year='1966' }
    [PSCustomObject]@{ Slug='good-will-hunting'; Title='Good Will Hunting'; Year='1997' }
    [PSCustomObject]@{ Slug='goodfellas'; Title='Goodfellas'; Year='1990' }
    [PSCustomObject]@{ Slug='green-mile'; Title='The Green Mile'; Year='1999' }
    [PSCustomObject]@{ Slug='inglourious-basterds'; Title='Inglourious Basterds'; Year='2009' }
    [PSCustomObject]@{ Slug='interstellar'; Title='Interstellar'; Year='2014' }
    [PSCustomObject]@{ Slug='into-the-spider-verse'; Title='Spider-Man: Into the Spider-Verse'; Year='2018' }
    [PSCustomObject]@{ Slug='joker'; Title='Joker'; Year='2019' }
    [PSCustomObject]@{ Slug='memento'; Title='Memento'; Year='2000' }
    [PSCustomObject]@{ Slug='no-country-for-old-men'; Title='No Country for Old Men'; Year='2007' }
    [PSCustomObject]@{ Slug='oldboy'; Title='Oldboy'; Year='2003' }
    [PSCustomObject]@{ Slug='once-upon-a-time-in-the-west'; Title='Once Upon a Time in the West'; Year='1968' }
    [PSCustomObject]@{ Slug='one-flew'; Title="One Flew Over the Cuckoo's Nest"; Year='1975' }
    [PSCustomObject]@{ Slug='parasite'; Title='Parasite'; Year='2019' }
    [PSCustomObject]@{ Slug='psycho'; Title='Psycho'; Year='1960' }
    [PSCustomObject]@{ Slug='pulp-fiction'; Title='Pulp Fiction'; Year='1994' }
    [PSCustomObject]@{ Slug='raiders'; Title='Raiders of the Lost Ark'; Year='1981' }
    [PSCustomObject]@{ Slug='rear-window'; Title='Rear Window'; Year='1954' }
    [PSCustomObject]@{ Slug='return-of-the-king'; Title='The Return of the King'; Year='2003' }
    [PSCustomObject]@{ Slug='saving-private-ryan'; Title='Saving Private Ryan'; Year='1998' }
    [PSCustomObject]@{ Slug='schindlers-list'; Title="Schindler's List"; Year='1993' }
    [PSCustomObject]@{ Slug='seven'; Title='Se7en'; Year='1995' }
    [PSCustomObject]@{ Slug='seven-samurai'; Title='Seven Samurai'; Year='1954' }
    [PSCustomObject]@{ Slug='shawshank-redemption'; Title='The Shawshank Redemption'; Year='1994' }
    [PSCustomObject]@{ Slug='silence-of-the-lambs'; Title='The Silence of the Lambs'; Year='1991' }
    [PSCustomObject]@{ Slug='spirited-away'; Title='Spirited Away'; Year='2001' }
    [PSCustomObject]@{ Slug='spotlight'; Title='Spotlight'; Year='2015' }
    [PSCustomObject]@{ Slug='stalker'; Title='Stalker'; Year='1979' }
    [PSCustomObject]@{ Slug='star-wars'; Title='Star Wars'; Year='1977' }
    [PSCustomObject]@{ Slug='the-departed'; Title='The Departed'; Year='2006' }
    [PSCustomObject]@{ Slug='the-matrix'; Title='The Matrix'; Year='1999' }
    [PSCustomObject]@{ Slug='the-prestige'; Title='The Prestige'; Year='2006' }
    [PSCustomObject]@{ Slug='the-shining'; Title='The Shining'; Year='1980' }
    [PSCustomObject]@{ Slug='there-will-be-blood'; Title='There Will Be Blood'; Year='2007' }
    [PSCustomObject]@{ Slug='toy-story'; Title='Toy Story'; Year='1995' }
    [PSCustomObject]@{ Slug='two-towers'; Title='The Two Towers'; Year='2002' }
    [PSCustomObject]@{ Slug='usual-suspects'; Title='The Usual Suspects'; Year='1995' }
    [PSCustomObject]@{ Slug='wall-e'; Title='WALL-E'; Year='2008' }
    [PSCustomObject]@{ Slug='whiplash'; Title='Whiplash'; Year='2014' }
)

function Invoke-iTunesSearch {
    param([string]$SearchTerm, [string]$Entity, [int]$Limit = 5)

    $term = [Uri]::EscapeDataString($SearchTerm)
    $searchUrl = "https://itunes.apple.com/search?term=$term&entity=$Entity&limit=$Limit"

    $maxAttempts = 4
    $waitSeconds = 5
    for ($attempt = 1; $attempt -le $maxAttempts; $attempt++) {
        try {
            return Invoke-RestMethod -Uri $searchUrl -UserAgent "Mozilla/5.0"
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

function Select-BestMatch {
    param($Results, [string]$ExpectedYear)

    if ($Results.resultCount -lt 1) { return $null }
    if (-not $ExpectedYear) { return $Results.results[0] }

    foreach ($r in $Results.results) {
        if ($r.releaseDate -and $r.releaseDate.Substring(0,4) -eq $ExpectedYear) {
            return $r
        }
    }
    # no exact year match, fall back to the first result
    return $Results.results[0]
}

$misses = New-Object System.Collections.Generic.List[string]
$i = 0

foreach ($f in $films) {
    $i++
    Write-Host "[$i/$($films.Count)] $($f.Title) ($($f.Year))..." -NoNewline

    try {
        $result = Invoke-iTunesSearch -SearchTerm "$($f.Title) $($f.Year)" -Entity 'movie' -Limit 5
        $best = Select-BestMatch -Results $result -ExpectedYear $f.Year

        if (-not $best) {
            # fallback: try the title alone, no year, in case the year threw off the query
            Write-Host " [no match, trying title alone...]" -NoNewline -ForegroundColor DarkYellow
            Start-Sleep -Seconds 2
            $result = Invoke-iTunesSearch -SearchTerm $f.Title -Entity 'movie' -Limit 5
            $best = Select-BestMatch -Results $result -ExpectedYear $f.Year
        }

        if (-not $best) {
            Write-Host " NO MATCH" -ForegroundColor Yellow
            $misses.Add("$($f.Slug) - $($f.Title) ($($f.Year)) (no search result)")
            continue
        }

        $artUrl = $best.artworkUrl100 -replace '100x100bb', '1200x1200bb'
        $outFile = Join-Path $outDir "$($f.Slug).jpg"

        Invoke-WebRequest -Uri $artUrl -OutFile $outFile -UserAgent "Mozilla/5.0"
        Write-Host " done ($($best.trackName), $($best.releaseDate.Substring(0,4)))" -ForegroundColor Green
    }
    catch {
        Write-Host " FAILED: $($_.Exception.Message)" -ForegroundColor Red
        $misses.Add("$($f.Slug) - $($f.Title) ($($f.Year)) (error: $($_.Exception.Message))")
    }

    Start-Sleep -Seconds 2.5
}

Write-Host "`nDone. Saved to: $outDir"
if ($misses.Count -gt 0) {
    Write-Host "`n$($misses.Count) film(s) need manual attention:" -ForegroundColor Yellow
    $misses | ForEach-Object { Write-Host "  - $_" }
    $misses | Out-File (Join-Path $outDir "MISSES.txt")
} else {
    Write-Host "`nAll films resolved." -ForegroundColor Green
}
