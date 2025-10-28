import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import '../utils/app_theme.dart';
import '../utils/app_constants.dart';
import '../widgets/custom_button.dart';

class SurveyScreen extends StatefulWidget {
  final Map<String, dynamic> survey;

  const SurveyScreen({super.key, required this.survey});

  @override
  State<SurveyScreen> createState() => _SurveyScreenState();
}

class _SurveyScreenState extends State<SurveyScreen> {
  final PageController _pageController = PageController();
  int _currentQuestionIndex = 0;
  Map<int, dynamic> _answers = {};
  bool _isSubmitting = false;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextQuestion() {
    if (_currentQuestionIndex < widget.survey['questions'].length - 1) {
      setState(() {
        _currentQuestionIndex++;
      });
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _submitSurvey();
    }
  }

  void _previousQuestion() {
    if (_currentQuestionIndex > 0) {
      setState(() {
        _currentQuestionIndex--;
      });
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  bool _isCurrentQuestionAnswered() {
    final question = widget.survey['questions'][_currentQuestionIndex];
    return _answers.containsKey(question['id']);
  }

  Future<void> _submitSurvey() async {
    setState(() => _isSubmitting = true);

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final apiService = Provider.of<ApiService>(context, listen: false);

      if (!authService.isAuthenticated) {
        throw Exception('Kullanıcı girişi gerekli');
      }

      // Prepare answers for API
      List<Map<String, dynamic>> apiAnswers = [];
      for (var entry in _answers.entries) {
        final questionId = entry.key;
        final answer = entry.value;
        final question = widget.survey['questions']
            .firstWhere((q) => q['id'] == questionId);

        Map<String, dynamic> apiAnswer = {
          'question_id': questionId,
        };

        switch (question['question_type']) {
          case 'rating':
            apiAnswer['rating'] = answer;
            break;
          case 'text':
            apiAnswer['text'] = answer;
            break;
          case 'multiple_choice':
            apiAnswer['choice'] = answer;
            break;
          case 'yes_no':
            apiAnswer['boolean'] = answer;
            break;
        }

        apiAnswers.add(apiAnswer);
      }

      final response = await apiService.post(
        '${AppConstants.submitSurveyEndpoint}/${widget.survey['id']}/submit',
        data: {'answers': apiAnswers},
        headers: authService.getAuthHeaders(),
      );

      if (mounted) {
        if (response['success'] == true) {
          _showSuccessDialog();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response['error'] ?? 'Anket gönderilirken hata oluştu'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Anket gönderilirken hata: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: AppTheme.cardDecoration,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(40),
                ),
                child: const Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: 50,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Teşekkür Ederiz!',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.black87,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 12),
              Text(
                'Anket yanıtlarınız başarıyla kaydedildi. Görüşleriniz bizim için çok değerli.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.black87,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              CustomButton(
                text: 'Tamam',
                onPressed: () {
                  Navigator.of(context).pop(); // Close dialog
                  Navigator.of(context).pop(); // Close survey screen
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final questions = widget.survey['questions'] as List;
    final currentQuestion = questions[_currentQuestionIndex];

    return Scaffold(
      body: Container(
        decoration: AppTheme.backgroundDecoration,
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(
                            Icons.arrow_back,
                            color: Colors.white,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            widget.survey['title'],
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(width: 48), // Balance the back button
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Progress indicator
                    Container(
                      height: 6,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: (_currentQuestionIndex + 1) / questions.length,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Soru ${_currentQuestionIndex + 1} / ${questions.length}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.white.withOpacity(0.8),
                          ),
                    ),
                  ],
                ),
              ),

              // Question content
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() {
                      _currentQuestionIndex = index;
                    });
                  },
                  itemCount: questions.length,
                  itemBuilder: (context, index) {
                    final question = questions[index];
                    return _buildQuestionWidget(question);
                  },
                ),
              ),

              // Navigation buttons
              Container(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    if (_currentQuestionIndex > 0)
                      Expanded(
                        child: CustomButton(
                          text: 'Önceki',
                          onPressed: _previousQuestion,
                          backgroundColor: Colors.white.withOpacity(0.2),
                          textColor: Colors.white,
                        ),
                      ),
                    if (_currentQuestionIndex > 0) const SizedBox(width: 16),
                    Expanded(
                      child: CustomButton(
                        text: _currentQuestionIndex == questions.length - 1
                            ? (_isSubmitting ? 'Gönderiliyor...' : 'Gönder')
                            : 'Sonraki',
                        onPressed: _isCurrentQuestionAnswered() && !_isSubmitting
                            ? _nextQuestion
                            : null,
                        isLoading: _isSubmitting,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuestionWidget(Map<String, dynamic> question) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  question['question_text'],
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.black87,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 24),
                _buildAnswerWidget(question),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnswerWidget(Map<String, dynamic> question) {
    final questionId = question['id'];
    final questionType = question['question_type'];

    switch (questionType) {
      case 'rating':
        return _buildRatingWidget(questionId);
      case 'text':
        return _buildTextWidget(questionId);
      case 'multiple_choice':
        return _buildMultipleChoiceWidget(questionId, question['options']);
      case 'yes_no':
        return _buildYesNoWidget(questionId);
      default:
        return const Text('Desteklenmeyen soru tipi');
    }
  }

  Widget _buildRatingWidget(int questionId) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '1-5 arasında puanlayın:',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.black87,
              ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(5, (index) {
            final rating = index + 1;
            final isSelected = _answers[questionId] == rating;
            
            return GestureDetector(
              onTap: () {
                setState(() {
                  _answers[questionId] = rating;
                });
              },
              child: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: isSelected ? AppTheme.primaryColor : Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(
                    color: isSelected ? AppTheme.primaryColor : Colors.grey.shade300,
                    width: 2,
                  ),
                ),
                child: Center(
                  child: Text(
                    rating.toString(),
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.black87,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildTextWidget(int questionId) {
    return TextField(
      onChanged: (value) {
        setState(() {
          _answers[questionId] = value;
        });
      },
      maxLines: 4,
      decoration: InputDecoration(
        hintText: 'Cevabınızı buraya yazın...',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppTheme.primaryColor, width: 2),
        ),
      ),
    );
  }

  Widget _buildMultipleChoiceWidget(int questionId, List<dynamic> options) {
    return Column(
      children: options.map<Widget>((option) {
        final isSelected = _answers[questionId] == option;
        
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          child: GestureDetector(
            onTap: () {
              setState(() {
                _answers[questionId] = option;
              });
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.primaryColor.withOpacity(0.1) : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? AppTheme.primaryColor : Colors.grey.shade300,
                  width: 2,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: isSelected ? AppTheme.primaryColor : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected ? AppTheme.primaryColor : Colors.grey.shade400,
                        width: 2,
                      ),
                    ),
                    child: isSelected
                        ? const Icon(
                            Icons.check,
                            color: Colors.white,
                            size: 14,
                          )
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      option.toString(),
                      style: TextStyle(
                        color: isSelected ? AppTheme.primaryColor : Colors.black87,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildYesNoWidget(int questionId) {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () {
              setState(() {
                _answers[questionId] = true;
              });
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _answers[questionId] == true
                    ? Colors.green.withOpacity(0.1)
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _answers[questionId] == true
                      ? Colors.green
                      : Colors.grey.shade300,
                  width: 2,
                ),
              ),
              child: Text(
                'Evet',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _answers[questionId] == true
                      ? Colors.green
                      : Colors.black87,
                  fontWeight: _answers[questionId] == true
                      ? FontWeight.bold
                      : FontWeight.normal,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: GestureDetector(
            onTap: () {
              setState(() {
                _answers[questionId] = false;
              });
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _answers[questionId] == false
                    ? Colors.red.withOpacity(0.1)
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _answers[questionId] == false
                      ? Colors.red
                      : Colors.grey.shade300,
                  width: 2,
                ),
              ),
              child: Text(
                'Hayır',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _answers[questionId] == false
                      ? Colors.red
                      : Colors.black87,
                  fontWeight: _answers[questionId] == false
                      ? FontWeight.bold
                      : FontWeight.normal,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
