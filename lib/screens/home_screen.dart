import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
// Remove direct import of sentiment_dart if no longer used directly here
// import 'package:sentiment_dart/sentiment_dart.dart'; 
import '../providers/player_provider.dart';
import '../services/sentiment_service.dart'; // Import the sentiment service
import '../services/youtube_api_service.dart'; // Import the YouTube API service

class HomeScreenContent extends StatefulWidget {
  const HomeScreenContent({super.key});

  @override
  State<HomeScreenContent> createState() => _HomeScreenContentState();
}

class _HomeScreenContentState extends State<HomeScreenContent> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  bool _isLoading = false;
  List<Map<String, dynamic>> _videoResults = [];
  final SentimentService _sentimentService = SentimentService(); 
  final YouTubeApiService _youTubeApiService = YouTubeApiService(); // Instantiate YouTube API service

  Future<void> _searchVideos(String query) async {
    if (query.isEmpty) return;

    setState(() {
      _isLoading = true;
      _videoResults = [];
    });

    try {
      // You can specify the desired number of regular videos here
      List<Map<String, dynamic>> fetchedVideosFromApi = 
          await _youTubeApiService.searchVideos(query, desiredRegularVideos: 10);

      List<Map<String, dynamic>> processedVideos = [];

      for (var videoData in fetchedVideosFromApi) {
        List<String> comments = await _youTubeApiService.getComments(videoData['videoId']);
        
        // CORRECTED METHOD NAME:
        double averageSentimentScore = _sentimentService.getOverallSentimentScore(comments);

        processedVideos.add({
          'id': videoData['videoId'], 
          'title': videoData['title'],
          'sentiment': averageSentimentScore,
          'durationInSeconds': videoData['durationInSeconds'], 
          'thumbnailUrl': videoData['thumbnailUrl'],
          'channelTitle': videoData['channelTitle'],
        });
      }

      // Sort videos by sentiment score (descending)
      processedVideos.sort((a, b) => (b['sentiment'] as double).compareTo(a['sentiment'] as double));

      _videoResults = processedVideos;

    } catch (e) {
      print('Error in _searchVideos (home_screen): $e');
      // Optionally, show an error message to the user in the UI
      // For example, by setting a state variable and displaying it.
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final playerProvider = Provider.of<PlayerProvider>(context, listen: false);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Your Search Bar UI would go here, calling _searchVideos on submit
          // For example: TextField(onSubmitted: _searchVideos, ...)
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator(color: colorScheme.primary))
                : _videoResults.isEmpty
                    ? const Center(child: Text('Search for videos to see results.'))
                    : ListView.builder(
                        itemCount: _videoResults.length,
                        itemBuilder: (context, index) {
                          final video = _videoResults[index];
                          final videoId = video['id'] as String? ?? 'default_id_$index';
                          // final thumbnailUrl = video['thumbnailUrl'] as String?;
                          // final channelTitle = video['channelTitle'] as String?;
                          // final duration = video['durationInSeconds'] as int? ?? 0;

                          return Container(
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(22),
                              color: theme.cardColor.withOpacity(0.8),
                              boxShadow: [
                                BoxShadow(
                                  color: theme.brightness == Brightness.dark
                                         ? Colors.black.withOpacity(0.3)
                                         : Colors.black.withOpacity(0.06),
                                  blurRadius: 16,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: ListTile(
                              // Example: Display thumbnail if available
                              // leading: thumbnailUrl != null 
                              //   ? Image.network(thumbnailUrl, width: 100, fit: BoxFit.cover)
                              //   : CircleAvatar(
                              //       backgroundColor: colorScheme.secondaryContainer,
                              //       child: Icon(Icons.video_library_outlined, color: colorScheme.onSecondaryContainer),
                              //     ),
                              leading: CircleAvatar(
                                backgroundColor: colorScheme.secondaryContainer,
                                foregroundColor: colorScheme.onSecondaryContainer,
                                child: Text('${((video['sentiment'] ?? 0.0) * 100).toInt()}%'), // Ensure sentiment is double
                              ),
                              title: Text(video['title'] ?? 'No Title', style: theme.textTheme.titleMedium),
                              // subtitle: Text('Channel: $channelTitle\nDuration: ${duration ~/ 60}m ${duration % 60}s'),
                              onTap: () {
                                print('Tapped on video: $videoId');
                                playerProvider.selectVideo(videoId);
                              },
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}