import 'dart:async';
import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../models/manga.dart';
import '../services/api_client.dart';
import '../services/catalog_service.dart';
import '../widgets/manga_card.dart';
import '../widgets/catalog_hero.dart';
import '../widgets/releases_section.dart';
import '../widgets/store_layout.dart';

class CatalogPageView extends StatefulWidget {
  const CatalogPageView({super.key, required this.catalog, this.section});

  final CatalogService catalog;
  final String? section;

  @override
  State<CatalogPageView> createState() => _CatalogPageViewState();
}

class _CatalogPageViewState extends State<CatalogPageView> {
  final _searchController = TextEditingController();
  final _catalogKey = GlobalKey();
  final _releasesKey = GlobalKey();
  final _footerKey = GlobalKey();
  bool _initialSectionScrolled = false;
  Timer? _searchTimer;
  List<Category> _categories = [];
  CatalogPage? _result;
  String _search = '';
  String? _category;
  String _sort = 'newest';
  int _page = 1;
  int _requestId = 0;
  bool _loading = true;
  String? _error;
  String? _categoriesError;

  @override
  void initState() {
    super.initState();
    unawaited(_loadCategories());
    unawaited(_loadCatalog());
  }

  @override
  void dispose() {
    _searchTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    try {
      final categories = await widget.catalog.categories();
      if (!mounted) return;
      setState(() {
        _categories = categories;
        _categoriesError = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(
        () => _categoriesError = 'Não foi possível carregar as categorias.',
      );
    }
  }

  Future<void> _loadCatalog() async {
    final requestId = ++_requestId;
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final result = await widget.catalog.list(
        search: _search,
        category: _category,
        sort: _sort,
        page: _page,
      );
      if (!mounted || requestId != _requestId) return;
      setState(() => _result = result);
      if (!_initialSectionScrolled && widget.section != null) {
        _initialSectionScrolled = true;
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => _openSection(widget.section!),
        );
      }
    } catch (error) {
      if (!mounted || requestId != _requestId) return;
      setState(
        () => _error = error is ApiException
            ? error.message
            : 'Não foi possível carregar o catálogo. Tente novamente.',
      );
    } finally {
      if (mounted && requestId == _requestId) setState(() => _loading = false);
    }
  }

  void _changeSearch(String value) {
    _searchTimer?.cancel();
    _searchTimer = Timer(const Duration(milliseconds: 350), () {
      if (value.trim() == _search) return;
      _search = value.trim();
      _page = 1;
      unawaited(_loadCatalog());
    });
  }

  void _clearFilters() {
    _searchTimer?.cancel();
    _searchController.clear();
    _search = '';
    _category = null;
    _page = 1;
    unawaited(_loadCatalog());
  }

  void _openSection(String section) {
    final key = section == 'sobre'
        ? _footerKey
        : section == 'novidades'
        ? _releasesKey
        : _catalogKey;
    final target = key.currentContext;
    if (target != null) {
      Scrollable.ensureVisible(
        target,
        duration: const Duration(milliseconds: 350),
      );
    }
  }

