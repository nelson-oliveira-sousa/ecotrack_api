puts "🌱 Limpando banco antigo..."
Telemetry::RawReading.destroy_all
Waste::Bin.destroy_all

puts "🗑️ Criando lixeiras em Guaiçara..."

Waste::Bin.create!([
  {
    tenant_slug: 'guaicara',
    label: 'Praça Matriz',
    level: 0,
    status: 'normal',
    latitude: -21.8364,
    longitude: -49.8861
  },
  {
    tenant_slug: 'guaicara',
    label: 'Escola Municipal',
    level: 40,
    status: 'normal',
    latitude: -21.8350,
    longitude: -49.8850
  },
  {
    tenant_slug: 'guaicara',
    label: 'Prefeitura',
    level: 80,
    status: 'critical',
    latitude: -21.8375,
    longitude: -49.8870
  }
])

puts "✅ #{Waste::Bin.count} Lixeiras criadas com sucesso!"
