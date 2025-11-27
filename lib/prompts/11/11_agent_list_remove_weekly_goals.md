# Prompt: Implementar remoção por swipe de Weekly Goal (Dismissible)

## Objetivo
---
Adicionar a funcionalidade de remoção de weekly goals via swipe-to-dismiss na listagem.

## Resumo do comportamento
---
- Envolver cada item da lista em um `Dismissible` com direção `DismissDirection.endToStart`.
- Ao detectar o gesto, chamar `confirmDismiss` que abre um `AlertDialog` de confirmação ("Remover meta de '{targetKm}' km? Sim / Não").
- Se o usuário confirmar, chamar o DAO para remover a meta (`WeeklyGoalsLocalDaoSharedPrefs.remove(id)` ou equivalente) dentro de `try/catch`.
- Em caso de sucesso, exibir `SnackBar` confirmando remoção; em caso de erro, reverter UI e exibir `SnackBar` de erro.
- Manter a listagem principal (arquivo listing-only) sem lógica de remoção — este prompt entrega apenas o patch que adiciona a camada `Dismissible` e a integração com o DAO.

## Integração e convenções
---
- Implementar em `lib/widgets/weekly_goal_list_item.dart` (já envolvido em Dismissible) ou alterar `WeeklyGoalListWidget`.
- Não criar novos repositórios; use `WeeklyGoalsLocalDaoSharedPrefs` existente.
- Garantir acessibilidade e animação suave (usando `background` e `secondaryBackground` do `Dismissible`).
- **Importante**: o diálogo de confirmação deve ser não-dismissable ao tocar fora. Use `showDialog(..., barrierDismissible: false)` para evitar remoções acidentais — o usuário só deve poder confirmar/cancelar pelos botões.

## Critérios de aceitação
---
1. Swipe para esquerda em item da lista exibe background vermelho com ícone de trash.
2. Ao completar o swipe ou tocar no background, abre `AlertDialog` de confirmação: "Remover meta de '{targetKm}' km? Esta ação não pode ser desfeita."
3. Ao confirmar, a meta é removida via DAO e exibe `SnackBar` de sucesso: "Meta removida com sucesso".
4. Se falhar, reverte o swipe e exibe `SnackBar` de erro: "Erro ao remover meta".
5. Não introduz comportamento de edição ou seleção — somente remoção.
6. Diálogo é não-dismissable (apenas botões fecham).

## Exemplo de fluxo
---
```
Usuário faz swipe para esquerda em "Meta: 50.00 km (75%)"
  ↓
Background vermelho aparece com ícone de trash
  ↓
Usuário libera o gesto ou toca no background
  ↓
Abre AlertDialog de confirmação:
  - Título: "Confirmar remoção"
  - Mensagem: "Remover meta de '50.00' km? Esta ação não pode ser desfeita."
  - Botão: Cancelar
  - Botão: Remover (vermelho)
  ↓
Usuário confirma
  ↓
DAO remove a meta
  ↓
SnackBar: "Meta removida com sucesso"
  ↓
Item desaparece da lista com animação
```

## Implementação técnica
---
- Usar `Dismissible` com `key: ValueKey(goal.id)`
- `direction: DismissDirection.endToStart` (swipe da direita para esquerda)
- `background`: Container vermelho com ícone de trash
- `onDismissed`: Callback quando diálogo confirma
- `confirmDismiss`: Future que retorna `true` (remover) ou `false` (manter)
- Dentro de `confirmDismiss`, chamar DAO para remover
- Tratar erros com try/catch e exibir SnackBar apropriada

## Campos do diálogo de confirmação
---
- **Título**: "Confirmar remoção"
- **Mensagem**: "Remover meta de '{targetKm}' km? Esta ação não pode ser desfeita."
- **Exemplo de mensagem**: "Remover meta de '50.00' km? Esta ação não pode ser desfeita."
- **Formato de distância**: 2 casas decimais (X.XX km)
- **Botão Cancelar**: Retorna `false` (Dismissible não remove)
- **Botão Remover**: Retorna `true`, DAO remove e exibe SnackBar
