import 'package:dart_sentiment/dart_sentiment.dart';

class SentimentService {
  final Sentiment sentiment = Sentiment();

  double getOverallSentimentScore(List<String> comments) {
    if (comments.isEmpty) {
      return 0.0; // Neutral score for no comments
    }

    double totalComparativeScore = 0;
    int validCommentsCount = 0;

    for (String commentText in comments) {
      if (commentText.trim().isNotEmpty) {
        try {
          final Map<String, dynamic> analysis = sentiment.analysis(commentText);
          // 'comparative' is the average sentiment per word.
          // It usually ranges from -1 to 1, but can exceed this for very strong short texts.
          // We might need to clamp it if dart_sentiment's comparative score can go beyond -1 to 1.
          double comparativeScore = (analysis['comparative'] as num?)?.toDouble() ?? 0.0;
          
          // Clamp the score to be within -1 to 1 for consistency, as dart_sentiment's comparative
          // score is an average and might slightly exceed this for very opinionated short texts.
          comparativeScore = comparativeScore.clamp(-1.0, 1.0);

          totalComparativeScore += comparativeScore;
          validCommentsCount++;
        } catch (e) {
          // Handle potential errors during sentiment analysis of a single comment
          print('Error analyzing sentiment for comment: "$commentText". Error: $e');
        }
      }
    }

    if (validCommentsCount == 0) {
      return 0.0; // Neutral if no valid comments were analyzed
    }

    // Average the comparative scores of all comments
    double averageScore = totalComparativeScore / validCommentsCount;
    return averageScore.clamp(-1.0, 1.0); // Ensure final average is also clamped
  }
}