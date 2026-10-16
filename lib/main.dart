import 'package:flutter/material.dart';

import 'data/pokemon_api.dart';
import 'models/pokemon.dart';

void main() {
  runApp(MyApp(repository: PokemonApiService()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, required this.repository});

  final PokemonRepository repository;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pokédex',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF6F5F0),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2D6A5A),
          surface: const Color(0xFFF6F5F0),
        ),
        textTheme: const TextTheme(
          headlineMedium: TextStyle(
            color: Color(0xFF18332E),
            fontWeight: FontWeight.w800,
            letterSpacing: -1.2,
          ),
          titleLarge: TextStyle(
            color: Color(0xFF18332E),
            fontWeight: FontWeight.w800,
          ),
          bodyMedium: TextStyle(color: Color(0xFF66736E)),
        ),
      ),
      home: PokedexPage(repository: repository),
    );
  }
}

class PokedexPage extends StatefulWidget {
  const PokedexPage({super.key, required this.repository});

  final PokemonRepository repository;

  @override
  State<PokedexPage> createState() => _PokedexPageState();
}

class _PokedexPageState extends State<PokedexPage> {
  final _searchController = TextEditingController();
  final _favorites = <int>{};
  Pokemon? _pokemon;
  String? _errorMessage;
  bool _isLoading = true;
  int _requestNumber = 0;

