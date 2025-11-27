# Relatório de Implementação: Features de Metas (RunSafe App)

**Aluno:** Bolivar Torres Neto
**Repositório:** https://github.com/bolivia00/runsafe-flutter-app

---

## [cite_start]1. Sumário Executivo [cite: 414]

Este documento detalha a implementação de features avançadas na seção de "Metas" do aplicativo RunSafe, como parte da atividade "Daily Goals". [cite_start]O projeto base (o app da "Emily") [cite: 396] foi usado como referência conceitual, mas as implementações foram feitas diretamente no app RunSafe para evoluir um projeto já existente.

Foram implementadas duas *features* principais, aplicando os conceitos da arquitetura (Entidade $\neq$ DTO + Mapper) e da interface de usuário (UI Polida) apresentados em aula:
1.  **Feature 1 (Persistência de Dados):** A camada de persistência (Repositório + Provider) foi implementada para as 4 entidades do domínio (`WeeklyGoal`, `SafetyAlert`, `Waypoint`, `RunningRoute`), fazendo com que os dados sejam salvos localmente no `SharedPreferences` e carregados no início do app.
2.  [cite_start]**Feature 2 (UI Polida e Interativa):** As telas de lista de todas as 4 entidades foram atualizadas para incluir a UI polida (FAB com microanimação [cite: 397][cite_start], "Tip Bubble" [cite: 397] [cite_start]e "Overlay de Tutorial" [cite: 397]) apresentada nos slides. Além disso, foi implementada a funcionalidade de **Edição** (ao tocar no item) e **Exclusão** (ao deslizar o item).

[cite_start]A IA (Gemini) foi usada como recurso opcional  para planejar a arquitetura, gerar código para os Mappers, Repositórios e Serviços, e para implementar a UI complexa dos slides.

## [cite_start]2. Arquitetura e Fluxo de Dados [cite: 415]

A arquitetura implementada segue o padrão ensinado, separando claramente as responsabilidades:

**Diagrama de Fluxo (ASCII):**

**Uso da IA no Fluxo:**
A IA (Gemini) foi usada para gerar o código-base de quase todos os componentes desta arquitetura[cite: 416]:
* **Prompt (IA):** "Me dê o DTO e o Mapper para a Entidade X."
* **Resposta (IA):** Geração dos arquivos `dto/X_dto.dart` e `mappers/X_mapper.dart`.
* **Prompt (IA):** "Me dê o Repositório e atualize o StorageService para a Entidade X."
* **Resposta (IA):** Geração do `domain/repositories/X_repository.dart` e atualização do `services/storage_service.dart` com os métodos de salvamento em JSON.

---

## 3. Features Implementadas

### Feature 1: Persistência de Dados (CRUD Básico)

* **Objetivo [cite: 418]:** Substituir a lista "layout-only" [cite: 399] (que se perdia ao fechar a tela) por um sistema de persistência real que salva os dados no dispositivo.
* **Prompt(s) Usados (IA)[cite: 419]:**
    * `"Como posso salvar uma lista de Entidades no SharedPreferences?"`
    * `"Me dê o código para um Repositório (ChangeNotifier) que carrega (load) e salva (save) uma lista de Entidades usando o StorageService, DTO e Mapper."`
    * `"Me dê o código para atualizar o main.dart para usar MultiProvider com este novo repositório."`
* **Como Testar Localmente[cite: 421]:**
    1.  Navegue para qualquer tela de lista (ex: "Minhas Metas").
    2.  Clique no botão `+` e adicione um novo item.
    3.  Verifique se o item aparece na lista.
    4.  **Feche completamente o aplicativo** (encerre o processo no emulador).
    5.  Abra o aplicativo novamente.
    6.  Navegue de volta para a tela de lista.
    7.  **Critério de Aceite:** O item que você criou **deve estar lá**.
* **Código Gerado pela IA[cite: 423]:**
    * `lib/domain/repositories/weekly_goal_repository.dart` (e os outros 3 repositórios).
    * `lib/services/storage_service.dart` (métodos `save...Json` e `get...Json`).
    * `lib/main.dart` (configuração do `MultiProvider`).

### Feature 2: UI Polida (Slides) e Edição/Exclusão

* **Objetivo [cite: 418]:** Replicar a experiência de usuário (UX) ensinada nos slides (`DailyGoalListPage.pdf`) [cite: 450-683] em todas as 4 listas de entidades e adicionar as funções de Edição e Exclusão.
* **Prompt(s) Usados (IA)[cite: 419]:**
    * `"Quero implementar TUDO o que está nos slides (DailyGoalListPage.pdf). Me dê o código completo para a 'WeeklyGoalListPage' que inclua a animação do FAB [cite: 489, 497-501], a Tip Bubble [cite: 455] e o Overlay de Tutorial[cite: 455]."
    * `"Agora, adicione a funcionalidade de Edição (onTap) e Exclusão (Dismissible) nesta lista."`
    * `"Me dê o código para o Formulário (DailyGoalEntityFormDialog.pdf) [cite: 1-253] para a entidade X, que suporte o modo de 'edição' (recebendo 'initial')."`
* **Como Testar Localmente[cite: 421]:**
    1.  Navegue para qualquer tela de lista (ex: "Alertas de Segurança").
    2.  **Verifique a UI:** O botão `+` deve estar pulsando[cite: 455]. A "bolha de dica" deve aparecer acima dele[cite: 455]. O botão "Não exibir dica" deve estar no canto.
    3.  Clique no `?` na AppBar. O "Overlay de Tutorial" deve aparecer[cite: 455].
    4.  **Teste a Edição:** Adicione um item. Toque nesse item. O formulário deve abrir com os dados preenchidos. Altere os dados e salve. A lista deve atualizar.
    5.  **Teste a Exclusão:** Deslize o item da direita para a esquerda. O item deve ser excluído.
    6.  **Teste a Persistência:** Feche e reabra o app. As edições e exclusões devem estar salvas.
* **Código Gerado pela IA[cite: 423]:**
    * `lib/screens/weekly_goal_list_page.dart` (e as outras 3 telas de lista).
    * `lib/widgets/forms/weekly_goal_form_dialog.dart` (e os outros 3 formulários).
    * `lib/domain/entities/weekly_goal.dart` (atualização para incluir `id` e `userId` para a edição).

## 4. Política de Branches e Commits [cite: 427]

O controle de versão foi feito seguindo a política de *feature branching*. Cada funcionalidade ou entidade principal foi desenvolvida em sua própria *branch* separada para isolar o trabalho:

1.  `feature/domain-architecture`: Implementação inicial da arquitetura (Entidades, DTOs, Mappers).
2.  `feature/goals-ui-polish`: Aplicação da UI dos slides (animações, dicas) na tela de Metas.
3.  `feature/goals-edit-delete`: Adição da lógica de Edição e Exclusão na tela de Metas.
4.  `feature/safety-alert-crud`: Implementação do ciclo CRUD completo para a entidade `SafetyAlert`.
5.  `feature/waypoint-crud`: Implementação do ciclo CRUD completo para a entidade `Waypoint`.
6.  `feature/running-route-crud`: Implementação do ciclo CRUD completo para a entidade `RunningRoute`.

Cada *commit* foi feito com uma mensagem clara e semântica (ex: `feat(...)`, `fix(...)`, `refactor(...)`) para descrever a mudança.