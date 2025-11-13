# Relatório Final: Uso de IA na Implementação do PRD "Avatar com Foto no Drawer"

**Projeto:** RunSafe App
**Aluno:** Bolivar Torres Neto
**Turma/Trio:** [Sua Turma/Trio Aqui - PREENCHA]
**Data:** 23 de outubro de 2025

---

## 1. Resumo
Este relatório documenta a implementação da funcionalidade "Avatar com Foto no Drawer" no aplicativo RunSafe, conforme o Product Requirements Document (PRD) fornecido. O desenvolvimento abrangeu o fluxo completo de adição, alteração e remoção de foto de perfil (via câmera e galeria), com persistência local, compressão de imagem, fallback para iniciais e respeito às diretrizes de LGPD e Acessibilidade (Material 3). O processo utilizou intensivamente o assistente de IA Gemini em todas as fases – planejamento, geração e refatoração de código, configuração de ambiente, depuração, criação de testes e documentação – com registro crítico das interações e decisões tomadas.

## 2. Introdução
O objetivo central foi substituir o `CircleAvatar` com iniciais no `Drawer` do RunSafe por uma foto de perfil gerenciada pelo usuário. O PRD detalhava requisitos específicos para a experiência do usuário (UX), tratamento de dados (LGPD), performance, acessibilidade (A11Y) e qualidade técnica, incluindo testes automatizados. Um requisito transversal obrigatório foi o emprego de uma ferramenta de IA (Gemini) como copiloto durante todo o ciclo de vida do desenvolvimento, avaliando sua eficácia e limitações.

## 3. Metodologia (Uso de IA)
O assistente de IA Gemini foi a ferramenta primária de apoio, atuando como um par programador e consultor técnico. Seu uso abrangeu:

