# Guia de Configuração do Supabase - RunSafe App

## 📋 Índice
1. [Criar Projeto](#1-criar-projeto)
2. [Obter Credenciais](#2-obter-credenciais)
3. [Criar Tabelas](#3-criar-tabelas)
4. [Configurar RLS](#4-configurar-rls)
5. [Testar Conexão](#5-testar-conexão)

---

## 1. Criar Projeto

### 1.1 Acesse o Dashboard
1. Vá para: https://supabase.com/dashboard
2. Clique em **"New Project"**

### 1.2 Configure o Projeto
- **Name**: `runsafe-app` (ou o nome que preferir)
- **Database Password**: Escolha uma senha forte (anote!)
- **Region**: Selecione a região mais próxima (ex: `South America (São Paulo)`)
- **Pricing Plan**: Free (suficiente para desenvolvimento)

### 1.3 Aguarde Provisionamento
- O Supabase levará ~2 minutos para criar o banco de dados
- Aguarde até ver "Project is ready"

---

## 2. Obter Credenciais

### 2.1 Acesse Project Settings
1. No dashboard do projeto, clique no ícone ⚙️ (Settings) na barra lateral
2. Vá em **"API"** no menu lateral

### 2.2 Copie as Credenciais
Você precisará de:

**Project URL:**
```
https://[seu-project-id].supabase.co
```

**anon/public key (API Key):**
```
eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9... (chave longa)
```

⚠️ **Importante**: 
- A `anon key` é segura para usar no app (público)
- NÃO compartilhe a `service_role key` (apenas para backend)

---

## 3. Criar Tabelas

### 3.1 Acesse o SQL Editor
1. No dashboard, clique em **SQL Editor** na barra lateral (ícone </> )
2. Clique em **"New Query"**

### 3.2 Execute o Script de Criação

Cole o script SQL completo abaixo e clique em **"Run"**:

```sql
-- ============================================
-- RunSafe App - Schema Completo
-- ============================================

-- 1. Função para atualizar updated_at automaticamente
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- 2. TABELA: running_routes
-- ============================================
CREATE TABLE running_routes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  waypoints JSONB NOT NULL DEFAULT '[]'::jsonb,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  
  CONSTRAINT waypoints_is_array CHECK (jsonb_typeof(waypoints) = 'array')
);

-- Índices
CREATE INDEX idx_running_routes_updated_at ON running_routes (updated_at DESC);
CREATE INDEX idx_running_routes_name ON running_routes (name);

-- Trigger
CREATE TRIGGER set_running_routes_updated_at
  BEFORE UPDATE ON running_routes
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- Comentários
COMMENT ON TABLE running_routes IS 'Rotas de corrida com lista de waypoints (coordenadas + timestamp)';
COMMENT ON COLUMN running_routes.waypoints IS 'Array JSONB de waypoints: [{lat, lon, ts}, ...]';

-- ============================================
-- 3. TABELA: safety_alerts
-- ============================================
CREATE TABLE safety_alerts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  description TEXT NOT NULL,
  type TEXT NOT NULL CHECK (type IN ('pothole', 'no_lighting', 'suspicious_activity', 'other')),
  severity INTEGER NOT NULL CHECK (severity BETWEEN 1 AND 5),
  timestamp TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Índices
CREATE INDEX idx_safety_alerts_updated_at ON safety_alerts (updated_at DESC);
CREATE INDEX idx_safety_alerts_severity ON safety_alerts (severity DESC);
CREATE INDEX idx_safety_alerts_type ON safety_alerts (type);

-- Trigger
CREATE TRIGGER set_safety_alerts_updated_at
  BEFORE UPDATE ON safety_alerts
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- Comentários
COMMENT ON TABLE safety_alerts IS 'Alertas de segurança reportados por usuários';
COMMENT ON COLUMN safety_alerts.type IS 'Tipo: pothole, no_lighting, suspicious_activity, other';
COMMENT ON COLUMN safety_alerts.severity IS 'Severidade de 1 (baixa) a 5 (crítica)';

-- ============================================
-- 4. TABELA: waypoints
-- ============================================
CREATE TABLE waypoints (
  latitude DOUBLE PRECISION NOT NULL,
  longitude DOUBLE PRECISION NOT NULL,
  timestamp TIMESTAMPTZ PRIMARY KEY,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  
  CONSTRAINT valid_latitude CHECK (latitude BETWEEN -90 AND 90),
  CONSTRAINT valid_longitude CHECK (longitude BETWEEN -180 AND 180)
);

-- Índices
CREATE INDEX idx_waypoints_timestamp ON waypoints (timestamp DESC);
CREATE INDEX idx_waypoints_updated_at ON waypoints (updated_at DESC);

-- Trigger
CREATE TRIGGER set_waypoints_updated_at
  BEFORE UPDATE ON waypoints
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- Comentários
COMMENT ON TABLE waypoints IS 'Pontos de localização individuais (timestamp como PK)';
COMMENT ON COLUMN waypoints.timestamp IS 'Timestamp como chave primária única';

-- ============================================
-- 5. TABELA: weekly_goals
-- ============================================
CREATE TABLE weekly_goals (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id TEXT NOT NULL,
  target_km DOUBLE PRECISION NOT NULL CHECK (target_km > 0),
  current_km DOUBLE PRECISION NOT NULL DEFAULT 0 CHECK (current_km >= 0),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Índices
CREATE INDEX idx_weekly_goals_user_id ON weekly_goals (user_id);
CREATE INDEX idx_weekly_goals_updated_at ON weekly_goals (updated_at DESC);

-- Trigger
CREATE TRIGGER set_weekly_goals_updated_at
  BEFORE UPDATE ON weekly_goals
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- Comentários
COMMENT ON TABLE weekly_goals IS 'Metas semanais de corrida por usuário';
COMMENT ON COLUMN weekly_goals.user_id IS 'Identificador do usuário (suporta multi-tenant)';
COMMENT ON COLUMN weekly_goals.current_km IS 'Quilometragem acumulada na semana';

-- ============================================
-- 6. Row Level Security (RLS) - Configuração Inicial
-- ============================================

-- Habilita RLS em todas as tabelas
ALTER TABLE running_routes ENABLE ROW LEVEL SECURITY;
ALTER TABLE safety_alerts ENABLE ROW LEVEL SECURITY;
ALTER TABLE waypoints ENABLE ROW LEVEL SECURITY;
ALTER TABLE weekly_goals ENABLE ROW LEVEL SECURITY;

-- Políticas permissivas para desenvolvimento (público)
-- ⚠️ NOTA: Em produção, você deve restringir por auth.uid()

-- running_routes: acesso público
CREATE POLICY "Public access to running_routes"
  ON running_routes
  FOR ALL
  USING (true)
  WITH CHECK (true);

-- safety_alerts: acesso público
CREATE POLICY "Public access to safety_alerts"
  ON safety_alerts
  FOR ALL
  USING (true)
  WITH CHECK (true);

-- waypoints: acesso público
CREATE POLICY "Public access to waypoints"
  ON waypoints
  FOR ALL
  USING (true)
  WITH CHECK (true);

-- weekly_goals: filtrado por user_id (mas ainda público para desenvolvimento)
CREATE POLICY "Users access their own goals"
  ON weekly_goals
  FOR ALL
  USING (true)  -- Temporariamente permissivo
  WITH CHECK (true);

-- ============================================
-- 7. Dados de Teste (Opcional)
-- ============================================

-- Inserir rota de exemplo
INSERT INTO running_routes (id, name, waypoints) VALUES
(
  '123e4567-e89b-12d3-a456-426614174000',
  'Rota Teste - Parque',
  '[
    {"lat": -23.550520, "lon": -46.633308, "ts": "2025-12-01T08:00:00.000Z"},
    {"lat": -23.551234, "lon": -46.634567, "ts": "2025-12-01T08:05:00.000Z"},
    {"lat": -23.552345, "lon": -46.635678, "ts": "2025-12-01T08:10:00.000Z"}
  ]'::jsonb
);

-- Inserir alertas de exemplo
INSERT INTO safety_alerts (description, type, severity) VALUES
('Buraco grande na pista', 'pothole', 4),
('Iluminação fraca nesta área', 'no_lighting', 3),
('Movimento suspeito reportado', 'suspicious_activity', 5);

-- Inserir waypoints de exemplo
INSERT INTO waypoints (latitude, longitude, timestamp) VALUES
(-23.550520, -46.633308, '2025-12-01T08:00:00.000Z'),
(-23.551234, -46.634567, '2025-12-01T08:05:00.000Z'),
(-23.552345, -46.635678, '2025-12-01T08:10:00.000Z');

-- Inserir meta semanal de exemplo
INSERT INTO weekly_goals (user_id, target_km, current_km) VALUES
('default-user', 20.0, 5.5),
('default-user', 30.0, 12.3);

-- ============================================
-- 8. Verificação
-- ============================================

-- Contar registros por tabela
SELECT 'running_routes' as table_name, COUNT(*) as count FROM running_routes
UNION ALL
SELECT 'safety_alerts', COUNT(*) FROM safety_alerts
UNION ALL
SELECT 'waypoints', COUNT(*) FROM waypoints
UNION ALL
SELECT 'weekly_goals', COUNT(*) FROM weekly_goals;

-- Verificar triggers
SELECT 
  trigger_name,
  event_object_table as table_name,
  action_timing as timing,
  event_manipulation as event
FROM information_schema.triggers
WHERE trigger_schema = 'public'
ORDER BY event_object_table, trigger_name;

```

### 3.3 Verifique a Criação
Após executar, você deve ver:
- ✅ 4 tabelas criadas
- ✅ 4 triggers de `updated_at`
- ✅ Políticas RLS ativas
- ✅ Dados de teste inseridos

---

## 4. Configurar RLS (Row Level Security)

### 4.1 Verificar Políticas
No SQL Editor, execute:

```sql
-- Listar todas as políticas RLS
SELECT 
  schemaname,
  tablename,
  policyname,
  permissive,
  roles,
  cmd,
  qual,
  with_check
FROM pg_policies
WHERE schemaname = 'public'
ORDER BY tablename, policyname;
```

### 4.2 Políticas Atuais (Desenvolvimento)
Todas as tabelas têm acesso público para facilitar o desenvolvimento:

- ✅ `running_routes`: Acesso total público
- ✅ `safety_alerts`: Acesso total público
- ✅ `waypoints`: Acesso total público
- ✅ `weekly_goals`: Acesso total público (mas com suporte a `user_id`)

### 4.3 Produção (Futuro)
Quando implementar autenticação, atualize as políticas:

```sql
-- Exemplo: restringir weekly_goals por usuário autenticado
DROP POLICY IF EXISTS "Users access their own goals" ON weekly_goals;

CREATE POLICY "Authenticated users access their own goals"
  ON weekly_goals
  FOR ALL
  USING (auth.uid()::text = user_id)
  WITH CHECK (auth.uid()::text = user_id);
```

---

## 5. Testar Conexão

### 5.1 Configurar App Flutter

Crie o arquivo `.env` na raiz do projeto:

```env
# Supabase Configuration
SUPABASE_URL=https://[seu-project-id].supabase.co
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

### 5.2 Atualizar main.dart

O código já está pronto, mas verifique se as credenciais estão corretas:

```dart
await Supabase.initialize(
  url: 'SUA_URL_AQUI',
  anonKey: 'SUA_ANON_KEY_AQUI',
);
```

### 5.3 Testar no App

Execute o app:
```bash
flutter run
```

Nos logs, você deve ver:
```
[RunningRoutesProvider] Carregando do cache...
[RunningRoutesProvider] Iniciando sync bidirecional...
[RunningRoutesRepositoryImplRemote] Iniciando PUSH de rotas locais...
[SupabaseRunningRoutesRemoteDatasource] Fetched X rotas
```

---

## 6. Monitoramento

### 6.1 Table Editor
1. Vá em **Table Editor** no dashboard
2. Visualize dados em tempo real de cada tabela
3. Adicione/edite/remova registros manualmente

### 6.2 Database
1. Vá em **Database** → **Tables**
2. Visualize estrutura, índices, constraints
3. Execute queries SQL customizadas

### 6.3 Logs
1. Vá em **Logs** → **Postgres Logs**
2. Monitore queries e erros em tempo real

---

## 7. Troubleshooting

### Problema: "relation does not exist"
**Causa**: Tabela não foi criada
**Solução**: Execute o script SQL novamente

### Problema: "new row violates row-level security policy"
**Causa**: RLS bloqueando inserção
**Solução**: Verifique políticas ou desabilite RLS temporariamente

### Problema: "could not connect to server"
**Causa**: URL ou anon key incorretos
**Solução**: Verifique credenciais no Project Settings → API

### Problema: "column 'updated_at' does not exist"
**Causa**: Trigger não foi criado
**Solução**: Execute a função `update_updated_at_column()` e os triggers

---

## 8. Próximos Passos

✅ **Concluído**:
- Projeto criado
- Tabelas criadas
- RLS configurado
- App conectado

🔜 **Opcional**:
- [ ] Configurar autenticação (Email/Password, Google, etc.)
- [ ] Adicionar Storage para imagens/avatars
- [ ] Configurar Realtime para atualizações ao vivo
- [ ] Implementar Edge Functions para lógica backend
- [ ] Configurar backups automáticos

---

## 📚 Recursos

- [Documentação Supabase](https://supabase.com/docs)
- [Supabase + Flutter](https://supabase.com/docs/guides/getting-started/tutorials/with-flutter)
- [Row Level Security](https://supabase.com/docs/guides/auth/row-level-security)
- [SQL Editor](https://supabase.com/docs/guides/database/overview)

---

**Data de criação**: 2025-12-01
**Status**: ✅ Pronto para uso
