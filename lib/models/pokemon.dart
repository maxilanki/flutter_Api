class Pokemon {
  const Pokemon({
    required this.id,
    required this.name,
    required this.height,
    required this.weight,
    required this.types,
    required this.stats,
    this.officialArtworkUrl,
    this.spriteUrl,
  });

  factory Pokemon.fromJson(Map<String, dynamic> json) {
    final sprites = json['sprites'] as Map<String, dynamic>? ?? const {};
    final other = sprites['other'] as Map<String, dynamic>? ?? const {};
    final artwork =
        other['official-artwork'] as Map<String, dynamic>? ?? const {};
    final typeEntries = json['types'] as List<dynamic>? ?? const [];
    final statEntries = json['stats'] as List<dynamic>? ?? const [];

    return Pokemon(
      id: json['id'] as int,
      name: json['name'] as String,
      height: json['height'] as int,
      weight: json['weight'] as int,
      types: typeEntries
          .map(
            (entry) => (entry as Map<String, dynamic>)['type']
                as Map<String, dynamic>,
          )
          .map((type) => type['name'] as String)
          .toList(growable: false),
      stats: statEntries
          .map((entry) => entry as Map<String, dynamic>)
          .map(
            (entry) => PokemonStat(
              name: (entry['stat'] as Map<String, dynamic>)['name'] as String,
              value: entry['base_stat'] as int,
            ),
          )
          .toList(growable: false),
      officialArtworkUrl: artwork['front_default'] as String?,
      spriteUrl: sprites['front_default'] as String?,
    );
  }

  final int id;
  final String name;
  final int height;
  final int weight;
  final List<String> types;
  final List<PokemonStat> stats;
  final String? officialArtworkUrl;
  final String? spriteUrl;
}

class PokemonStat {
  const PokemonStat({required this.name, required this.value});

  final String name;
  final int value;
}
