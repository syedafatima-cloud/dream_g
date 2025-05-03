import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CustomerReview {
  final String customerName;
  final String productName;
  final double rating;
  final String reviewText;
  final DateTime date;
  final String? photoUrl;
  bool isDisplayed;
  bool isResponded;
  String? responseText;

  CustomerReview({
    required this.customerName,
    required this.productName,
    required this.rating,
    required this.reviewText,
    required this.date,
    this.photoUrl,
    this.isDisplayed = true,
    this.isResponded = false,
    this.responseText,
  });
}

class CustomerReviewsPage extends StatefulWidget {
  const CustomerReviewsPage({super.key});

  @override
  _CustomerReviewsPageState createState() => _CustomerReviewsPageState();
}

class _CustomerReviewsPageState extends State<CustomerReviewsPage> {
  // Mock data for customer reviews
  final List<CustomerReview> _reviews = [
    CustomerReview(
      customerName: 'John Smith',
      productName: 'Red Roses Bouquet',
      rating: 4.5,
      reviewText: 'Beautiful roses! They were fresh and lasted over a week. The arrangement was exactly as pictured.',
      date: DateTime.now().subtract(const Duration(days: 2)),
      photoUrl: null,
      isResponded: true,
      responseText: 'Thank you for your kind words, John! We\'re glad you enjoyed the roses.',
    ),
    CustomerReview(
      customerName: 'Sarah Johnson',
      productName: 'Birthday Gift Box',
      rating: 5.0,
      reviewText: 'Perfect gift for my sister\'s birthday! The chocolates were delicious and the presentation was amazing.',
      date: DateTime.now().subtract(const Duration(days: 5)),
    ),
    CustomerReview(
      customerName: 'Michael Brown',
      productName: 'Anniversary Special',
      rating: 3.0,
      reviewText: 'Delivery was on time, but some flowers were slightly wilted. Overall decent but expected better for the price.',
      date: DateTime.now().subtract(const Duration(days: 7)),
    ),
    CustomerReview(
      customerName: 'Emily Davis',
      productName: 'Mixed Flowers Vase',
      rating: 4.0,
      reviewText: 'Beautiful arrangement and prompt delivery. Would order again!',
      date: DateTime.now().subtract(const Duration(days: 10)),
    ),
    CustomerReview(
      customerName: 'David Wilson',
      productName: 'Chocolate Hamper',
      rating: 2.5,
      reviewText: 'Packaging was damaged upon arrival. Some chocolates were melted. Disappointed with the overall experience.',
      date: DateTime.now().subtract(const Duration(days: 14)),
      isDisplayed: false,
    ),
  ];

  String _filterOption = 'All Reviews';
  final List<String> _filterOptions = [
    'All Reviews', 
    'High Ratings (4-5)', 
    'Low Ratings (1-3)', 
    'Responded', 
    'Not Responded',
    'Hidden Reviews'
  ];
  String _sortOption = 'Newest First';
  final List<String> _sortOptions = ['Newest First', 'Oldest First', 'Highest Rating', 'Lowest Rating'];
  
  final TextEditingController _responseController = TextEditingController();
  int? _selectedReviewIndex;

  @override
  void dispose() {
    _responseController.dispose();
    super.dispose();
  }

