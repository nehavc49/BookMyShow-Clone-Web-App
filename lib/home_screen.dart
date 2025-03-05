import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'bookings_screen.dart'; // Used for navigation
import 'profile_screen.dart';
import 'bookinghistoryscreen.dart'; // Used for navigation

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  String _selectedCategory = 'All';
  String? _selectedLocationId; // Track selected location ID
  String? _selectedLocationName; // Track selected location name
  final PageController _pageController = PageController();
  final List<String> categories = [
    'All',
    'Action',
    'Comedy',
    'Drama',
    'Horror'
  ];

  // Firestore instance
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Fetch movies from Firestore based on selected location
  Future<List<Map<String, dynamic>>> _fetchMovies() async {
    try {
      Query query = _firestore.collection('movies');

      // Filter movies by location if a location is selected
      if (_selectedLocationId != null) {
        query = query.where('locationId', isEqualTo: _selectedLocationId);
      }

      final QuerySnapshot snapshot = await query.get();
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          'id': doc.id,
          'title': data['title'] ?? 'No Title',
          'imageUrl': data['imageUrl'] ?? '',
          'genre': data['genre'] ?? 'Unknown Genre',
          'rating': data['rating']?.toString() ?? '0.0',
          'duration': data['duration']?.toString() ?? '0',
          'price': data['price']?.toString() ?? '0',
          'locationId':
              data['locationId'] ?? '', // Ensure locationId is included
        };
      }).toList();
    } catch (e) {
      print('Error fetching movies: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading movies: ${e.toString()}')),
      );
      return [];
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // Method to handle navigation bar item selection
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    // Navigate to the corresponding screen
    switch (index) {
      case 0: // Home
        // Already on the home screen
        break;
      case 1: // Bookings
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => BookingHistoryScreen()),
        );
        break;
      case 2: // Profile
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => ProfileScreen()),
        );
        break;
    }
  }

  Widget _buildBanner(List<Map<String, dynamic>> movies) {
    return Container(
      height: 250,
      child: CarouselSlider.builder(
        itemCount: movies.length,
        options: CarouselOptions(
          height: 250,
          viewportFraction: 0.9,
          enlargeCenterPage: true,
          autoPlay: true,
          autoPlayInterval: Duration(seconds: 3),
          autoPlayAnimationDuration: Duration(milliseconds: 800),
        ),
        itemBuilder: (context, index, realIndex) {
          final movie = movies[index];
          return GestureDetector(
            onTap: () {
              // Navigate to movie details/booking screen
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => BookingScreen(movieId: movie['id']),
                ),
              );
            },
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: 5),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 5,
                    offset: Offset(0, 2),
                  )
                ],
              ),
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: Image.network(
                      movie['imageUrl'],
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey[300],
                          child: Icon(Icons.error),
                        );
                      },
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.7),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 20,
                    left: 20,
                    right: 20,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          movie['title'],
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.star, color: Colors.amber, size: 20),
                            SizedBox(width: 4),
                            Text(
                              movie['rating'],
                              style: TextStyle(color: Colors.white),
                            ),
                            SizedBox(width: 16),
                            Icon(Icons.access_time,
                                color: Colors.white, size: 20),
                            SizedBox(width: 4),
                            Text(
                              movie['duration'],
                              style: TextStyle(color: Colors.white),
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              movie['genre'],
                              style: TextStyle(color: Colors.white70),
                            ),
                            ElevatedButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        BookingScreen(movieId: movie['id']),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                              child: Text('Book Now'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCategoryChips() {
    return Container(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 16),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(categories[index]),
              selected: _selectedCategory == categories[index],
              onSelected: (selected) {
                setState(() {
                  _selectedCategory = selected ? categories[index] : 'All';
                });
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildMovieGrid(List<Map<String, dynamic>> movies) {
    return GridView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      padding: EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.7,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: movies.length,
      itemBuilder: (context, index) {
        final movie = movies[index];
        return Card(
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          elevation: 5,
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => BookingScreen(movieId: movie['id']),
                ),
              );
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: Image.network(
                    movie['imageUrl'],
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey[300],
                        child: Icon(Icons.error),
                      );
                    },
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Padding(
                    padding: EdgeInsets.all(8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          movie['title'],
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 14),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 4),
                        Text(
                          movie['genre'],
                          style:
                              TextStyle(color: Colors.grey[600], fontSize: 12),
                        ),
                        Spacer(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.star, color: Colors.amber, size: 16),
                                SizedBox(width: 4),
                                Text(
                                  movie['rating'],
                                  style: TextStyle(fontSize: 12),
                                ),
                              ],
                            ),
                            Text(
                              movie['price'],
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.location_on, size: 20),
            SizedBox(width: 8),
            Text(_selectedLocationName ??
                'Select Location'), // Display location name
            IconButton(
              icon: Icon(Icons.arrow_drop_down),
              onPressed: () {
                _showLocationSelector(context); // Open location selector
              },
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.notifications),
            onPressed: () {},
          ),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _fetchMovies(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No movies found for this location'));
          }

          final movies = snapshot.data!;
          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildBanner(movies),
                SizedBox(height: 16),
                _buildCategoryChips(),
                Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Now Showing',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
                _buildMovieGrid(movies),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onItemTapped,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.book),
            label: 'Bookings',
          ),
          NavigationDestination(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  // Method to show location selector
  void _showLocationSelector(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => FutureBuilder<QuerySnapshot>(
        future: _firestore.collection('locations').get(),
        builder: (ctx, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error loading locations'));
          }
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          final locations = snapshot.data!.docs;
          return ListView.builder(
            padding: EdgeInsets.all(16),
            itemCount: locations.length,
            itemBuilder: (ctx, i) => ListTile(
              leading: Icon(Icons.location_on),
              title: Text(locations[i]['name']),
              onTap: () {
                setState(() {
                _selectedLocationId = locations[i].id; // Use document ID
                _selectedLocationName = locations[i]['name'];
              });
                Navigator.pop(ctx); // Close the bottom sheet
                _fetchMovies(); // Refresh movies after selecting location
              },
            ),
          );
        },
      ),
    );
  }
}