* **Planejamento:** A IA foi solicitada a analisar o PRD e propor uma divisão da implementação em Pull Requests (PRs) lógicos e sequenciais (#1 Infra, #2 Lógica, #3 UI, #4 Testes), o que estruturou todo o desenvolvimento subsequente.
* **Geração e Refatoração de Código:** Geração de código inicial para a arquitetura solicitada (esqueletos de `ProfileRepository`, `LocalPhotoStore`), implementação de funcionalidades complexas (compressão de imagem com `flutter_image_compress`, lógica de persistência com `shared_preferences` encapsulada no `StorageService`), configuração do gerenciador de estado `Provider`, e refatoração do código existente (ex: implementação de rotas nomeadas).
* **Configuração de Ambiente e Pacotes:** Instruções passo a passo para adicionar dependências no `pubspec.yaml`, configurar permissões essenciais no `AndroidManifest.xml` (Android) e `Info.plist` (iOS), e resolver problemas de configuração do ambiente de desenvolvimento (ex: falta do `avdmanager`, erro de `ANDROID_SDK_ROOT`, ativação do Modo de Desenvolvedor no Windows).
* **Debugging e Correção de Erros:** Análise de mensagens de erro do compilador Dart/Flutter e do Git, identificação da causa raiz (ex: erros de digitação em `import`, ambiguidade de imports, arquivos não salvos antes do commit, falhas no `git pull`) e fornecimento das soluções precisas.
* **Geração de Testes:** Criação do código completo para os testes de unidade (`storage_service_test.dart`) e testes de widget (`app_drawer_test.dart`), incluindo a configuração de mocks e a estrutura `Arrange-Act-Assert`.
* **Documentação e Conformidade:** Auxílio no preenchimento dos formulários de Avaliador e Observador com base no estado do projeto, geração do conteúdo para o `checklist_avatar.md` e fornecimento da estrutura e sugestões para este relatório.

A interação com a IA foi predominantemente conversacional. Foram fornecidos prompts claros solicitando blocos de código, explicações de conceitos, soluções para erros específicos ou planejamento estratégico. As respostas da IA foram frequentemente utilizadas como ponto de partida, sendo revisadas, adaptadas e integradas ao projeto. A validação das respostas se deu pela compilação do código, execução dos testes (manuais e automatizados) e verificação do comportamento no emulador.

## 4. Desenvolvimento (Decisões, Prompts, Iterações, Correções)
O desenvolvimento seguiu o plano de 4 PRs (mais um PR de polimento), com auxílio constante da IA:

* **PR #1 (Infraestrutura):** Criação do Drawer com fallback "BT", instalação inicial de pacotes (`image_picker`, `provider`, etc.), criação dos esqueletos `ProfileRepository` e `LocalPhotoStore`.
    * *Interação Chave com IA:* Solicitado planejamento dos PRs e código inicial do `AppDrawer` e esqueletos dos serviços. [Veja Apêndice - Exemplo 1]
* **PR #2 (Lógica):** Implementação da lógica central: permissões Android/iOS, uso do `image_picker`, compressão/remoção de EXIF com `flutter_image_compress`, salvamento do arquivo (`LocalPhotoStore`) e do path (`StorageService`), transformação do `ProfileRepository` em `ChangeNotifier`.
    * *Interação Chave com IA:* Solicitado código para `AndroidManifest.xml`, `Info.plist`, implementação completa do `LocalPhotoStore` (incluindo compressão) e `ProfileRepository`. Correção de erro de `import` faltante (`debugPrint`). [Veja Apêndice - Exemplo 2]
* **PR #3 (UI e Estado):** Conexão da UI (`AppDrawer`) ao `ProfileRepository` via `Provider` e `Consumer`, exibição da foto (`Image.file`), implementação do `BottomSheet` com opções (Câmera, Galeria, Remover) e mensagem de privacidade. Adição de `Semantics` e `Tooltip`.
    * *Interação Chave com IA:* Solicitado código para configurar o `Provider` no `main.dart` e refatoração completa do `AppDrawer` para usar `Consumer`, `Image.file` e `BottomSheet`.
* **PR #4 (Testes):** Criação dos testes de unidade para `StorageService` e widget para `AppDrawer`.
    * *Interação Chave com IA:* Solicitado código completo dos arquivos `storage_service_test.dart` e `app_drawer_test.dart`. Correção de erro de `import` faltante (`ImageSource`). [Veja Apêndice - Exemplo 3]
* **PR #5 (Polimento):** Após revisão do PRD oficial, foram feitos ajustes finos: salvamento da data `userPhotoUpdatedAt` no `StorageService` (e atualização do teste unitário correspondente) e uso de `Image.file` com `cacheWidth`/`cacheHeight` no `AppDrawer`.
    * *Interação Chave com IA:* Solicitado revisão do código implementado versus o PDF do PRD e fornecimento do código corrigido para `StorageService`, `storage_service_test.dart` e `AppDrawer`. Correção de erro de ambiguidade de `import` (`StorageService` definido em dois lugares).

**Decisões e Correções:** Diversos erros foram encontrados e corrigidos com auxílio da IA, desde simples erros de digitação (`package.flutter` em vez de `package:flutter`), problemas de import (`debugPrint`, `ImageSource`), até questões mais complexas de estado assíncrono (`BuildContext` across async gaps) e conflitos de Git (`git pull` falhou, `tag` criada no commit errado). A IA foi eficaz em identificar a causa raiz e fornecer a solução correta na maioria dos casos. A decisão de pular o teste de unidade do `LocalPhotoStore` foi tomada devido à complexidade de mockar o sistema de arquivos e canais nativos, priorizando as outras correções e testes dentro do prazo percebido.

## 5. Validações
A funcionalidade foi validada conforme os critérios do PRD:
* **Testes Manuais:** Fluxo completo de adicionar (Câmera/Galeria), remover e persistência da foto foi verificado com sucesso no emulador Android (API 34). O fallback para iniciais "BT" funcionou corretamente.
* **Testes Automatizados:** O comando `flutter test` resultou em "All tests passed!", validando a lógica de persistência no `StorageService` e a renderização condicional (foto vs. iniciais) no `AppDrawer`.
* **Acessibilidade (A11Y):** O tamanho do avatar (72dp) excede o mínimo de 48dp. `Tooltip` e `Semantics` foram adicionados ao avatar clicável. O estado desabilitado do botão de aceite na tela de políticas foi verificado visualmente. A verificação de contraste e foco foi feita manualmente e considerada adequada.
* **LGPD:** O opt-in explícito (scroll + checkbox), a mensagem de privacidade no `BottomSheet` e a funcionalidade de revogar consentimento (ícone na `AppBar` da `HomeScreen`) foram implementados e testados. A remoção de EXIF/GPS é feita pela biblioteca `flutter_image_compress`.
* **Desempenho:** A compressão da imagem (`quality: 80`, `minWidth/Height: 512`) visa manter o arquivo abaixo de 200KB. O uso de `cacheWidth: 256` no `Image.file` otimiza o uso de memória. A abertura do Drawer permaneceu fluida durante os testes manuais.

## 6. Recursos Flutter Usados
* **Widgets Principais:** `Drawer`, `UserAccountsDrawerHeader`, `CircleAvatar`, `Image.file`, `ClipOval`, `GestureDetector`, `Consumer` (Provider), `ChangeNotifierProvider`, `BottomSheet`, `ListTile`, `CheckboxListTile`, `ScrollController`, `Tooltip`, `Semantics`, `Stack`, `CircularProgressIndicator`.
* **Pacotes Externos:** `provider`, `shared_preferences`, `image_picker`, `flutter_image_compress`, `path_provider`, `path`. (E `dots_indicator`, `flutter_svg` de funcionalidades anteriores).
* **Permissões:** `CAMERA`, `READ_MEDIA_IMAGES` (Android), `NSCameraUsageDescription`, `NSPhotoLibraryUsageDescription` (iOS).
* **Arquitetura:** Separação em camadas UI (`widgets`, `screens`), Repositório (`repositories/profile_repository.dart`) e Serviços (`services/storage_service.dart`, `services/local_photo_store.dart`). Gerenciamento de estado com `ChangeNotifier` e `Provider`.

## 7. Resultados e Discussão
A funcionalidade de avatar com foto foi implementada com sucesso, atendendo a todos os requisitos obrigatórios do PRD MVP. O uso intensivo da IA Gemini acelerou significativamente o processo, especialmente na geração de código para funcionalidades que envolviam múltiplos pacotes e lógica assíncrona, além da criação de testes. A capacidade da IA de diagnosticar erros rapidamente também foi um grande benefício.

No entanto, o processo não foi isento de desafios. A IA, por vezes, gerou código com pequenos erros (imports faltando, erros de tipo) que exigiram depuração manual ou novas interações. A configuração inicial do ambiente Android e a resolução de conflitos no Git foram pontos onde a IA foi crucial, mas que consumiram tempo considerável. A qualidade da resposta da IA dependeu fortemente da clareza do prompt fornecido.

Uma limitação do produto final é a ausência de um feedback visual mais robusto para erros (ex: falha na compressão, falha ao carregar o arquivo). A compressão atual visa $\le 200KB$, mas o tamanho final pode variar. O teste de unidade do `LocalPhotoStore` foi omitido devido à sua complexidade.

A IA me atendeu de forma correta e prestativa.

## 8. Conclusão e Próximos Passos
Conclui-se que a implementação do PRD foi bem-sucedida e que o uso da IA como ferramenta de apoio foi extremamente valioso, embora exija supervisão constante e senso crítico do desenvolvedor. O aplicativo RunSafe agora possui uma funcionalidade de perfil mais rica e personalizada, implementada com boas práticas de arquitetura, performance e conformidade (LGPD/A11Y).

---

