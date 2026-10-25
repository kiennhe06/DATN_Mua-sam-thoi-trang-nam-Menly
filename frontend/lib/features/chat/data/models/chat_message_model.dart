class SuggestedProductItem {
  final String id;
  final String name;
  final int price;
  final String? thumbnailUrl;
  final String? slug;

  SuggestedProductItem({
    required this.id,
    required this.name,
    required this.price,
    this.thumbnailUrl,
    this.slug,
  });

  factory SuggestedProductItem.fromJson(Map<String, dynamic> json) =>
      SuggestedProductItem(
        id: json['id'] as String? ?? '',
        name: json['name'] as String? ?? '',
        price: (json['price'] as num?)?.toInt() ?? 0,
        thumbnailUrl: json['thumbnailUrl'] as String?,
        slug: json['slug'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'price': price,
        'thumbnailUrl': thumbnailUrl,
        'slug': slug,
      };
}

class ChatMessageModel {
  final String id;
  final String senderType; // 'user' | 'staff'
  final String senderName;
  final String content;
  final DateTime createdAt;
  final bool isStaff;
  final String? attachmentUrl;
  final List<SuggestedProductItem>? suggestedProducts;

  ChatMessageModel({
    required this.id,
    required this.senderType,
    required this.senderName,
    required this.content,
    required this.createdAt,
    this.isStaff = false,
    this.attachmentUrl,
    this.suggestedProducts,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'senderType': senderType,
        'senderName': senderName,
        'content': content,
        'createdAt': createdAt.toIso8601String(),
        'isStaff': isStaff,
        'attachmentUrl': attachmentUrl,
        'suggestedProducts':
            suggestedProducts?.map((p) => p.toJson()).toList(),
      };

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) =>
      ChatMessageModel(
        id: json['id'] as String? ?? '',
        senderType: json['senderType'] as String? ?? 'user',
        senderName: json['senderName'] as String? ?? 'Khách hàng',
        content: json['content'] as String? ?? '',
        createdAt: json['createdAt'] != null
            ? DateTime.parse(json['createdAt'] as String)
            : DateTime.now(),
        isStaff: (json['senderType'] == 'staff') ||
            (json['isStaff'] as bool? ?? false),
        attachmentUrl: json['attachmentUrl'] as String?,
        suggestedProducts: json['suggestedProducts'] != null
            ? (json['suggestedProducts'] as List)
                .map((p) =>
                    SuggestedProductItem.fromJson(p as Map<String, dynamic>))
                .toList()
            : null,
      );
}
