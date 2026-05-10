# Analise completa do projeto `ecotrack_api`

Data da analise: 2026-05-10

## 1. Resumo executivo

O `ecotrack_api` e uma API Rails 8 para uma plataforma EcoTrack de gestao inteligente de residuos. O projeto cobre multi-tenancy, autenticacao JWT, usuarios por papel, lixeiras IoT, ingestao MQTT, historico de leituras, alertas, dashboard operacional, frota, rotas e otimizacao com IA.

A base tem boas escolhas arquiteturais: separacao por dominios em `app/domains`, uso de services, serializers, `Result`, `CurrentAttributes`, Solid Queue e PostgreSQL. O desenho geral esta acima de um CRUD simples e ja aponta para uma arquitetura modular.

O principal ponto de atencao e que existem inconsistencias entre codigo, schema e rotas que podem quebrar fluxos criticos em runtime, especialmente ingestao IoT/MQTT, criacao de tenants, rota publica de sensor e testes. A recomendacao e estabilizar esses contratos antes de evoluir features.

## 2. Stack e infraestrutura

- Linguagem/runtime: Ruby 3.4.1.
- Framework: Rails `~> 8.1.3`, API-only.
- Banco: PostgreSQL.
- Jobs/cache/cable: `solid_queue`, `solid_cache`, `solid_cable`.
- Auth/seguranca: `bcrypt`, `jwt`, `rack-attack`, `rack-cors`.
- IoT: `mqtt`.
- IA/HTTP: `faraday`, adapter Gemini.
- Validacao: `dry-validation`.
- Testes: Minitest.
- Deploy/container: Dockerfile de producao, Kamal presente, `docker-compose.yml` para Postgres e PGWeb em desenvolvimento.

## 3. Organizacao do codigo

### Pontos fortes

- Controllers REST em `app/controllers/api/v1`.
- Dominios separados em `app/domains`: `identity`, `telemetry`, `waste`, `fleet`, `alerts`, `dashboard`, `tenants`.
- Models namespaced para subdominios: `Waste::*`, `Fleet::*`, `Telemetry::*`.
- Serializers simples e previsiveis por dominio.
- Services com `ApplicationService` e objeto `Result`.
- `StatusCatalog` ja existe para normalizar status expostos pela API.

### Pontos de melhoria

- Nem todos os services seguem o mesmo contrato. Alguns retornam `Result`, outros retornam `Hash`.
- Ha comentarios de fase MVP e notas temporarias ainda em codigo de producao.
- Algumas rotas declaradas nao possuem action implementada.
- Ha codigo legado referenciando colunas removidas/renomeadas em migracoes.
- O README ainda e o template padrao do Rails, sem onboarding real.

## 4. Modelo de dominio

### Multi-tenancy

Entidades principais pertencem a `Tenant`: usuarios, lixeiras, caminhoes, rotas, alertas e mensagens MQTT. O isolamento em controllers normalmente usa `Current.tenant`, por exemplo em bins, users e trucks.

Riscos:

- `ApiController#current_tenant` retorna `@current_tenant`, mas `authorize_request` define `Current.tenant`, nao `@current_tenant`.
- Usuarios de sistema (`super_admin`, `vendedor`, `suporte`) tem `tenant` opcional no model, mas `authorize_request` exige `Current.tenant`; isso dificulta rotas globais autenticadas.
- Criacao de tenants esta inconsistentes entre controller e service.

### Identidade

O projeto usa JWT com `jti` e tabela `revoked_tokens`, uma boa base para logout/revogacao. Roles estao modeladas como enum string no `User`, o que facilita leitura.

Riscos:

- `UsersController#create` renderiza erro quando `result.success?` e falso, mas nao retorna em seguida. Isso pode causar double render e/ou acessar `result.data` nulo.
- `require_manager!` chama `current_user&.manager?`, mas `manager` nao existe no enum de roles.
- A autorizacao ainda e manual e espalhada; para crescer, vale centralizar politicas por papel.

