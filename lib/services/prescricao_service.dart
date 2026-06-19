import '../config/api_config.dart';
import '../models/prescricao.dart';
import 'api_client.dart';

class PrescricaoService {
  final ApiClient _client;

  PrescricaoService(this._client);

  Future<Prescricao> criar({
    required int pacienteId,
    required String conteudo,
    required List<Map<String, dynamic>> medicamentos,
    int? teleconsultaId,
  }) async {
    final response = await _client.post('/prescricoes', data: {
      'paciente_id': pacienteId,
      'conteudo': conteudo,
      'medicamentos': medicamentos,
      'teleconsulta_id': teleconsultaId,
    });
    return Prescricao.fromJson(response.data['data']);
  }

  Future<Prescricao> atualizar(int id, {
    required String conteudo,
    required List<Map<String, dynamic>> medicamentos,
  }) async {
    final response = await _client.put('/prescricoes/$id', data: {
      'conteudo': conteudo,
      'medicamentos': medicamentos,
    });
    return Prescricao.fromJson(response.data['data']);
  }

  Future<Prescricao> assinar(int id) async {
    final response = await _client.post('/prescricoes/$id/sign');
    return Prescricao.fromJson(response.data['data']);
  }

  Future<Prescricao> getPrescricao(int id) async {
    final response = await _client.get('/prescricoes/$id');
    return Prescricao.fromJson(response.data['data']);
  }

  Future<List<Prescricao>> getHistory() async {
    final response = await _client.get('/prescricoes/history');
    final list = response.data['data']['data'] as List;
    return list.map((e) => Prescricao.fromJson(e)).toList();
  }

  Future<List<Prescricao>> getPatientHistory() async {
    final response = await _client.get('/paciente/prescricoes');
    final list = response.data['data'] as List;
    return list.map((e) => Prescricao.fromJson(e)).toList();
  }

  Future<String> downloadPdfUrl(int id) async {
    return '${ApiConfig.baseUrl}/prescricoes/$id/pdf';
  }
}
