import 'package:flutter/foundation.dart';
import '../models/fila_virtual.dart';
import '../models/fila_paciente.dart';
import '../services/api_client.dart';
import '../services/fila_service.dart';

class FilaProvider extends ChangeNotifier {
  final FilaService _service;
  List<FilaVirtual> _filas = [];
  List<FilaPaciente> _pacientes = [];
  Map<String, dynamic>? _minhaPosicao;
  bool _loading = false;
  String? _error;

  FilaProvider(ApiClient client) : _service = FilaService(client);

  List<FilaVirtual> get filas => _filas;
  List<FilaPaciente> get pacientes => _pacientes;
  Map<String, dynamic>? get minhaPosicao => _minhaPosicao;
  bool get loading => _loading;
  String? get error => _error;

  void _setError(dynamic e) {
    _error = e.toString();
    notifyListeners();
  }

  Future<void> loadFilas() async {
    _error = null;
    try {
      _filas = await _service.getFilasAbertas();
    } catch (e) {
      _setError(e);
    }
    notifyListeners();
  }

  Future<void> loadPacientes(int filaId) async {
    _error = null;
    try {
      _pacientes = await _service.getPacientes(filaId);
    } catch (e) {
      _setError(e);
    }
    notifyListeners();
  }

  Future<void> entrarFila(int filaId, int pacienteId) async {
    _error = null;
    try {
      await _service.entrarFila(filaId, pacienteId);
      await carregarMinhaPosicao(pacienteId);
    } catch (e) {
      _setError(e);
    }
  }

  Future<void> sairFila(int filaId, int pacienteId) async {
    _error = null;
    try {
      await _service.sairFila(filaId, pacienteId);
      _minhaPosicao = null;
    } catch (e) {
      _setError(e);
    }
    notifyListeners();
  }

  Future<FilaPaciente?> chamarProximo(int filaId) async {
    _error = null;
    try {
      final proximo = await _service.chamarProximo(filaId);
      await loadPacientes(filaId);
      return proximo;
    } catch (e) {
      _setError(e);
      return null;
    }
  }

  Future<void> marcarAusente(int filaId, int filaPacienteId) async {
    _error = null;
    try {
      await _service.marcarAusente(filaId, filaPacienteId);
      await loadPacientes(filaId);
    } catch (e) {
      _setError(e);
    }
  }

  Future<void> atender(int filaId, int filaPacienteId) async {
    _error = null;
    try {
      await _service.atender(filaId, filaPacienteId);
      await loadPacientes(filaId);
    } catch (e) {
      _setError(e);
    }
  }

  Future<void> carregarMinhaPosicao(int pacienteId) async {
    _error = null;
    try {
      _minhaPosicao = await _service.getMinhaPosicao(pacienteId);
    } catch (e) {
      _setError(e);
    }
    notifyListeners();
  }
}