### Waste/IoT

`Waste::Bin` tem endereco, status operacional, nivel, bateria, historico de leituras e campos de IA. O uso de `sensor_id` e coerente com o schema final.

Riscos:

- Ha codigo antigo ainda usando `dev_eui` e `tenant_slug`, ambos removidos/renomeados.
- O endpoint `/api/v1/bins/:id/sensor` esta roteado como publico, mas nao existe action `sensor` no controller e nao ha `skip_before_action` para JWT.
- `destroy` de lixeira e soft-disable via `equipment_status: offline`, mas o nome HTTP `DELETE` pode confundir clientes, auditoria e produto.

### Fleet/rotas

Ha models para caminhoes, rotas e pontos de rota, com geracao assíncrona via job e tentativa de otimizacao com Gemini.

Riscos:

- `Fleet::Truck` tem callback que transforma `inactive` em `available` antes de salvar. Isso impede persistir caminhão inativo e quebra `toggle_status`.
- `RouteGenerator` compara `waste_bins.status` com inteiro `1`, mas essa coluna e string.
- `RouteGenerator` assume que toda lixeira tem `bin_address`; se faltar endereco, `b.bin_address.latitude` quebra.
- O cliente Gemini e instanciado sem argumento (`Ai::GeminiClient.new.generate`), mas o initializer exige `purpose`.

## 5. Fluxos criticos

### Autenticacao

Fluxo esperado:

1. `POST /api/v1/login`.
2. `Identity::Services::Authenticator` valida tenant, usuario e senha.
3. `TokenManager` gera JWT com `user_id`, `tenant_id`, `exp` e `jti`.
4. Requests autenticados validam token e tenant.

Maturidade: boa para MVP.

Prioridades:

- Padronizar resposta de erro em `authorize_request` usando `render_result`.
- Decidir como usuarios de sistema autenticam sem tenant.
- Garantir `return` apos renders de bloqueio (`check_user_status!`, `enforce_password_change!`, autorizadores).

### Criacao de tenant

Fluxo declarado: `POST /api/v1/tenants`.

Problema: o controller chama `Tenants::Services::CreateWithAdmin.call(tenant_params:, admin_params:)`, mas o service define `def self.call(params)` e retorna `Hash`, nao `Result`. Em seguida, o controller chama `result.success?`, que nao existe em `Hash`.

Impacto: criacao de tenant tende a falhar em runtime.

### Ingestao IoT/MQTT

Existem pelo menos tres caminhos de ingestao:

- `Telemetry::MqttProcessor`, que persiste `MqttMessage`.
- `MqttBatchProcessorJob`, que processa `MqttMessage`.
- `Telemetry::Services::IngestReading` / `ProcessMessage`, com contratos diferentes.

Problemas criticos:

- `MqttBatchProcessorJob` busca `Waste::Bin.find_by!(dev_eui: dev_eui)`, mas o schema tem `sensor_id`.
- O mesmo job atualiza `error_log`, coluna inexistente em `mqtt_messages`.
- `Telemetry::Services::IngestReading` busca `tenant_slug` em `Waste::Bin`, coluna removida.
- `Telemetry::Services::ProcessMessage` chama `Waste::Services::UpdateBinStatusService`, que nao existe.
- `ProcessMessage` faz `JSON.parse(message.payload)`, mas `payload` ja e `jsonb` e pode chegar como Hash.

Impacto: este e o fluxo mais fragil do sistema hoje.

### Dashboard

`Dashboard::Services::SummaryService` esta simples e bem posicionado. Conta bins por status e usa query object para proxima prioridade.

Ponto de atencao: se a API externa padronizar status pelo `StatusCatalog`, mas o banco usa status do dominio (`critical`, `warning`, etc.), filtros e dashboards precisam deixar claro se trabalham com status interno ou status canonico exposto.

### Rotas e SSE

