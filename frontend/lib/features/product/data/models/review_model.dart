class Review {
  final String id;
  final String userId;
  final String productId;
  final int rating;
  final String? comment;
  final String userName;
  final DateTime createdAt;

  Review({
    required this.id,
    required this.userId,
    required this.productId,
    required this.rating,
    this.comment,
    required this.userName,
    required this.createdAt,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    String name = 'Khách';
    if (json['user'] != null && json['user'] is Map) {
      name = json['user']['name'] ??
          json['user']['fullName'] ??
          json['user']['email'] ??
          'Khách';
    } else if (json['userName'] != null) {
      name = json['userName'].toString();
    }

    return Review(
      id: json['id']?.toString() ?? '',
      userId: json['userId'] ?? json['user_id'] ?? '',
      productId: json['productId'] ?? json['product_id'] ?? '',
      rating: json['rating'] is int
          ? json['rating']
          : int.tryParse(json['rating']?.toString() ?? '5') ?? 5,
      comment: json['comment']?.toString(),
      userName: name,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : (json['created_at'] != null
              ? DateTime.tryParse(json['created_at'].toString()) ??
                  DateTime.now()
              : DateTime.now()),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'productId': productId,
        'rating': rating,
        'comment': comment,
        'userName': userName,
        'createdAt': createdAt.toIso8601String(),
      };
}
