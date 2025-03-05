import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'bookings_screen.dart';

class MovieListScreen extends StatefulWidget {
  @override
  _MovieListScreenState createState() => _MovieListScreenState();
}

class _MovieListScreenState extends State<MovieListScreen> {
  String? _selectedLocationId;
  String? _selectedLocationName;
  final Future<SharedPreferences> _prefs = SharedPreferences.getInstance();

  @override
  void initState() {
    super.initState();
    _loadLocation();
  }

  void _loadLocation() async {
    final prefs = await _prefs;
    setState(() {
      _selectedLocationId = prefs.getString('locationId');
      _selectedLocationName = prefs.getString('locationName');
    });
  }

  void _saveLocation(String? id, String? name) async {
    if (id == null || name == null) return;
    final prefs = await _prefs;
    await prefs.setString('locationId', id);
    await prefs.setString('locationName', name);
    setState(() {
      _selectedLocationId = id;
      _selectedLocationName = name;
    });
  }

  // Add the _showLocationSelector method here
  void _showLocationSelector(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => FutureBuilder<QuerySnapshot>(
        future: FirebaseFirestore.instance.collection('locations').get(),
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
              subtitle: Text(locations[i]['theaters'].join(', ')),
              onTap: () {
                _saveLocation(locations[i].id, locations[i]['name']);
                Navigator.pop(ctx);
              },
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Movie Booking'),
        actions: [
          IconButton(
            icon: Icon(Icons.location_on),
            onPressed: () => _showLocationSelector(context),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.location_on, color: Colors.blue),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _selectedLocationName != null
                        ? 'Selected Location: $_selectedLocationName'
                        : 'Select Location',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
                TextButton.icon(
                  icon: Icon(Icons.arrow_drop_down),
                  label: Text('Change'),
                  onPressed: () => _showLocationSelector(context),
                ),
              ],
            ),
          ),
          Expanded(
            child: _selectedLocationId == null
                ? Center(child: Text('Select a location'))
                : StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('movies')
                        .where('location', isEqualTo: _selectedLocationId)
                        .snapshots(),
                    builder: (ctx, snapshot) {
                      if (snapshot.hasError)
                        return Center(child: Text('Error loading movies'));
                      if (!snapshot.hasData)
                        return Center(child: CircularProgressIndicator());

                      final movies = snapshot.data!.docs;
                      if (movies.isEmpty)
                        return Center(
                            child: Text('No movies found for this location'));

                      return GridView.builder(
                        padding: EdgeInsets.all(8),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.7,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                        ),
                        itemCount: movies.length,
                        itemBuilder: (ctx, i) => MovieCard(movies[i]),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class MovieCard extends StatelessWidget {
  final QueryDocumentSnapshot movie;

  MovieCard(this.movie);

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 4,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
            child: CachedNetworkImage(
              imageUrl: movie['imageUrl'],
              height: 180,
              fit: BoxFit.cover,
              placeholder: (ctx, url) => Container(color: Colors.grey[200]),
              errorWidget: (ctx, url, err) => Icon(Icons.error),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  movie['title'],
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 8),
                RatingBar.builder(
                  initialRating: double.parse(movie['rating'].toString()),
                  minRating: 1,
                  direction: Axis.horizontal,
                  allowHalfRating: true,
                  itemCount: 5,
                  itemSize: 20,
                  itemPadding: EdgeInsets.symmetric(horizontal: 2),
                  itemBuilder: (context, _) =>
                      Icon(Icons.star, color: Colors.amber),
                  onRatingUpdate: (rating) {},
                  ignoreGestures: true,
                ),
                SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.movie_filter, size: 16),
                    SizedBox(width: 4),
                    Text(movie['genre'],
                        style: TextStyle(color: Colors.grey[600])),
                  ],
                ),
                SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.schedule, size: 16),
                    SizedBox(width: 4),
                    Text('${movie['duration']} mins'),
                  ],
                ),
                SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => BookingScreen(
                            movieId: movie.id), // Pass movieId here
                      ),
                    );
                  },
                  child: Text('Book Now'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
