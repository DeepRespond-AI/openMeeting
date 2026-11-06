param()
$ErrorActionPreference='Stop'
Add-Type -AssemblyName System.Drawing
$artifactRoot=if ($env:OPENMEETING_PARITY_ARTIFACTS) { $env:OPENMEETING_PARITY_ARTIFACTS } else { Join-Path (Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))) '.artifacts/mobile-desktop-parity' }
$allRows=Get-Content -Raw -Encoding UTF8 -LiteralPath (Join-Path $artifactRoot $(if ($env:OPENMEETING_PARITY_RESULTS) { $env:OPENMEETING_PARITY_RESULTS } else { 'ui-results.json' })) | ConvertFrom-Json
$rows=@($allRows | Where-Object { $_.screenshot })
$output=Join-Path $artifactRoot 'logs\contacts'
New-Item -ItemType Directory -Force -Path $output | Out-Null
$groups=@($rows|Group-Object {($_.action -split '/')[0]})
foreach($group in $groups){
  $batch=0
  for($offset=0;$offset -lt $group.Group.Count;$offset+=4){
    $batch++
    $items=@($group.Group|Select-Object -Skip $offset -First 4)
    $wide=$group.Name -like '*平板*'
    $tileWidth=if($wide){1000}else{540}
    $tileHeight=if($wide){800}else{1150}
    $canvas=New-Object Drawing.Bitmap ($tileWidth*2),($tileHeight*2)
    $graphics=[Drawing.Graphics]::FromImage($canvas)
    $graphics.Clear([Drawing.Color]::White)
    $font=New-Object Drawing.Font 'Microsoft YaHei',10
    for($i=0;$i -lt $items.Count;$i++){
      $item=$items[$i]
      $source=[Drawing.Image]::FromFile((Join-Path $artifactRoot $item.screenshot))
      $scale=[Math]::Min(($tileWidth-12)/$source.Width,($tileHeight-45)/$source.Height)
      $x=($i%2)*$tileWidth+6
      $y=[Math]::Floor($i/2)*$tileHeight+35
      $graphics.DrawString((($item.action -split '/')[-1]),$font,[Drawing.Brushes]::Black,$x,$y-30)
      $graphics.DrawImage($source,[int]$x,[int]$y,[int]($source.Width*$scale),[int]($source.Height*$scale))
      $source.Dispose()
    }
    $safeName=if($group.Name -like '*平板*'){'wide'}else{'narrow'}
    $file=Join-Path $output ('{0}-{1:D2}.png' -f $safeName,$batch)
    $canvas.Save($file,[Drawing.Imaging.ImageFormat]::Png)
    $font.Dispose();$graphics.Dispose();$canvas.Dispose()
    Write-Output $file
  }
}
