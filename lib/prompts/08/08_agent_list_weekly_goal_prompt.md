## Prompt: Gerar listagem de metas semanais (weekly_goals)

Parâmetros (defina estes valores no início do prompt antes de executar)
---------------------------------------------------------------
- ENTITY_SINGULAR: Meta semanal   # nome singular legível (ex.: 'Meta semanal')
- ENTITY_PLURAL: metas_semanais    # nome plural legível em minúsculas (ex.: 'metas_semanais')
- DTO_CLASS: WeeklyGoalDto       # nome da classe/DTO usada no projeto (ex.: 'WeeklyGoalDto')
- FEATURE_FOLDER: weekly_goals   # pasta/feature onde o código vive (ex.: 'weekly_goals')
- PAGE_DEFAULT: 1                # página padrão
- PAGE_SIZE_DEFAULT: 20          # tamanho de página padrão
- MAX_PAGE_SIZE: 100             # limite máximo recomendado para pageSize
- SORT_BY_DEFAULT: week_start    # campo de ordenação padrão
- INCLUDE_HINT: activities,metrics # relacionamentos opcionais sugeridos

OBS: Substitua os tokens acima antes de enviar o prompt ao agente ou forneça esses valores na invocação.

Contexto
---
Você é um agente que ajuda a produzir tanto a especificação de dados quanto, quando solicitado, código Flutter/Dart que implemente a listagem de metas semanais (widget/fluxo) seguindo as convenções do repositório. O prompt abaixo está parametrizado para permitir gerar:

- uma especificação/contract (JSON) para a API/DAO que fornece a listagem;
- e opcionalmente, um widget Flutter/Dart muito semelhante ao `lib/features/weekly_goals/presentation/weekly_goals_page.dart`, com integração ao DAO local da feature.

Objetivo
---
Gerar (conforme modo solicitado na invocação) uma das seguintes saídas:

1. Especificação e exemplo de JSON (contrato de dados) para a listagem paginada e filtrável.
2. Código Flutter/Dart que implemente a página/listagem de metas semanais (widget), integrando com o DAO local da feature, e obedecendo às convenções do projeto (idioma, nomes, patterns de persistência e handlers de UI).

Entradas esperadas (inputs)
---
- filters: objeto opcional com critérios de busca (por exemplo: {"q": "corrida", "min_target_km": 10, "status": "active"})
- page: número da página (inteiro, default 1)
- pageSize: itens por página (inteiro, default 20)
- sortBy: campo para ordenação (por exemplo: "week_start", "createdAt")
- sortDir: direção da ordenação ("asc" ou "desc")
- include: lista opcional de relacionamentos a incluir (por exemplo: ["activities","metrics"]) — o agente deve explicar resoluções possíveis.

Se o modo de execução pedir geração de código, o agente deve aceitar parâmetros adicionais (passe-os como tokens no topo):

- DAO_CLASS_HINT: WeeklyGoalsLocalDaoSharedPrefs  # sugestão de nome do DAO local a ser importado
- DAO_METHODS: [listAll, upsertAll, clear]       # métodos esperados no DAO (ajuste se diferente)

Regras e restrições
---
- Se o modo for "especificação", produza apenas a descrição/JSON (não gere código). Se o modo for "implementar_widget", gere código Flutter/Dart que implemente a página/listagem conforme as instruções abaixo.
- Campos sensíveis devem ser mascarados na saída de exemplo (por exemplo: IDs de usuário parcialmente ocultos) e, no código gerado, aplicar máscaras quando exibir tais campos.
- A resposta deve considerar performance: indicar limites razoáveis de pageSize (por exemplo <= 100), sugerir cursor-based pagination para grandes volumes e limitar atributos carregados quando `include` não for solicitado.
- Permissões: o código gerado e a especificação devem mencionar que a listagem respeita permissões/escopo do usuário (exibir apenas metas que o usuário tem acesso).
- Ao gerar código, respeite os padrões do repositório: estrutura de pastas (`lib/features/{FEATURE_FOLDER}/presentation`), idioma (português nas labels), tratamento de erros (`try/catch`) e feedback via `SnackBar`.
- Importante: todos os diálogos gerados devem ser não-dismissable ao tocar fora (use `showDialog(..., barrierDismissible: false)` ou equivalente). O fechamento deve ocorrer somente pelos botões/ações explícitas do diálogo.

Escopo de geração de código (quando aplicável)
---
O agente deve gerar um widget Flutter que implemente apenas a listagem (modo "listing-only"). No modo listing-only o widget deve conter, no mínimo:

- Carregamento inicial via DAO (`listAll`) e indicação de loading (CircularProgressIndicator).
- (Pull-to-refresh foi extraído para um prompt separado.)
- `ListView.builder` para apresentar os itens (sem `Dismissible`, sem handlers de remoção por swipe neste arquivo).
- Renderização condicional de ícone/imagem com `Image.network` quando houver `image_url`, incluindo `errorBuilder` e `loadingBuilder`.
- Exibição de `target_km`/`target_time`, `progress_percent` (formatado com 0-100%), e `week_start`/`week_end` formatados.
- Integração com DAO local da feature: identificar e importar o DAO (por exemplo `WeeklyGoalsLocalDaoSharedPrefs`) e usar os métodos de leitura (`listAll`) — operações de escrita/remoção/edição devem ser mantidas fora deste arquivo e implementadas separadamente.

