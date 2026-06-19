import 'package:dio/dio.dart';
import '../models/fila_virtual.dart';
import '../models/fila_paciente.dart';
import 'api_client.dart';

class FilaService {
  final ApiClient _client;

  FilaService(this._client);

  Future<List<FilaVirtual>> getFilasAbertas() async {
    final response = await _client.get('/filas');
    final list = response.data['data'] as List;
    return list.map((e) => FilaVirtual.fromJson(e)).toList();
  }

  Future<FilaPaciente> entrarFila(int filaId, int pacienteId) async {
    final response = await _client.post('/filas/$filaId/entrar', data: {
      'paciente_id': pacienteId,
    });
    return FilaPaciente.fromJson(response.data['data']);
  }

  Future<void> sairFila(int filaId, int pacienteId) async {
    await _client.post('/filas/$filaId/sair', data: {
      'paciente_id': pacienteId,
    });
  }

  Future<List<FilaPaciente>> getPacientes(int filaId) async {
    final response = await _client.get('/filas/$filaId/pacientes');
    final list = response.data['data'] as List;
    return list.map((e) => FilaPaciente.fromJson(e)).toList();
  }

  Future<FilaPaciente?> chamarProximo(int filaId) async {
    try {
      final response = await _client.post('/filas/$filaId/chamar-proximo');
      return FilaPaciente.fromJson(response.data['data']);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      rethrow;
    }
  }

  Future<void> marcarAusente(int filaId, int filaPacienteId) async {
    await _client.post('/filas/$filaId/ausente/$filaPacienteId');
  }

  Future<void> atender(int filaId, int filaPacienteId) async {
    await _client.post('/filas/$filaId/atender/$filaPacienteId');
  }

  Future<Map<String, dynamic>> getMinhaPosicao(int pacienteId) async {
    final response = await _client.get('/minha-posicao/$pacienteId');
    return response.data['data'];
  }
}