O projeto usa `LISTEN/NOTIFY` do PostgreSQL com SSE. A ideia e boa para MVP e evita infra extra.

Riscos:

- `RoutesController#stream` escuta canal de alertas (`alerts_tenant_...`) para progresso de rotas. O nome funciona tecnicamente, mas mistura conceitos.
- `broadcast_update` monta SQL com `sanitize_sql_array([ "NOTIFY %s, '%s'", ...])`; isso e fragil para payload JSON com aspas/caracteres especiais.
- Falhas da IA caem em fallback, o que e bom, mas algumas falhas acontecem antes do fallback por null address ou initializer errado.

## 6. Achados de maior severidade

### Alta severidade

1. Pipeline MQTT quebrado por colunas inexistentes.
   - Arquivo: `app/jobs/mqtt_batch_processor_job.rb`
   - Linhas: `36`, `59`, `62`
   - Problema: usa `dev_eui` e `error_log`, ausentes no schema atual.
   - Impacto: mensagens MQTT falham e nao atualizam lixeiras.

2. Criacao de tenants incompatível com o contrato do service.
   - Arquivos: `app/controllers/api/v1/tenants_controller.rb`, `app/domains/tenants/services/create_with_admin.rb`
   - Problema: controller chama keywords e espera `Result`; service recebe um hash posicional e retorna `Hash`.
   - Impacto: endpoint de onboarding pode quebrar imediatamente.

3. Rota publica de sensor nao implementada.
   - Arquivos: `config/routes.rb`, `app/controllers/api/v1/bins_controller.rb`
   - Problema: rota aponta para `bins#sensor`, mas a action nao existe.
   - Impacto: hardware nao consegue publicar por HTTP nesse endpoint.

4. Testes nao executam.
   - Arquivo: `config/database.yml`
   - Problema: nao existe ambiente `test`.
   - Evidencia: `bin/rails test` aborta com `The test database is not configured for the test environment`.
   - Impacto: CI nao valida regressao.

5. Ingestao alternativa usa colunas/classes inexistentes.
   - Arquivos: `app/domains/telemetry/services/ingest_reading.rb`, `app/domains/telemetry/services/process_message.rb`
   - Problema: `tenant_slug`, `UpdateBinStatusService`, `error_log`.
   - Impacto: duplicidade de pipelines e comportamento indefinido.

### Media severidade

1. `Fleet::Truck` nao consegue ficar inativo.
   - Arquivo: `app/models/fleet/truck.rb`
   - Linhas: `27-32`
   - Problema: callback converte `inactive` em `available`.
   - Impacto: `toggle_status` de trucks nao funciona como esperado.

2. `UsersController#create` pode fazer double render.
   - Arquivo: `app/controllers/api/v1/users_controller.rb`
   - Linha: `25`
   - Problema: renderiza falha sem `return`.
   - Impacto: erro de controller em validacoes de usuario.

3. `RouteGenerator` tem query de status incorreta.
   - Arquivo: `app/domains/fleet/services/route_generator.rb`
   - Linha: `18`
   - Problema: compara string column com inteiro.
   - Impacto: lixeiras criticas podem nao entrar na geracao de rotas.

4. `GeminiClient` instanciado sem argumento.
   - Arquivo: `app/domains/fleet/services/route_generator.rb`
   - Linha: `81`
   - Problema: `Ai::GeminiClient#initialize` exige `purpose`.
   - Impacto: geracao com IA quebra antes de obter resposta.

5. CORS aberto para qualquer origem.
   - Arquivo: `config/initializers/cors.rb`
   - Problema: `origins "*"` em configuracao global.
   - Impacto: aceitavel em MVP local, arriscado em producao.

### Baixa severidade / manutencao

1. README ainda e template.
2. Comentarios temporarios e emojis em codigo de dominio dificultam manutencao profissional.
3. Arquivos vazios acidentais na raiz: `Booting`, `Rails`, `Run`.
4. `StatusCatalog` existe, mas ainda nao ha testes dedicados para contrato de status da API.
5. Rotas incluem `resources :shifts`, mas nao ha controller visivel.

