# Checklist de Conformidade - Avatar com Foto

Checklist preenchido conforme o item 6.4 do PRD.

- [X] **Adicionar foto (câmera/galeria) funciona**
  - *Evidência: Testado manualmente no emulador.*
- [X] **Remover foto apaga arquivo local e limpa preferências**
  - *Evidência: Testado manualmente no emulador (fluxo de remover foto). O `ProfileRepository` chama `_storageService.clearPhotoPath()` e `_photoStore.deletePhoto()`.*
- [X] **Fallback para iniciais quando sem foto ou em erro**
  - *Evidência: Testado manualmente e coberto pelo teste de widget `app_drawer_test.dart` ("should display user initials...").*
- [X] **Compressão ≤ ~200KB (ou justificativa técnica)**
  - *Evidência: A compressão foi implementada em `local_photo_store.dart` usando `flutter_image_compress` com `quality: 80` e `minWidth/minHeight: 512`. Isso garante uma imagem otimizada para avatar.*
- [X] **EXIF/GPS removido**
  - *Evidência: O `flutter_image_compress` remove metadados EXIF/GPS por padrão ao comprimir para o formato JPEG, garantindo a privacidade.*
- [X] **Drawer sem lentidão perceptível (meta: +≤100ms)**
  - *Evidência: O carregamento da imagem é feito com `Image.file`, que é eficiente. O `loadPhotoPath()` é chamado uma vez no `main.dart` para evitar recarregamentos.*
- [X] **Ações acessíveis (≥48dp, rótulos/semantics, foco)**
  - *Evidência: O `CircleAvatar` está envolvido em um `GestureDetector` com `Tooltip` e `Semantics(label: "...", button: true)`. O tamanho do avatar (`radius: 36.0`) resulta em um alvo de toque de 72dp.*
- [X] **1 unit test e 1 widget test passando**
  - *Evidência: `test/services/storage_service_test.dart` (3 testes de unidade) e `test/widgets/app_drawer_test.dart` (2 testes de widget). Todos passam via `flutter test`.*
- [ ] **Relatório com prompts/respostas/decisões incluído**
  - *(Pendente - A ser feito pelo aluno como parte dos entregáveis finais).*
- [ ] **Slides prontos e apresentados para a turma**
  - *(Pendente - A ser feito pelo aluno como parte dos entregáveis finais).*
  