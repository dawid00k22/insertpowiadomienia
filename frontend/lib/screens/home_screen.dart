import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:intl/intl.dart';
import 'package:frontend/screens/login_screen.dart';
import 'package:frontend/models/notification_item.dart';
import 'package:frontend/services/notification_service.dart';
import '../theme/colors.dart';

class HomeScreen extends StatefulWidget {
  final String email;

  const HomeScreen({required this.email});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<List<NotificationItem>> futureNotifications;
  List<NotificationItem> _allNotifications = [];
  List<NotificationItem> _filteredNotifications = [];
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    futureNotifications = fetchNotifications();
    futureNotifications.then((notifications) {
      setState(() {
        _allNotifications = notifications;
        _filteredNotifications = notifications;
      });
    });
  }

  void _filterSearchResults(String query) {
    setState(() {
      _filteredNotifications = _allNotifications
          .where((item) => item.title.toLowerCase().contains(query.toLowerCase()) ||
              item.excerpt.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  void _signOut(BuildContext context) async {
    await GoogleSignIn().signOut();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LoginScreen()),
    );
  }

  Future<void> _refreshNotifications() async {
    final refreshed = await fetchNotifications();
    setState(() {
      _allNotifications = refreshed;
      _filteredNotifications = refreshed;
    });
  }

  void _showPostDialog(BuildContext context, NotificationItem post) {
    final formattedDate = DateFormat('dd.MM.yyyy HH:mm').format(DateTime.parse(post.scheduledTime));
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(16),
        child: DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.85,
          maxChildSize: 0.95,
          minChildSize: 0.6,
          builder: (context, scrollController) => SingleChildScrollView(
            controller: scrollController,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      post.leadingImage,
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Icon(Icons.broken_image, size: 100),
                    ),
                  ),
                ),
                SizedBox(height: 10),
                Center(
                  child: Text(
                    formattedDate,
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ),
                SizedBox(height: 16),
                Text(post.title, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                SizedBox(height: 10),
                Text(post.content, style: TextStyle(fontSize: 16)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _timeAgo(DateTime dateTime) {
  final now = DateTime.now();
  final difference = now.difference(dateTime);

  if (difference.inSeconds < 0) {
    final futureDiff = dateTime.difference(now);
    if (futureDiff.inDays > 1) return 'za ${futureDiff.inDays} dni';
    if (futureDiff.inHours > 1) return 'za ${futureDiff.inHours} godzin';
    if (futureDiff.inMinutes > 1) return 'za ${futureDiff.inMinutes} minut';
    return 'za chwilę';
  } else {
    if (difference.inDays > 1) return '${difference.inDays} dni temu';
    if (difference.inHours > 1) return '${difference.inHours} godzin temu';
    if (difference.inMinutes > 1) return '${difference.inMinutes} minut temu';
    return 'przed chwilą';
  }
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF0071B8),
      appBar: AppBar(
        backgroundColor: Color(0xFF0071B8),
        elevation: 0,
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                onChanged: _filterSearchResults,
                decoration: InputDecoration(
                  hintText: 'Szukaj...',
                  border: InputBorder.none,
                  hintStyle: TextStyle(color: Colors.white70),
                ),
                style: TextStyle(color: Colors.white),
              )
            : Image.asset(
                'assets/logoinsert.png',
                height: 116,
              ),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            iconSize: 36,
            onPressed: () {
              setState(() {
                if (_isSearching) {
                  _searchController.clear();
                  _filteredNotifications = _allNotifications;
                }
                _isSearching = !_isSearching;
              });
            },
          ),
          IconButton(
            icon: Icon(Icons.logout),
            iconSize: 36,
            onPressed: () => _signOut(context),
          )
        ],
      ),
      body: FutureBuilder<List<NotificationItem>>(
        future: futureNotifications,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text("Błąd: \${snapshot.error}"));
          }

          return RefreshIndicator(
            onRefresh: _refreshNotifications,
            child: ListView.builder(
              itemCount: _filteredNotifications.length,
              itemBuilder: (context, index) {
                final post = _filteredNotifications[index];
                return GestureDetector(
                  onLongPress: () => _showPostDialog(context, post),
                  child: Card(
                    margin: EdgeInsets.all(10),
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 4,
                    child: ExpansionTile(
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          post.leadingImage,
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              Icon(Icons.broken_image),
                        ),
                      ),
                      title: Text(
                        post.title,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryDark,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            post.excerpt,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 4),
                          Text(
                            _timeAgo(DateTime.parse(post.scheduledTime)),
                            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Text(post.content),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
