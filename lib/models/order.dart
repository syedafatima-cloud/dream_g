// First, let's check what your Order.fromFirestore method might look like
// This is what you should have in your Order class:

class Order {
  final String orderId;
  final String customerName;
  final String product;
  final String dueDate;
  final String status;
  // Other fields...

  Order({
    required this.orderId,
    required this.customerName,
    required this.product,
    required this.dueDate,
    required this.status,
    // Other fields...
  });

  // Your current method is probably causing the issue
  // It expects a different parameter signature than what you're passing

  // Current method (problematic):
  factory Order.fromFirestore(Map<String, dynamic> data, String docId) {
    // Assuming this is what you have - the problem is in how you're calling it
    return Order(
      orderId: docId,
      customerName: data['customerName'] ?? 'Unknown',
      product: data['product'] ?? 'Unknown',
      dueDate: data['dueDate'] ?? 'Unknown',
      status: data['status'] ?? 'Pending',
      // Other fields...
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'customerName': customerName,
      'product': product,
      'dueDate': dueDate,
      'status': status,
      // Don't include orderId in the map as it's the document ID
    };
  }
}