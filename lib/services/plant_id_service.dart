import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import '../config/secrets.dart';
import '../data/models/plant_result.dart';

Map<String, dynamic> _asMap(dynamic value) =>
    Map<String, dynamic>.from(value as Map);

const _details = 'watering,description,edible_parts,propagation_methods,taxonomy';

PlantResult _parseDetails(String species, Map<String, dynamic> details) {
  debugPrint('>>> _parseDetails for $species: keys=${details.keys.toList()}');
  debugPrint('>>> family raw: ${details['taxonomy']}');
  debugPrint('>>> description raw: ${details['description']}');
  debugPrint('>>> edible_parts raw: ${details['edible_parts']}');
  debugPrint('>>> propagation_methods raw: ${details['propagation_methods']}');
  final watering = details['watering'] != null ? _asMap(details['watering']) : <String, dynamic>{};
  final wateringMax = (watering['max'] as num?)?.toInt() ?? 2;

  final taxonomy = details['taxonomy'] != null ? _asMap(details['taxonomy']) : <String, dynamic>{};
  final family = taxonomy['family'] as String?;

  final description = (details['description'] as Map?)?['value'] as String?
      ?? details['description'] as String?;

  final edibleParts = (details['edible_parts'] as List?)
      ?.map((e) => e.toString()).toList() ?? [];

  final propagationMethods = (details['propagation_methods'] as List?)
      ?.map((e) => e.toString()).toList() ?? [];

  return PlantResult(
    species: species,
    wateringMax: wateringMax,
    isToxic: false,
    family: family,
    description: description,
    edibleParts: edibleParts,
    propagationMethods: propagationMethods,
  );
}

class PlantIdService {
  static final _dio = Dio(BaseOptions(
    baseUrl: 'https://plant.id',
    headers: {'Api-Key': plantIdApiKey},
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 15),
  ));

  static Future<PlantResult> identify(String imagePath) async {
    try {
      final bytes = await File(imagePath).readAsBytes();
      final base64Image = 'data:image/jpeg;base64,${base64Encode(bytes)}';

      final response = await _dio.post(
        '/api/v3/identification',
        queryParameters: {'details': _details},
        data: {'images': [base64Image], 'similar_images': false},
      );

      final suggestions =
          response.data['result']['classification']['suggestions'] as List;
      if (suggestions.isEmpty) throw Exception('no_suggestions');

      final top = _asMap(suggestions.first);
      final details = top['details'] != null ? _asMap(top['details']) : <String, dynamic>{};
      return _parseDetails(top['name'] as String, details);
    } on DioException catch (e) {
      _throwTyped(e);
    }
  }

  static Future<PlantResult> search(String name) async {
    try {
      final searchResponse = await _dio.get(
        '/api/v3/kb/plants/name_search',
        queryParameters: {'q': name.trim(), 'lang': 'es'},
      );

      final entities = searchResponse.data['entities'] as List;
      if (entities.isEmpty) throw Exception('not_found');

      final entity = _asMap(entities.first);
      final accessToken = entity['access_token'] as String;
      final species = entity['entity_name'] as String? ?? name;

      final detailResponse = await _dio.get(
        '/api/v3/kb/plants/$accessToken',
        queryParameters: {'details': _details},
      );

      final details = detailResponse.data['details'] != null
          ? _asMap(detailResponse.data['details'])
          : <String, dynamic>{};
      return _parseDetails(species, details);
    } on DioException catch (e) {
      _throwTyped(e);
    }
  }

  static Never _throwTyped(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.connectionError) {
      throw Exception('network_error');
    }
    if (e.response?.statusCode == 401) throw Exception('auth_error');
    throw Exception('api_error:${e.response?.statusCode}');
  }
}
