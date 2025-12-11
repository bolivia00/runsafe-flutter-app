Add-Type -AssemblyName System.Drawing

# Caminhos
$originalPath = "c:\runsafe\assets\icons\app_icon.png"
$outputPath = "c:\runsafe\assets\icons\app_icon.png"
$backupPath = "c:\runsafe\assets\icons\app_icon_backup.png"

# Backup
Copy-Item $originalPath $backupPath -Force
Write-Host "Backup criado: $backupPath"

# Carregar imagem
$img = [System.Drawing.Image]::FromFile($backupPath)

# Criar novo bitmap
$width = 1024
$height = 1024
$bitmap = New-Object System.Drawing.Bitmap($width, $height)
$graphics = [System.Drawing.Graphics]::FromImage($bitmap)
$graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
$graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic

# Fundo verde
$greenBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(255, 16, 185, 129))
$graphics.FillRectangle($greenBrush, 0, 0, $width, $height)

# Recortar parte superior (60% = apenas corredor, sem texto)
$cropHeight = [int]($img.Height * 0.58)
$srcRect = New-Object System.Drawing.Rectangle(0, 0, $img.Width, $cropHeight)

# Centralizar e aumentar
$targetSize = 680
$x = ($width - $targetSize) / 2
$y = ($height - $targetSize) / 2 - 20
$destRect = New-Object System.Drawing.Rectangle($x, $y, $targetSize, $targetSize)

# Desenhar
$graphics.DrawImage($img, $destRect, $srcRect, [System.Drawing.GraphicsUnit]::Pixel)

# Salvar
$img.Dispose()
$bitmap.Save($outputPath, [System.Drawing.Imaging.ImageFormat]::Png)
$bitmap.Dispose()
$graphics.Dispose()
$greenBrush.Dispose()

Write-Host "Imagem processada com sucesso!"
Write-Host "Nova imagem salva em: $outputPath"
Write-Host "Original em: $backupPath"