## 7. Testes e qualidade

### Estado atual

Ha testes de models, controllers e integracao, mas a suite nao inicia por falta de configuracao `test` no banco.

Comando executado:

```bash
bin/rails test
```

Resultado:

```text
The `test` database is not configured for the `test` environment.
Available database configurations are:
default
development: primary, queue, cable, cache
```

### Recomendacoes

1. Adicionar `test:` em `config/database.yml` com `primary`, `queue`, `cable` e `cache`.
2. Corrigir fixtures que ainda possuem campos antigos (`tenant_slug`).
3. Adicionar testes para:
   - login/logout/me;
   - isolamento por tenant;
   - ingestao MQTT com payload ChirpStack;
   - endpoint publico de sensor, se ele for mantido;
   - geracao de rotas com fallback sem Gemini;
   - status serializados com `StatusCatalog`.

## 8. Seguranca

Pontos positivos:

- JWT com expiracao.
- Revogacao por `jti`.
- `rack-attack` para login e troca de senha.
- API bloqueia por padrao via `ApiController`.a
- Escopo por tenant nos principais controllers.

Riscos:

- CORS aberto globalmente.
- Endpoint de sensor declarado como publico precisa autenticacao propria de dispositivo: token por sensor, assinatura HMAC, API key rotacionavel ou allowlist controlada.
- Falta auditoria de eventos sensiveis: login, logout, troca de senha, criacao de tenant, mudanca de status, coleta.
- `render_unauthorized` nao segue o envelope `{ success, data, error }` usado pelo `ApiResponder`.
- Renders de autorizacao sem `return` podem permitir continuacao de callbacks/actions em alguns cenarios.

## 9. Observabilidade e operacao

O projeto ja usa jobs e logs, mas ainda falta robustez operacional.

Recomendacoes:

- Logs estruturados para MQTT: `event_id`, `tenant_id`, `sensor_id`, status, retry_count.
- DLQ ou status de falha com motivo persistido. Hoje nao existe coluna `error_log`.
- Politica explicita de retry/backoff usando `next_attempt_at` e `retry_count`, que ja existem no schema.
- Metrica de mensagens processadas/falhas por minuto.
- Health checks para DB, Solid Queue e conectividade MQTT.
- Separar canais SSE por finalidade: `routes_tenant_ID`, `alerts_tenant_ID`.

## 10. Status e contratos de API

O `StatusCatalog` e uma boa decisao para normalizar a API, mas o projeto mistura:

- enums inteiros (`Tenant`, `Fleet::Truck`, `Fleet::Route`, `Alert`);
- enums string (`Waste::Bin`, `Waste::Bin#equipment_status`, `MqttMessage`);
- status canonicos expostos (`active`, `pending`, `completed`, etc.).

Recomendacao:

- Manter status internos por dominio quando fizer sentido.
- Expor sempre strings canonicas na API.
- Documentar por recurso:
  - status interno;
  - status externo;
  - transicoes permitidas;
  - quem pode mudar.
- Criar testes de contrato para serializers.

## 11. Documentacao

O README precisa virar documentacao executavel de desenvolvimento.

Conteudo recomendado:

1. Requisitos: Ruby, PostgreSQL, Docker opcional.
2. Variaveis `.env`: `POSTGRES_HOST`, `POSTGRES_USER`, `POSTGRES_PASSWORD`, `POSTGRES_DB`, `GEMINI_API_KEY`, MQTT.
3. Setup local:
   - `bundle install`
   - `docker compose up -d db`
   - `bin/rails db:prepare`
   - `bin/dev`
4. Como rodar jobs e worker MQTT.
5. Como rodar testes.
6. Exemplos de payload para login, sensor e MQTT.
7. Troubleshooting: banco, credentials, Solid Queue, MQTT.

