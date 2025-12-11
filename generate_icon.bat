@echo off
REM Script para Windows - Gera ícone PNG a partir do SVG

echo ========================================
echo GERADOR DE ÍCONE PNG PARA RUNSAFE
echo ========================================
echo.
echo Este script precisa de uma ferramenta de conversão SVG para PNG.
echo.
echo OPÇÕES DISPONÍVEIS:
echo.
echo 1. ONLINE (Recomendado para Windows):
echo    - Acesse: https://cloudconvert.com/svg-to-png
echo    - Carregue: assets\icons\runsafe_icon.svg
echo    - Configure: 1024x1024 pixels
echo    - Salve como: assets\icons\app_icon.png
echo.
echo 2. INKSCAPE (Se instalado):
echo    - Baixe: https://inkscape.org/
echo    - Execute: inkscape assets\icons\runsafe_icon.svg --export-type=png --export-filename=assets\icons\app_icon.png -w 1024 -h 1024
echo.
echo 3. IMAGEMAGICK (Se instalado):
echo    - Baixe: https://imagemagick.org/
echo    - Execute: magick convert -background "#10B981" -density 300 assets\icons\runsafe_icon.svg -resize 1024x1024 assets\icons\app_icon.png
echo.
echo 4. CRIAR MANUALMENTE:
echo    - Use Figma, Photoshop, GIMP ou similar
echo    - Crie um canvas 1024x1024
echo    - Desenhe escudo verde (#10B981) com check mark branco
echo    - Exporte como PNG: assets\icons\app_icon.png
echo.
echo ========================================

pause
