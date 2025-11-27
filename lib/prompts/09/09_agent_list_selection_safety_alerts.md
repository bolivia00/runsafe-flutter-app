# Prompt: Implementar seleção de Safety Alert com diálogo de ações

## Objetivo
---
Adicionar um fluxo de seleção de safety alert que, ao fazer long-press em um item, exibe um diálogo com ações: Editar, Remover, Fechar.

## Resumo do comportamento
---
- O diálogo de seleção contém três ações: Editar (abre o formulário de edição de alerta), Remover (abre confirmação de remoção) e Fechar (fecha o diálogo).
- A ação Editar deve delegar ao handler de edição do safety alert.
- A ação Remover deve abrir `AlertDialog` de confirmação e remover o alerta via `SafetyAlertsLocalDaoSharedPrefs`.
- O código deste prompt deve apenas adicionar o diálogo e as rotas de delegação — a lógica fina de edição/removal permanece nos prompts especializados.

## Integração e convenções
---
- Criar o diálogo em `lib/widgets/safety_alert_actions_dialog.dart` como helper reutilizável.
- Não implemente diretamente a persistência aqui — invoque os helpers já existentes ou as funções de callback fornecidas pelo widget de listagem.
- Labels e textos em português.
- **Importante**: o diálogo de ações deve ser não-dismissable ao tocar fora. Use `showDialog(..., barrierDismissible: false)` para garantir que apenas os botões internos possam fechá-lo.

## Critérios de aceitação
---
1. Long-press em um item da lista exibe um diálogo com as três opções (Editar, Remover, Fechar).
2. Cada opção delega corretamente:
   - **Editar**: abre o formulário/tela de edição do safety alert
   - **Remover**: abre AlertDialog de confirmação; ao confirmar, remove da DAO e atualiza a listagem
   - **Fechar**: fecha o diálogo sem ações
3. O diálogo é não-dismissable (apenas botões fecham).
4. O safety alert selecionado (tipo, severidade, descrição) é exibido no título/corpo do diálogo.

## Exemplo de fluxo
---
```
Usuário faz long-press em "Alerta: Queda (Severidade 5)" 
  ↓
Exibe diálogo: 
  - Título: "Alerta de Segurança"
  - Corpo: "Tipo: Queda | Severidade: 5 (Crítica)"
  - Botão "Editar" → abre formulário para editar
  - Botão "Remover" → abre confirmação
  - Botão "Fechar" → fecha sem ações
```

## Integração com SafetyAlertListWidget
---
- Modificar `SafetyAlertListItem` para aceitar `onLongPress` callback.
- Passar o callback do diálogo de ações para o item.
- O diálogo deve acessar `SafetyAlertsLocalDaoSharedPrefs` para remover e atualizar estado.
