# Prompt: Implementar edição de Safety Alert (ícone lápis)

## Objetivo
---
Gerar código Flutter/Dart que adicione a funcionalidade de edição a itens da listagem de safety alerts.

## Resumo do comportamento esperado
---
- Cada item da lista (renderizado em `SafetyAlertListItem`) deverá exibir um ícone de lápis (edit) como trailing widget.
- Ao tocar no ícone de lápis, abrir um formulário em diálogo (`AlertDialog`) preenchido com os dados atuais do alerta (tipo, severidade, descrição).
- O formulário deve permitir editar campos seguindo os campos do DTO (`SafetyAlertDto`).
- Ao confirmar, chamar `SafetyAlertsLocalDaoSharedPrefs.upsertAll()` para persistir a alteração dentro de `try/catch`.
- Exibir `SnackBar` de sucesso ou erro conforme o resultado.
- Não implementar remoção nem swipe neste prompt; apenas edição.

## Integração e convenções
---
- Local de criação/edição: `lib/widgets/safety_alert_edit_dialog.dart` ou integrado direto em `SafetyAlertListItem`.
- Nomes e labels em português.
- Código deve seguir o padrão do repositório: tratamento de erros com `try/catch`, feedback via `SnackBar`.
- **Importante**: o diálogo de edição não deve ser fechado ao tocar fora. Use `showDialog(..., barrierDismissible: false)` para garantir que apenas os botões fechem o diálogo.

## Exemplo de API esperada do DAO
---
```dart
Future<void> upsertAll(List<SafetyAlertDto> dtos)
```

## Critérios de aceitação
---
1. O ícone de edição aparece em cada item (trailing icon na `ListTile`).
2. Tocar no ícone abre o formulário pré-preenchido com tipo, severidade e descrição do alerta.
3. Ao salvar, os dados são persistidos via `SafetyAlertsLocalDaoSharedPrefs.upsertAll()` e o usuário vê um `SnackBar` de confirmação.
4. Validação de entrada (descrição não vazia, severidade entre 1-5).
5. Tratamento de erros com feedback ao usuário.
6. O código não altera o widget de listagem para adicionar remoção por swipe.

## Exemplo de fluxo
---
```
Usuário toca no ícone edit de "Alerta: Queda (Severidade 5)"
  ↓
Abre diálogo com formulário pré-preenchido:
  - Campo: Tipo (dropdown: Buraco, Falta iluminação, Atividade suspeita, Outro)
  - Campo: Severidade (slider 1-5 ou dropdown)
  - Campo: Descrição (text area)
  - Botão: Salvar
  - Botão: Cancelar
  ↓
Usuário edita descrição e muda severidade
  ↓
DAO persiste alteração
  ↓
SnackBar: "Alerta atualizado com sucesso"
  ↓
Diálogo fecha e lista recarrega
```

## Campos do formulário
---
- **Tipo**: Dropdown obrigatório (pothole, noLighting, suspiciousActivity, other)
- **Severidade**: Slider ou Dropdown obrigatório (1-5)
- **Descrição**: TextArea obrigatória, máximo 500 caracteres
- **Timestamp**: Display apenas (read-only), não editável
