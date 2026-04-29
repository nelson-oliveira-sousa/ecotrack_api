puts "🌱 Limpando banco de dados (Respeitando integridade)..."
Waste::BinAddress.destroy_all # Importante limpar os endereços primeiro!
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

guaicara = Tenant.create!(
  name: 'Prefeitura de Guaiçara',
  code: '12345678000199',
  slug: 'guaicara',
  status: 1
)

TenantProfile.create!(
  tenant: guaicara,
  document: '12.345.678/0001-99',
  contact_email: 'infraestrutura@guaicara.sp.gov.br',
  contact_phone: '1433334444'
)

User.create!(
  tenant: guaicara,
  name: 'Maurício Prefeito',
  email: 'mauricio@guaicara.sp.gov.br',
  password: 'SenhaDaPrefeitura!123',
  role: 'admin'
)
puts "✅ Prefeitura de Guaiçara provisionada."

puts "========================================"
puts "🗑️ 3. CADASTRANDO LIXEIRAS (LO-RA-WAN)"
puts "========================================"

# Agora usamos dev_eui e bin_address_attributes (Nested Attributes)
Waste::Bin.create!([
  {
    tenant: guaicara,
    label: 'Praça Matriz',
    sensor_id: '0011223344556601', # Identificador para o ChirpStack
    level: 5,
    status: 'normal',
    battery: 98,
    bin_address_attributes: {
      address: 'Praça Matriz',
      number: 'S/N',
      neighborhood: 'Centro',
      city: 'Guaiçara',
      state: 'SP',
      zip_code: '16430-000'
    }
  },
  {
    tenant: guaicara,
    label: 'Escola Municipal',
    sensor_id: '0011223344556602',
    level: 45,
    status: 'normal',
    battery: 82,
    bin_address_attributes: {
      address: 'Rua Olavo Bilac',
      number: '120',
      neighborhood: 'Vila Nova',
      city: 'Guaiçara',
      state: 'SP',
      zip_code: '16430-000'
    }
  },
  {
    tenant: guaicara,
    label: 'Pronto Socorro',
    sensor_id: '0011223344556603',
    level: 88,
    status: 'critical',
    battery: 12,
    bin_address_attributes: {
      address: 'Rua Tiradentes',
      number: '450',
      neighborhood: 'Centro',
      city: 'Guaiçara',
      state: 'SP',
      zip_code: '16430-000'
    }
  }
])

puts "✅ #{Waste::Bin.where(tenant: guaicara).count} lixeiras criadas com endereços e Sensor IDs."
puts "========================================"
puts "🚀 AMBIENTE SMART CITY PRONTO!"
