# Prompt: Implementar edição de Waypoint (ícone lápis)

## Objetivo
---
Gerar código Flutter/Dart que adicione a funcionalidade de edição a itens da listagem de waypoints.

## Resumo do comportamento esperado
---
- Cada item da lista (renderizado em `WaypointListItem`) deverá exibir um ícone de lápis (edit) como trailing widget.
- Ao tocar no ícone de lápis, abrir um formulário em diálogo (`AlertDialog`) preenchido com os dados atuais do waypoint (latitude, longitude).
- O formulário deve permitir editar campos seguindo os campos do DTO (`WaypointDto`).
- Ao confirmar, chamar `WaypointsLocalDaoSharedPrefs.upsertAll()` para persistir a alteração dentro de `try/catch`.
- Exibir `SnackBar` de sucesso ou erro conforme o resultado.
- Não implementar remoção nem swipe neste prompt; apenas edição.

## Integração e convenções
---
- Local de criação/edição: `lib/widgets/waypoint_edit_dialog.dart` ou integrado direto em `WaypointListItem`.
- Nomes e labels em português.
- Código deve seguir o padrão do repositório: tratamento de erros com `try/catch`, feedback via `SnackBar`.
- **Importante**: o diálogo de edição não deve ser fechado ao tocar fora. Use `showDialog(..., barrierDismissible: false)` para garantir que apenas os botões fechem o diálogo.

## Exemplo de API esperada do DAO
---
```dart
Future<void> upsertAll(List<WaypointDto> dtos)
```

## Critérios de aceitação
---
1. O ícone de edição aparece em cada item (trailing icon na `ListTile`).
2. Tocar no ícone abre o formulário pré-preenchido com latitude e longitude do waypoint.
3. Ao salvar, os dados são persistidos via `WaypointsLocalDaoSharedPrefs.upsertAll()` e o usuário vê um `SnackBar` de confirmação.
4. Validação de entrada (latitude -90 a 90, longitude -180 a 180).
5. Tratamento de erros com feedback ao usuário.
6. O código não altera o widget de listagem para adicionar remoção por swipe.

## Exemplo de fluxo
---
```
Usuário toca no ícone edit de "Ponto: -16.5023, -68.1193"
  ↓
Abre diálogo com formulário pré-preenchido:
  - Campo: Latitude (text input numérico -90 a 90)
  - Campo: Longitude (text input numérico -180 a 180)
  - Campo: Timestamp (display apenas, read-only)
  - Botão: Salvar
  - Botão: Cancelar
  ↓
Usuário edita coordenadas
  ↓
DAO persiste alteração
  ↓
SnackBar: "Waypoint atualizado com sucesso"
  ↓
Diálogo fecha e lista recarrega
```

## Campos do formulário
---
- **Latitude**: TextField obrigatório, numérico, intervalo -90.0 a 90.0, 6 casas decimais
- **Longitude**: TextField obrigatório, numérico, intervalo -180.0 a 180.0, 6 casas decimais
- **Timestamp**: Display apenas (read-only), formato dd/mm/yyyy hh:mm:ss, não editável

## Validações
---
- Latitude e Longitude devem ser números válidos
- Latitude entre -90 e 90
- Longitude entre -180 e 180
- Ambos campos obrigatórios
