import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:developer'; // Import for log function

class YouTubeApiService {
  final String apiKey = 'AIzaSyB61djOSvsHDVksUA9qCD_Nf9LfqZopgKs'; // Your existing key

  int _parseDuration(String isoDuration) {
    // log('Parsing duration: $isoDuration', name: 'YouTubeApiService._parseDuration'); // Log raw duration
    if (!isoDuration.startsWith('PT')) {
      // log('Duration does not start with PT: $isoDuration', name: 'YouTubeApiService._parseDuration');
      return 0;
    }
    String duration = isoDuration.substring(2);
    int totalSeconds = 0;

    RegExpMatch? hoursMatch = RegExp(r'(\d+)H').firstMatch(duration);
    if (hoursMatch != null) {
      totalSeconds += int.parse(hoursMatch.group(1)!) * 3600;
      duration = duration.replaceFirst(RegExp(r'(\d+)H'), '');
    }

    RegExpMatch? minutesMatch = RegExp(r'(\d+)M').firstMatch(duration);
    if (minutesMatch != null) {
      totalSeconds += int.parse(minutesMatch.group(1)!) * 60;
      duration = duration.replaceFirst(RegExp(r'(\d+)M'), '');
    }

    RegExpMatch? secondsMatch = RegExp(r'(\d+)S').firstMatch(duration);
    if (secondsMatch != null) {
      totalSeconds += int.parse(secondsMatch.group(1)!);
    }
    // log('Parsed $isoDuration to $totalSeconds seconds', name: 'YouTubeApiService._parseDuration');
    return totalSeconds;
  }

