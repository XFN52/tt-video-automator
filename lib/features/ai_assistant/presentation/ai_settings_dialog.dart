import 'package:flutter/material.dart';
import '../../../core/services/app_settings_service.dart';
import '../data/ai_assistant_service.dart';

class AiSettingsDialog extends StatefulWidget {
  const AiSettingsDialog({super.key});

  @override
  State<AiSettingsDialog> createState() => _AiSettingsDialogState();
}

class _AiSettingsDialogState extends State<AiSettingsDialog> {
  late TextEditingController _apiKeyController;
  late TextEditingController _baseUrlController;
  late TextEditingController _modelController;
  late bool _autoHooks;
  late bool _autoPosts;
  String _selectedProvider = 'deepseek';
  bool _isTesting = false;
  String? _testResult;
  bool? _testSuccess;

  @override
  void initState() {
    super.initState();
    final settings = AppSettingsService.instance;
    _apiKeyController =
        TextEditingController(text: settings.getString(AppSettingsService.keyAiApiKey) ?? '');
    _baseUrlController = TextEditingController(
      text: settings.getString(AppSettingsService.keyAiBaseUrl) ??
          'https://api.deepseek.com/v1',
    );
    _modelController = TextEditingController(
      text: settings.getString(AppSettingsService.keyAiModel) ?? 'deepseek-chat',
    );
    _selectedProvider =
        settings.getString(AppSettingsService.keyAiProvider) ?? 'deepseek';
    _autoHooks = settings.getBool(
      AppSettingsService.keyAiAutoGenerateHooks,
      defaultValue: true,
    );
    _autoPosts = settings.getBool(
      AppSettingsService.keyAiAutoGeneratePosts,
      defaultValue: true,
    );
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    _baseUrlController.dispose();
    _modelController.dispose();
    super.dispose();
  }

  void _applyProviderPreset(String provider) {
    setState(() {
      _selectedProvider = provider;
      switch (provider) {
        case 'deepseek':
          _baseUrlController.text = 'https://api.deepseek.com/v1';
          _modelController.text = 'deepseek-chat';
          break;
        case 'anymodel':
          _baseUrlController.text = 'https://anymodel.org/v1';
          _modelController.text = 'ag/gemini-3.7-flash-high';
          break;
        case 'openai':
          _baseUrlController.text = 'https://api.openai.com/v1';
          _modelController.text = 'gpt-4o-mini';
          break;
        case 'ollama':
          _baseUrlController.text = 'http://localhost:11434/v1';
          _modelController.text = 'llama3';
          break;
        case 'openrouter':
          _baseUrlController.text = 'https://openrouter.ai/api/v1';
          _modelController.text = 'deepseek/deepseek-chat';
          break;
        case 'custom':
          break;
      }
    });
  }

  Future<void> _testConnection() async {
    setState(() {
      _isTesting = true;
      _testResult = null;
      _testSuccess = null;
    });

    // Временно сохраняем в настройки для проверки
    final settings = AppSettingsService.instance;
    await settings.setString(
      AppSettingsService.keyAiApiKey,
      _apiKeyController.text.trim(),
    );
    await settings.setString(
      AppSettingsService.keyAiBaseUrl,
      _baseUrlController.text.trim(),
    );
    await settings.setString(
      AppSettingsService.keyAiModel,
      _modelController.text.trim(),
    );

    final (success, msg) = await AiAssistantService.instance.testConnection();

    if (mounted) {
      setState(() {
        _isTesting = false;
        _testSuccess = success;
        _testResult = msg;
      });
    }
  }