  @override
  void initState() {
    super.initState();
    _loadPokemon('1');
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadPokemon(String identifier) async {
    final requestNumber = ++_requestNumber;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final pokemon = await widget.repository.fetchPokemon(identifier);
      if (!mounted || requestNumber != _requestNumber) return;
      setState(() {
        _pokemon = pokemon;
        _searchController.text = pokemon.name;
        _isLoading = false;
      });
    } on PokemonApiException catch (error) {
      if (!mounted || requestNumber != _requestNumber) return;
      setState(() {
        _errorMessage = error.message;
        _isLoading = false;
      });
    } on FormatException catch (error) {
      if (!mounted || requestNumber != _requestNumber) return;
      setState(() {
        _errorMessage = error.message;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted || requestNumber != _requestNumber) return;
      setState(() {
        _errorMessage =
            'No se pudo conectar. Revisa tu conexión e inténtalo de nuevo.';
        _isLoading = false;
      });
    }
  }

  void _search() {
    final query = _searchController.text.trim();
    if (query.isEmpty) {
      setState(() => _errorMessage = 'Escribe un nombre o número de Pokémon.');
      return;
    }
    if (!RegExp(r'^[a-zA-Z0-9-]+$').hasMatch(query)) {
      setState(
        () => _errorMessage =
            'Usa solo letras, números o guiones para buscar.',
      );
      return;
    }
    _loadPokemon(query);
  }

  void _movePokemon(int offset) {
    final nextId = (_pokemon?.id ?? 1) + offset;
    if (nextId > 0) _loadPokemon('$nextId');
  }

  @override
  Widget build(BuildContext context) {
    final pokemon = _pokemon;
    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          color: const Color(0xFF2D6A5A),
          onRefresh: () => _loadPokemon('${pokemon?.id ?? 1}'),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(22, 18, 22, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 26),
                _buildSearch(),
                if (_errorMessage != null) ...[
                  const SizedBox(height: 16),
                  _buildError(),
                ],
                if (_isLoading && pokemon == null) ...[
                  const SizedBox(height: 70),
                  const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF2D6A5A),
                    ),
                  ),
                  const SizedBox(height: 70),
                ] else if (pokemon != null) ...[
                  const SizedBox(height: 24),
                  _buildPokemonCard(pokemon),
                  const SizedBox(height: 18),
                  _buildStatsCard(pokemon),
                  const SizedBox(height: 18),
                  _buildNavigation(pokemon),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: const Color(0xFF18332E),
            borderRadius: BorderRadius.circular(15),
          ),
          child: const Icon(Icons.catching_pokemon, color: Color(0xFFFFC66D)),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'POKÉDEX',
                style: TextStyle(
                  color: Color(0xFF18332E),
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                ),
              ),
              Text('Tu colección Pokémon', style: TextStyle(fontSize: 12)),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFE7EEE8),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Row(
            children: [
              Icon(Icons.circle, color: Color(0xFF4D9A78), size: 9),
              SizedBox(width: 6),
              Text(
                'EN LÍNEA',
                style: TextStyle(
                  color: Color(0xFF2D6A5A),
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: .6,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSearch() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _searchController,
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => _search(),
            decoration: InputDecoration(
              hintText: 'Busca por nombre o número',
              prefixIcon: const Icon(Icons.search, color: Color(0xFF668078)),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(vertical: 16),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          height: 54,
          width: 54,
          child: FilledButton(
            key: const Key('search-submit'),
            onPressed: _isLoading ? null : _search,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF2D6A5A),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: const Icon(Icons.arrow_forward_rounded),
          ),
        ),
      ],
    );
  }

  Widget _buildError() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFE8E2),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(Icons.wifi_off_rounded, color: Color(0xFFB34E3C)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _errorMessage!,
              style: const TextStyle(color: Color(0xFF8D3F32), fontSize: 13),
            ),
          ),
          IconButton(
            tooltip: 'Reintentar',
            onPressed: _isLoading
                ? null
                : () => _loadPokemon('${_pokemon?.id ?? 1}'),
            icon: const Icon(Icons.refresh, color: Color(0xFF8D3F32)),
          ),
        ],
      ),
    );
  }

  Widget _buildPokemonCard(Pokemon pokemon) {
    final isFavorite = _favorites.contains(pokemon.id);
    final imageUrl = pokemon.officialArtworkUrl ?? pokemon.spriteUrl;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(22, 20, 22, 18),
      decoration: BoxDecoration(
        color: const Color(0xFF18332E),
        borderRadius: BorderRadius.circular(26),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1C18332E),
            blurRadius: 22,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                '#${pokemon.id.toString().padLeft(3, '0')}',
                style: const TextStyle(
                  color: Color(0xFFB9CDC4),
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                ),
              ),
              const Spacer(),
              IconButton(
                tooltip: isFavorite ? 'Quitar de favoritos' : 'Añadir a favoritos',
                onPressed: () {
                  setState(() {
                    if (isFavorite) {
                      _favorites.remove(pokemon.id);
                    } else {
                      _favorites.add(pokemon.id);
                    }
                  });
                },
                icon: Icon(
                  isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: const Color(0xFFFF8B70),
                ),
              ),
            ],
          ),
          Text(
            _capitalize(pokemon.name),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.w800,
              letterSpacing: -.8,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 180,
            child: imageUrl == null
                ? const Center(
                    child: Icon(
                      Icons.catching_pokemon,
                      size: 110,
                      color: Color(0xFF76938A),
                    ),
                  )
                : Image.network(
                    imageUrl,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => const Icon(
                      Icons.catching_pokemon,
                      size: 110,
                      color: Color(0xFF76938A),
                    ),
                  ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: pokemon.types
                .map((type) => _TypeChip(type: type))
                .toList(),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _PokemonMeasure(
                  icon: Icons.height,
                  label: 'ALTURA',
                  value: '${(pokemon.height / 10).toStringAsFixed(1)} m',
                ),
              ),
              Container(width: 1, height: 38, color: const Color(0xFF365149)),
              Expanded(
                child: _PokemonMeasure(
                  icon: Icons.monitor_weight_outlined,
                  label: 'PESO',
                  value: '${(pokemon.weight / 10).toStringAsFixed(1)} kg',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCard(Pokemon pokemon) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.insights_rounded, color: Color(0xFF2D6A5A), size: 20),
              SizedBox(width: 8),
              Text('Estadísticas base', style: TextStyle(fontSize: 16)),
            ],
          ),
          const SizedBox(height: 18),
          ...pokemon.stats.map(
            (stat) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: _StatBar(stat: stat),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigation(Pokemon pokemon) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _isLoading || pokemon.id <= 1
                ? null
                : () => _movePokemon(-1),
            icon: const Icon(Icons.arrow_back_rounded),
            label: const Text('Anterior'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF2D6A5A),
              padding: const EdgeInsets.symmetric(vertical: 15),
              side: const BorderSide(color: Color(0xFFD8E0D9)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: FilledButton.icon(
            onPressed: _isLoading ? null : () => _movePokemon(1),
            icon: const Icon(Icons.arrow_forward_rounded),
            label: const Text('Siguiente'),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF2D6A5A),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _TypeChip extends StatelessWidget {
  const _TypeChip({required this.type});

  final String type;

  @override
  Widget build(BuildContext context) {
    final color = _typeColors[type] ?? const Color(0xFF87948E);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        _typeNames[type] ?? _capitalize(type),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _PokemonMeasure extends StatelessWidget {
  const _PokemonMeasure({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: const Color(0xFFB9CDC4)),
            const SizedBox(width: 5),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFFB9CDC4),
            fontSize: 9,
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }
}

class _StatBar extends StatelessWidget {
  const _StatBar({required this.stat});

  final PokemonStat stat;

  @override
  Widget build(BuildContext context) {
    final progress = (stat.value / 255).clamp(0.0, 1.0);
    return Row(
      children: [
        SizedBox(
          width: 54,
          child: Text(
            _statNames[stat.name] ?? _capitalize(stat.name),
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
          ),
        ),
        SizedBox(
          width: 30,
          child: Text(
            '${stat.value}',
            textAlign: TextAlign.right,
            style: const TextStyle(
              color: Color(0xFF18332E),
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 7,
              backgroundColor: const Color(0xFFEDF0EC),
              color: const Color(0xFF65A982),
            ),
          ),
        ),
      ],
    );
  }
}

String _capitalize(String value) =>
    value.isEmpty ? value : '${value[0].toUpperCase()}${value.substring(1)}';

const _typeColors = <String, Color>{
  'normal': Color(0xFF9A9A74),
  'fire': Color(0xFFE77B51),
  'water': Color(0xFF5C91D6),
  'electric': Color(0xFFD5AC35),
  'grass': Color(0xFF64A66D),
  'ice': Color(0xFF6FBDB9),
  'fighting': Color(0xFFC6534D),
  'poison': Color(0xFF9A65AE),
  'ground': Color(0xFFBF9254),
  'flying': Color(0xFF8D8BCB),
  'psychic': Color(0xFFE27091),
  'bug': Color(0xFF8C9D40),
  'rock': Color(0xFF9E8956),
  'ghost': Color(0xFF71659B),
  'dragon': Color(0xFF6A70C3),
  'dark': Color(0xFF655A54),
  'steel': Color(0xFF8996A6),
  'fairy': Color(0xFFD77BA7),
};

const _typeNames = <String, String>{
  'normal': 'Normal',
  'fire': 'Fuego',
  'water': 'Agua',
  'electric': 'Eléctrico',
  'grass': 'Planta',
  'ice': 'Hielo',
  'fighting': 'Lucha',
  'poison': 'Veneno',
  'ground': 'Tierra',
  'flying': 'Volador',
  'psychic': 'Psíquico',
  'bug': 'Bicho',
  'rock': 'Roca',
  'ghost': 'Fantasma',
  'dragon': 'Dragón',
  'dark': 'Siniestro',
  'steel': 'Acero',
  'fairy': 'Hada',
};

const _statNames = <String, String>{
  'hp': 'PS',
  'attack': 'Ataque',
  'defense': 'Defensa',
  'special-attack': 'At. esp.',
  'special-defense': 'Def. esp.',
  'speed': 'Velocidad',
};