  Future<List<Map<String, dynamic>>> searchVideos(String query, {int desiredRegularVideos = 10}) async {
    List<Map<String, dynamic>> regularVideosFound = [];
    String? nextPageToken;
    int maxApiResultsPerSearchCall = 25; 
    int totalVideosProcessed = 0;
    int safetyFetchLimit = 100; 

    log('Starting search for "$query", aiming for $desiredRegularVideos regular videos.', name: 'YouTubeApiService.searchVideos');

    while (regularVideosFound.length < desiredRegularVideos && totalVideosProcessed < safetyFetchLimit) {
      String searchUrl =
          'https://www.googleapis.com/youtube/v3/search?part=snippet&q=$query&type=video&maxResults=$maxApiResultsPerSearchCall&key=$apiKey';
      if (nextPageToken != null) {
        searchUrl += '&pageToken=$nextPageToken';
      }
      log('Fetching search batch: $searchUrl', name: 'YouTubeApiService.searchVideos');

      try {
        final searchResponse = await http.get(Uri.parse(searchUrl));

        if (searchResponse.statusCode == 200) {
          final searchData = json.decode(searchResponse.body);
          List<String> videoIdsBatch = [];
          Map<String, Map<String, dynamic>> videoSnippetsBatch = {}; 

          if (searchData['items'] != null && (searchData['items'] as List).isNotEmpty) {
            for (var item in searchData['items']) {
              if (item['id'] != null && item['id']['videoId'] != null && item['snippet'] != null) {
                String videoId = item['id']['videoId'];
                videoIdsBatch.add(videoId);
                videoSnippetsBatch[videoId] = {
                  'title': item['snippet']['title'],
                  'description': item['snippet']['description'],
                  'thumbnailUrl': item['snippet']['thumbnails']?['default']?['url'],
                  'channelTitle': item['snippet']['channelTitle'],
                };
              }
            }
          } else {
            log('No items found in search batch or no items at all. Ending search.', name: 'YouTubeApiService.searchVideos');
            break; 
          }

          totalVideosProcessed += videoIdsBatch.length;
          log('Search batch fetched ${videoIdsBatch.length} video IDs. Total processed so far: $totalVideosProcessed.', name: 'YouTubeApiService.searchVideos');

          if (videoIdsBatch.isEmpty) {
            log('Video ID batch is empty. Ending search.', name: 'YouTubeApiService.searchVideos');
            break; 
          }

          final idsString = videoIdsBatch.join(',');
          final detailsUrl =
              'https://www.googleapis.com/youtube/v3/videos?part=snippet,contentDetails&id=$idsString&key=$apiKey';
          log('Fetching details for batch: $detailsUrl', name: 'YouTubeApiService.searchVideos');
          
          final detailsResponse = await http.get(Uri.parse(detailsUrl));

          if (detailsResponse.statusCode == 200) {
            final detailsData = json.decode(detailsResponse.body);
            if (detailsData['items'] != null) {
              for (var item in detailsData['items']) {
                String videoId = item['id'];
                Map<String, dynamic>? snippetData = videoSnippetsBatch[videoId]; 

                if (snippetData != null && item['contentDetails'] != null) {
                  String isoDuration = item['contentDetails']['duration'] ?? 'PT0S';
                  // **** ADDING DEBUG LOGS HERE ****
                  log('Video ID: $videoId, Title: ${snippetData['title']}, Raw Duration: $isoDuration', name: 'YouTubeApiService.searchVideos');
                  int durationInSeconds = _parseDuration(isoDuration);
                  log('Video ID: $videoId, Parsed Duration (s): $durationInSeconds', name: 'YouTubeApiService.searchVideos');

                  if (durationInSeconds >= 60) {
                    if(regularVideosFound.length < desiredRegularVideos) {
                        log('ADDING Video ID: $videoId as regular video. Current count: ${regularVideosFound.length + 1}', name: 'YouTubeApiService.searchVideos');
                        regularVideosFound.add({
                          'videoId': videoId,
                          'title': snippetData['title'],
                          'description': snippetData['description'],
                          'thumbnailUrl': snippetData['thumbnailUrl'],
                          'channelTitle': snippetData['channelTitle'],
                          'durationInSeconds': durationInSeconds, 
                        });
                    } else {
                        log('SKIPPING Video ID: $videoId (already have $desiredRegularVideos regular videos)', name: 'YouTubeApiService.searchVideos');
                    }
                  } else {
                    log('FILTERING OUT Short: Video ID: $videoId, Duration (s): $durationInSeconds', name: 'YouTubeApiService.searchVideos');
                  }
                }
              }
            }
          } else {
            log('Failed to load video details for a batch: ${detailsResponse.statusCode}. Ending current search attempt.', name: 'YouTubeApiService.searchVideos');
            break;
          }
          
          nextPageToken = searchData['nextPageToken'];
          if (nextPageToken == null) {
            log('No next page token. Ending search.', name: 'YouTubeApiService.searchVideos');
            break; 
          }
        } else {
          log('Failed to load search results: ${searchResponse.statusCode}. Response: ${searchResponse.body}', name: 'YouTubeApiService.searchVideos');
          throw Exception('Failed to load search results. Status code: ${searchResponse.statusCode}');
        }
      } catch (e) {
        log('Error during video search batch: $e', name: 'YouTubeApiService.searchVideos');
        // Decide if you want to rethrow or break. Rethrowing will stop the process.
        throw Exception('Error during video search batch: $e'); 
      }
    }
    log('Search finished. Found ${regularVideosFound.length} regular videos.', name: 'YouTubeApiService.searchVideos');
    return regularVideosFound;
  }

  Future<List<String>> getComments(String videoId, {int maxResults = 20}) async {
    final url =
        'https://www.googleapis.com/youtube/v3/commentThreads?part=snippet&videoId=$videoId&maxResults=$maxResults&key=$apiKey&textFormat=plainText';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<String> comments = [];
        if (data['items'] != null) {
          for (var item in data['items']) {
            if (item['snippet']?['topLevelComment']?['snippet']?['textDisplay'] != null) {
              comments.add(item['snippet']['topLevelComment']['snippet']['textDisplay']);
            }
          }
        }
        return comments;
      } else {
        log('Failed to load comments for $videoId: ${response.statusCode}', name: 'YouTubeApiService.getComments');
        return []; 
      }
    } catch (e) {
      log('Error fetching comments for $videoId: $e', name: 'YouTubeApiService.getComments');
      return [];
    }
  }
}