  List<CustomerReview> get _filteredReviews {
    List<CustomerReview> filtered;
    
    // Apply filter
    switch (_filterOption) {
      case 'High Ratings (4-5)':
        filtered = _reviews.where((review) => review.rating >= 4.0 && review.isDisplayed).toList();
        break;
      case 'Low Ratings (1-3)':
        filtered = _reviews.where((review) => review.rating < 4.0 && review.isDisplayed).toList();
        break;
      case 'Responded':
        filtered = _reviews.where((review) => review.isResponded && review.isDisplayed).toList();
        break;
      case 'Not Responded':
        filtered = _reviews.where((review) => !review.isResponded && review.isDisplayed).toList();
        break;
      case 'Hidden Reviews':
        filtered = _reviews.where((review) => !review.isDisplayed).toList();
        break;
      default:
        filtered = _reviews.where((review) => review.isDisplayed).toList();
    }
    
    // Apply sort
    switch (_sortOption) {
      case 'Oldest First':
        filtered.sort((a, b) => a.date.compareTo(b.date));
        break;
      case 'Highest Rating':
        filtered.sort((a, b) => b.rating.compareTo(a.rating));
        break;
      case 'Lowest Rating':
        filtered.sort((a, b) => a.rating.compareTo(b.rating));
        break;
      default:
        filtered.sort((a, b) => b.date.compareTo(a.date)); // Newest first
    }
    
    return filtered;
  }

