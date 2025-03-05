import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'bookinghistoryscreen.dart';

class BookingScreen extends StatefulWidget {
  final String movieId;

  const BookingScreen({required this.movieId});

  @override
  _BookingScreenState createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  int selectedSeats = 1;
  String? selectedTime;
  List<String> selectedSeatNumbers = [];
  final double ticketPrice = 150;
  final List<String> showTimes = [
    '10:00 AM',
    '1:00 PM',
    '4:00 PM',
    '7:00 PM',
    '10:00 PM',
  ];
  final int rows = 8;
  final int seatsPerRow = 10;
  final Set<String> bookedSeats = {};

  @override
  void initState() {
    super.initState();
    _fetchBookedSeats();
  }

  Future<void> _fetchBookedSeats() async {
    if (selectedTime == null) return;

    final bookingsSnapshot = await FirebaseFirestore.instance
        .collection('bookings')
        .where('movieId', isEqualTo: widget.movieId)
        .where('showTime', isEqualTo: selectedTime)
        .get();

    setState(() {
      bookedSeats.clear();
      for (var doc in bookingsSnapshot.docs) {
        List<String> seats = List<String>.from(doc['seatNumbers']);
        bookedSeats.addAll(seats);
      }
    });
  }

  Future<void> _bookTicket(BuildContext context) async {
    if (selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select a show time')),
      );
      return;
    }

    if (selectedSeatNumbers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select your seats')),
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please sign in to book tickets')),
      );
      return;
    }

    try {
      // Validate movie exists
      final movieDoc = await FirebaseFirestore.instance
          .collection('movies')
          .doc(widget.movieId)
          .get();

      if (!movieDoc.exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Movie not found')),
        );
        return;
      }

      // Create booking document
      await FirebaseFirestore.instance.collection('bookings').add({
        'userId': user.uid,
        'movieId': widget.movieId,
        'movieTitle': movieDoc['title'],
        'timestamp': DateTime.now(),
        'showTime': selectedTime,
        'seatNumbers': selectedSeatNumbers,
        'totalAmount': ticketPrice * selectedSeatNumbers.length,
        'status': 'confirmed'
      });

      // Update user's booking history
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('bookingHistory')
          .add({
        'movieId': widget.movieId,
        'movieTitle': movieDoc['title'],
        'timestamp': DateTime.now(),
        'showTime': selectedTime,
        'seatNumbers': selectedSeatNumbers,
        'totalAmount': ticketPrice * selectedSeatNumbers.length,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Tickets booked successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      // Reset selection
      setState(() {
        selectedSeatNumbers.clear();
        selectedTime = null;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to book tickets. Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildSeatLayout() {
    return Container(
      height: 300,
      child: SingleChildScrollView(
        child: Column(
          children: List.generate(rows, (row) {
            return Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(seatsPerRow, (seat) {
                final seatNumber =
                    '${String.fromCharCode(65 + row)}${seat + 1}';
                final isSelected = selectedSeatNumbers.contains(seatNumber);
                final isBooked = bookedSeats.contains(seatNumber);

                return Padding(
                  padding: EdgeInsets.all(4),
                  child: InkWell(
                    onTap: isBooked
                        ? null
                        : () {
                            setState(() {
                              if (isSelected) {
                                selectedSeatNumbers.remove(seatNumber);
                              } else {
                                selectedSeatNumbers.add(seatNumber);
                              }
                            });
                          },
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: isBooked
                            ? Colors.grey
                            : isSelected
                                ? Colors.green
                                : Colors.blue,
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Center(
                        child: Text(
                          seatNumber,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            );
          }),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Book Ticket'),
        actions: [
          IconButton(
            icon: Icon(Icons.history),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => BookingHistoryScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection('movies')
            .doc(widget.movieId)
            .get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return Center(child: Text('Movie not found'));
          }

          final movie = snapshot.data!;
          return SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    movie['title'],
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 16),
                  Text('Genre: ${movie['genre']}'),
                  Text('Duration: ${movie['duration']} mins'),
                  Text('Rating: ${movie['rating']}'),
                  SizedBox(height: 24),
                  Text(
                    'Select Show Time',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: showTimes.map((time) {
                        return Padding(
                          padding: EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(time),
                            selected: selectedTime == time,
                            onSelected: (selected) {
                              setState(() {
                                selectedTime = selected ? time : null;
                                selectedSeatNumbers.clear();
                              });
                              _fetchBookedSeats();
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  SizedBox(height: 24),
                  Text(
                    'Select Seats',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  _buildSeatLayout(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildLegendItem('Available', Colors.blue),
                      SizedBox(width: 16),
                      _buildLegendItem('Selected', Colors.green),
                      SizedBox(width: 16),
                      _buildLegendItem('Booked', Colors.grey),
                    ],
                  ),
                  SizedBox(height: 24),
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Price Summary',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Tickets (${selectedSeatNumbers.length}x)'),
                            Text(
                              '\$${(ticketPrice * selectedSeatNumbers.length).toStringAsFixed(2)}',
                            ),
                          ],
                        ),
                        Divider(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Total',
                                style: TextStyle(fontWeight: FontWeight.bold)),
                            Text(
                              '\$${(ticketPrice * selectedSeatNumbers.length).toStringAsFixed(2)}',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => _bookTicket(context),
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Text(
                        'Book ${selectedSeatNumbers.length} Ticket(s)',
                        style: TextStyle(fontSize: 16),
                      ),
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

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        SizedBox(width: 4),
        Text(label),
      ],
    );
  }
}
