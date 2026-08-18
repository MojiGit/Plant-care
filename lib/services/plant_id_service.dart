import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import '../config/secrets.dart';
import '../data/models/plant_result.dart';

class PlantIdService {
  static final _dio = Dio(BaseOptions(
    baseUrl: 'https://plant.id',
    headers: {'Api-Key': plantIdApiKey},
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 15),
  ));

  /// Identifica una planta a partir de una imagen local.
  static Future<PlantResult> identify(String imagePath) async {
    final bytes = await File(imagePath).readAsBytes();
    final base64Image = 'data:image/jpeg;base64,${base64Encode(bytes)}';

    final response = await _dio.post(
      '/api/v3/identification',
      queryParameters: {'details': 'common_names,watering'},
      data: {'images': [base64Image], 'similar_images': false},
    );

    final suggestions =
        response.data['result']['classification']['suggestions'] as List;
    if (suggestions.isEmpty) throw Exception('no_suggestions');

    final top = suggestions.first as Map<String, dynamic>;
    final details = (top['details'] ?? {}) as Map<String, dynamic>;

    final commonNames = (details['common_names'] as List?) ?? [];
    final commonName = commonNames.isNotEmpty
        ? commonNames.first as String
        : top['name'] as String;
    final species = top['name'] as String;
    final watering = (details['watering'] as Map?) ?? {};
    final wateringMax = (watering['max'] as num?)?.toInt() ?? 2;

    return PlantResult(
      commonName: commonName,
      species: species,
      wateringMax: wateringMax,
      isToxic: false, // Plant.id v3 no expone toxicidad en este endpoint
    );
  }

  /// Busca una planta por nombre en el knowledge base de Plant.id (2 pasos).
  static Future<PlantResult> search(String name) async {
    try {
      // Paso 1: buscar por nombre → obtener access_token
      final searchResponse = await _dio.get(
        '/api/v3/kb/plants/search',
        queryParameters: {'q': name.trim()},
      );

      final entities = searchResponse.data['entities'] as List;
      if (entities.isEmpty) throw Exception('not_found');

      final entity = entities.first as Map<String, dynamic>;
      final accessToken = entity['access_token'] as String;
      final species = entity['entity_name'] as String? ?? name;

      // Paso 2: pedir detalles con el access_token
      final detailResponse = await _dio.get(
        '/api/v3/kb/plants/$accessToken',
        queryParameters: {'details': 'common_names,watering'},
      );

      final details = (detailResponse.data['details'] ?? {}) as Map<String, dynamic>;
      final commonNames = (details['common_names'] as List?) ?? [];
      final commonName = commonNames.isNotEmpty
          ? commonNames.first as String
          : species;
      final watering = (details['watering'] as Map?) ?? {};
      final wateringMax = (watering['max'] as num?)?.toInt() ?? 2;

      return PlantResult(
        commonName: commonName,
        species: species,
        wateringMax: wateringMax,
        isToxic: false,
      );
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.connectionError) {
        throw Exception('network_error');
      }
      if (e.response?.statusCode == 401) throw Exception('auth_error');
      throw Exception('api_error:${e.response?.statusCode}');
    }
  }
}
