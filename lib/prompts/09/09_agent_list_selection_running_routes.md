# Prompt: Implementar seleção de Running Route com diálogo de ações

## Objetivo
---
Adicionar um fluxo de seleção de running route que, ao fazer long-press em um item, exibe um diálogo com ações: Editar, Remover, Fechar.

## Resumo do comportamento
---
- O diálogo de seleção contém três ações: Editar (abre o formulário de edição de rota), Remover (abre confirmação de remoção) e Fechar (fecha o diálogo).
- A ação Editar deve delegar ao handler de edição da running route.
- A ação Remover deve abrir `AlertDialog` de confirmação e remover a rota via `RunningRoutesLocalDaoSharedPrefs`.
- O código deste prompt deve apenas adicionar o diálogo e as rotas de delegação — a lógica fina de edição/removal permanece nos prompts especializados.

## Integração e convenções
---
- Criar o diálogo em `lib/widgets/running_route_actions_dialog.dart` como helper reutilizável.
- Não implemente diretamente a persistência aqui — invoque os helpers já existentes ou as funções de callback fornecidas pelo widget de listagem.
- Labels e textos em português.
- **Importante**: o diálogo de ações deve ser não-dismissable ao tocar fora. Use `showDialog(..., barrierDismissible: false)` para garantir que apenas os botões internos possam fechá-lo.

## Critérios de aceitação
---
1. Long-press em um item da lista exibe um diálogo com as três opções (Editar, Remover, Fechar).
2. Cada opção delega corretamente:
   - **Editar**: abre o formulário/tela de edição da running route
   - **Remover**: abre AlertDialog de confirmação; ao confirmar, remove da DAO e atualiza a listagem
   - **Fechar**: fecha o diálogo sem ações
3. O diálogo é não-dismissable (apenas botões fecham).
4. A running route selecionada (nome, waypoints_count, distância) é exibida no título do diálogo.

## Exemplo de fluxo
---
```
Usuário faz long-press em "Rota A (5 pontos)" 
  ↓
Exibe diálogo: 
  - Título: "Rota A (5 pontos)"
  - Botão "Editar" → abre formulário para editar
  - Botão "Remover" → abre confirmação
  - Botão "Fechar" → fecha sem ações
```

## Integração com RunningRouteListWidget
---
- Modificar `RunningRouteListItem` para aceitar `onLongPress` callback.
- Passar o callback do diálogo de ações para o item.
- O diálogo deve acessar `RunningRoutesLocalDaoSharedPrefs` para remover e atualizar estado.
