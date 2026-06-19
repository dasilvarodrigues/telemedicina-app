import 'package:flutter/foundation.dart';
import '../models/teleconsulta.dart';
import '../services/api_client.dart';
import '../services/teleconsulta_service.dart';

class TeleconsultaProvider extends ChangeNotifier {
  final TeleconsultaService _service;
  Teleconsulta? _currentConsulta;
  Map<String, dynamic>? _accessData;
  List<Teleconsulta> _history = [];
  List<Teleconsulta> _activeList = [];
  bool _loading = false;
  String? _error;

  TeleconsultaProvider(ApiClient client) : _service = TeleconsultaService(client);

  Teleconsulta? get currentConsulta => _currentConsulta;
  Map<String, dynamic>? get accessData => _accessData;
  List<Teleconsulta> get history => _history;
  List<Teleconsulta> get activeList => _activeList;
  bool get loading => _loading;
  String? get error => _error;

  Future<void> create(int pacienteId, {int? agendamentoId}) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final result = await _service.create(pacienteId, agendamentoId: agendamentoId);
      _currentConsulta = Teleconsulta.fromJson(result['data']);
      _accessData = result['access'] as Map<String, dynamic>?;
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> join(int consultaId) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _accessData = await _service.join(consultaId);
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> end(int consultaId) async {
    _error = null;
    try {
      await _service.end(consultaId);
    } catch (e) {
      _error = e.toString();
    }
    _currentConsulta = null;
    _accessData = null;
    notifyListeners();
  }

  Future<void> loadActive() async {
    _error = null;
    try {
      _activeList = await _service.getActive();
    } catch (e) {
      _error = e.toString();
    }
    notifyListeners();
  }

  Future<void> loadHistory() async {
    _error = null;
    try {
      _history = await _service.getHistory();
    } catch (e) {
      _error = e.toString();
    }
    notifyListeners();
  }

  void clear() {
    _currentConsulta = null;
    _accessData = null;
    _error = null;
    notifyListeners();
  }
}
