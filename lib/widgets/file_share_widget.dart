import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/api_client.dart';

class FileShareWidget extends StatefulWidget {
  final int consultaId;
  final ApiClient apiClient;

  const FileShareWidget({
    super.key,
    required this.consultaId,
    required this.apiClient,
  });

  @override
  State<FileShareWidget> createState() => _FileShareWidgetState();
}

class _FileShareWidgetState extends State<FileShareWidget> {
  final _files = <Map<String, String>>[];
  final _picker = ImagePicker();
  bool _uploading = false;

  @override
  void initState() {
    super.initState();
    _loadFiles();
  }

  Future<void> _loadFiles() async {
    try {
      final response = await widget.apiClient.get('/teleconsultas/${widget.consultaId}/files');
      final data = response.data['data'];
      if (data is List) {
        setState(() {
          _files.clear();
          for (final f in data) {
            _files.add({
              'name': f['nome_original'] ?? f['name'] ?? 'Arquivo',
              'size': _formatSize(f['tamanho_bytes']),
              'url': f['url'] ?? '',
            });
          }
        });
      }
    } catch (_) {}
  }

  String _formatSize(dynamic bytes) {
    if (bytes == null) return '';
    final b = int.tryParse(bytes.toString()) ?? 0;
    if (b < 1024) return '${b}B';
    if (b < 1024 * 1024) return '${(b / 1024).toStringAsFixed(1)}KB';
    return '${(b / (1024 * 1024)).toStringAsFixed(1)}MB';
  }

  Future<void> _pickAndUpload() async {
    final file = await _picker.pickImage(source: ImageSource.gallery);
    if (file == null) return;

    setState(() => _uploading = true);
    try {
      await widget.apiClient.uploadFile(
        '/teleconsultas/${widget.consultaId}/files',
        file.path,
      );
      await _loadFiles();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao enviar: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey[100],
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            color: Colors.green,
            child: const Text('Arquivos', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
          Expanded(
            child: _files.isEmpty
                ? const Center(child: Text('Nenhum arquivo'))
                : ListView.builder(
                    itemCount: _files.length,
                    itemBuilder: (_, i) => ListTile(
                      leading: const Icon(Icons.insert_drive_file),
                      title: Text(_files[i]['name'] ?? ''),
                      subtitle: Text(_files[i]['size'] ?? ''),
                      dense: true,
                    ),
                  ),
          ),
          if (_uploading)
            const Padding(
              padding: EdgeInsets.all(8),
              child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
            )
          else
            TextButton.icon(
              onPressed: _pickAndUpload,
              icon: const Icon(Icons.attach_file),
              label: const Text('Adicionar'),
            ),
        ],
      ),
    );
  }
}
