import 'package:flutter/material.dart';
import 'package:rfid_scanner_app/core/theme/app_theme.dart';
import 'package:rfid_scanner_app/features/prestart/domain/prestart_question.dart';
import 'package:rfid_scanner_app/features/prestart/presentation/widgets/answer_button.dart';
import 'package:rfid_scanner_app/features/prestart/presentation/widgets/badges.dart';

class QuestionCard extends StatefulWidget {
  const QuestionCard({
    super.key,
    required this.question,
    required this.selectedAnswer,
    this.comment,
    required this.onAnswerSelected,
    required this.onCommentChanged,
  });

  final PrestartQuestion question;
  final String? selectedAnswer;
  final String? comment;
  final void Function(String answer) onAnswerSelected;
  final void Function(String comment) onCommentChanged;

  @override
  State<QuestionCard> createState() => _QuestionCardState();
}

class _QuestionCardState extends State<QuestionCard> {
  late TextEditingController _commentController;
  bool _showCommentField = false;

  @override
  void initState() {
    super.initState();
    _commentController = TextEditingController(text: widget.comment ?? '');
    _updateCommentFieldVisibility();
  }

  @override
  void didUpdateWidget(QuestionCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.comment != widget.comment) {
      _commentController.text = widget.comment ?? '';
    }
    if (oldWidget.selectedAnswer != widget.selectedAnswer) {
      _updateCommentFieldVisibility();
    }
  }

  void _updateCommentFieldVisibility() {
    setState(() {
      _showCommentField = (widget.selectedAnswer != null &&
              widget.selectedAnswer != widget.question.correctAnswer) ||
          (widget.comment != null && widget.comment!.isNotEmpty);
    });
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  bool get _isAnswered => widget.selectedAnswer != null;
  bool get _isCorrect => widget.selectedAnswer == widget.question.correctAnswer;

  Color _answerBg(String answer) {
    if (widget.selectedAnswer != answer) return Colors.transparent;
    return answer == widget.question.correctAnswer
        ? AppTheme.success.withValues(alpha: 0.3)
        : AppTheme.error.withValues(alpha: 0.3);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppTheme.secondaryBackground,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 12),
            _buildQuestionText(),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(width: 220, height: 80, child: _buildAnswerButtons()),
                const SizedBox(width: 16),
                Expanded(child: _buildCommentSection()),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        CategoryBadge(category: widget.question.category),
        const SizedBox(width: 8),
        if (widget.question.required) const RequiredBadge(),
        const SizedBox(width: 8),
        if (widget.question.keySafetyFeature) const KeySafetyBadge(),
        const Spacer(),
        if (_isAnswered) ...[
          if (widget.comment != null && widget.comment!.isNotEmpty)
            const Padding(
              padding: EdgeInsets.only(right: 8),
              child: Icon(Icons.comment, color: AppTheme.accent, size: 18),
            ),
          Icon(
            _isCorrect ? Icons.check_circle : Icons.warning,
            color: _isCorrect ? AppTheme.success : AppTheme.error,
            size: 20,
          ),
        ],
      ],
    );
  }

  Widget _buildQuestionText() {
    return Text(
      '${widget.question.id}. ${widget.question.question}',
      style: AppTheme.bodyMedium.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Widget _buildAnswerButtons() {
    return Row(
      children: [
        Expanded(
          child: AnswerButton(
            icon: Icons.check,
            isSelected: widget.selectedAnswer == 'yes',
            backgroundColor: _answerBg('yes'),
            onTap: () {
              widget.onAnswerSelected('yes');
              _updateCommentFieldVisibility();
            },
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: AnswerButton(
            icon: Icons.close,
            isSelected: widget.selectedAnswer == 'no',
            backgroundColor: _answerBg('no'),
            onTap: () {
              widget.onAnswerSelected('no');
              _updateCommentFieldVisibility();
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCommentSection() {
    return SizedBox(
      height: 80,
      child: !_isAnswered
          ? _buildPlaceholder('Select an answer')
          : _showCommentField
              ? _buildCommentField()
              : _buildAddCommentButton(),
    );
  }

  Widget _buildPlaceholder(String text) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.primaryBackground.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppTheme.secondaryText.withValues(alpha: 0.1),
        ),
      ),
      child: Center(
        child: Text(
          text,
          style: TextStyle(
            color: AppTheme.secondaryText.withValues(alpha: 0.5),
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildCommentField() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.primaryBackground.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: !_isCorrect
              ? AppTheme.error.withValues(alpha: 0.3)
              : AppTheme.secondaryText.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.edit_note, color: AppTheme.secondaryText, size: 18),
              const SizedBox(width: 6),
              const Expanded(
                child: Text(
                  'Work Required / Comments',
                  style: TextStyle(
                    color: AppTheme.secondaryText,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (!_isCorrect)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.error.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'Required',
                    style: TextStyle(
                      color: AppTheme.error,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Expanded(
            child: TextField(
              controller: _commentController,
              maxLines: null,
              expands: true,
              keyboardType: TextInputType.text,
              textInputAction: TextInputAction.done,
              style: const TextStyle(color: AppTheme.primaryText, fontSize: 12),
              decoration: InputDecoration(
                hintText: !_isCorrect
                    ? 'Describe the issue...'
                    : 'Add optional comments...',
                hintStyle: TextStyle(
                  color: AppTheme.secondaryText.withValues(alpha: 0.5),
                  fontSize: 12,
                ),
                fillColor: AppTheme.secondaryBackground,
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: BorderSide(
                    color: AppTheme.secondaryText.withValues(alpha: 0.3),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: const BorderSide(color: AppTheme.accent, width: 1.5),
                ),
                contentPadding: const EdgeInsets.all(8),
              ),
              onChanged: widget.onCommentChanged,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddCommentButton() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.primaryBackground.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppTheme.secondaryText.withValues(alpha: 0.1),
        ),
      ),
      child: Center(
        child: TextButton.icon(
          onPressed: () => setState(() => _showCommentField = true),
          icon: const Icon(Icons.add_comment, size: 16, color: AppTheme.accent),
          label: const Text(
            'Add Comment (Optional)',
            style: TextStyle(color: AppTheme.accent, fontSize: 12),
          ),
        ),
      ),
    );
  }
}