## 12. Plano priorizado

### Prioridade 0: fazer a base validar

1. Adicionar config `test` em `database.yml`.
2. Rodar `bin/rails test` e corrigir fixtures quebradas.
3. Rodar `bin/rails routes` e remover/implementar rotas sem controller/action.
4. Remover arquivos acidentais da raiz se nao forem intencionais.

### Prioridade 1: estabilizar IoT

1. Escolher um unico pipeline de ingestao.
2. Padronizar identificador como `sensor_id`.
3. Corrigir `MqttBatchProcessorJob`.
4. Decidir se `mqtt_messages` tera `error_log`/`last_error`.
5. Usar `ready_for_processing` com retry/backoff.
6. Cobrir com teste de integracao.

### Prioridade 2: corrigir onboarding e identidade

1. Refatorar `Tenants::Services::CreateWithAdmin` para `ApplicationService`.
2. Ajustar controller para receber `Result`.
3. Corrigir associacao de profile.
4. Definir fluxo de usuarios de sistema sem tenant.
5. Adicionar retornos apos renders de bloqueio.

### Prioridade 3: rotas/frota

1. Remover callback que impede truck inativo.
2. Corrigir query de bins criticos.
3. Tratar bins sem coordenadas.
4. Corrigir chamada ao Gemini.
5. Garantir fallback deterministico testado.

### Prioridade 4: hardening

1. Restringir CORS por ambiente.
2. Criar autenticacao propria para hardware.
3. Adicionar auditoria.
4. Padronizar erros da API.
5. Documentar OpenAPI/Swagger dos endpoints principais.

## 13. Conclusao

O projeto tem uma fundacao promissora: boa separacao de dominios, escolha moderna de stack Rails, preocupacao real com multi-tenancy, jobs e IoT. A arquitetura esta no caminho certo.

O risco atual nao e a falta de arquitetura; e a divergencia entre iteracoes do codigo. Algumas migracoes evoluiram (`dev_eui` para `sensor_id`, remocao de `tenant_slug`), mas services e fixtures ficaram para tras. Corrigir esses contratos vai destravar testes, ingestao de telemetria, onboarding de tenants e evolucao segura das features.

Minha leitura: antes de adicionar novas funcionalidades, vale fazer uma sprint curta de estabilizacao. O retorno deve ser alto, porque os problemas estao bem localizados e afetam justamente os fluxos centrais.

## 14. Reanalise apos implementacao

Data da reanalise: 2026-05-10

### Estado atual

O primeiro pacote de estabilizacao foi aplicado e commitado em `413acef` (`ajuste codex`). A suite automatizada agora executa com sucesso contra o banco de teste PostgreSQL.

Validacao executada:

```bash
env RAILS_ENV=test POSTGRES_HOST=127.0.0.1 bin/rails test
```

Resultado:

```text
9 runs, 48 assertions, 0 failures, 0 errors, 0 skips
```

### Pontos corrigidos

1. `config/database.yml` agora possui ambiente `test`.
2. Fixtures antigas foram alinhadas ao schema atual.
3. `MqttBatchProcessorJob` passou a usar `sensor_id` e `ready_for_processing`.
4. Uso de colunas inexistentes `dev_eui` e `error_log` foi removido do job MQTT.
5. `Tenants::Services::CreateWithAdmin` agora segue o contrato `ApplicationService`/`Result`.
6. `UsersController#create` evita double render em erro.
7. `BinsController#sensor` foi implementado para a rota publica ja declarada.
8. `ApiResponder` voltou a tratar `ActiveRecord::RecordNotFound` como `404`, nao `500`.
9. `Fleet::Truck` agora consegue persistir `inactive`.
10. `RouteGenerator` foi ajustado para status string e chamada correta ao `GeminiClient`.

### Riscos remanescentes

