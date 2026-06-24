# PowerShell script to generate PNG placeholders for Peblo mascot assets
Add-Type -AssemblyName System.Drawing

$assetsDir = "d:\Flutter\flutter dev\projects\peblo_ai\assets\images"
if (!(Test-Path $assetsDir)) {
    New-Item -ItemType Directory -Path $assetsDir -Force
}

$width = 200
$height = 160

# Brand colors (PRD Section 5.2)
$purple = [System.Drawing.Color]::FromArgb(255, 92, 45, 145)    # #5C2D91 (Raga)
$teal = [System.Drawing.Color]::FromArgb(255, 0, 188, 212)       # #00BCD4 (Vidya)

$ragaAssets = @{
    "raga_idle.png" = "Raga Idle"
    "raga_speaking.png" = "Raga Speaking"
    "raga_thinking.png" = "Raga Thinking"
    "raga_shy.png" = "Raga Shy"
    "raga_wave_bye.png" = "Raga Wave Bye"
}

$vidyaAssets = @{
    "vidya_idle.png" = "Vidya Idle"
    "vidya_pointing.png" = "Vidya Pointing"
    "vidya_sympathetic.png" = "Vidya Sympathetic"
    "vidya_celebrating.png" = "Vidya Celebrating"
}

# Generate Raga Assets
foreach ($file in $ragaAssets.Keys) {
    $text = $ragaAssets[$file]
    $filePath = Join-Path $assetsDir $file
    
    $bmp = New-Object System.Drawing.Bitmap($width, $height)
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    
    $g.Clear($purple)
    
    $brush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::White)
    $font = New-Object System.Drawing.Font("Arial", 16, [System.Drawing.FontStyle]::Bold)
    $sf = New-Object System.Drawing.StringFormat
    $sf.Alignment = [System.Drawing.StringAlignment]::Center
    $sf.LineAlignment = [System.Drawing.StringAlignment]::Center
    
    $rect = New-Object System.Drawing.RectangleF(0, 0, $width, $height)
    $g.DrawString($text, $font, $brush, $rect, $sf)
    
    $bmp.Save($filePath, [System.Drawing.Imaging.ImageFormat]::Png)
    
    $brush.Dispose()
    $font.Dispose()
    $sf.Dispose()
    $g.Dispose()
    $bmp.Dispose()
    
    Write-Host "Generated: $filePath"
}

# Generate Vidya Assets
foreach ($file in $vidyaAssets.Keys) {
    $text = $vidyaAssets[$file]
    $filePath = Join-Path $assetsDir $file
    
    $bmp = New-Object System.Drawing.Bitmap($width, $height)
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    
    $g.Clear($teal)
    
    $brush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::White)
    $font = New-Object System.Drawing.Font("Arial", 16, [System.Drawing.FontStyle]::Bold)
    $sf = New-Object System.Drawing.StringFormat
    $sf.Alignment = [System.Drawing.StringAlignment]::Center
    $sf.LineAlignment = [System.Drawing.StringAlignment]::Center
    
    $rect = New-Object System.Drawing.RectangleF(0, 0, $width, $height)
    $g.DrawString($text, $font, $brush, $rect, $sf)
    
    $bmp.Save($filePath, [System.Drawing.Imaging.ImageFormat]::Png)
    
    $brush.Dispose()
    $font.Dispose()
    $sf.Dispose()
    $g.Dispose()
    $bmp.Dispose()
    
    Write-Host "Generated: $filePath"
}
