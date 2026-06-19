import 'package:flutter/material.dart';
import '../models/prescricao.dart';
import '../services/api_client.dart';
import '../services/prescricao_service.dart';

class PrescricaoFormScreen extends StatefulWidget {
  final Prescricao? prescricao;
  final int? teleconsultaId;
  final int? pacienteId;

  const PrescricaoFormScreen({super.key, this.prescricao, this.teleconsultaId, this.pacienteId});

  @override
  State<PrescricaoFormScreen> createState() => _PrescricaoFormScreenState();
}

class _PrescricaoFormScreenState extends State<PrescricaoFormScreen> {
  final _pacienteIdCtrl = TextEditingController();
  final _conteudoCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _medicamentos = <_MedicamentoForm>[];
  bool _saving = false;
  bool _isEdit = false;

  @override
  void initState() {
    super.initState();
    if (widget.pacienteId != null) {
      _pacienteIdCtrl.text = widget.pacienteId.toString();
    }
    if (widget.prescricao != null) {
      _isEdit = true;
      _conteudoCtrl.text = widget.prescricao!.conteudo;
      for (final m in widget.prescricao!.medicamentos) {
        _medicamentos.add(_MedicamentoForm(
          nomeCtrl: TextEditingController(text: m.nome),
          dosagemCtrl: TextEditingController(text: m.dosagem),
          quantidadeCtrl: TextEditingController(text: m.quantidade.toString()),
          instrucoesCtrl: TextEditingController(text: m.instrucoes),
        ));
      }
    }
  }

  @override
  void dispose() {
    _pacienteIdCtrl.dispose();
    _conteudoCtrl.dispose();
    for (final m in _medicamentos) {
      m.dispose();
    }
    super.dispose();
  }

  void _addMedicamento() {
    setState(() {
      _medicamentos.add(_MedicamentoForm(
        nomeCtrl: TextEditingController(),
        dosagemCtrl: TextEditingController(),
        quantidadeCtrl: TextEditingController(),
        instrucoesCtrl: TextEditingController(),
      ));
    });
  }

  void _removeMedicamento(int index) {
    setState(() {
      _medicamentos[index].dispose();
      _medicamentos.removeAt(index);
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final medicamentos = _medicamentos.map((m) => {
      'nome': m.nomeCtrl.text,
      'dosagem': m.dosagemCtrl.text,
      'quantidade': int.tryParse(m.quantidadeCtrl.text) ?? 0,
      'instrucoes': m.instrucoesCtrl.text,
    }).toList();

    try {
      final service = PrescricaoService(ApiClient());
      if (_isEdit) {
        await service.atualizar(widget.prescricao!.id,
          conteudo: _conteudoCtrl.text,
          medicamentos: medicamentos,
        );
      } else {
        await service.criar(
          pacienteId: int.parse(_pacienteIdCtrl.text),
          conteudo: _conteudoCtrl.text,
          medicamentos: medicamentos,
          teleconsultaId: widget.teleconsultaId,
        );
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_isEdit ? 'Prescrição atualizada!' : 'Prescrição criada!')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? 'Editar Prescrição' : 'Nova Prescrição')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (!_isEdit)
              TextFormField(
                controller: _pacienteIdCtrl,
                decoration: const InputDecoration(labelText: 'ID do Paciente'),
                keyboardType: TextInputType.number,
                enabled: widget.pacienteId == null,
                validator: (v) => (v?.isEmpty ?? true) ? 'Obrigatório' : null,
              ),
            if (widget.teleconsultaId != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text('Vinculado à consulta #${widget.teleconsultaId}',
                    style: TextStyle(color: Colors.grey[600], fontSize: 13)),
              ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _conteudoCtrl,
              decoration: const InputDecoration(labelText: 'Recomendações', alignLabelWithHint: true),
              maxLines: 4,
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Medicamentos', style: Theme.of(context).textTheme.titleMedium),
                TextButton.icon(
                  onPressed: _addMedicamento,
                  icon: const Icon(Icons.add),
                  label: const Text('Adicionar'),
                ),
              ],
            ),
            ..._medicamentos.asMap().entries.map((entry) {
              final i = entry.key;
              final m = entry.value;
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: m.nomeCtrl,
                              decoration: const InputDecoration(labelText: 'Nome', isDense: true),
                              validator: (v) => (v?.isEmpty ?? true) ? 'Obrigatório' : null,
                            ),
                          ),
                          const SizedBox(width: 8),
                          SizedBox(
                            width: 100,
                            child: TextFormField(
                              controller: m.dosagemCtrl,
                              decoration: const InputDecoration(labelText: 'Dosagem', isDense: true),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _removeMedicamento(i),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          SizedBox(
                            width: 80,
                            child: TextFormField(
                              controller: m.quantidadeCtrl,
                              decoration: const InputDecoration(labelText: 'Qtd', isDense: true),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextFormField(
                              controller: m.instrucoesCtrl,
                              decoration: const InputDecoration(labelText: 'Instruções', isDense: true),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                    : Text(_isEdit ? 'Atualizar' : 'Criar Prescrição'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MedicamentoForm {
  final TextEditingController nomeCtrl;
  final TextEditingController dosagemCtrl;
  final TextEditingController quantidadeCtrl;
  final TextEditingController instrucoesCtrl;

  _MedicamentoForm({
    required this.nomeCtrl,
    required this.dosagemCtrl,
    required this.quantidadeCtrl,
    required this.instrucoesCtrl,
  });

  void dispose() {
    nomeCtrl.dispose();
    dosagemCtrl.dispose();
    quantidadeCtrl.dispose();
    instrucoesCtrl.dispose();
  }
}
