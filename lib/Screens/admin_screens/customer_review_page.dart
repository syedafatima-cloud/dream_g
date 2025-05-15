import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mobile_ap/pastel_theme.dart';

class CustomerReview {
  final String id; // Document ID from Firestore
  final String customerName;
  final String productId; // Added productId field
  final String productName;
  final double rating;
  final String reviewText;
  final DateTime date;
  final String? photoUrl;
  bool isDisplayed;
  bool isResponded;
  String? responseText;

  CustomerReview({
    required this.id,
    required this.customerName,
    required this.productId, // Added productId field
    required this.productName,
    required this.rating,
    required this.reviewText,
    required this.date,
    this.photoUrl,
    this.isDisplayed = true,
    this.isResponded = false,
    this.responseText,
  });

  // FIXED: More robust document parsing with better error handling
  factory CustomerReview.fromFirestore(DocumentSnapshot doc) {
    try {
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      
      // Debug data to see exactly what's coming from Firebase
      print('Processing review document ID: ${doc.id}');
      print('Review Data: $data');
      
      // Handle all fields with fallbacks to avoid null errors
      return CustomerReview(
        id: doc.id,
        customerName: data['customerName'] ?? 'Anonymous',
        productId: data['productId'] ?? '', // Get productId field
        productName: data['productName'] ?? 'Unknown Product',
        // FIX: More robust rating parsing
        rating: (data['rating'] is num) 
            ? (data['rating'] as num).toDouble() 
            : 0.0,
        reviewText: data['reviewText'] ?? '',
        // FIX: More robust date parsing - try multiple field names
        date: data['date'] is Timestamp 
            ? (data['date'] as Timestamp).toDate()
            : data['timestamp'] is Timestamp 
                ? (data['timestamp'] as Timestamp).toDate()
                : DateTime.now(),
        photoUrl: data['photoUrl'],
        isDisplayed: data['isDisplayed'] ?? true,
        isResponded: data['isResponded'] ?? false,
        responseText: data['responseText'],
      );
    } catch (e, stack) {
      print('Error parsing review: $e');
      print('Error stack trace: $stack');
      print('Document ID with error: ${doc.id}');
      
      // FIX: Instead of rethrowing, return a default review object
      // This prevents the entire list from failing if one document is malformed
      return CustomerReview(
        id: doc.id,
        customerName: 'Error Loading',
        productId: '',
        productName: 'Error',
        rating: 0.0,
        reviewText: 'There was an error loading this review. Please report this issue.',
        date: DateTime.now(),
        isDisplayed: false,
      );
    }
  }

  // Convert the review to a map for updating Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'customerName': customerName,
      'productId': productId, // Include productId in updates
      'productName': productName,
      'rating': rating,
      'reviewText': reviewText,
      'date': Timestamp.fromDate(date),
      'photoUrl': photoUrl,
      'isDisplayed': isDisplayed,
      'isResponded': isResponded,
      'responseText': responseText,
    };
  }
}

class CustomerReviewsPage extends StatefulWidget {
  const CustomerReviewsPage({super.key});

  @override
  _CustomerReviewsPageState createState() => _CustomerReviewsPageState();
}

class _CustomerReviewsPageState extends State<CustomerReviewsPage> {
  final CollectionReference _reviewsCollection =
      FirebaseFirestore.instance.collection('reviews');

  late Stream<QuerySnapshot> _reviewsStream;
  List<CustomerReview> _reviews = [];
  bool _isLoading = true;
  String? _errorMessage;

  // Product filter
  String? _selectedProductId;
  List<Map<String, String>> _availableProducts = [];
  bool _loadingProducts = true;

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
  
  @override
  void initState() {
    super.initState();
    // FIX: Add a small delay to ensure Firebase is fully initialized
    Future.delayed(Duration(milliseconds: 300), () {
      _loadProductsList();
      _initializeReviewsStream();
    });
  }
  
