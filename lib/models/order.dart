import 'cart_item.dart';

enum OrderStatus {
  pending,
  confirmed,
  preparing,
  ready,
  outForDelivery,
  delivered,
  cancelled,
}

enum DeliveryType { delivery, pickup }

class Order {
  final String id;
  final String? orderNumber;
  final String customerName;
  final String customerEmail;
  final String customerPhone;
  final String customerAddress;
  final List<CartItem> items;
  final double total;
  final OrderStatus status;
  final String orderDate;
  final String? deliveryDate;
  final String? notes;
  final DeliveryType deliveryType;
  final String? pickupTime;
  final String? driverId;

  Order({
    required this.id,
    this.orderNumber,
    required this.customerName,
    required this.customerEmail,
    required this.customerPhone,
    required this.customerAddress,
    required this.items,
    required this.total,
    this.status = OrderStatus.pending,
    required this.orderDate,
    this.deliveryDate,
    this.notes,
    this.deliveryType = DeliveryType.delivery,
    this.pickupTime,
    this.driverId,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'] as String,
      orderNumber:
          json['order_number'] as String? ?? json['orderNumber'] as String?,
      customerName:
          json['customer_name'] as String? ??
          json['customerName'] as String? ??
          'Unknown',
      customerEmail:
          json['customer_email'] as String? ??
          json['customerEmail'] as String? ??
          '',
      customerPhone:
          json['customer_phone'] as String? ??
          json['customerPhone'] as String? ??
          '',
      customerAddress:
          json['customer_address'] as String? ??
          json['customerAddress'] as String? ??
          '',
      items:
          (json['items'] as List?)
              ?.map((item) => CartItem.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
      total:
          ((json['total_amount'] ?? json['total']) as num?)?.toDouble() ?? 0.0,
      status: OrderStatus.values.firstWhere(
        (e) => e.name == (json['status'] as String?)?.toLowerCase(),
        orElse: () => OrderStatus.pending,
      ),
      orderDate:
          (json['created_at'] ?? json['orderDate']) as String? ??
          DateTime.now().toIso8601String(),
      deliveryDate: (json['delivery_date'] ?? json['deliveryDate']) as String?,
      notes: json['notes'] as String?,
      deliveryType: DeliveryType.values.firstWhere(
        (e) =>
            e.name ==
            (json['delivery_type'] ?? json['deliveryType'] as String?)
                ?.toLowerCase(),
        orElse: () => DeliveryType.delivery,
      ),
      pickupTime:
          json['pickup_time'] as String? ?? json['pickupTime'] as String?,
      driverId: json['driver_id'] as String? ?? json['driverId'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order_number': orderNumber,
      'customerName': customerName,
      'customerEmail': customerEmail,
      'customerPhone': customerPhone,
      'customerAddress': customerAddress,
      'items': items.map((item) => item.toJson()).toList(),
      'total': total,
      'status': status.name,
      'orderDate': orderDate,
      'deliveryDate': deliveryDate,
      'notes': notes,
      'deliveryType': deliveryType.name,
      'pickupTime': pickupTime,
      'driverId': driverId,
    };
  }

  Order copyWith({
    String? id,
    String? orderNumber,
    String? customerName,
    String? customerEmail,
    String? customerPhone,
    String? customerAddress,
    List<CartItem>? items,
    double? total,
    OrderStatus? status,
    String? orderDate,
    String? deliveryDate,
    String? notes,
    DeliveryType? deliveryType,
    String? pickupTime,
    String? driverId,
  }) {
    return Order(
      id: id ?? this.id,
      orderNumber: orderNumber ?? this.orderNumber,
      customerName: customerName ?? this.customerName,
      customerEmail: customerEmail ?? this.customerEmail,
      customerPhone: customerPhone ?? this.customerPhone,
      customerAddress: customerAddress ?? this.customerAddress,
      items: items ?? this.items,
      total: total ?? this.total,
      status: status ?? this.status,
      orderDate: orderDate ?? this.orderDate,
      deliveryDate: deliveryDate ?? this.deliveryDate,
      notes: notes ?? this.notes,
      deliveryType: deliveryType ?? this.deliveryType,
      pickupTime: pickupTime ?? this.pickupTime,
      driverId: driverId ?? this.driverId,
    );
  }
}

extension OrderStatusExtension on OrderStatus {
  String get displayName {
    switch (this) {
      case OrderStatus.pending:
        return 'Pending';
      case OrderStatus.confirmed:
        return 'Confirmed';
      case OrderStatus.preparing:
        return 'Preparing';
      case OrderStatus.ready:
        return 'Ready';
      case OrderStatus.outForDelivery:
        return 'Out for Delivery';
      case OrderStatus.delivered:
        return 'Delivered';
      case OrderStatus.cancelled:
        return 'Cancelled';
    }
  }
}