1. O endpoint publico de sensor ainda precisa de autenticacao de dispositivo antes de producao.
2. `Telemetry::Services::IngestReading` e `Telemetry::Services::ProcessMessage` ainda representam caminhos legados/inconsistentes; o pipeline principal validado agora e `MqttMessage` + `MqttBatchProcessorJob`.
3. `mqtt_messages` ainda nao possui campo persistido para erro detalhado (`last_error` ou equivalente).
4. README segue precisando de setup executavel.
5. CORS permanece aberto e deve ser restringido por ambiente antes de deploy real.

### Proxima etapa recomendada

Priorizar o hardening do fluxo IoT:

1. Criar autenticacao para sensores.
2. Adicionar coluna `last_error` em `mqtt_messages`.
3. Remover ou refatorar services legados de telemetria.
4. Criar testes especificos para payloads MQTT validos, payloads invalidos e sensor desconhecido.

## 15. Padronizacao por camadas aplicada

Data da revisao: 2026-05-10

### Padrao arquitetural definido

O projeto passa a seguir este contrato entre camadas:

1. Controllers apenas autenticam, autorizam, extraem parametros e renderizam `Result`.
2. Services concentram regra de negocio e sempre retornam `Result`.
3. Jobs apenas orquestram services e registram falhas em log.
4. Models mantem associacoes, validacoes, callbacks pequenos e invariantes locais.
5. Serializers normalizam a exposicao da API, incluindo status canonicos via `StatusCatalog`.
6. Fixtures e testes devem refletir o schema atual, sem campos legados.

### Melhorias implementadas nesta rodada

1. Criado `Waste::Services::RecordReading` como ponto unico para registrar leitura, atualizar estado atual da lixeira, criar historico e disparar analise de IA quando necessario.
2. `Telemetry::Services::IngestReading` foi reescrito para usar contrato por `sensor_id`, `level` e `battery`, sem `tenant_slug`.
3. `Telemetry::Services::ProcessMessage` foi reescrito como `ApplicationService`, processando `MqttMessage` e retornando `Result`.
4. `MqttBatchProcessorJob` passou a delegar o processamento para o service de telemetria.
5. `Waste::Services::CollectBinService` agora retorna `Result` e preserva o status `collected`.
6. `Waste::Bin` foi ajustado para nao sobrescrever coleta explicita com `normal` no callback de status.
7. `Identity::Services::Authenticator`, `Identity::Services::Revoker`, `Waste::Services::AnalyzeBinService` e `Fleet::Services::RouteGenerator` foram alinhados ao contrato `ApplicationService`/`Result`.
8. `ApiController` passou a renderizar erros de autenticacao/autorizacao no envelope padrao `{ success, data, error }`.
9. `User` ganhou role `manager`, eliminando chamada para role inexistente.
10. `BinsController` e `TrucksController` foram limpos para orquestracao simples, sem `puts` e sem comentarios temporarios.
11. `config/routes.rb`, serializers e runners foram limpos de anotacoes temporarias.
12. `CORS_ORIGINS` foi introduzido para permitir restringir origens por ambiente.
13. `Api::V1::ShiftsController#index` foi criado para cobrir a rota declarada.
14. Foram adicionados testes de dominio para processamento MQTT e coleta de lixeira.

### Validacao

Comando executado:

```bash
env RAILS_ENV=test POSTGRES_HOST=127.0.0.1 bin/rails test
```

Resultado:

```text
12 runs, 61 assertions, 0 failures, 0 errors, 0 skips
```

### Pendencias tecnicas restantes

1. Adicionar autenticacao propria para o endpoint publico de sensor antes de producao.
2. Persistir motivo de falha em `mqtt_messages` com `last_error` ou tabela de eventos.
3. Criar serializer dedicado para rotas e alertas, removendo `as_json` direto dos controllers.
4. Transformar `README.md` em guia executavel de setup, testes, jobs e MQTT.
5. Rever `LISTEN/NOTIFY` para usar canais separados entre alertas e progresso de rotas.
