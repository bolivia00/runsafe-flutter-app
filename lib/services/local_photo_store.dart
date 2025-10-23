import 'package:flutter/material.dart'; // <-- ADICIONE ESTA LINHA
import 'dart:io';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class LocalPhotoStore {
  /// Salva, comprime e remove metadados de um arquivo de imagem.
  /// Retorna o novo caminho (path) onde o arquivo comprimido foi salvo.
  Future<String> savePhoto(File originalFile) async {
    // 1. Encontra o diretório de documentos do app (um local seguro).
    final appDir = await getApplicationDocumentsDirectory();
    
    // 2. Cria um nome de arquivo único usando a data/hora.
    final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
    final targetPath = p.join(appDir.path, fileName);

    // 3. Comprime a imagem, define um tamanho máximo (1024x1024)
    // e qualidade (80), e remove os metadados (EXIF/GPS).
    final XFile? compressedXFile = await FlutterImageCompress.compressAndGetFile(
      originalFile.absolute.path,
      targetPath,
      quality: 80, // Meta de compressão (ajuda a atingir os ~200KB)
      minWidth: 512,  // Define um tamanho razoável para um avatar
      minHeight: 512,
      autoCorrectionAngle: true, // Corrige rotação da câmera
      format: CompressFormat.jpeg,
    );

    if (compressedXFile == null) {
      throw Exception("Falha ao comprimir a imagem.");
    }

    // 4. Retorna o caminho do novo arquivo comprimido.
    return compressedXFile.path;
  }

  /// Apaga um arquivo de foto do armazenamento local.
  Future<void> deletePhoto(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      // Ignora erros (ex: arquivo já não existia)
      debugPrint("Erro ao deletar arquivo: $e");
    }
  }
}