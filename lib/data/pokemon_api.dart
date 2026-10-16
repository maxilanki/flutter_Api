import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/pokemon.dart';

abstract interface class PokemonRepository {
  Future<Pokemon> fetchPokemon(String identifier);
}

class PokemonApiService implements PokemonRepository {
  PokemonApiService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  @override
  Future<Pokemon> fetchPokemon(String identifier) async {
    final normalized = identifier.trim().toLowerCase();
    if (!RegExp(r'^[a-z0-9-]+$').hasMatch(normalized)) {
      throw const FormatException('Nombre o número de Pokémon no válido.');
    }

    final uri = Uri.https('pokeapi.co', '/api/v2/pokemon/$normalized');
    final response = await _client.get(uri);
    if (response.statusCode != 200) {
      throw PokemonApiException(
        response.statusCode == 404
            ? 'No encontramos ese Pokémon. Prueba con otro nombre o número.'
            : 'La PokéAPI respondió con el error ${response.statusCode}.',
      );
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return Pokemon.fromJson(json);
  }
}

class PokemonApiException implements Exception {
  const PokemonApiException(this.message);

  final String message;
}
