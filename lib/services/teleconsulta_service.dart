
import '../models/teleconsulta.dart';
import 'api_client.dart';

class TeleconsultaService {
  final ApiClient _client;

  TeleconsultaService(this._client);

  Future<Map<String, dynamic>> create(int pacienteId, {int? agendamentoId}) async {
    final response = await _client.post('/teleconsultas', data: {
      'paciente_id': pacienteId,
      'agendamento_id': agendamentoId,
    });
    return response.data;
  }

  Future<Map<String, dynamic>> join(int consultaId) async {
    final response = await _client.get('/teleconsultas/$consultaId/join');
    return response.data['data'];
  }

  Future<void> end(int consultaId) async {
    await _client.post('/teleconsultas/$consultaId/end');
  }

  Future<Teleconsulta> getStatus(int consultaId) async {
    final response = await _client.get('/teleconsultas/$consultaId/status');
    return Teleconsulta.fromJson(response.data['data']);
  }

  Future<List<Teleconsulta>> getHistory() async {
    final response = await _client.get('/teleconsultas/history');
    final list = response.data['data']['data'] as List;
    return list.map((e) => Teleconsulta.fromJson(e)).toList();
  }

  Future<List<Teleconsulta>> getActive() async {
    final response = await _client.get('/teleconsultas/ativas');
    final list = response.data['data'] as List;
    return list.map((e) => Teleconsulta.fromJson(e)).toList();
  }

  Future<void> uploadFile(int consultaId, String filePath) async {
    await _client.uploadFile('/teleconsultas/$consultaId/files', filePath);
  }
}
