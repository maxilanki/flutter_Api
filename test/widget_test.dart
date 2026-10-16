import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:flutter_api/data/pokemon_api.dart';
import 'package:flutter_api/main.dart';
import 'package:flutter_api/models/pokemon.dart';

void main() {
  testWidgets('shows the first Pokémon and supports favorites and navigation', (
    tester,
  ) async {
    final repository = _FakePokemonRepository();
    await tester.pumpWidget(MyApp(repository: repository));
    await tester.pumpAndSettle();

    expect(find.text('Bulbasaur'), findsOneWidget);
    expect(find.text('#001'), findsOneWidget);
    expect(find.text('Planta'), findsOneWidget);

    await tester.tap(find.byTooltip('Añadir a favoritos'));
    await tester.pump();
    expect(find.byTooltip('Quitar de favoritos'), findsOneWidget);

    await tester.ensureVisible(find.text('Siguiente'));
    await tester.tap(find.text('Siguiente'));
    await tester.pumpAndSettle();
    expect(find.text('Ivysaur'), findsOneWidget);
    expect(repository.requests, ['1', '2']);
  });

  testWidgets('searches by name', (tester) async {
    final repository = _FakePokemonRepository();
    await tester.pumpWidget(MyApp(repository: repository));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'pikachu');
    await tester.tap(find.byKey(const Key('search-submit')));
    await tester.pumpAndSettle();

    expect(find.text('Pikachu'), findsOneWidget);
    expect(repository.requests, ['1', 'pikachu']);
  });

  test('requests and parses a Pokémon from the PokeAPI endpoint', () async {
    late Uri requestedUri;
    final client = MockClient((request) async {
      requestedUri = request.url;
      return http.Response(
        jsonEncode({
          'id': 1,
          'name': 'bulbasaur',
          'height': 7,
          'weight': 69,
          'sprites': {
            'front_default': 'https://example.com/sprite.png',
            'other': {
              'official-artwork': {
                'front_default': 'https://example.com/artwork.png',
              },
            },
          },
          'types': [
            {
              'type': {'name': 'grass'},
            },
            {
              'type': {'name': 'poison'},
            },
          ],
          'stats': [
            {
              'base_stat': 45,
              'stat': {'name': 'hp'},
            },
          ],
        }),
        200,
      );
    });

    final pokemon = await PokemonApiService(client: client).fetchPokemon('1');

    expect(requestedUri.host, 'pokeapi.co');
    expect(requestedUri.path, '/api/v2/pokemon/1');
    expect(pokemon.name, 'bulbasaur');
    expect(pokemon.types, ['grass', 'poison']);
    expect(pokemon.stats.single.value, 45);
    expect(pokemon.officialArtworkUrl, 'https://example.com/artwork.png');
  });
}

class _FakePokemonRepository implements PokemonRepository {
  final requests = <String>[];

  @override
  Future<Pokemon> fetchPokemon(String identifier) async {
    requests.add(identifier);
    final id = int.tryParse(identifier) ?? 25;
    final name = switch (identifier) {
      '1' => 'bulbasaur',
      '2' => 'ivysaur',
      'pikachu' => 'pikachu',
      _ => 'pokemon',
    };
    return Pokemon(
      id: id,
      name: name,
      height: 7,
      weight: 69,
      types: const ['grass'],
      stats: const [PokemonStat(name: 'hp', value: 45)],
    );
  }
}
