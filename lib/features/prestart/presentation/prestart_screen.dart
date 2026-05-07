import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rfid_scanner_app/core/logging/app_logger.dart';
import 'package:rfid_scanner_app/core/routing/app_routes.dart';
import 'package:rfid_scanner_app/core/session/session.dart';
import 'package:rfid_scanner_app/core/theme/app_theme.dart';
import 'package:rfid_scanner_app/features/prestart/data/prestart_repository.dart';
import 'package:rfid_scanner_app/features/prestart/presentation/prestart_controller.dart';
import 'package:rfid_scanner_app/features/prestart/presentation/widgets/completion_dialog.dart';
import 'package:rfid_scanner_app/features/prestart/presentation/widgets/empty_state.dart';
import 'package:rfid_scanner_app/features/prestart/presentation/widgets/question_card.dart';
import 'package:rfid_scanner_app/features/prestart/presentation/widgets/submit_check_fab.dart';

class PrestartScreen extends StatefulWidget {
  const PrestartScreen({super.key});

  @override
  State<PrestartScreen> createState() => _PrestartScreenState();
}

class _PrestartScreenState extends State<PrestartScreen> {
  late final PrestartController _controller;
  final ScrollController _scrollController = ScrollController();
  final Map<int, GlobalKey> _questionKeys = {};
  bool _errorShown = false;

  @override
  void initState() {
    super.initState();
    _controller = PrestartController(
      repository: context.read<PrestartRepository>(),
      session: context.read<Session>(),
    );
    _controller.load();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _logout() {
    context.read<Session>().logout();
    Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.login, (_) => false);
  }

  void _handleSubmitPressed() {
    final validation = _controller.validate();
    showCompletionDialog(
      context: context,
      validation: validation,
      onComplete: _finalizeSubmission,
      onScrollToIncomplete: _scrollToQuestionId,
    );
  }

  Future<void> _finalizeSubmission() async {
    try {
      await _controller.submit();
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed(AppRoutes.welcome);
    } catch (e) {
      AppLogger.e('Failed to submit prestart: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save submission: $e'),
          backgroundColor: AppTheme.error,
        ),
      );
    }
  }

  void _scrollToQuestionId(int questionId) {
    final index = _controller.questions.indexWhere((q) => q.id == questionId);
    if (index < 0) return;
    _scrollToIndex(index);
  }

  void _scrollToIndex(int index) {
    Future.delayed(const Duration(milliseconds: 75), () {
      if (!mounted) return;
      final ctx = _questionKeys[index]?.currentContext;
      if (ctx != null && ctx.mounted) {
        Scrollable.ensureVisible(
          ctx,
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
          alignment: 0.5,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<PrestartController>.value(
      value: _controller,
      child: Scaffold(
        backgroundColor: AppTheme.primaryBackground,
        body: SafeArea(
          child: Consumer<PrestartController>(
            builder: (context, controller, _) {
              if (controller.errorMessage != null &&
                  !controller.isLoading &&
                  !_errorShown) {
                _errorShown = true;
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(controller.errorMessage!),
                      backgroundColor: AppTheme.error,
                    ),
                  );
                });
              }
              return Column(
                children: [
                  _buildHeader(controller),
                  Expanded(child: _buildContent(controller)),
                ],
              );
            },
          ),
        ),
        floatingActionButton: Consumer<PrestartController>(
          builder: (context, controller, _) {
            if (controller.questions.isEmpty || controller.isLoading) {
              return const SizedBox.shrink();
            }
            return SubmitCheckFAB(onPressed: _handleSubmitPressed);
          },
        ),
      ),
    );
  }

  Widget _buildHeader(PrestartController controller) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: const BoxDecoration(color: AppTheme.secondaryBackground),
      child: Row(
        children: [
          IconButton(
            onPressed: _logout,
            icon: const Icon(Icons.arrow_back),
            color: AppTheme.accent,
            iconSize: 28,
            tooltip: 'Logout',
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              controller.title,
              style: AppTheme.headingLarge,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (!controller.isLoading) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.accent.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${controller.answeredCount}/${controller.totalQuestions}',
                style: AppTheme.bodyMedium.copyWith(
                  color: AppTheme.accent,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildContent(PrestartController controller) {
    if (controller.isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.accent));
    }
    if (controller.questions.isEmpty) {
      return const EmptyStateWidget(
        message: 'No questions available',
        icon: Icons.error_outline,
      );
    }
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.only(bottom: 96),
      itemCount: controller.questions.length,
      itemBuilder: (context, index) {
        final question = controller.questions[index];
        _questionKeys[index] ??= GlobalKey();
        return Container(
          key: _questionKeys[index],
          child: QuestionCard(
            question: question,
            selectedAnswer: controller.getAnswer(question.id),
            comment: controller.getComment(question.id),
            onAnswerSelected: (answer) {
              controller.answerQuestion(question.id, answer);
              if (answer == question.correctAnswer &&
                  index < controller.questions.length - 1) {
                _scrollToIndex(index + 1);
              }
            },
            onCommentChanged: (comment) =>
                controller.updateComment(question.id, comment),
          ),
        );
      },
    );
  }
}
