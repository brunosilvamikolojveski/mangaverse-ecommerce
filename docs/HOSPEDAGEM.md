# Hospedagem para a apresentação

O frontend fica na Vercel e a API Laravel com MySQL fica na Railway. Esta branch prepara o Flutter Web; a configuração anterior do Vue continua em `front/`. As requisições passam pelo domínio da Vercel para que os cookies de sessão funcionem no mesmo domínio. O Docker local continua funcionando de forma independente.

## 1. Criar o projeto na Railway

Entre na Railway com o GitHub. Confira se a conta possui créditos de teste disponíveis antes de criar serviços. Crie um projeto e adicione um banco MySQL. Mantenha o nome do serviço como `MySQL` para usar as referências abaixo.

No mesmo projeto, adicione o repositório do GitHub como outro serviço, chamado `api`. A raiz é a pasta principal do repositório. O arquivo `railway.json` seleciona o `Dockerfile` de produção, executa migrations antes de cada implantação e verifica `/up`.

## 2. Configurar as variáveis da API

Defina estas variáveis no serviço `api`, na Railway. As referências `${{MySQL...}}` apontam para as variáveis do serviço MySQL do mesmo projeto; não são os dados do banco local.

```dotenv
APP_NAME=Mangáverse
APP_ENV=production
APP_DEBUG=false
APP_URL=https://SEU-PROJETO.vercel.app
APP_KEY=CHAVE-GERADA-PARA-A-HOSPEDAGEM
LOG_CHANNEL=stderr
LOG_LEVEL=warning
DB_CONNECTION=mysql
DB_HOST=${{MySQL.MYSQLHOST}}
DB_PORT=${{MySQL.MYSQLPORT}}
DB_DATABASE=${{MySQL.MYSQLDATABASE}}
DB_USERNAME=${{MySQL.MYSQLUSER}}
DB_PASSWORD=${{MySQL.MYSQLPASSWORD}}
SESSION_DRIVER=database
SESSION_SECURE_COOKIE=true
SESSION_SAME_SITE=lax
SANCTUM_STATEFUL_DOMAINS=SEU-PROJETO.vercel.app
TRUSTED_PROXIES=*
CACHE_STORE=database
QUEUE_CONNECTION=sync
ADMIN_SEED_ENABLED=true
SEED_ON_DEPLOY=true
ADMIN_NAME=Mangáverse Admin
ADMIN_EMAIL=SEU-EMAIL-DE-ADMIN
ADMIN_PASSWORD=UMA-SENHA-NOVA-PARA-A-HOSPEDAGEM
```

Substitua os textos em maiúsculas pelos valores reais. Nas caixas individuais de variáveis do painel, os valores não precisam de aspas. A `APP_KEY` da hospedagem deve ser estável entre implantações. Gere uma chave nova no seu computador e copie a saída diretamente para a variável na Railway:

```bash
docker compose exec php php artisan key:generate --show
```

Esse comando apenas mostra uma chave nova; não altera a chave do ambiente local. Não publique a chave, a senha do admin ou credenciais do banco no GitHub.

## 3. Configurar imagens e publicar a API

No serviço `api`, crie um volume com ponto de montagem `/app/storage/app/public`. O serviço MySQL usa seu próprio volume. O volume da API preserva as capas após novas implantações.

Gere um domínio público para a API, usando a porta configurada em `PORT` pela Railway. O FrankenPHP usa essa variável, com padrão 8000 quando ela não está definida. Confira `/up` e `/api/docs` no domínio gerado.

Na primeira implantação, `SEED_ON_DEPLOY=true` cria o catálogo. `ADMIN_SEED_ENABLED=true` permite criar o admin com as credenciais acima. As contas e pedidos de demonstração locais não são criados em produção.

Depois de confirmar que o catálogo e o admin existem, altere `SEED_ON_DEPLOY=false` e `ADMIN_SEED_ENABLED=false`. Isso evita executar os seeders ou redefinir a senha do admin nas próximas implantações.

## 4. Publicar o Flutter Web na Vercel

Importe o repositório na Vercel ou ajuste o projeto existente. Use a branch `feat/flutter-web` enquanto o Flutter estiver sendo desenvolvido nela. Se o projeto continuar configurado para a branch `main`, ele publicará a versão dessa branch.

Configure:

- Framework Preset: Other.
- Root Directory: `front_flutter`.
- Build Command: `sh build-web.sh`.
- Output Directory: `build/web`.
- Install Command: vazio; as dependências são instaladas pelo script de build.

`front_flutter/vercel.json` já define essas opções, exceto a pasta raiz e a branch, que são selecionadas no painel. O script baixa o SDK Flutter 3.50.0 quando necessário, instala as dependências do `pubspec.lock` e gera os arquivos web. A [documentação do Flutter](https://docs.flutter.dev/deployment/web) descreve a geração do build, e a [documentação da Vercel](https://vercel.com/docs/project-configuration/vercel-json) explica as opções do arquivo de configuração.

Deixe `API_BASE_URL` sem configurar na Vercel. O script gera o frontend usando o próprio domínio para as requisições; as regras de `vercel.json` encaminham `/api/`, `/sanctum/`, `/storage/` e `/up` para a API Railway. Elas apontam para `mangaverse-ecommerce-production.up.railway.app`; atualize os destinos se o domínio da API mudar. `VITE_API_BASE_URL` pertence apenas ao Vue.

Use o domínio definitivo da Vercel em `APP_URL` e `SANCTUM_STATEFUL_DOMAINS` na Railway. `APP_URL` inclui `https://`; `SANCTUM_STATEFUL_DOMAINS` contém apenas o host. Em `SESSION_DOMAIN`, mantenha o padrão vazio, sem definir domínio da Railway nem `.vercel.app`.

Para manter o Vue hospedado, seu projeto continua usando Root Directory `front`, Framework Vite, Build Command `npm run build` e Output Directory `dist`. Os dois frontends têm configurações separadas. Preparar estes arquivos não altera automaticamente o projeto existente no painel da Vercel.

## 5. Conferir antes da apresentação

Abra uma janela anônima no domínio da Vercel. Navegue no catálogo, adicione um produto ao carrinho, registre uma conta e confira a fusão. Cadastre um endereço, finalize a compra e confirme o pagamento simulado. Depois confira os pedidos e faça login com o admin para atualizar o status e enviar uma capa.

Abra também `/api/docs` e `/api/docs/openapi.yaml` pelo domínio da Vercel. Recarregue uma URL como `/#/mangas/1` ou `/#/pedidos/1` para verificar a navegação do Flutter. Confira subtotal, frete, total e data do pagamento nos detalhes do pedido.

Depois da apresentação, confira o consumo dos créditos e remova os serviços quando não forem mais necessários. A versão local e seus dados permanecem separados da hospedagem.