Observação: funcionalidades adicionais (editar, remover por swipe, seleção com diálogo de ações) devem ser implementadas em arquivos/pedidos separados.

Contrato de DTO / Campos esperados
---
O agente deve mapear o DTO aos campos usados no código existente. Campos típicos para uma meta semanal:

- id: string
- title: string
- description: string (opcional)
- ownerId: string (mascarado quando exibido)
- target_km: number (double, opcional)
- target_time_min: integer (opcional)
- progress_percent: number (0-100)
- week_start: ISO8601 date (ex: "2025-11-24")
- week_end: ISO8601 date
- activities: array opcional (resumo de atividades)
- metrics: objeto opcional com métricas agregadas
- status: string (ex: "active","completed","paused")
- createdAt / updatedAt: ISO8601 datetimes
- image_url: string (opcional)

O agente deve preferir a classe `{DTO_CLASS}` quando existir e gerar import/uso desta classe no código produzido.

Formato de saída desejado (modo: especificação)
---
Quando em modo de especificação, o agente deve apresentar um exemplo JSON com os seguintes elementos:

- meta: { total: inteiro, page: inteiro, pageSize: inteiro, totalPages: inteiro }
- filtersApplied: objeto descrevendo os filtros usados
- data: lista de objetos de meta semanal, cada um contendo ao menos os campos abaixo

Campos de cada meta semanal (exemplo mínimo)
---
- id: string (UUID ou identificador)
- title: string
- ownerId: string (mascarado, ex: "usr_78***90")
- target_km: number opcional
- progress_percent: number (ex: 56.3)
- week_start: date (ISO8601)
- week_end: date (ISO8601)
- status: string
- createdAt: ISO8601 datetime
- updatedAt: ISO8601 datetime

Exemplo de saída (JSON)
---
```json
{
  "meta": {
    "total": 5,
    "page": 1,
    "pageSize": 20,
    "totalPages": 1
  },
  "filtersApplied": {
    "q": "meta corrida",
    "min_target_km": 10,
    "sortBy": "week_start",
    "sortDir": "desc"
  },
  "data": [
    {
      "id": "wg_2025_11_24_a1b2c3",
      "title": "Treino de base",
      "ownerId": "usr_78***90",
      "target_km": 30.0,
      "progress_percent": 40.0,
      "week_start": "2025-11-24",
      "week_end": "2025-11-30",
      "status": "active",
      "createdAt": "2025-11-20T09:00:00Z",
      "updatedAt": "2025-11-25T18:00:00Z"
    }
  ]
}
```

Critérios de aceitação
---
Modo: especificação
1. O agente descreve claramente quais inputs aceita e como eles afetam a listagem.
2. Fornece o formato de saída (meta + data) e um exemplo JSON válido e mascarado quando aplicável.
3. Informa restrições (pageSize máximo, ordenação padrão) e considerações sobre permissões e privacidade.

Modo: implementar_widget
1. O agente gera um widget Flutter/Dart que implementa a página de listagem com comportamento compatível com `weekly_goals_page.dart` (loading, list, image handling).
2. O widget integra com o DAO local da feature — identifica o DAO existente, importa e usa os métodos padrão (ex.: `listAll`, `upsertAll`, `clear`) ou adapta conforme encontrado.
3. Operações de persistência são envolvidas em `try/catch` e o UX apresenta `SnackBar`s de sucesso/erro. O código respeita nomes/pastas do projeto.
4. Ao finalizar, o agente fornece instruções de teste manual (passos rápidos) e um breve resumo das alterações/arquivos propostos.

Notas adicionais para o agente
---
- Explique brevemente alternativas de paginação (offset/limit vs cursor-based) e recomende cursor-based para grandes volumes de dados.
- Sugira campos opcionais que podem ser incluídos se solicitado (ex.: target_elevation_gain, tags) e como isso impacta performance.
- Indique tratamentos de erro/validação (por exemplo: page inválida => retornar página 1, pageSize fora do intervalo => truncar para limites permitidos).

Geração de código e limitações
---
Quando o modo for `implementar_widget`, o agente pode gerar código Dart/Flutter que modifica ou cria arquivos dentro de `lib/features/{FEATURE_FOLDER}/presentation` e `lib/features/{FEATURE_FOLDER}/infrastructure` (se necessário). Sempre:

- prefira reutilizar componentes existentes quando detectados no repositório;
- adicione apenas os arquivos mínimos necessários (ex.: `weekly_goals_page.dart`, `weekly_goal_list_widget.dart`, `weekly_goal_list_item.dart`) e siga as convenções de nomes e pastas;
- não faça alterações em arquivos não relacionados sem justificativa.

Se não houver DAO detectada automaticamente, o agente deve instruir o desenvolvedor sobre a API esperada do DAO (métodos: `listAll`, `upsertAll`, `clear`) e fornecer um stub simples comentado para implementação posterior.

Resumo
---
Este prompt agora está parametrizável e suporta dois modos: gerar especificação (JSON/contract) ou gerar implementação Flutter/Dart de uma página de listagem compatível com `weekly_goals_page.dart`. Configure os tokens no topo (`ENTITY_SINGULAR`, `DTO_CLASS`, `FEATURE_FOLDER`, `DAO_CLASS_HINT`, etc.) antes de executar o prompt com o agente.
