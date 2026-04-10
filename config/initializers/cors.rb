# config/initializers/cors.rb
Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    # Para o MVP, permitimos qualquer origem ('*'). Em produção, você restringe para o domínio do seu App/Painel.
    origins "*"

    resource "*",
      headers: :any,
      methods: [ :get, :post, :put, :patch, :delete, :options, :head ],
      # Isso aqui é crucial se o front-end for ler algum header customizado
      expose: [ "Authorization" ]
  end
end
