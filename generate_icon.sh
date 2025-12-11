#!/bin/bash
# Script para gerar ícone PNG a partir do SVG usando ImageMagick ou Inkscape
# Execute este script no terminal Linux/Mac ou WSL

# Método 1: Usando Inkscape (recomendado)
inkscape assets/icons/runsafe_icon.svg --export-type=png --export-filename=assets/icons/app_icon.png -w 1024 -h 1024

# Método 2: Usando ImageMagick/convert
# convert -background "#10B981" -density 300 assets/icons/runsafe_icon.svg -resize 1024x1024 assets/icons/app_icon.png

# Método 3: Usando rsvg-convert
# rsvg-convert -w 1024 -h 1024 assets/icons/runsafe_icon.svg -o assets/icons/app_icon.png

echo "Ícone gerado em assets/icons/app_icon.png"