  Future<void> _save() async {
    final settings = AppSettingsService.instance;
    await settings.setString(
      AppSettingsService.keyAiApiKey,
      _apiKeyController.text.trim(),
    );
    await settings.setString(
      AppSettingsService.keyAiBaseUrl,
      _baseUrlController.text.trim(),
    );
    await settings.setString(
      AppSettingsService.keyAiModel,
      _modelController.text.trim(),
    );
    await settings.setString(
      AppSettingsService.keyAiProvider,
      _selectedProvider,
    );
    await settings.setBool(
      AppSettingsService.keyAiAutoGenerateHooks,
      _autoHooks,
    );
    await settings.setBool(
      AppSettingsService.keyAiAutoGeneratePosts,
      _autoPosts,
    );

    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Настройки ИИ-ассистента сохранены!'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.smart_toy_outlined, color: Color(0xFF25F4EE)),
          SizedBox(width: 10),
          Text('Настройки ИИ-Ассистента (LLM)'),
        ],
      ),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Выберите провайдера нейросети:',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  ChoiceChip(
                    label: const Text('DeepSeek'),
                    selected: _selectedProvider == 'deepseek',
                    onSelected: (_) => _applyProviderPreset('deepseek'),
                  ),
                  ChoiceChip(
                    label: const Text('AnyModel'),
                    selected: _selectedProvider == 'anymodel',
                    onSelected: (_) => _applyProviderPreset('anymodel'),
                  ),
                  ChoiceChip(
                    label: const Text('OpenAI (GPT-4o)'),
                    selected: _selectedProvider == 'openai',
                    onSelected: (_) => _applyProviderPreset('openai'),
                  ),
                  ChoiceChip(
                    label: const Text('Ollama (Локально)'),
                    selected: _selectedProvider == 'ollama',
                    onSelected: (_) => _applyProviderPreset('ollama'),
                  ),
                  ChoiceChip(
                    label: const Text('OpenRouter'),
                    selected: _selectedProvider == 'openrouter',
                    onSelected: (_) => _applyProviderPreset('openrouter'),
                  ),
                  ChoiceChip(
                    label: const Text('Custom URL'),
                    selected: _selectedProvider == 'custom',
                    onSelected: (_) => _applyProviderPreset('custom'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _apiKeyController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: _selectedProvider == 'ollama'
                      ? 'API Key (не требуется для локальной Ollama)'
                      : 'API Key (sk-...)',
                  hintText: _selectedProvider == 'ollama'
                      ? 'Оставьте пустым'
                      : 'Вставьте ваш API ключ',
                  prefixIcon: const Icon(Icons.key),
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _baseUrlController,
                decoration: const InputDecoration(
                  labelText: 'Base URL эндпоинта',
                  hintText: 'https://api.deepseek.com/v1',
                  prefixIcon: Icon(Icons.link),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _modelController,
                decoration: const InputDecoration(
                  labelText: 'Имя модели',
                  hintText: 'deepseek-chat, gpt-4o-mini, llama3',
                  prefixIcon: Icon(Icons.psychology),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 14),
              const Divider(),
              const SizedBox(height: 6),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Авто-генерация заголовка-хука'),
                subtitle: const Text(
                  'ИИ придумывает вирусный заголовок на плашку сверху по транскрипту Whisper.',
                  style: TextStyle(fontSize: 11),
                ),
                value: _autoHooks,
                onChanged: (val) => setState(() => _autoHooks = val),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Авто-сохранение текста поста (.txt)'),
                subtitle: const Text(
                  'Создает файл с описанием, CTA и хэштегами рядом с готовым MP4.',
                  style: TextStyle(fontSize: 11),
                ),
                value: _autoPosts,
                onChanged: (val) => setState(() => _autoPosts = val),
              ),
              const SizedBox(height: 10),
              if (_testResult != null)
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _testSuccess == true
                        ? Colors.green.withValues(alpha: 0.15)
                        : Colors.red.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: _testSuccess == true ? Colors.green : Colors.red,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _testSuccess == true
                            ? Icons.check_circle_outline
                            : Icons.error_outline,
                        color: _testSuccess == true ? Colors.green : Colors.red,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _testResult!,
                          style: TextStyle(
                            color: _testSuccess == true
                                ? Colors.greenAccent
                                : Colors.redAccent,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
      actions: [
        OutlinedButton.icon(
          onPressed: _isTesting ? null : _testConnection,
          icon: _isTesting
              ? const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.wifi_tethering, size: 16),
          label: const Text('ТЕСТ СВЯЗИ'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('ОТМЕНА'),
        ),
        FilledButton(
          onPressed: _save,
          child: const Text('СОХРАНИТЬ'),
        ),
      ],
    );
  }
}
