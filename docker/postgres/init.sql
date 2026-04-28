-- Garante que o script é idempotente usando blocos PL/pgSQL

-- 1. Cria o banco da aplicação Rails (Apenas se não existir)
SELECT 'CREATE DATABASE ecotrack_development'
WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'ecotrack_development')\gexec

-- 2. Cria o usuário do ChirpStack (Apenas se não existir)
DO $$
BEGIN
  IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'chirpstack_user') THEN
    CREATE USER chirpstack_user WITH PASSWORD 'ecotrack_super_secret';
  END IF;
END
$$;

-- 3. Cria o banco do ChirpStack (Apenas se não existir)
SELECT 'CREATE DATABASE chirpstack OWNER chirpstack_user'
WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'chirpstack')\gexec

-- 4. Conecta no banco do ChirpStack para configurar permissões
\c chirpstack;

-- 5. Habilita as extensões (IF NOT EXISTS já garante a idempotência aqui)
CREATE EXTENSION IF NOT EXISTS pg_trgm;
CREATE EXTENSION IF NOT EXISTS hstore;

-- 6. Garante as permissões
GRANT ALL ON SCHEMA public TO chirpstack_user;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO chirpstack_user;
