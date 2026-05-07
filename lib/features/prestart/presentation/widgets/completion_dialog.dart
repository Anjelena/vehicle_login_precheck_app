import 'package:flutter/material.dart';
import 'package:rfid_scanner_app/core/theme/app_theme.dart';
import 'package:rfid_scanner_app/features/prestart/presentation/prestart_controller.dart';

/// Submit-confirmation dialog. Shows progress, status, issues with comments,
/// and a list of any unanswered required questions. The "Finish" button only
/// appears when the check is complete and every issue has a comment; otherwise
/// the button reads "Continue" and pops the dialog so the user can scroll back
/// to the first incomplete question.
class CompletionDialog extends StatelessWidget {
  const CompletionDialog({
    super.key,
    required this.validation,
    required this.onComplete,
    this.onScrollToIncomplete,
  });

  final CheckValidation validation;
  final VoidCallback onComplete;
  final void Function(int questionId)? onScrollToIncomplete;

  bool get _isFullyComplete =>
      validation.isComplete &&
      validation.questionsWithIssues.every((i) => i.response.hasComment);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppTheme.secondaryBackground,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Icon(
            _isFullyComplete ? Icons.check_circle_outline : Icons.info_outline,
            color: _isFullyComplete ? AppTheme.success : AppTheme.error,
            size: 28,
          ),
          const SizedBox(width: 12),
          Text(
            _isFullyComplete ? 'Check Complete' : 'Incomplete Check',
            style: AppTheme.headingMedium.copyWith(
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProgressIndicator(),
            const SizedBox(height: 16),
            _buildStatusMessage(),
            if (validation.questionsWithIssues.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildIssuesSummary(),
            ],
            if (validation.unansweredRequired.isNotEmpty) ...[
              const SizedBox(height: 12),
              _buildMissingList(),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => _onPressed(context),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            backgroundColor: _isFullyComplete
                ? AppTheme.accent
                : AppTheme.secondaryBackground,
          ),
          child: Text(
            _isFullyComplete ? 'Finish' : 'Continue',
            style: AppTheme.bodyMedium.copyWith(
              color: _isFullyComplete ? AppTheme.primaryText : AppTheme.accent,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  void _onPressed(BuildContext context) {
    Navigator.of(context).pop();

    if (_isFullyComplete) {
      onComplete();
      return;
    }

    if (onScrollToIncomplete == null) return;

    final ids = <int>[
      ...validation.unansweredRequired.map((q) => q.id),
      ...validation.questionsWithIssues
          .where((i) => !i.response.hasComment)
          .map((i) => i.question.id),
    ];
    if (ids.isNotEmpty) {
      ids.sort();
      onScrollToIncomplete!(ids.first);
    }
  }

  Widget _buildProgressIndicator() {
    final issuesWithoutComment = validation.questionsWithIssues
        .where((i) => !i.response.hasComment)
        .length;
    final progress = validation.totalCount == 0
        ? 0.0
        : (validation.answeredCount - issuesWithoutComment) /
            validation.totalCount;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Progress',
              style: AppTheme.bodyMedium.copyWith(color: AppTheme.secondaryText),
            ),
            Text(
              '${validation.answeredCount - issuesWithoutComment}/${validation.totalCount}',
              style: AppTheme.bodyMedium.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: progress.clamp(0.0, 1.0),
          backgroundColor: AppTheme.secondaryText.withValues(alpha: 0.2),
          valueColor: AlwaysStoppedAnimation<Color>(
            _isFullyComplete ? AppTheme.success : AppTheme.accent,
          ),
          minHeight: 6,
        ),
      ],
    );
  }

  Widget _buildStatusMessage() {
    if (!validation.isComplete) {
      return _StatusBanner(
        color: AppTheme.error,
        icon: Icons.warning_amber,
        text: '${validation.unansweredRequired.length} required '
            'question${validation.unansweredRequired.length == 1 ? '' : 's'} '
            'not answered',
      );
    }
    if (validation.questionsWithIssues.isNotEmpty) {
      return _StatusBanner(
        color: AppTheme.warning,
        icon: Icons.warning_amber,
        text: 'Check completed with ${validation.questionsWithIssues.length} '
            'issue${validation.questionsWithIssues.length == 1 ? '' : 's'} '
            'found',
      );
    }
    return const _StatusBanner(
      color: AppTheme.success,
      icon: Icons.check,
      text: 'All checks passed successfully!',
    );
  }

  Widget _buildIssuesSummary() {
    return Container(
      constraints: const BoxConstraints(maxHeight: 250),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.warning.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.warning.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Icon(Icons.build, color: AppTheme.warning, size: 18),
              const SizedBox(width: 8),
              Text(
                'Work Required / Comments',
                style: AppTheme.bodyMedium.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: validation.questionsWithIssues
                    .map((issue) => _IssueRow(issue: issue))
                    .toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMissingList() {
    return Container(
      constraints: const BoxConstraints(maxHeight: 150),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppTheme.error.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Missing Required Questions:',
            style: AppTheme.bodyMedium.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: validation.unansweredRequired
                    .map((q) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                '• ',
                                style: TextStyle(
                                  color: AppTheme.error,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  'Q${q.id}: ${q.category}',
                                  style: const TextStyle(
                                    color: AppTheme.primaryText,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ))
                    .toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({
    required this.color,
    required this.icon,
    required this.text,
  });

  final Color color;
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: AppTheme.bodyMedium.copyWith(
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _IssueRow extends StatelessWidget {
  const _IssueRow({required this.issue});

  final QuestionWithIssue issue;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppTheme.secondaryBackground,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: issue.isCorrect
                      ? AppTheme.accent.withValues(alpha: 0.2)
                      : AppTheme.error.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Q${issue.question.id}',
                  style: TextStyle(
                    color: issue.isCorrect ? AppTheme.accent : AppTheme.error,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              if (issue.question.keySafetyFeature)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.warning.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Icon(
                    Icons.warning_amber,
                    color: AppTheme.warning,
                    size: 12,
                  ),
                ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  issue.question.category,
                  style: const TextStyle(
                    color: AppTheme.primaryText,
                    fontSize: 11,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (!issue.isCorrect)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.error.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'FAIL',
                    style: TextStyle(
                      color: AppTheme.error,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            issue.response.hasComment
                ? issue.response.comment!
                : 'No comment provided',
            style: TextStyle(
              color: issue.response.hasComment
                  ? AppTheme.primaryText
                  : AppTheme.secondaryText.withValues(alpha: 0.6),
              fontSize: 12,
              fontStyle: issue.response.hasComment
                  ? FontStyle.normal
                  : FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}

void showCompletionDialog({
  required BuildContext context,
  required CheckValidation validation,
  required VoidCallback onComplete,
  required void Function(int questionId)? onScrollToIncomplete,
}) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => CompletionDialog(
      validation: validation,
      onComplete: onComplete,
      onScrollToIncomplete: onScrollToIncomplete,
    ),
  );
}
