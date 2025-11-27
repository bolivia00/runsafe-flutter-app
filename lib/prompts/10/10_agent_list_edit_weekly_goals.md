# Prompt: Implementar edição de Weekly Goal (ícone lápis)

## Objetivo
---
Gerar código Flutter/Dart que adicione a funcionalidade de edição a itens da listagem de weekly goals.

## Resumo do comportamento esperado
---
- Cada item da lista (renderizado em `WeeklyGoalListItem`) deverá exibir um ícone de lápis (edit) como trailing widget.
- Ao tocar no ícone de lápis, abrir um formulário em diálogo (`AlertDialog`) preenchido com os dados atuais da meta (distância alvo, progresso atual).
- O formulário deve permitir editar campos seguindo os campos do DTO (`WeeklyGoalDto`).
- Ao confirmar, chamar `WeeklyGoalsLocalDaoSharedPrefs.upsertAll()` para persistir a alteração dentro de `try/catch`.
- Exibir `SnackBar` de sucesso ou erro conforme o resultado.
- Não implementar remoção nem swipe neste prompt; apenas edição.

## Integração e convenções
---
- Local de criação/edição: `lib/widgets/weekly_goal_edit_dialog.dart` ou integrado direto em `WeeklyGoalListItem`.
- Nomes e labels em português.
- Código deve seguir o padrão do repositório: tratamento de erros com `try/catch`, feedback via `SnackBar`.
- **Importante**: o diálogo de edição não deve ser fechado ao tocar fora. Use `showDialog(..., barrierDismissible: false)` para garantir que apenas os botões fechem o diálogo.

## Exemplo de API esperada do DAO
---
```dart
Future<void> upsertAll(List<WeeklyGoalDto> dtos)
```

## Critérios de aceitação
---
1. O ícone de edição aparece em cada item (trailing icon na `ListTile`).
2. Tocar no ícone abre o formulário pré-preenchido com distância alvo e progresso atual da meta.
3. Ao salvar, os dados são persistidos via `WeeklyGoalsLocalDaoSharedPrefs.upsertAll()` e o usuário vê um `SnackBar` de confirmação.
4. Validação de entrada (distância alvo > 0, progresso >= 0, progresso <= alvo).
5. Tratamento de erros com feedback ao usuário.
6. O código não altera o widget de listagem para adicionar remoção por swipe.

## Exemplo de fluxo
---
```
Usuário toca no ícone edit de "Meta: 50.00 km (75%)"
  ↓
Abre diálogo com formulário pré-preenchido:
  - Campo: Distância Alvo (text input numérico > 0)
  - Campo: Progresso Atual (text input numérico >= 0)
  - Campo: Progresso % (display apenas, calculado automaticamente)
  - Botão: Salvar
  - Botão: Cancelar
  ↓
Usuário edita distância alvo e/ou progresso
  ↓
DAO persiste alteração
  ↓
SnackBar: "Meta atualizada com sucesso"
  ↓
Diálogo fecha e lista recarrega
```

## Campos do formulário
---
- **Distância Alvo (km)**: TextField obrigatório, numérico (decimal), > 0, máximo 999.99 km, 2 casas decimais
- **Progresso Atual (km)**: TextField obrigatório, numérico (decimal), >= 0, máximo = distância alvo, 2 casas decimais
- **Progresso (%)**: Display apenas (calculado), formato X.X%, não editável

## Validações
---
- Target_km deve ser maior que zero
- Current_progress_km não pode ser negativo
- Current_progress_km não pode ser maior que target_km
- Ambos campos obrigatórios
- Valores devem ser numéricos válidos com até 2 casas decimais
