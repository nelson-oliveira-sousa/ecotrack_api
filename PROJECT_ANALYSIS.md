# Análise Completa do Projeto `ecotrack_api`

## 1) Resumo executivo
O `ecotrack_api` é uma API Rails (8.x) para gestão de resíduos com multi-tenant, IoT (MQTT), frota, roteirização assistida por IA e alertas operacionais. A base está bem estruturada por domínio, porém ainda há espaço para padronização transversal (especialmente **status**) e robustez operacional.

## 2) Stack técnica
- Rails `~> 8.1.3`
- PostgreSQL (`pg`)
- Jobs/cache/cable: `solid_queue`, `solid_cache`, `solid_cable`
- Segurança: `bcrypt`, `jwt`, `rack-attack`, `rack-cors`
- Integrações: `mqtt`, `faraday`
- Contratos: `dry-validation`

## 3) Arquitetura e domínios
- **API**: `app/controllers/api/v1/*`.
- **Domínios**: `identity`, `telemetry`, `waste`, `fleet`, `alerts`, `dashboard` em `app/domains/*`.
- **Modelos centrais**: `Tenant`, `User`, `Waste::Bin`, `Waste::Reading`, `Fleet::Truck`, `Fleet::Route`, `Alert`, `MqttMessage`.
- **Assíncrono**: jobs em `app/jobs/*` para processamento IoT/IA/rotas.

## 4) Fluxos críticos de negócio
1. Login/logout/me com JWT e contexto de tenant.
2. Ingestão de telemetria por sensor/MQTT.
3. Análise de bins por IA para predição de lotação.
4. Geração de rotas para caminhões com fallback.
5. Emissão de alertas/atualizações em tempo real.

## 5) Achados técnicos relevantes
1. Em `Telemetry::Services::ProcessMessage`, há risco de erro por chamada de utilitário em módulo (`mount_reading_data`) sem padronização explícita de método de classe.
2. No mesmo fluxo, existe chave `batery`, potencial inconsistente com o domínio (`battery`).
3. Forte dependência de IA na roteirização, mesmo com fallback.
4. README atual não cobre onboarding completo.

## 6) Padronização de status (solicitado)
Hoje o projeto usa status em formatos mistos (integer enum e string enum), além de vocabulários diferentes por contexto. Isso dificulta filtros, integrações e consistência de API.

### 6.1 Estado atual (diagnóstico)
- `User.status`: **string enum** (`active`, `inactive`, `suspended`).
- `Waste::Bin.status`: **string enum** (`normal`, `warning`, `critical`, `collected`).
- `Waste::Bin.equipment_status`: **string enum** (`online`, `offline`, `maintenance`).
- `Fleet::Truck.status`: **integer enum** (`available`, `in_route`, `maintenance`, `inactive`).
- `Fleet::Route.status`: **integer enum** (`planned`, `active`, `completed`, `cancelled`).
- `Alert.status`: **integer enum** (`pending`, `resolved`).
- `Tenant.status`: **integer enum** (`inactive`, `active`).
- `MqttMessage.status`: enum específico de pipeline.

### 6.2 Padrão recomendado
Adotar padrão único de contrato para exposição de status na API:
- **Padrão externo (API)**: sempre string (`snake_case`, inglês).
- **Padrão interno (DB)**: pode permanecer integer enum por eficiência, desde que serialização normalize para string.
- **Vocabulário base (cross-domain)**:
  - `active`, `inactive`, `maintenance`, `pending`, `processing`, `completed`, `failed`, `cancelled`, `resolved`, `critical`.

### 6.3 Plano de implementação
1. Criar um **Status Dictionary** central (`config/statuses.yml` ou módulo em `app/lib/status_catalog.rb`).
2. Padronizar serialização de todos os recursos para retornar string canônica.
3. Mapear aliases legados (`in_route` vs `active_route`, etc.) apenas no domínio interno.
4. Adicionar validação de contrato nos testes de API para garantir status padronizado.
5. Migrar gradualmente enums integer→string apenas onde fizer sentido, evitando big-bang.

### 6.4 Ganhos
- Menor ambiguidade entre times (produto, backend, frontend, dados).
- APIs mais previsíveis.
- Menos retrabalho em filtros e dashboards.

## 7) Segurança, observabilidade e confiabilidade
- Reforçar auditoria de endpoint público de sensor.
- Implantar logs estruturados + métricas + tracing para jobs e pipeline MQTT.
- Implementar política de idempotência/retry/DLQ no consumo de telemetria.

## 8) Recomendações priorizadas
### Curto prazo (1–2 sprints)
1. Corrigir inconsistências do `ProcessMessage`.
2. Padronizar contrato de status na API (serialização + testes).
3. Completar README com setup, workers, variáveis e troubleshooting.

### Médio prazo (3–5 sprints)
1. Catálogo central de status por domínio.
2. OpenAPI dos endpoints críticos.
3. Observabilidade completa para jobs e stream.

### Longo prazo
1. Otimização híbrida de rotas (IA + heurística determinística).
2. SLOs formais por domínio.
3. Governança multi-tenant com auditoria operacional.

## 9) Conclusão
O projeto tem base sólida de domínio e arquitetura. O próximo salto de maturidade é **padronização de status + confiabilidade operacional + documentação executável** para escalar com segurança.
