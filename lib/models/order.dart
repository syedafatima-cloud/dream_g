class Order {
  final String orderId;
  final String customerName;
  final String product;
  final String dueDate;
  final String status; // New field

  Order({
    required this.orderId,
    required this.customerName,
    required this.product,
    required this.dueDate,
    required this.status,
  });
}