import 'package:material_ui/material_ui.dart';

import '../services/admin_service.dart';
import '../services/order_service.dart';
import '../widgets/admin_layout.dart';
import '../widgets/admin_components.dart';
import '../state/store_scope.dart';
import '../widgets/store_layout.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({
    super.key,
    required this.admin,
    required this.orders,
  });
  final AdminService admin;
  final OrderService orders;
  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  List<int>? _counts;
  String? _error;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final mangas = await widget.admin.mangas();
      final orders = await widget.orders.list(admin: true);
      if (mounted) {
        setState(
          () => _counts = [
            mangas.where((m) => m.isActive).length,
            orders.where((o) => o.isPending).length,
            orders.where((o) => {'paid', 'shipped'}.contains(o.status)).length,
          ],
        );
      }
    } catch (error) {
      if (mounted) setState(() => _error = errorMessage(error));
    }
  }

  @override
  Widget build(BuildContext context) => AdminLayout(
    path: '/admin',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AdminHeading(
          'Olá, ${StoreScope.of(context).user!.name}',
          eyebrow: 'RESUMO DA LOJA',
          subtitle: 'Escolha uma área para continuar gerenciando a Mangáverse.',
        ),
        if (_error != null)
          StoreMessage(
            title: 'Não foi possível carregar o painel',
            message: _error!,
            actionLabel: 'Tentar novamente',
            onAction: _load,
            isError: true,
          )
        else if (_counts == null)
          const Center(child: CircularProgressIndicator())
        else
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              AdminStat(
                'Volumes ativos',
                '${_counts![0]}',
                caption: 'Visíveis no catálogo',
                accent: StoreColors.purple,
              ),
              AdminStat(
                'Aguardando pagamento',
                '${_counts![1]}',
                caption: 'Pedidos pendentes',
                accent: const Color(0xFFE4A829),
              ),
              AdminStat(
                'Em andamento',
                '${_counts![2]}',
                caption: 'Pagos ou enviados',
                accent: const Color(0xFF3F78A8),
              ),
            ],
          ),
        const SizedBox(height: 24),
        LayoutBuilder(
          builder: (context, constraints) => Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              for (final (path, title, description, icon) in const [
                (
                  '/admin/cadastros',
                  'Séries, autores e categorias',
                  'Organize as informações usadas para cadastrar os volumes.',
                  Icons.category_outlined,
                ),
                (
                  '/admin/mangas',
                  'Gerenciar catálogo',
                  'Cadastre mangás, capas, preço, estoque e visibilidade.',
                  Icons.auto_stories_outlined,
                ),
                (
                  '/admin/pedidos',
                  'Gerenciar pedidos',
                  'Revise as compras e acompanhe o envio e a entrega.',
                  Icons.local_shipping_outlined,
                ),
              ])
                SizedBox(
                  width: constraints.maxWidth < 800
                      ? constraints.maxWidth
                      : (constraints.maxWidth - 16) / 2,
                  child: Material(
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: const BorderSide(color: Color(0xFFE8E7ED)),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: () => Navigator.of(context).pushNamed(path),
                      child: Padding(
                        padding: const EdgeInsets.all(22),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: StoreColors.lavender,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                icon,
                                size: 23,
                                color: StoreColors.purple,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    title,
                                    style: const TextStyle(
                                      color: StoreColors.purple,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    description,
                                    style: const TextStyle(
                                      color: StoreColors.muted,
                                      fontSize: 12,
                                      height: 1.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Icon(
                              Icons.arrow_forward,
                              size: 20,
                              color: StoreColors.purple,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(
            onPressed: () =>
                Navigator.of(context)
                    .pushNamedAndRemoveUntil('/', (_) => false),
            child: const Text('Abrir a loja como cliente'),
          ),
        ),
      ],
    ),
  );
}