  void _scrollToCatalog() {
    final target = _catalogKey.currentContext;
    if (target != null) {
      Scrollable.ensureVisible(
        target,
        duration: const Duration(milliseconds: 350),
      );
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: LayoutBuilder(
      builder: (context, constraints) {
        final horizontalPadding = math.max(
          constraints.maxWidth < 720 ? 14.0 : 24.0,
          (constraints.maxWidth - 1440) / 2,
        );
        final contentWidth = constraints.maxWidth - horizontalPadding * 2;
        final columns = contentWidth < 340
            ? 1
            : contentWidth < 720
            ? 2
            : contentWidth < 1050
            ? 3
            : 5;

        return CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: StoreHeader(
                searchController: _searchController,
                onSearchChanged: _changeSearch,
                onSection: _openSection,
              ),
            ),
            SliverToBoxAdapter(child: CatalogHero(onExplore: _scrollToCatalog)),
            if (!_loading &&
                _error == null &&
                _result != null &&
                _result!.mangas.isNotEmpty &&
                _search.isEmpty &&
                _category == null &&
                _sort == 'newest' &&
                _page == 1)
              SliverToBoxAdapter(
                child: ReleasesSection(
                  key: _releasesKey,
                  mangas: _result!.mangas.take(10).toList(),
                  onExplore: _scrollToCatalog,
                ),
              ),
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                40,
                horizontalPadding,
                24,
              ),
              sliver: SliverToBoxAdapter(child: _buildControls(context)),
            ),
            if (_loading)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(64),
                  child: Center(
                    child: CircularProgressIndicator(
                      semanticsLabel: 'Carregando catálogo',
                    ),
                  ),
                ),
              )
            else if (_error != null)
              SliverToBoxAdapter(
                child: StoreContainer(
                  child: StoreMessage(
                    title: 'Não foi possível carregar o catálogo',
                    message: _error!,
                    actionLabel: 'Tentar novamente',
                    onAction: _loadCatalog,
                    isError: true,
                  ),
                ),
              )
            else if (_result == null || _result!.mangas.isEmpty)
              SliverToBoxAdapter(
                child: StoreContainer(
                  child: StoreMessage(
                    title: 'Nenhum mangá encontrado',
                    message:
                        'Tente outro termo ou escolha uma categoria diferente.',
                    actionLabel: 'Limpar filtros',
                    onAction: _clearFilters,
                  ),
                ),
              )
            else
              SliverPadding(
                padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                sliver: SliverGrid.builder(
                  itemCount: _result!.mangas.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columns,
                    mainAxisExtent: contentWidth < 720 ? 420 : 460,
                    mainAxisSpacing: 20,
                    crossAxisSpacing: contentWidth < 720 ? 13 : 20,
                  ),
                  itemBuilder: (context, index) => MangaCard(
                    key: ValueKey('catalog-${_result!.mangas[index].id}'),
                    manga: _result!.mangas[index],
                  ),
                ),
              ),
            SliverToBoxAdapter(child: _buildPagination()),
            SliverFillRemaining(
              hasScrollBody: false,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [StoreFooter(key: _footerKey)],
              ),
            ),
          ],
        );
      },
    ),
  );

  Widget _buildControls(BuildContext context) => Column(
    key: _catalogKey,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        'ENCONTRE SUA PRÓXIMA LEITURA',
        style: TextStyle(
          color: StoreColors.purple,
          fontWeight: FontWeight.w600,
          fontSize: 12,
          letterSpacing: 1.2,
        ),
      ),
      const SizedBox(height: 10),
      Text(
        _search.isEmpty ? 'Explore o catálogo' : 'Resultados para “$_search”',
        style: Theme.of(context).textTheme.headlineMedium
            ?.copyWith(fontWeight: FontWeight.w700),
      ),
      const SizedBox(height: 24),
      Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          ChoiceChip(
            showCheckmark: false,
            selectedColor: StoreColors.yellow,
            label: const Text('Todas'),
            selected: _category == null,
            onSelected: (_) => _selectCategory(null),
          ),
          for (final category in _categories)
            ChoiceChip(
              showCheckmark: false,
              selectedColor: StoreColors.yellow,
              label: Text(category.name),
              selected: _category == category.slug,
              onSelected: (_) => _selectCategory(category.slug),
            ),
        ],
      ),
      if (_categoriesError != null)
        Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                _categoriesError!,
                style: const TextStyle(color: StoreColors.muted),
              ),
              TextButton(
                onPressed: _loadCategories,
                child: const Text('Tentar carregar categorias'),
              ),
            ],
          ),
        ),
      const SizedBox(height: 24),
      Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 24,
        runSpacing: 16,
        children: [
          Semantics(
            liveRegion: true,
            child: Text(
              _loading
                  ? 'Buscando mangás…'
                  : '${_result?.total ?? 0} resultado(s)',
              style: const TextStyle(color: StoreColors.muted),
            ),
          ),
          SizedBox(
            width: 230,
            child: DropdownButtonFormField<String>(
              isExpanded: true,
              initialValue: _sort,
              decoration: const InputDecoration(
                labelText: 'Ordenar por',
                isDense: true,
              ),
              items: const [
                DropdownMenuItem(value: 'newest', child: Text('Mais recentes')),
                DropdownMenuItem(
                  value: 'price_asc',
                  child: Text('Menor preço'),
                ),
                DropdownMenuItem(
                  value: 'price_desc',
                  child: Text('Maior preço'),
                ),
              ],
              onChanged: (value) {
                if (value == null) return;
                _sort = value;
                _page = 1;
                unawaited(_loadCatalog());
              },
            ),
          ),
        ],
      ),
    ],
  );

  void _selectCategory(String? category) {
    _category = category;
    _page = 1;
    unawaited(_loadCatalog());
  }

  Widget _buildPagination() {
    final result = _result;
    if (_error != null || result == null || result.lastPage <= 1) {
      return const SizedBox(height: 48);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
      child: Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 20,
        runSpacing: 12,
        children: [
          OutlinedButton(
            onPressed: _loading || result.currentPage <= 1
                ? null
                : () => _goToPage(result.currentPage - 1),
            child: const Text('Anterior'),
          ),
          Text('Página ${result.currentPage} de ${result.lastPage}'),
          OutlinedButton(
            onPressed: _loading || result.currentPage >= result.lastPage
                ? null
                : () => _goToPage(result.currentPage + 1),
            child: const Text('Próxima'),
          ),
        ],
      ),
    );
  }

  void _goToPage(int page) {
    _page = page;
    unawaited(_loadCatalog());
    _scrollToCatalog();
  }
}
