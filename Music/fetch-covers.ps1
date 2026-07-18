<#
  fetch-covers.ps1
  Downloads official album cover art (via the free iTunes Search API) for every
  Autopsy on the maktub/Final Cut Music site, and saves each one named to match
  its page slug, ready to drop into Final Cut/Music/img/.

  USAGE:
    1. Open PowerShell (Windows 10/11 built-in PowerShell or PowerShell 7 both work).
    2. cd to wherever you saved this script.
    3. Run:  .\fetch-covers.ps1
    4. Covers land in a new "covers-output" folder next to the script.
    5. Spot-check them, then copy the whole folder's contents into:
         E:\Claudius\Personal\Projects\Final Cut\Music\img\
  Needs an internet connection. No installs required (Invoke-RestMethod /
  Invoke-WebRequest are built into PowerShell). Takes a few minutes for 71 albums
  since it waits briefly between requests to be polite to the API.
#>

$ErrorActionPreference = 'Stop'
$outDir = Join-Path $PSScriptRoot "covers-output"
New-Item -ItemType Directory -Force -Path $outDir | Out-Null

$albums = @(
    [PSCustomObject]@{ Slug='abbey-road'; Artist='The Beatles'; Album='Abbey Road' }
    [PSCustomObject]@{ Slug='after-hours'; Artist='The Weeknd'; Album='After Hours' }
    [PSCustomObject]@{ Slug='alligator-bites-never-heal'; Artist='Doechii'; Album='Alligator Bites Never Heal' }
    [PSCustomObject]@{ Slug='ants-from-up-there'; Artist='Black Country, New Road'; Album='Ants From Up There' }
    [PSCustomObject]@{ Slug='aquemini'; Artist='Outkast'; Album='Aquemini' }
    [PSCustomObject]@{ Slug='astroworld'; Artist='Travis Scott'; Album='Astroworld' }
    [PSCustomObject]@{ Slug='beauty-behind-the-madness'; Artist='The Weeknd'; Album='Beauty Behind the Madness' }
    [PSCustomObject]@{ Slug='black-on-both-sides'; Artist='Mos Def'; Album='Black on Both Sides' }
    [PSCustomObject]@{ Slug='blonde'; Artist='Frank Ocean'; Album='Blonde' }
    [PSCustomObject]@{ Slug='blue-joni'; Artist='Joni Mitchell'; Album='Blue' }
    [PSCustomObject]@{ Slug='born-to-run'; Artist='Springsteen'; Album='Born to Run' }
    [PSCustomObject]@{ Slug='brat'; Artist='Charli XCX'; Album='Brat' }
    [PSCustomObject]@{ Slug='channel-orange'; Artist='Frank Ocean'; Album='Channel Orange' }
    [PSCustomObject]@{ Slug='clipse'; Artist='Clipse'; Album='Let God Sort Em Out' }
    [PSCustomObject]@{ Slug='college-dropout'; Artist='Kanye West'; Album='The College Dropout' }
    [PSCustomObject]@{ Slug='ctrl-sza'; Artist='SZA'; Album='Ctrl' }
    [PSCustomObject]@{ Slug='currents'; Artist='Tame Impala'; Album='Currents' }
    [PSCustomObject]@{ Slug='damn'; Artist='Kendrick Lamar'; Album='DAMN.' }
    [PSCustomObject]@{ Slug='dark-side'; Artist='Pink Floyd'; Album='The Dark Side of the Moon' }
    [PSCustomObject]@{ Slug='dragon-new-warm-mountain'; Artist='Big Thief'; Album='Dragon New Warm Mountain I Believe in You' }
    [PSCustomObject]@{ Slug='fetch-the-bolt-cutters'; Artist='Fiona Apple'; Album='Fetch the Bolt Cutters' }
    [PSCustomObject]@{ Slug='forest-hills-drive'; Artist='J. Cole'; Album='2014 Forest Hills Drive' }
    [PSCustomObject]@{ Slug='funeral'; Artist='Arcade Fire'; Album='Funeral' }
    [PSCustomObject]@{ Slug='gkmc'; Artist='Kendrick Lamar'; Album='good kid, m.A.A.d city' }
    [PSCustomObject]@{ Slug='god-does-like-ugly'; Artist='JID'; Album='God Does Like Ugly' }
    [PSCustomObject]@{ Slug='gorillaz'; Artist='Gorillaz'; Album='Gorillaz' }
    [PSCustomObject]@{ Slug='graduation'; Artist='Kanye West'; Album='Graduation' }
    [PSCustomObject]@{ Slug='great-divide-noah-kahan'; Artist='Noah Kahan'; Album='The Great Divide' }
    [PSCustomObject]@{ Slug='hell-hath-no-fury'; Artist='Clipse'; Album='Hell Hath No Fury' }
    [PSCustomObject]@{ Slug='hit-me-hard-and-soft'; Artist='Billie Eilish'; Album='Hit Me Hard and Soft' }
    [PSCustomObject]@{ Slug='honeymoon'; Artist='Lana Del Rey'; Album='Honeymoon' }
    [PSCustomObject]@{ Slug='igor'; Artist='Tyler, the Creator'; Album='Igor' }
    [PSCustomObject]@{ Slug='illmatic'; Artist='Nas'; Album='Illmatic' }
    [PSCustomObject]@{ Slug='in-rainbows'; Artist='Radiohead'; Album='In Rainbows' }
    [PSCustomObject]@{ Slug='is-this-it'; Artist='The Strokes'; Album='Is This It' }
    [PSCustomObject]@{ Slug='kind-of-blue'; Artist='Miles Davis'; Album='Kind of Blue' }
    [PSCustomObject]@{ Slug='kiwanuka'; Artist='Kiwanuka'; Album='Kiwanuka' }
    [PSCustomObject]@{ Slug='led-zeppelin-iv'; Artist='Led Zeppelin'; Album='Led Zeppelin IV' }
    [PSCustomObject]@{ Slug='love-and-hate-kiwanuka'; Artist='Kiwanuka'; Album='Love & Hate' }
    [PSCustomObject]@{ Slug='low-end-theory'; Artist='A Tribe Called Quest'; Album='The Low End Theory' }
    [PSCustomObject]@{ Slug='madvillainy'; Artist='Madvillain'; Album='Madvillainy' }
    [PSCustomObject]@{ Slug='maps-billy-woods'; Artist='billy woods & Kenny Segel'; Album='Maps' }
    [PSCustomObject]@{ Slug='mbdtf'; Artist='Kanye West'; Album='My Beautiful Dark Twisted Fantasy' }
    [PSCustomObject]@{ Slug='melodrama'; Artist='Lorde'; Album='Melodrama' }
    [PSCustomObject]@{ Slug='miseducation'; Artist='Lauryn Hill'; Album='The Miseducation of Lauryn Hill' }
    [PSCustomObject]@{ Slug='motomami'; Artist='Rosalía'; Album='MOTOMAMI' }
    [PSCustomObject]@{ Slug='mr-morale'; Artist='Kendrick Lamar'; Album='Mr. Morale & the Big Steppers' }
    [PSCustomObject]@{ Slug='nevermind'; Artist='Nirvana'; Album='Nevermind' }
    [PSCustomObject]@{ Slug='no-thank-you'; Artist='Little Simz'; Album='No Thank You' }
    [PSCustomObject]@{ Slug='ok-computer'; Artist='Radiohead'; Album='OK Computer' }
    [PSCustomObject]@{ Slug='pure-heroine'; Artist='Lorde'; Album='Pure Heroine' }
    [PSCustomObject]@{ Slug='purple-rain'; Artist='Prince'; Album='Purple Rain' }
    [PSCustomObject]@{ Slug='reasonable-doubt'; Artist='Jay-Z'; Album='Reasonable Doubt' }
    [PSCustomObject]@{ Slug='revolver'; Artist='The Beatles'; Album='Revolver' }
    [PSCustomObject]@{ Slug='saint-cloud'; Artist='Waxahatchee'; Album='Saint Cloud' }
    [PSCustomObject]@{ Slug='sometimes-i-might-be-introvert'; Artist='Little Simz'; Album='Sometimes I Might Be Introvert' }
    [PSCustomObject]@{ Slug='songs-key-of-life'; Artist='Stevie Wonder'; Album='Songs in the Key of Life' }
    [PSCustomObject]@{ Slug='sos-sza'; Artist='SZA'; Album='SOS' }
    [PSCustomObject]@{ Slug='the-bends'; Artist='Radiohead'; Album='The Bends' }
    [PSCustomObject]@{ Slug='the-fall-off'; Artist='J. Cole'; Album='The Fall-Off' }
    [PSCustomObject]@{ Slug='the-forever-story'; Artist='JID'; Album='The Forever Story' }
    [PSCustomObject]@{ Slug='the-infamous'; Artist='Mobb Deep'; Album='The Infamous' }
    [PSCustomObject]@{ Slug='the-wall'; Artist='Pink Floyd'; Album='The Wall' }
    [PSCustomObject]@{ Slug='thriller'; Artist='Michael Jackson'; Album='Thriller' }
    [PSCustomObject]@{ Slug='torches'; Artist='Foster the People'; Album='Torches' }
    [PSCustomObject]@{ Slug='tpab'; Artist='Kendrick Lamar'; Album='To Pimp a Butterfly' }
    [PSCustomObject]@{ Slug='unreal-unearth'; Artist='Hozier'; Album='Unreal Unearth' }
    [PSCustomObject]@{ Slug='utopia'; Artist='Travis Scott'; Album='Utopia' }
    [PSCustomObject]@{ Slug='velvet-underground-and-nico'; Artist='The Velvet Underground'; Album='The Velvet Underground & Nico' }
    [PSCustomObject]@{ Slug='whats-going-on'; Artist='Marvin Gaye'; Album="What's Going On" }
    [PSCustomObject]@{ Slug='white-album'; Artist='The Beatles'; Album='The Beatles (White Album)' }
)

