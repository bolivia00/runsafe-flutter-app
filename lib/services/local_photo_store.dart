import 'package:flutter/material.dart';
import 'dart:io';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

// CERTIFIQUE-SE QUE A CLASSE SE CHAMA LocalPhotoStore
class LocalPhotoStore {

  Future<String> savePhoto(File originalFile) async {
    final appDir = await getApplicationDocumentsDirectory();
    final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
    final targetPath = p.join(appDir.path, fileName);

    final XFile? compressedXFile = await FlutterImageCompress.compressAndGetFile(
      originalFile.absolute.path,
      targetPath,
      quality: 80,
      minWidth: 512,
      minHeight: 512,
      autoCorrectionAngle: true,
      format: CompressFormat.jpeg,
    );

    if (compressedXFile == null) {
      throw Exception("Falha ao comprimir a imagem.");
    }
    return compressedXFile.path;
  }

  Future<void> deletePhoto(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      debugPrint("Erro ao deletar arquivo: $e");
    }
  }
}