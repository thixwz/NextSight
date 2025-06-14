import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart'; 
import 'dart:developer'; // Added for log function

// --- ADD Imports for screens and widgets --- 
import 'home_screen.dart';
import 'history_screen.dart';
import 'favorites_screen.dart';
import 'profile_screen.dart';
import '../widgets/glassmorphic_search_bar.dart';
// import '../providers/player_provider.dart'; // Assuming PlayerProvider is used in _handleSearchSubmitted - Not used directly here now
import 'package:nextsight2_0/services/youtube_api_service.dart'; // For YouTube API
import 'package:nextsight2_0/models/video_item.dart';          // For VideoItem model
import 'package:nextsight2_0/providers/theme_provider.dart';     // For ThemeProvider
import 'package:nextsight2_0/services/sentiment_service.dart'; // Import SentimentService

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with WidgetsBindingObserver, TickerProviderStateMixin {
  int _selectedIndex = 0; 
  double _bottomPadding = 0.0;

  late TextEditingController _searchController;
  late FocusNode _searchFocusNode;
  late AnimationController _buttonAnimationController;
  late Animation<double> _buttonScaleAnimation;

  // --- State for YouTube Search ---
  bool _showSearchBackButton = false; // Added to control search bar icon
  final YouTubeApiService _youTubeApiService = YouTubeApiService();
  List<VideoItem> _fetchedVideos = [];
  bool _isLoading = false;
  String _searchError = '';
  // --- End of State for YouTube Search ---

  static const List<Widget> _widgetOptions = <Widget>[
    HomeScreenContent(), 
    HistoryScreen(),
    FavoritesScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    _searchController = TextEditingController();
    _searchFocusNode = FocusNode();

    _buttonAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
      reverseDuration: const Duration(milliseconds: 100)
    );
    _buttonScaleAnimation = Tween<double>(begin: 1.0, end: 0.85).animate(
      CurvedAnimation(parent: _buttonAnimationController, curve: Curves.easeInOut)
    );
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) { 
        setState(() {
          _bottomPadding = MediaQuery.of(context).padding.bottom;
        });
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _searchController.dispose();
    _searchFocusNode.dispose();
    _buttonAnimationController.dispose();
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    final bottomInset = WidgetsBinding.instance.window.viewPadding.bottom / WidgetsBinding.instance.window.devicePixelRatio;
    if (mounted && bottomInset != _bottomPadding) {
       setState(() {
         _bottomPadding = bottomInset;
       });
    }
  }

  void _onItemTapped(int index) {
    if (_selectedIndex == index) return; // Do nothing if tapping the current tab

    final bool navigatingAwayFromHome = _selectedIndex == 0 && index != 0;

    setState(() {
      _selectedIndex = index; // Update to the new tab index

      // If navigating away from the home screen and the search bar had focus, unfocus it.
      // The search query, results, error state, loading state, and back button state are preserved.
      if (navigatingAwayFromHome) {
        if (_searchFocusNode.hasFocus) {
          _searchFocusNode.unfocus();
        }
      }
    });
  }

  Future<void> _logout() async {
    await GoogleSignIn().signOut();
    await FirebaseAuth.instance.signOut();
  }

  final SentimentService _sentimentService = SentimentService(); // Add SentimentService instance

  Future<void> _performSearch(String query) async {
    log('Performing search for: $query', name: 'MainScreen');
    if (query.isEmpty) {
      setState(() {
        _fetchedVideos = [];
        _showSearchBackButton = false;
        _searchError = '';
        _isLoading = false;
      });
      return;
    }

    if (query.isNotEmpty) {
      _searchFocusNode.unfocus();
      setState(() {
        _isLoading = true;
        _fetchedVideos = [];
        _searchError = '';
        _selectedIndex = 0;
      });
      try {
        List<Map<String, dynamic>> videoDataFromApi = 
            await _youTubeApiService.searchVideos(query, desiredRegularVideos: 10);
        
        List<VideoItem> tempFetchedVideos = [];
        for (var data in videoDataFromApi) {
          List<String> comments = await _youTubeApiService.getComments(data['videoId']);
          // CORRECTED METHOD NAME HERE:
          double calculatedScore = _sentimentService.getOverallSentimentScore(comments);
          
          Map<String, dynamic> videoJsonWithScore = Map<String, dynamic>.from(data);
          videoJsonWithScore['score'] = calculatedScore;

          tempFetchedVideos.add(VideoItem.fromJson(videoJsonWithScore));
        }

        // Sort videos by score in descending order (highest score first)
        tempFetchedVideos.sort((a, b) => (b.score ?? -2.0).compareTo(a.score ?? -2.0)); 
        // Using -2.0 for null scores ensures they appear last if not handled otherwise

        if (mounted) {
          setState(() {
            _fetchedVideos = tempFetchedVideos;
            _isLoading = false;
            _showSearchBackButton = true;
          });
        }
        log('Fetched and sorted ${_fetchedVideos.length} videos.', name: 'MainScreen');
      } catch (e) {
        log('Error during search: $e', name: 'MainScreen');
        if (mounted) {
          setState(() {
            _isLoading = false;
            _searchError = 'Failed to fetch videos. Please try again.';
            _showSearchBackButton = true;
          });
        }
      }
    }
  }

  void _handleSearchSubmitted(String query) {
    log('Search submitted: $query', name: 'MainScreen');
    if (query.isNotEmpty) {
      setState(() {
        _showSearchBackButton = true; // Show back button when search is submitted
      });
      _performSearch(query);
    } else {
      // If search is submitted with an empty query (e.g., by pressing enter on empty field)
      // We can choose to clear results or do nothing. Here, let's clear.
      setState(() {
        _fetchedVideos = [];
        _showSearchBackButton = false;
        _searchError = '';
        _isLoading = false;
        _searchController.clear(); // Clear the text field as well
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context); // For theme access
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final user = FirebaseAuth.instance.currentUser;
    final String displayName = user?.displayName ?? 'User';
    final String? photoURL = user?.photoURL;

    // Handler for the search bar's back button
    void _handleSearchBackButtonPressed() {
      log('Search back button pressed', name: 'MainScreen');
      setState(() {
        _searchController.clear();
        _fetchedVideos = [];
        _showSearchBackButton = false;
        _searchError = '';
        _isLoading = false;
        _searchFocusNode.unfocus(); // Unfocus the search bar
      });
    }
    // final bool isDarkMode = theme.brightness == Brightness.dark; // Use themeProvider for consistency
    final bool isDarkMode = themeProvider.themeMode == ThemeMode.dark;
    final Color textColor = theme.colorScheme.onSurface; // For text in list items

    final systemUiOverlayStyle = SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
      statusBarIconBrightness: isDarkMode ? Brightness.light : Brightness.dark,
      systemNavigationBarIconBrightness: isDarkMode ? Brightness.light : Brightness.dark,
      systemNavigationBarDividerColor: Colors.transparent,
    );
    SystemChrome.setSystemUIOverlayStyle(systemUiOverlayStyle);

    bool isSearchActive = _searchFocusNode.hasFocus || _searchController.text.isNotEmpty;
    // Determine if the search results area should be shown (this variable is for the content list)
    bool showSearchResultsArea = _selectedIndex == 0 && (_fetchedVideos.isNotEmpty || _isLoading || _searchError.isNotEmpty);
    
    // --- Revised Header Visibility Logic ---
    // isSearchActive is defined above. The new header logic simplifies its direct use for showFullHeader.
    final bool isHomeScreen = _selectedIndex == 0;
    
    final bool showFullHeader = isHomeScreen; // "Hello, User" header now always shows on Home screen.
    final bool showTitleHeader = (_selectedIndex == 1 || _selectedIndex == 2); // Show "History" or "Favorites" title.
    // Profile screen (_selectedIndex == 3) will result in showHeaderArea being false with this logic.
    final bool showHeaderArea = showFullHeader || showTitleHeader; // Render the header container if main or title header is visible.
    
    String pageTitle = '';
    if (_selectedIndex == 1) pageTitle = 'History';
    if (_selectedIndex == 2) pageTitle = 'Favorites';

    bool showSearchBar = _selectedIndex == 0; 

    final Color selectedItemColorNav = isDarkMode ? colorScheme.primary : colorScheme.primary;
    final Color unselectedItemColorNav = isDarkMode ? Colors.grey[400]! : Colors.grey[600]!;

    final double topSafeArea = MediaQuery.of(context).padding.top;
    const double baseHeaderHeight = 60.0;
    const double headerVerticalPadding = 8.0;
    // final double headerHeight = baseHeaderHeight + (headerVerticalPadding * 2); // Not directly used, SizedBox has fixed height
    final double contentTopPadding = topSafeArea + headerVerticalPadding; 
    const double searchBarTopMargin = 22.0;

    return Scaffold(
      body: SafeArea(
        bottom: false, 
        child: Column(
          children: [
            if (showHeaderArea)
              Padding(
                padding: EdgeInsets.only(top: contentTopPadding, left: 16.0, right: 16.0, bottom: headerVerticalPadding), // Added bottom padding to header
                child: SizedBox(
                  height: baseHeaderHeight, // Use baseHeaderHeight for the content part of header
                  child: Stack(
                    children: [
                      if (showFullHeader)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Hello, $displayName',
                                  style: theme.textTheme.headlineSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2.0),
                                Text(
                                  'Welcome to NextSight', // Reverted to original welcome message
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
                                  ),
                                ),
                              ],
                            ),
                            CircleAvatar(
                              radius: 24,
                              backgroundImage: photoURL != null ? NetworkImage(photoURL) : null,
                              child: photoURL == null ? const Icon(Icons.person) : null,
                            ),
                          ],
                        ),
                      if (showTitleHeader)
                        Align(
                          alignment: Alignment.topLeft,
                           // Adjust padding to vertically center the title within baseHeaderHeight
                          child: Padding(
                            padding: EdgeInsets.only(top: (baseHeaderHeight - (theme.textTheme.headlineLarge?.fontSize ?? 32)) / 2),
                            child: Text(
                              pageTitle,
                              style: theme.textTheme.headlineLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),

            if (showSearchBar)
              Padding(
                padding: EdgeInsets.only(
                  left: 24.0, 
                  right: 24.0,
                  // Adjust top padding based on whether header is shown
                  top: showHeaderArea ? searchBarTopMargin : contentTopPadding + searchBarTopMargin, 
                  bottom: 8.0 
                ),
                child: GlassmorphicSearchBar(
                  onSubmitted: _handleSearchSubmitted,
                  hintText: 'Search YouTube videos...',
                  controller: _searchController, // Pass the controller
                  focusNode: _searchFocusNode, // Pass the focus node
                  showBackButton: _showSearchBackButton, // Control icon state
                  onBackButtonPressed: _handleSearchBackButtonPressed, // Handle back press
                ),
              ),
            
            // --- Loading Indicator for Search ---
            if (_isLoading && _selectedIndex == 0) 
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Center(child: CircularProgressIndicator()),
              ),
            
            // --- Error Message for Search ---
            if (_searchError.isNotEmpty && _selectedIndex == 0) 
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Center(child: Text(_searchError, style: const TextStyle(color: Colors.red))),
              ),

            // --- Content Area: Either search results or other tab content ---
            Expanded(
              child: (_selectedIndex == 0 && (_fetchedVideos.isNotEmpty || _isLoading || _searchError.isNotEmpty))
                  // If on home tab (selectedIndex == 0) AND
                  // (there are fetched videos OR it's loading OR there's an error),
                  // THEN show ListView for results.
                  ? ListView.builder( 
                      padding: const EdgeInsets.all(8.0),
                      itemCount: _fetchedVideos.length,
                      itemBuilder: (context, index) {
                        final video = _fetchedVideos[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
                          child: ListTile(
                            leading: video.thumbnailUrl != null && video.thumbnailUrl!.isNotEmpty
                                ? Image.network(video.thumbnailUrl!, width: 100, fit: BoxFit.cover, 
                                    errorBuilder: (context, error, stackTrace) => Container(width: 100, height: 56, color: Colors.grey[300], child: Icon(Icons.broken_image, color: Colors.grey[600])))
                                : Container(width: 100, height: 56, color: Colors.grey[300], child: Icon(Icons.videocam_off, color: Colors.grey[600])),
                            title: Text(video.title, style: TextStyle(color: textColor)),
                            subtitle: Text(video.channelTitle ?? '', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: textColor.withOpacity(0.7))),
                            trailing: Text(
                              // Format the score to 2 decimal places, or show N/A
                              video.score != null ? video.score!.toStringAsFixed(2) : 'N/A', 
                              style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
                            ),
                            onTap: () {
                              log('Tapped on video: ${video.title} (ID: ${video.videoId})', name: 'MainScreen');
                              // TODO: Navigate to a video player screen or handle tap
                            },
                          ),
                        );
                      },
                    )
                  // Otherwise (not on home tab OR no search activity on home tab),
                  // show the standard IndexedStack for tab content (which includes HomeScreenContent for index 0).
                  : IndexedStack( 
                      index: _selectedIndex,
                      children: _widgetOptions,
                    ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: EdgeInsets.only(bottom: _bottomPadding), 
        child: Container(
          height: 80.0, 
          margin: const EdgeInsets.only(left: 12.0, right: 12.0, bottom: 12.0), 
          decoration: BoxDecoration(
            color: isDarkMode ? const Color(0xFF2C2C2E) : Colors.white,
            borderRadius: BorderRadius.circular(40.0),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDarkMode ? 0.4 : 0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect( 
            borderRadius: BorderRadius.circular(40.0), 
            child: BottomNavigationBar(
              items: <BottomNavigationBarItem>[
                _buildNavItem(Icons.home_outlined, Icons.home, 'Home', 0, selectedItemColorNav, unselectedItemColorNav),
                _buildNavItem(Icons.history_outlined, Icons.history, 'History', 1, selectedItemColorNav, unselectedItemColorNav),
                _buildNavItem(Icons.favorite_border, Icons.favorite, 'Favorites', 2, selectedItemColorNav, unselectedItemColorNav),
                _buildNavItem(Icons.person_outline, Icons.person, 'Profile', 3, selectedItemColorNav, unselectedItemColorNav),
              ],
              currentIndex: _selectedIndex,
              onTap: _onItemTapped,
              type: BottomNavigationBarType.fixed,
              backgroundColor: Colors.transparent,
              elevation: 0,
              showSelectedLabels: false,
              showUnselectedLabels: false,
              selectedFontSize: 0, 
              unselectedFontSize: 0,
            ),
          ),
        ),
      ),
    );
  }

  BottomNavigationBarItem _buildNavItem(
    IconData outlinedIcon, 
    IconData filledIcon, 
    String label, 
    int index, 
    Color selectedItemColor,
    Color unselectedItemColor
  ) {
    final bool isSelected = _selectedIndex == index;
    
    return BottomNavigationBarItem(
      icon: Padding(
        padding: const EdgeInsets.only(top: 12.0), 
        child: Icon(
          isSelected ? filledIcon : outlinedIcon,
          color: isSelected ? selectedItemColor : unselectedItemColor, 
          size: 26, 
        ),
      ),
      label: '', 
    );
  }
}