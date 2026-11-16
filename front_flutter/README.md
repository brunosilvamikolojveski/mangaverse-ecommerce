# Mangáverse em Flutter Web

Frontend Flutter separado do Vue, consumindo a mesma API Laravel. O Flutter oferece catálogo com novidades, busca, categorias, ordenação, paginação, detalhes, login, cadastro, carrinho de visitante com merge, perfil, endereços, checkout, pedidos e painel administrativo. O painel permite gerenciar mangás, capas, estoque, séries, autores, categorias e entregas.

## Executar pelo Docker

Na raiz do repositório:

```bash
docker compose up -d --build
```

O Docker baixa o SDK Flutter, compila este frontend e serve a loja em <http://localhost>. Não é necessário instalar Flutter no computador para esse modo. Na primeira instalação, configure a API e o banco seguindo o README da raiz.

Para voltar ao Vue, preservado em `front/`:

```bash
docker compose -f compose.yaml -f compose.vue.yaml up -d --build --no-deps frontend
```

Para retornar ao Flutter, execute `docker compose up -d --build --no-deps frontend`.

## Desenvolver localmente

Use Flutter 3.50 ou superior. A interface usa o pacote oficial `material_ui`. Para instalar o SDK em outro computador, siga a [documentação do Flutter](https://docs.flutter.dev/install/manual).

Neste computador, o SDK está instalado em `~/development/flutter`. Se o comando `flutter` ainda não estiver disponível no terminal, execute:

```bash
  export PATH="$PATH:$HOME/development/flutter/bin"
```

Na raiz do repositório, inicie o ambiente local existente:

```bash
docker compose up -d
```

Se for uma instalação nova, conclua primeiro a configuração do Laravel descrita no README da raiz, incluindo a chave da aplicação e as migrations.

Depois, entre nesta pasta e inicie o Flutter:

```bash
cd front_flutter
flutter pub get
flutter run -d web-server --web-hostname localhost --web-port 5173
```

Abra <http://localhost:5173>. O terminal precisa continuar aberto enquanto o servidor estiver em uso; `Ctrl+C` encerra o Flutter. A API padrão é <http://localhost:8000>. A porta 5173 já está permitida no CORS do backend.

O frontend compilado pelo Docker fica em <http://localhost>. Para executar o Flutter na porta 5173, encerre antes um eventual servidor Vite usando essa mesma porta.

Para apontar para outra API:

```bash
flutter run -d web-server --web-hostname localhost --web-port 5173 --dart-define=API_BASE_URL=https://endereco-da-api
```

Use o mesmo hostname no navegador e na API (`localhost` nos comandos acima), pois o cookie CSRF precisa ser lido pelo frontend. O backend precisa permitir a origem usada pelo Flutter. A Railway pode continuar desligada durante o desenvolvimento local.

## Login e carrinho

A autenticação usa a sessão do Laravel e os cookies do navegador. O cliente HTTP inicia uma sessão antes das consultas, envia os cookies nas chamadas à API e lê o cookie `XSRF-TOKEN` para enviar o header `X-XSRF-TOKEN` nas operações de escrita.

O visitante pode adicionar itens, alterar quantidades, remover itens e limpar o carrinho. Para finalizar a compra, deve entrar e selecionar um endereço. Os pagamentos são simulados para o projeto acadêmico; pedidos pendentes podem ser pagos ou cancelados em Meus pedidos. Ao entrar ou criar uma conta, o backend faz o merge; o Flutter carrega o carrinho resultante e informa ajustes de quantidade ou produtos indisponíveis. Recarregar a página recupera o usuário e o carrinho pela API. Ao cadastrar um endereço no checkout, ele fica selecionado para a compra atual, mesmo que outro endereço continue definido como principal. Os detalhes do pedido mostram subtotal, frete, total e a data do pagamento quando confirmado.

As quantidades e os totais exibidos vêm das respostas do servidor. Adicionar ao carrinho não desconta o estoque. O cabeçalho soma as unidades e exibe `99+` quando ultrapassa 99.

Se o Flutter já estava aberto quando os arquivos foram atualizados, encerre com `Ctrl+C` e execute novamente `flutter pub get` e o comando `flutter run` acima. Atualize a página do navegador depois de iniciar.

## Verificação

```bash
flutter analyze
flutter test --concurrency=1
flutter build web --no-web-resources-cdn
```

Os testes usam respostas HTTP simuladas e não alteram o banco local. O build fica em `build/web`. `build-web.sh` executa o mesmo build usado na Vercel, instalando o SDK quando ele não está disponível e usando o domínio do frontend para chamar a API. Rode `sh build-web.sh` dentro desta pasta para conferir esse modo localmente. Para testar o resultado com a API e o proxy, use o Docker. A configuração pública está em `vercel.json`; consulte [o guia de hospedagem](../docs/HOSPEDAGEM.md).

## Organização

- `lib/main.dart`: inicialização, tema e navegação.
- `lib/models`: conversão das respostas JSON para objetos Dart.
- `lib/services`: chamadas HTTP e consultas do catálogo.
- `lib/pages`: telas da loja, da conta e da administração.
- `lib/state`: usuário e carrinho compartilhados entre as telas.
- `lib/widgets`: cabeçalho, rodapé, cards e capas compartilhados.

Os filtros são enviados ao Laravel. A consulta, a ordenação, a paginação e as regras de negócio continuam no backend.

## Telas

| Área | Rota no navegador |
| --- | --- |
| Catálogo | `/#/` |
| Login e cadastro | `/#/entrar` |
| Carrinho | `/#/carrinho` |
| Perfil e endereços | `/#/perfil` |
| Checkout | `/#/finalizar` |
| Pedidos | `/#/pedidos` |
| Administração | `/#/admin` |
| Mangás e capas | `/#/admin/mangas` |
| Séries, autores e categorias | `/#/admin/cadastros` |
| Gestão de pedidos | `/#/admin/pedidos` |

A navegação usa fragmentos (`#`), permitindo recarregar as telas em servidores de arquivos estáticos. O backend continua responsável por autenticação, autorização, estoque, preços e regras dos pedidos. A interface acompanha essas respostas, sem substituir as validações do Laravel.

O projeto deve ser executado dentro de `front_flutter`, onde fica o `pubspec.yaml`. Se iniciar na pasta principal do repositório, entre primeiro nessa pasta. Para manter o SDK disponível nos próximos terminais Bash, adicione `export PATH="$PATH:$HOME/development/flutter/bin"` ao final de `~/.bashrc` uma única vez.
