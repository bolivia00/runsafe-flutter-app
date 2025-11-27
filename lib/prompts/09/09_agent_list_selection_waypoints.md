# Prompt: Implementar seleção de Waypoint com diálogo de ações

## Objetivo
---
Adicionar um fluxo de seleção de waypoint que, ao fazer long-press em um item, exibe um diálogo com ações: Editar, Remover, Fechar.

## Resumo do comportamento
---
- O diálogo de seleção contém três ações: Editar (abre o formulário de edição de waypoint), Remover (abre confirmação de remoção) e Fechar (fecha o diálogo).
- A ação Editar deve delegar ao handler de edição do waypoint.
- A ação Remover deve abrir `AlertDialog` de confirmação e remover o waypoint via `WaypointsLocalDaoSharedPrefs`.
- O código deste prompt deve apenas adicionar o diálogo e as rotas de delegação — a lógica fina de edição/removal permanece nos prompts especializados.

## Integração e convenções
---
- Criar o diálogo em `lib/widgets/waypoint_actions_dialog.dart` como helper reutilizável.
- Não implemente diretamente a persistência aqui — invoque os helpers já existentes ou as funções de callback fornecidas pelo widget de listagem.
- Labels e textos em português.
- **Importante**: o diálogo de ações deve ser não-dismissable ao tocar fora. Use `showDialog(..., barrierDismissible: false)` para garantir que apenas os botões internos possam fechá-lo.

## Critérios de aceitação
---
1. Long-press em um item da lista exibe um diálogo com as três opções (Editar, Remover, Fechar).
2. Cada opção delega corretamente:
   - **Editar**: abre o formulário/tela de edição do waypoint
   - **Remover**: abre AlertDialog de confirmação; ao confirmar, remove da DAO e atualiza a listagem
   - **Fechar**: fecha o diálogo sem ações
3. O diálogo é não-dismissable (apenas botões fecham).
4. O waypoint selecionado (latitude, longitude, timestamp) é exibido no título/corpo do diálogo.

## Exemplo de fluxo
---
```
Usuário faz long-press em "Ponto: -16.5023, -68.1193" 
  ↓
Exibe diálogo: 
  - Título: "Waypoint"
  - Corpo: "Lat: -16.5023 | Lon: -68.1193 | Criado: 27/11/2025 14:30"
  - Botão "Editar" → abre formulário para editar
  - Botão "Remover" → abre confirmação
  - Botão "Fechar" → fecha sem ações
```

## Integração com WaypointListWidget
---
- Modificar `WaypointListItem` para aceitar `onLongPress` callback.
- Passar o callback do diálogo de ações para o item.
- O diálogo deve acessar `WaypointsLocalDaoSharedPrefs` para remover e atualizar estado.
