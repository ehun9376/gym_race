import "package:easy_localization/easy_localization.dart";
import "package:flutter/material.dart";
import "package:provider/provider.dart";

import "../../../../core/di/get_it_service.dart";
import "../../../../core/simple_widget/default_scaffold.dart";
import "../../../../core/simple_widget/simple_button.dart";
import "../../../../core/simple_widget/simple_text.dart";
import "../../../../core/simple_widget/simple_text_field.dart";
import "../../../../core/utility/design_color.dart";
import "../../../../core/utility/widget_fixer.dart";
import "../../../auth/data/services/auth_service.dart";
import "../../data/models/training_log_entry.dart";
import "../../data/models/voice_log_result.dart";
import "../../data/services/speech_service.dart";
import "../../data/services/voice_intent_channel.dart";
import "../view_models/voice_record_view_model.dart";

/// 語音記錄頁（依 CLAUDE.md：DefaultScaffold + Simple 系列 + widget_fixer，
/// Selector 精準監聽、func 內直接用 widget.viewModel）。
class VoiceRecordPage extends StatefulWidget {
  const VoiceRecordPage({super.key});

  @override
  State<VoiceRecordPage> createState() => _VoiceRecordPageState();
}

class _VoiceRecordPageState extends State<VoiceRecordPage>
    with WidgetsBindingObserver {
  final VoiceRecordViewModel viewModel = getIt<VoiceRecordViewModel>();
  final AuthService _authService = getIt<AuthService>();
  final SpeechService _speechService = getIt<SpeechService>();
  final TextEditingController _controller = TextEditingController();

  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _init();
  }

  /// 進場流程：確保已登入（匿名）→ 載入本機歷史 → 處理 Siri 待辦文字。
  Future<void> _init() async {
    await _authService.ensureSignedIn();
    await viewModel.loadHistory();
    await _consumePendingSiriText();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // App 被 Siri/捷徑 喚醒回前景 → 取出待處理語音文字
    if (state == AppLifecycleState.resumed) {
      _consumePendingSiriText();
    }
  }

  Future<void> _consumePendingSiriText() async {
    final text = await VoiceIntentChannel.getPendingVoiceText();
    if (text != null && mounted) {
      _controller.text = text;
      await viewModel.submitVoiceText(text);
    }
  }

  Future<void> _toggleListening() async {
    if (_isListening) {
      await _speechService.stop();
      setState(() => _isListening = false);
      return;
    }
    setState(() => _isListening = true);
    await _speechService.startListening(
      onResult: (text) => _controller.text = text,
      onFinal: (text) {
        _controller.text = text;
        setState(() => _isListening = false);
      },
    );
  }

  Future<void> _submit() async {
    await viewModel.submitVoiceText(_controller.text);
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: viewModel,
      child: DefaultScaffold(
        title: "title_voice_record",
        actions: [_buildAuthChip()],
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 16,
            children: [
              _buildHint(),
              _buildInputField(),
              _buildActions(),
              _buildLoading(),
              _buildResult(),
              _buildHistory(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAuthChip() {
    final isAnon = _authService.isAnonymous;
    final chip = SimpleText(
      // 匿名時顯示可升級提示，正式時顯示「正式」。
      text: isAnon ? "label_login_google" : "label_official",
      fontSize: 13,
      textColor: DesignColor.textSecondary,
    ).container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: DesignColor.backgroundTertiary,
        borderRadius: BorderRadius.circular(16),
      ),
    );
    // 匿名才可點擊升級。
    return isAnon ? chip.inkWell(onTap: _upgradeWithGoogle) : chip;
  }

  /// 匿名用戶點擊 → 以 Google 升級為正式帳號（uid 不變，紀錄保留）。
  Future<void> _upgradeWithGoogle() async {
    final result = await _authService.linkGoogle();
    if (!mounted) {
      return;
    }
    setState(() {}); // 刷新標籤（匿名→正式）
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(result.message.tr())),
    );
  }

  Widget _buildHint() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 6,
      children: [
        SimpleText(text: "desc_voice_hint", textColor: DesignColor.textPrimary),
        SimpleText(
          text: "hint_voice_example",
          fontSize: 13,
          textColor: DesignColor.textSecondary,
        ),
      ],
    ).container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: DesignColor.backgroundTertiary,
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }

  Widget _buildInputField() {
    return SimpleTextField(
      controller: _controller,
      placeHolder: "hint_voice_example",
      maxLines: 3,
      onEditValue: (_) {},
    );
  }

  Widget _buildActions() {
    return Row(
      spacing: 12,
      children: [
        SimpleButton(
          buttonAction: _toggleListening,
          buttonIcon: _isListening ? Icons.stop : Icons.mic,
          buttontitle: _isListening ? "label_stop" : "label_voice_input",
          backgroundColor: DesignColor.backgroundTertiary,
          titleColor: DesignColor.textPrimary,
          iconColor: DesignColor.textPrimary,
          cornerRadius: 12,
        ).flexible(),
        SimpleButton(
          buttonAction: _submit,
          buttonIcon: Icons.check,
          buttontitle: "label_record",
          backgroundColor: DesignColor.buttonPrimary,
          titleColor: Colors.white,
          iconColor: Colors.white,
          cornerRadius: 12,
        ).flexible(),
      ],
    );
  }

  Widget _buildLoading() {
    return Selector<VoiceRecordViewModel, bool>(
      selector: (_, vm) => vm.isLoading,
      builder: (context, isLoading, child) {
        return isLoading
            ? const LinearProgressIndicator()
            : const SizedBox.shrink();
      },
    );
  }

  Widget _buildResult() {
    return Selector<VoiceRecordViewModel, VoiceLogResult?>(
      selector: (_, vm) => vm.lastResult,
      builder: (context, result, child) {
        if (result == null) {
          return const SizedBox.shrink();
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 6,
          children: [
            SimpleText(
              text: "${"title_recorded".tr()}（${"label_parsed_by".tr()}"
                  "：${result.parsedBy}）",
              fontWeight: FontWeight.bold,
              textColor: DesignColor.textPrimary,
            ),
            SimpleText(
              text: "${"label_exercise".tr()}：${result.exerciseId}",
              textColor: DesignColor.textSecondary,
            ),
            SimpleText(
              text: "${"label_weight".tr()} ${result.weight} "
                  "${"unit_kg".tr()} × ${result.reps} ${"label_reps".tr()}"
                  "　${"label_rpe".tr()} ${result.rpe}",
              textColor: DesignColor.textSecondary,
            ),
            SimpleText(
              text: "${"label_one_rm".tr()}：${result.oneRmEst} "
                  "${"unit_kg".tr()}",
              fontSize: 20,
              fontWeight: FontWeight.bold,
              textColor: DesignColor.textAccent,
            ),
          ],
        ).container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: DesignColor.backgroundPrimary,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: DesignColor.borderColor),
          ),
        );
      },
    );
  }

  /// 本機歷史紀錄清單（A 方案：手機快取，匿名重開也看得到）。
  Widget _buildHistory() {
    return Selector<VoiceRecordViewModel, List<TrainingLogEntry>>(
      selector: (_, vm) => vm.history,
      builder: (context, history, child) {
        if (history.isEmpty) {
          return const SizedBox.shrink();
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 8,
          children: [
            SimpleText(
              text: "title_history",
              fontWeight: FontWeight.bold,
              textColor: DesignColor.textPrimary,
            ),
            ...history.map(_buildHistoryItem),
          ],
        );
      },
    );
  }

  Widget _buildHistoryItem(TrainingLogEntry entry) {
    final time = DateFormat("MM/dd HH:mm").format(
      DateTime.fromMillisecondsSinceEpoch(entry.recordedAtMillis),
    );
    return Row(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 2,
          children: [
            SimpleText(
              text: entry.exerciseId,
              textColor: DesignColor.textPrimary,
            ),
            SimpleText(
              text: "${entry.weight} ${"unit_kg".tr()} × ${entry.reps} "
                  "${"label_reps".tr()}　$time",
              fontSize: 12,
              textColor: DesignColor.textSecondary,
            ),
          ],
        ).flexible(),
        SimpleText(
          text: "1RM ${entry.oneRmEst}",
          fontWeight: FontWeight.bold,
          textColor: DesignColor.textAccent,
        ),
      ],
    ).container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: DesignColor.backgroundPrimary,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: DesignColor.borderColor),
      ),
    );
  }
}
