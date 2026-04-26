puts "🌱 Limpando banco de dados (Respeitando integridade)..."
# Ordem de destruição respeitando as Foreign Keys do seu schema
Waste::Reading.destroy_all
Telemetry::RawReading.destroy_all
Waste::Bin.destroy_all
MqttMessage.destroy_all
User.destroy_all
TenantProfile.destroy_all
Tenant.destroy_all

puts "========================================"
puts "👑 1. CRIANDO USUÁRIO DO SISTEMA (MASTER)"
puts "========================================"

# Super Admin: O dono da plataforma. tenant_id é nil.
super_admin = User.create!(
  name: 'Nelson Master',
  email: 'nelson@suaempresa.com.br',
  password: 'SenhaSuperForte!2026',
  role: 'super_admin',
  tenant_id: nil
)
puts "✅ Super Admin criado: #{super_admin.email}"

puts "========================================"
puts "🏢 2. PROVISIONANDO CLIENTE: GUAIÇARA"
puts "========================================"

# Criando o Tenant (Prefeitura)
guaicara = Tenant.create!(
  name: 'Prefeitura de Guaiçara',
  code: '12345678000199',
  slug: 'guaicara',
  status: 1 # Assumindo 1 como active no enum de status
)

# Criando o Perfil Detalhado (tabela tenant_profiles)
TenantProfile.create!(
  tenant: guaicara,
  document: '12.345.678/0001-99',
  contact_email: 'infraestrutura@guaicara.sp.gov.br',
  contact_phone: '1433334444'
)

# Criando o Admin da Prefeitura (O Maurício)
User.create!(
  tenant: guaicara,
  name: 'Maurício Prefeito',
  email: 'mauricio@guaicara.sp.gov.br',
  password: 'SenhaDaPrefeitura!123',
  role: 'admin'
)
puts "✅ Prefeitura de Guaiçara provisionada com sucesso."

puts "========================================"
puts "🗑️ 3. CADASTRANDO LIXEIRAS (WASTE_BINS)"
puts "========================================"

# Usando o namespace correto Waste::Bin que aponta para waste_bins
Waste::Bin.create!([
  {
    tenant: guaicara,
    label: 'Praça Matriz',
    level: 5,
    status: 'normal',
    latitude: -21.8364,
    longitude: -49.8861,
    battery: 98
  },
  {
    tenant: guaicara,
    label: 'Escola Municipal',
    level: 45,
    status: 'normal',
    latitude: -21.8350,
    longitude: -49.8850,
    battery: 82
  },
  {
    tenant: guaicara,
    label: 'Pronto Socorro',
    level: 88,
    status: 'critical',
    latitude: -21.8375,
    longitude: -49.8870,
    battery: 12
  }
])

puts "✅ #{Waste::Bin.where(tenant: guaicara).count} lixeiras criadas para Guaiçara."
puts "========================================"
puts "🚀 AMBIENTE PRONTO: Mãos à obra!"