$misses = New-Object System.Collections.Generic.List[string]
$i = 0

foreach ($a in $albums) {
    $i++
    Write-Host "[$i/$($albums.Count)] $($a.Artist) - $($a.Album)..." -NoNewline

    try {
        $term = [Uri]::EscapeDataString("$($a.Artist) $($a.Album)")
        $searchUrl = "https://itunes.apple.com/search?term=$term&entity=album&limit=1"
        $result = Invoke-RestMethod -Uri $searchUrl -UserAgent "Mozilla/5.0"

        if ($result.resultCount -lt 1) {
            Write-Host " NO MATCH" -ForegroundColor Yellow
            $misses.Add("$($a.Slug) - $($a.Artist) - $($a.Album) (no search result)")
            continue
        }

        # iTunes gives a 100x100 thumbnail URL by default; swap it for a bigger size.
        $artUrl = $result.results[0].artworkUrl100 -replace '100x100bb', '1000x1000bb'
        $outFile = Join-Path $outDir "$($a.Slug).jpg"

        Invoke-WebRequest -Uri $artUrl -OutFile $outFile -UserAgent "Mozilla/5.0"
        Write-Host " done" -ForegroundColor Green
    }
    catch {
        Write-Host " FAILED: $($_.Exception.Message)" -ForegroundColor Red
        $misses.Add("$($a.Slug) - $($a.Artist) - $($a.Album) (error: $($_.Exception.Message))")
    }

    Start-Sleep -Milliseconds 400
}

Write-Host "`nDone. Saved to: $outDir"
if ($misses.Count -gt 0) {
    Write-Host "`n$($misses.Count) album(s) need manual attention:" -ForegroundColor Yellow
    $misses | ForEach-Object { Write-Host "  - $_" }
    $misses | Out-File (Join-Path $outDir "MISSES.txt")
}