  void _toggleReviewVisibility(int index) {
    setState(() {
      final CustomerReview review = _reviews.firstWhere(
        (r) => r == _filteredReviews[index],
      );
      review.isDisplayed = !review.isDisplayed;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _filteredReviews[index].isDisplayed 
              ? 'Review is now visible to customers' 
              : 'Review has been hidden from customers'
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _respondToReview(int index) {
    showDialog(
      context: context,
      builder: (context) {
        _responseController.text = _filteredReviews[index].responseText ?? '';
        return AlertDialog(
          title: const Text('Respond to Review'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Responding to ${_filteredReviews[index].customerName}\'s review of ${_filteredReviews[index].productName}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                _filteredReviews[index].reviewText,
                style: const TextStyle(fontStyle: FontStyle.italic),
              ),
              const SizedBox(height: 16),
              const Text('Your Response:'),
              const SizedBox(height: 8),
              TextField(
                controller: _responseController,
                maxLines: 5,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Type your response here...',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  final CustomerReview review = _reviews.firstWhere(
                    (r) => r == _filteredReviews[index],
                  );
                  review.isResponded = _responseController.text.isNotEmpty;
                  review.responseText = _responseController.text.isEmpty 
                      ? null 
                      : _responseController.text;
                });
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Response submitted successfully'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              child: const Text('Submit Response'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildRatingStars(double rating) {
    return Row(
      children: List.generate(5, (index) {
        if (index < rating.floor()) {
          return const Icon(Icons.star, color: Colors.amber, size: 16);
        } else if (index == rating.floor() && rating % 1 != 0) {
          return const Icon(Icons.star_half, color: Colors.amber, size: 16);
        } else {
          return const Icon(Icons.star_border, color: Colors.amber, size: 16);
        }
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Customer Reviews'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary section - MADE SMALLER
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
            color: Colors.grey.shade100,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildSummaryCard(
                  title: 'Total Reviews',
                  value: _reviews.where((r) => r.isDisplayed).length.toString(),
                  icon: Icons.rate_review,
                  color: Colors.blue,
                ),
                _buildSummaryCard(
                  title: 'Avg Rating',
                  value: (_reviews.where((r) => r.isDisplayed).fold<double>(0, (sum, item) => sum + item.rating) / 
                          _reviews.where((r) => r.isDisplayed).length)
                      .toStringAsFixed(1),
                  icon: Icons.star,
                  color: Colors.amber,
                ),
                _buildSummaryCard(
                  title: 'Pending',
                  value: _reviews.where((r) => r.isDisplayed && !r.isResponded).length.toString(),
                  icon: Icons.message,
                  color: Colors.green,
                ),
              ],
            ),
          ),
          
          // Filter and sort controls - MADE SMALLER
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _filterOption,
                    decoration: InputDecoration(
                      labelText: 'Filter',
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    items: _filterOptions.map((String option) {
                      return DropdownMenuItem<String>(
                        value: option,
                        child: Text(option, style: const TextStyle(fontSize: 13)),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        setState(() {
                          _filterOption = newValue;
                        });
                      }
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _sortOption,
                    decoration: InputDecoration(
                      labelText: 'Sort By',
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    items: _sortOptions.map((String option) {
                      return DropdownMenuItem<String>(
                        value: option,
                        child: Text(option, style: const TextStyle(fontSize: 13)),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        setState(() {
                          _sortOption = newValue;
                        });
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
          
          // Reviews list
          Expanded(
            child: _filteredReviews.isEmpty
                ? const Center(
                    child: Text(
                      'No reviews found matching the current filters.',
                      style: TextStyle(fontSize: 16),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.only(bottom: 16),
                    itemCount: _filteredReviews.length,
                    itemBuilder: (context, index) {
                      final review = _filteredReviews[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        elevation: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ListTile(
                              title: Row(
                                children: [
                                  Text(
                                    review.customerName,
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: review.rating >= 4
                                          ? Colors.green.shade100
                                          : review.rating >= 3
                                              ? Colors.amber.shade100
                                              : Colors.red.shade100,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      review.rating.toString(),
                                      style: TextStyle(
                                        color: review.rating >= 4
                                            ? Colors.green.shade800
                                            : review.rating >= 3
                                                ? Colors.amber.shade800
                                                : Colors.red.shade800,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4),
                                  Text(
                                    'Product: ${review.productName}',
                                    style: TextStyle(
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  _buildRatingStars(review.rating),
                                  const SizedBox(height: 4),
                                  Text(
                                    DateFormat('MMM dd, yyyy').format(review.date),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                              trailing: PopupMenuButton<String>(
                                onSelected: (value) {
                                  if (value == 'respond') {
                                    _respondToReview(index);
                                  } else if (value == 'toggle_visibility') {
                                    _toggleReviewVisibility(index);
                                  }
                                },
                                itemBuilder: (context) => [
                                  PopupMenuItem(
                                    value: 'respond',
                                    child: Row(
                                      children: [
                                        Icon(
                                          review.isResponded ? Icons.edit : Icons.reply,
                                          size: 16,
                                          color: Colors.blue,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          review.isResponded ? 'Edit Response' : 'Respond',
                                        ),
                                      ],
                                    ),
                                  ),
                                  PopupMenuItem(
                                    value: 'toggle_visibility',
                                    child: Row(
                                      children: [
                                        Icon(
                                          review.isDisplayed ? Icons.visibility_off : Icons.visibility,
                                          size: 16,
                                          color: review.isDisplayed ? Colors.red : Colors.green,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          review.isDisplayed ? 'Hide Review' : 'Show Review',
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    review.reviewText,
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                  if (review.isResponded && review.responseText != null) ...[
                                    const SizedBox(height: 16),
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.blue.shade50,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: Colors.blue.shade100,
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Row(
                                            children: [
                                              Icon(
                                                Icons.store,
                                                size: 16,
                                                color: Colors.blue,
                                              ),
                                              SizedBox(width: 8),
                                              Text(
                                                'Your Response:',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.blue,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          Text(review.responseText!),
                                        ],
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            OverflowBar(
                              alignment: MainAxisAlignment.end,
                              children: [
                                if (!review.isResponded)
                                  TextButton.icon(
                                    icon: const Icon(Icons.reply, size: 16),
                                    label: const Text('Respond', style: TextStyle(fontSize: 13)),
                                    onPressed: () => _respondToReview(index),
                                  )
                                else
                                  TextButton.icon(
                                    icon: const Icon(Icons.edit, size: 16),
                                    label: const Text('Edit Response', style: TextStyle(fontSize: 13)),
                                    onPressed: () => _respondToReview(index),
                                  ),
                                TextButton.icon(
                                  icon: Icon(
                                    review.isDisplayed ? Icons.visibility_off : Icons.visibility,
                                    size: 16,
                                  ),
                                  label: Text(
                                    review.isDisplayed ? 'Hide' : 'Show',
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                  onPressed: () => _toggleReviewVisibility(index),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      width: 90,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 10,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}