  Future<void> _loadProductsList() async {
    try {
      print('Loading products list');
      
      // Get unique products from reviews
      final snapshot = await _reviewsCollection.get();
      
      // Create a set of product IDs to avoid duplicates
      final Map<String, String> productMap = {};
      
      for (var doc in snapshot.docs) {
        try {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          final productId = data['productId'] as String?;
          final productName = data['productName'] as String?;
          
          if (productId != null && productName != null && productId.isNotEmpty) {
            productMap[productId] = productName;
          }
        } catch (e) {
          print('Error processing product: $e');
        }
      }
      
      // Convert to list
      _availableProducts = productMap.entries
          .map((entry) => {'id': entry.key, 'name': entry.value})
          .toList();
      
      setState(() {
        _loadingProducts = false;
      });
      
      print('Loaded ${_availableProducts.length} unique products');
    } catch (e) {
      print('Error loading products: $e');
      setState(() {
        _loadingProducts = false;
      });
    }
  }
  
  void _initializeReviewsStream() {
    try {
      print('Initializing Firestore reviews stream');
      
      // Updated query to match customer-side query structure
      Query query = _reviewsCollection;
      
      // Add product filter if selected
      if (_selectedProductId != null && _selectedProductId!.isNotEmpty) {
        query = query.where('productId', isEqualTo: _selectedProductId);
      }
      
      // FIX: Try to use timestamp first, fallback to date for sorting
      try {
        query = query.orderBy('timestamp', descending: true);
      } catch (e) {
        print('Error ordering by timestamp, trying date: $e');
        query = query.orderBy('date', descending: true);
      }
      
      // Set up stream from Firestore
      _reviewsStream = query.snapshots();
      
      // Listen to the stream and update the reviews list
      _reviewsStream.listen((QuerySnapshot snapshot) {
        print('Received snapshot with ${snapshot.docs.length} documents');
        
        setState(() {
          // Process each document and handle errors individually
          _reviews = [];
          for (var doc in snapshot.docs) {
            try {
              _reviews.add(CustomerReview.fromFirestore(doc));
            } catch (e) {
              print('Error processing document ${doc.id}: $e');
              // Skip this document and continue
            }
          }
          _isLoading = false;
          
          // Debug print all loaded reviews
          print('Loaded ${_reviews.length} reviews successfully');
          for (var review in _reviews) {
            print('Review: ${review.id} - ${review.customerName} - ${review.rating} - ${review.productName}');
          }
        });
      }, onError: (error) {
        print('Stream error: $error');
        setState(() {
          _errorMessage = 'Failed to load reviews: $error';
          _isLoading = false;
        });
      });
    } catch (e) {
      print('Exception in _initializeReviewsStream: $e');
      setState(() {
        _errorMessage = 'Error connecting to database: $e';
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _responseController.dispose();
    super.dispose();
  }

  List<CustomerReview> get _filteredReviews {
    // FIX: Debug filtered reviews
    print('Filtering reviews. Total reviews: ${_reviews.length}');
    
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
    
    print('Filtered reviews count: ${filtered.length}');
    return filtered;
  }

  Future<void> _toggleReviewVisibility(int index) async {
    try {
      final CustomerReview review = _filteredReviews[index];
      final bool newVisibility = !review.isDisplayed;
      
      // Update in Firestore
      await _reviewsCollection.doc(review.id).update({
        'isDisplayed': newVisibility
      });
      
      // Update local state
      setState(() {
        review.isDisplayed = newVisibility;
      });
      
      // Show feedback
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            newVisibility 
                ? 'Review is now visible to customers' 
                : 'Review has been hidden from customers'
          ),
          backgroundColor: newVisibility 
              ? PastelTheme.success 
              : PastelTheme.secondary,
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update review: $e'),
          backgroundColor: PastelTheme.error,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _respondToReview(int index) async {
    final review = _filteredReviews[index];
    
    showDialog(
      context: context,
      builder: (context) {
        _responseController.text = review.responseText ?? '';
        return AlertDialog(
          backgroundColor: PastelTheme.cardColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            'Respond to Review', 
            style: TextStyle(color: PastelTheme.textPrimary),
          ),
          content: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Responding to ${review.customerName}\'s review of ${review.productName}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: PastelTheme.textPrimary,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  review.reviewText,
                  style: TextStyle(
                    fontStyle: FontStyle.italic,
                    color: PastelTheme.textSecondary,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Your Response:',
                  style: TextStyle(color: PastelTheme.textPrimary, fontSize: 14),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _responseController,
                  maxLines: 4,
                  style: TextStyle(color: PastelTheme.textPrimary, fontSize: 14),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: PastelTheme.inputBackground,
                    hintText: 'Type your response here...',
                    hintStyle: TextStyle(color: PastelTheme.textSecondary),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: PastelTheme.primary),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              style: TextButton.styleFrom(
                foregroundColor: PastelTheme.textSecondary,
              ),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  final String responseText = _responseController.text;
                  
                  // Update in Firestore
                  await _reviewsCollection.doc(review.id).update({
                    'isResponded': responseText.isNotEmpty,
                    'responseText': responseText.isEmpty ? null : responseText,
                  });
                  
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Response submitted successfully'),
                      backgroundColor: PastelTheme.success,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                } catch (e) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to submit response: $e'),
                      backgroundColor: PastelTheme.error,
                      duration: const Duration(seconds: 3),
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: PastelTheme.primary,
              ),
              child: const Text('Submit'),
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
          return Icon(Icons.star, color: PastelTheme.secondary, size: 14);
        } else if (index == rating.floor() && rating % 1 != 0) {
          return Icon(Icons.star_half, color: PastelTheme.secondary, size: 14);
        } else {
          return Icon(Icons.star_border, color: PastelTheme.secondary, size: 14);
        }
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: PastelTheme.theme,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Customer Reviews'),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 48,
                          color: PastelTheme.error,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Error Loading Reviews',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: PastelTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32),
                          child: Text(
                            _errorMessage!,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: PastelTheme.textSecondary,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () {
                            setState(() {
                              _isLoading = true;
                              _errorMessage = null;
                            });
                            _initializeReviewsStream();
                          },
                          icon: const Icon(Icons.refresh),
                          label: const Text('Retry'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: PastelTheme.primary,
                          ),
                        ),
                      ],
                    ),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Debug info for empty reviews (remove in production)
                      if (_reviews.isEmpty)
                        Container(
                          padding: EdgeInsets.all(10),
                          margin: EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.red[100],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Debug Info: No reviews loaded',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              Text('Check console logs for more information'),
                              ElevatedButton(
                                onPressed: () {
                                  // Force a manual check of Firestore data
                                  _reviewsCollection.get().then((snapshot) {
                                    String message = 'Firestore has ${snapshot.docs.length} reviews';
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text(message)),
                                    );
                                    print(message);
                                    
                                    if (snapshot.docs.isNotEmpty) {
                                      print('Sample data from first review:');
                                      print(snapshot.docs.first.data());
                                    }
                                  });
                                },
                                child: Text('Check Firestore Directly'),
                              ),
                            ],
                          ),
                        ),
                      
                      // Product filter dropdown (NEW)
                      if (_availableProducts.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(10, 8, 10, 0),
                          child: DropdownButtonFormField<String?>(
                            value: _selectedProductId,
                            decoration: InputDecoration(
                              labelText: 'Filter by Product',
                              labelStyle: TextStyle(
                                color: PastelTheme.textSecondary,
                                fontSize: 14,
                              ),
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              filled: true,
                              fillColor: PastelTheme.inputBackground,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(20),
                                borderSide: BorderSide.none,
                              ),
                              prefixIcon: Icon(Icons.filter_list, color: PastelTheme.primary),
                            ),
                            items: [
                              DropdownMenuItem<String?>(
                                value: null,
                                child: Text('All Products'),
                              ),
                              ..._availableProducts.map((product) {
                                return DropdownMenuItem<String?>(
                                  value: product['id'],
                                  child: Text(product['name'] ?? 'Unnamed Product', 
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                );
                              }),
                            ],
                            onChanged: (String? newValue) {
                              setState(() {
                                _selectedProductId = newValue;
                                _isLoading = true;
                              });
                              _initializeReviewsStream();
                            },
                          ),
                        ),
                      
                      // Compact summary section with pastel theme
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                        color: PastelTheme.background,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildSummaryCard(
                              title: 'Reviews',
                              value: _reviews.where((r) => r.isDisplayed).length.toString(),
                              icon: Icons.rate_review,
                              color: PastelTheme.primary,
                            ),
                            _buildSummaryCard(
                              title: 'Rating',
                              value: _reviews.where((r) => r.isDisplayed).isEmpty
                                  ? '0.0'
                                  : (_reviews.where((r) => r.isDisplayed).fold<double>(0, (sum, item) => sum + item.rating) / 
                                      _reviews.where((r) => r.isDisplayed).length)
                                      .toStringAsFixed(1),
                              icon: Icons.star,
                              color: PastelTheme.secondary,
                            ),
                            _buildSummaryCard(
                              title: 'Pending',
                              value: _reviews.where((r) => r.isDisplayed && !r.isResponded).length.toString(),
                              icon: Icons.message,
                              color: PastelTheme.success,
                            ),
                          ],
                        ),
                      ),
                      
                      // Filter and sort controls
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        child: Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: _filterOption,
                                decoration: InputDecoration(
                                  labelText: 'Filter',
                                  labelStyle: TextStyle(
                                    color: PastelTheme.textSecondary,
                                    fontSize: 12,
                                  ),
                                  isDense: true,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                  filled: true,
                                  fillColor: PastelTheme.inputBackground,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(20),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                                items: _filterOptions.map((String option) {
                                  return DropdownMenuItem<String>(
                                    value: option,
                                    child: Text(option, style: const TextStyle(fontSize: 12)),
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
                                  labelStyle: TextStyle(
                                    color: PastelTheme.textSecondary,
                                    fontSize: 12,
                                  ),
                                  isDense: true,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                  filled: true,
                                  fillColor: PastelTheme.inputBackground,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(20),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                                items: _sortOptions.map((String option) {
                                  return DropdownMenuItem<String>(
                                    value: option,
                                    child: Text(option, style: const TextStyle(fontSize: 12)),
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
                      
                      // Reviews list with updated pastel styling
                      Expanded(
                        child: _filteredReviews.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.rate_review_outlined,
                                      size: 48,
                                      color: PastelTheme.primary.withOpacity(0.5),
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'No reviews found',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: PastelTheme.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : RefreshIndicator(
                                onRefresh: () async {
                                  // This will refresh the reviews from Firestore
                                  setState(() {
                                    _isLoading = true;
                                  });
                                  await Future.delayed(const Duration(milliseconds: 500));
                                  _initializeReviewsStream();
                                },
                                child: ListView.builder(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  itemCount: _filteredReviews.length,
                                  itemBuilder: (context, index) {
                                    final review = _filteredReviews[index];
                                    return Card(
                                      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                      elevation: 1,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          // Review header with compact design
                                          Padding(
                                            padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
                                            child: Row(
                                              children: [
                                                CircleAvatar(
                                                  backgroundColor: PastelTheme.primary.withOpacity(0.2),
                                                  radius: 16,
                                                  child: Text(
                                                    review.customerName.isNotEmpty 
                                                        ? review.customerName[0].toUpperCase() 
                                                        : '?',
                                                    style: TextStyle(
                                                      color: PastelTheme.primary,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Row(
                                                        children: [
                                                          Text(
                                                            review.customerName,
                                                            style: TextStyle(
                                                              fontWeight: FontWeight.bold,
                                                              color: PastelTheme.textPrimary,
                                                              fontSize: 13,
                                                            ),
                                                          ),
                                                          const Spacer(),
                                                          Container(
                                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                            decoration: BoxDecoration(
                                                              color: review.rating >= 4
                                                                  ? PastelTheme.success.withOpacity(0.5)
                                                                  : review.rating >= 3
                                                                      ? PastelTheme.secondary.withOpacity(0.5)
                                                                      : PastelTheme.error.withOpacity(0.5),
                                                              borderRadius: BorderRadius.circular(12),
                                                            ),
                                                            child: Text(
                                                              review.rating.toString(),
                                                              style: TextStyle(
                                                                color: PastelTheme.accent,
                                                                fontWeight: FontWeight.bold,
                                                                fontSize: 12,
                                                              ),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                      const SizedBox(height: 2),
                                                      Row(
                                                        children: [
                                                          Icon(
                                                            Icons.shopping_bag_outlined,
                                                            size: 12,
                                                            color: PastelTheme.textSecondary,
                                                          ),
                                                          const SizedBox(width: 4),
                                                          Expanded(
                                                            child: Text(
                                                              review.productName,
                                                              style: TextStyle(
                                                                color: PastelTheme.textSecondary,
                                                                fontSize: 11,
                                                              ),
                                                              maxLines: 1,
                                                              overflow: TextOverflow.ellipsis,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          
                                          // Review date and stars
                                          Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                            child: Row(
                                              children: [
                                                _buildRatingStars(review.rating),
                                                const Spacer(),
                                                Text(
                                                  DateFormat('MMM d, yyyy').format(review.date),
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    color: PastelTheme.textSecondary,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          
                                          // Review content
                                          Padding(
                                            padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
                                            child: Text(
                                              review.reviewText,
                                              style: TextStyle(
                                                color: PastelTheme.textPrimary,
                                                fontSize: 13,
                                              ),
                                            ),
                                          ),
                                          
                                          // Response section - if responded
                                          if (review.isResponded && review.responseText != null)
                                            Container(
                                              margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                                              padding: const EdgeInsets.all(8),
                                              decoration: BoxDecoration(
                                                color: PastelTheme.primary.withOpacity(0.1),
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    children: [
                                                      Icon(
                                                        Icons.store,
                                                        size: 12,
                                                        color: PastelTheme.primary,
                                                      ),
                                                      const SizedBox(width: 4),
                                                      Text(
                                                        'Your Response:',
                                                        style: TextStyle(
                                                          fontWeight: FontWeight.bold,
                                                          color: PastelTheme.primary,
                                                          fontSize: 11,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    review.responseText!,
                                                    style: TextStyle(
                                                      color: PastelTheme.textPrimary,
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          
                                          // Action buttons
                                          Padding(
                                            padding: const EdgeInsets.fromLTRB(8, 0, 8, 4),
                                            child: Row(
                                              mainAxisAlignment: MainAxisAlignment.end,
                                              children: [
                                                // Respond button
                                                TextButton.icon(
                                                  icon: Icon(
                                                    review.isResponded ? Icons.edit : Icons.reply,
                                                    size: 14,
                                                    color: PastelTheme.primary,
                                                  ),
                                                  label: Text(
                                                    review.isResponded ? 'Edit' : 'Respond',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: PastelTheme.primary,
                                                    ),
                                                  ),
                                                  style: TextButton.styleFrom(
                                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                    minimumSize: Size.zero,
                                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                                  ),
                                                  onPressed: () => _respondToReview(index),
                                                ),
                                                const SizedBox(width: 4),
                                                // Hide/Show button
                                                TextButton.icon(
                                                  icon: Icon(
                                                    review.isDisplayed ? Icons.visibility_off : Icons.visibility,
                                                    size: 14,
                                                    color: review.isDisplayed ? PastelTheme.error : PastelTheme.success,
                                                  ),
                                                  label: Text(
                                                    review.isDisplayed ? 'Hide' : 'Show',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: review.isDisplayed ? PastelTheme.error : PastelTheme.success,
                                                    ),
                                                  ),
                                                  style: TextButton.styleFrom(
                                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                    minimumSize: Size.zero,
                                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                                  ),
                                                  onPressed: () => _toggleReviewVisibility(index),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ),
                      ),
                    ],
                  ),
        // Floating action button to refresh reviews
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            setState(() {
              _isLoading = true;
            });
            _initializeReviewsStream();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Refreshing reviews...'),
                backgroundColor: PastelTheme.primary,
                duration: const Duration(seconds: 1),
              ),
            );
          },
          mini: true, // Make it smaller
          child: const Icon(Icons.refresh),
        ),
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
      width: 80, // Made smaller
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: PastelTheme.cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: PastelTheme.cardShadow,
            spreadRadius: 1,
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 2),
          Text(
            title,
            style: TextStyle(
              color: PastelTheme.textSecondary,
              fontSize: 10,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: PastelTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
