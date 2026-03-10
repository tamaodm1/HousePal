// Models cho HousePal App

class House {
  final int id;
  final String name;
  final String? description;
  final String joinCode;
  final int memberCount;
  final DateTime createdAt;

  House({
    this.id = 0,
    required this.name,
    this.description,
    this.joinCode = '',
    this.memberCount = 1,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory House.fromJson(Map<String, dynamic> json) {
    return House(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      description: json['description'],
      joinCode: json['joinCode'] ?? '',
      memberCount: json['memberCount'] ?? 1,
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    final map = {
      'name': name,
      'description': description,
      'joinCode': joinCode,
      'memberCount': memberCount,
    };
    if (id != 0) {
      map['id'] = id;
    }
    return map;
  }
}

class User {
  final int id;
  final String name;
  final String email;
  final String? avatarUrl;
  final int chorePoints;
  int houseId; // Changed from final to mutable
  final bool isAdmin;

  User({
    this.id = 0,
    required this.name,
    required this.email,
    this.avatarUrl,
    this.chorePoints = 0,
    this.houseId = 0,
    this.isAdmin = false,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      avatarUrl: json['avatarUrl'],
      chorePoints: json['chorePoints'] ?? 0,
      houseId: json['houseId'] ?? 0,
      isAdmin: json['isAdmin'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'name': name,
      'email': email,
    };
    if (avatarUrl != null) {
      map['avatarUrl'] = avatarUrl!;
    }
    if (chorePoints != 0) {
      map['chorePoints'] = chorePoints;
    }
    if (houseId != 0) {
      map['houseId'] = houseId;
    }
    if (isAdmin) {
      map['isAdmin'] = isAdmin;
    }
    if (id != 0) {
      map['id'] = id;
    }
    return map;
  }
}

class Chore {
  final int id;
  final String title;
  final String? description;
  final String frequency; // 'daily', 'weekly', 'monthly'
  final int points;
  final int houseId;
  final bool isActive;
  final int rotationOrderIndex;
  final DateTime createdAt;
  final DateTime updatedAt;

  Chore({
    this.id = 0,
    required this.title,
    this.description,
    this.frequency = 'weekly',
    this.points = 10,
    this.houseId = 0,
    this.isActive = true,
    this.rotationOrderIndex = 0,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Chore copyWith({
    int? id,
    String? title,
    String? description,
    String? frequency,
    int? points,
    int? houseId,
    bool? isActive,
    int? rotationOrderIndex,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Chore(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      frequency: frequency ?? this.frequency,
      points: points ?? this.points,
      houseId: houseId ?? this.houseId,
      isActive: isActive ?? this.isActive,
      rotationOrderIndex: rotationOrderIndex ?? this.rotationOrderIndex,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory Chore.fromJson(Map<String, dynamic> json) {
    return Chore(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      description: json['description'],
      frequency: json['frequency'] ?? 'weekly',
      points: json['points'] ?? 10,
      houseId: json['houseId'] ?? 0,
      isActive: json['isActive'] ?? true,
      rotationOrderIndex: json['rotationOrderIndex'] ?? 0,
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now(),
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'title': title,
      'frequency': frequency,
      'points': points,
      'isActive': isActive,
      'rotationOrderIndex': rotationOrderIndex,
    };
    if (description != null) {
      map['description'] = description!;
    }
    if (houseId != 0) {
      map['houseId'] = houseId;
    }
    if (id != 0) {
      map['id'] = id;
    }
    return map;
  }
}

class Expense {
  final int id;
  final String title;
  final double amount;
  final int paidBy;
  final String? paidByName;
  final int houseId;
  final DateTime date;
  final String? category;
  final String? note;
  final DateTime createdAt;

  Expense({
    this.id = 0,
    required this.title,
    required this.amount,
    required this.paidBy,
    this.paidByName,
    this.houseId = 0,
    DateTime? date,
    this.category,
    this.note,
    DateTime? createdAt,
  })  : date = date ?? DateTime.now(),
        createdAt = createdAt ?? DateTime.now();

  factory Expense.fromJson(Map<String, dynamic> json) {
    return Expense(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
      paidBy: json['paidBy'] ?? 0,
      paidByName: json['paidByName'],
      houseId: json['houseId'] ?? 0,
      date: json['date'] != null ? DateTime.parse(json['date']) : DateTime.now(),
      category: json['category'],
      note: json['note'],
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'title': title,
      'amount': amount,
      'paidBy': paidBy,
      'date': date.toIso8601String(),
    };
    if (paidByName != null) {
      map['paidByName'] = paidByName!;
    }
    if (houseId != 0) {
      map['houseId'] = houseId;
    }
    if (category != null) {
      map['category'] = category!;
    }
    if (note != null) {
      map['note'] = note!;
    }
    if (id != 0) {
      map['id'] = id;
    }
    return map;
  }
}

class BulletinNote {
  final int id;
  final String title;
  final String content;
  final DateTime createdAt;
  final int createdBy;
  final String? createdByName;
  final bool isPinned;
  final int houseId;

  BulletinNote({
    this.id = 0,
    required this.title,
    required this.content,
    DateTime? createdAt,
    required this.createdBy,
    this.createdByName,
    this.isPinned = false,
    this.houseId = 0,
  }) : createdAt = createdAt ?? DateTime.now();

  factory BulletinNote.fromJson(Map<String, dynamic> json) {
    return BulletinNote(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now(),
      createdBy: json['createdBy'] ?? 0,
      createdByName: json['createdByName'],
      isPinned: json['isPinned'] ?? false,
      houseId: json['houseId'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'title': title,
      'content': content,
      'createdBy': createdBy,
      'isPinned': isPinned,
    };
    if (createdByName != null) {
      map['createdByName'] = createdByName!;
    }
    if (houseId != 0) {
      map['houseId'] = houseId;
    }
    if (id != 0) {
      map['id'] = id;
    }
    return map;
  }
}

class ShoppingItem {
  final int id;
  final String name;
  final bool isPurchased;
  final int addedBy;
  final String? addedByName;
  final DateTime addedAt;
  final int? purchasedBy;
  final String? purchasedByName;
  final DateTime? purchasedAt;
  final int houseId;

  ShoppingItem({
    this.id = 0,
    required this.name,
    this.isPurchased = false,
    required this.addedBy,
    this.addedByName,
    DateTime? addedAt,
    this.purchasedBy,
    this.purchasedByName,
    this.purchasedAt,
    this.houseId = 0,
  }) : addedAt = addedAt ?? DateTime.now();

  factory ShoppingItem.fromJson(Map<String, dynamic> json) {
    return ShoppingItem(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      isPurchased: json['isPurchased'] ?? false,
      addedBy: json['addedBy'] ?? 0,
      addedByName: json['addedByName'],
      addedAt: json['addedAt'] != null ? DateTime.parse(json['addedAt']) : DateTime.now(),
      purchasedBy: json['purchasedBy'],
      purchasedByName: json['purchasedByName'],
      purchasedAt: json['purchasedAt'] != null ? DateTime.parse(json['purchasedAt']) : null,
      houseId: json['houseId'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'name': name,
      'isPurchased': isPurchased,
      'addedBy': addedBy,
      'addedAt': addedAt.toIso8601String(),
    };
    if (addedByName != null) {
      map['addedByName'] = addedByName!;
    }
    if (purchasedBy != null) {
      map['purchasedBy'] = purchasedBy!;
    }
    if (purchasedByName != null) {
      map['purchasedByName'] = purchasedByName!;
    }
    if (purchasedAt != null) {
      map['purchasedAt'] = purchasedAt!.toIso8601String();
    }
    if (houseId != 0) {
      map['houseId'] = houseId;
    }
    if (id != 0) {
      map['id'] = id;
    }
    return map;
  }

  ShoppingItem copyWith({
    int? id,
    String? name,
    bool? isPurchased,
    int? addedBy,
    String? addedByName,
    DateTime? addedAt,
    int? purchasedBy,
    String? purchasedByName,
    DateTime? purchasedAt,
    int? houseId,
  }) {
    return ShoppingItem(
      id: id ?? this.id,
      name: name ?? this.name,
      isPurchased: isPurchased ?? this.isPurchased,
      addedBy: addedBy ?? this.addedBy,
      addedByName: addedByName ?? this.addedByName,
      addedAt: addedAt ?? this.addedAt,
      purchasedBy: purchasedBy ?? this.purchasedBy,
      purchasedByName: purchasedByName ?? this.purchasedByName,
      purchasedAt: purchasedAt ?? this.purchasedAt,
      houseId: houseId ?? this.houseId,
    );
  }
}

// ========== Balance & Debt Models ==========

class BalanceResponse {
  final int houseId;
  final String houseName;
  final List<UserBalanceInfo> members;
  final List<DebtDetail> debts;
  final List<SimplifiedPayment> simplifiedPayments;
  final double totalUnsettledAmount;

  BalanceResponse({
    required this.houseId,
    required this.houseName,
    required this.members,
    required this.debts,
    required this.simplifiedPayments,
    required this.totalUnsettledAmount,
  });

  factory BalanceResponse.fromJson(Map<String, dynamic> json) {
    return BalanceResponse(
      houseId: json['houseId'] ?? 0,
      houseName: json['houseName'] ?? '',
      members: (json['members'] as List<dynamic>?)
          ?.map((m) => UserBalanceInfo.fromJson(m))
          .toList() ?? [],
      debts: (json['debts'] as List<dynamic>?)
          ?.map((d) => DebtDetail.fromJson(d))
          .toList() ?? [],
      simplifiedPayments: (json['simplifiedPayments'] as List<dynamic>?)
          ?.map((s) => SimplifiedPayment.fromJson(s))
          .toList() ?? [],
      totalUnsettledAmount: (json['totalUnsettledAmount'] ?? 0).toDouble(),
    );
  }
}

class UserBalanceInfo {
  final int userId;
  final String userName;
  final String email;
  final double totalOwes;
  final double totalOwed;
  final double netBalance;

  UserBalanceInfo({
    required this.userId,
    required this.userName,
    required this.email,
    required this.totalOwes,
    required this.totalOwed,
    required this.netBalance,
  });

  factory UserBalanceInfo.fromJson(Map<String, dynamic> json) {
    return UserBalanceInfo(
      userId: json['userId'] ?? 0,
      userName: json['userName'] ?? '',
      email: json['email'] ?? '',
      totalOwes: (json['totalOwes'] ?? 0).toDouble(),
      totalOwed: (json['totalOwed'] ?? 0).toDouble(),
      netBalance: (json['netBalance'] ?? 0).toDouble(),
    );
  }
}

class UserBalanceResponse {
  final int userId;
  final String userName;
  final double totalOwes;
  final double totalOwed;
  final double netBalance;
  final List<DebtDetail> debtsOwing;
  final List<DebtDetail> debtsOwed;

  UserBalanceResponse({
    required this.userId,
    required this.userName,
    required this.totalOwes,
    required this.totalOwed,
    required this.netBalance,
    required this.debtsOwing,
    required this.debtsOwed,
  });

  factory UserBalanceResponse.fromJson(Map<String, dynamic> json) {
    return UserBalanceResponse(
      userId: json['userId'] ?? 0,
      userName: json['userName'] ?? '',
      totalOwes: (json['totalOwes'] ?? 0).toDouble(),
      totalOwed: (json['totalOwed'] ?? 0).toDouble(),
      netBalance: (json['netBalance'] ?? 0).toDouble(),
      debtsOwing: (json['debtsOwing'] as List<dynamic>?)
          ?.map((d) => DebtDetail.fromJson(d))
          .toList() ?? [],
      debtsOwed: (json['debtsOwed'] as List<dynamic>?)
          ?.map((d) => DebtDetail.fromJson(d))
          .toList() ?? [],
    );
  }
}

class DebtDetail {
  final int id;
  final int debtorUserId;
  final String debtorName;
  final int creditorUserId;
  final String creditorName;
  final double amount;
  final String? description;
  final DateTime createdAt;

  DebtDetail({
    required this.id,
    required this.debtorUserId,
    required this.debtorName,
    required this.creditorUserId,
    required this.creditorName,
    required this.amount,
    this.description,
    required this.createdAt,
  });

  factory DebtDetail.fromJson(Map<String, dynamic> json) {
    return DebtDetail(
      id: json['id'] ?? 0,
      debtorUserId: json['debtorUserId'] ?? 0,
      debtorName: json['debtorName'] ?? '',
      creditorUserId: json['creditorUserId'] ?? 0,
      creditorName: json['creditorName'] ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
      description: json['description'],
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt']) 
          : DateTime.now(),
    );
  }
}

class SimplifiedPayment {
  final int fromUserId;
  final String fromUserName;
  final int toUserId;
  final String toUserName;
  final double amount;

  SimplifiedPayment({
    required this.fromUserId,
    required this.fromUserName,
    required this.toUserId,
    required this.toUserName,
    required this.amount,
  });

  factory SimplifiedPayment.fromJson(Map<String, dynamic> json) {
    return SimplifiedPayment(
      fromUserId: json['fromUserId'] ?? 0,
      fromUserName: json['fromUserName'] ?? '',
      toUserId: json['toUserId'] ?? 0,
      toUserName: json['toUserName'] ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
    );
  }
}

class Balance {
  final int fromUserId;
  final String? fromUserName;
  final int toUserId;
  final String? toUserName;
  final double amount;

  Balance({
    required this.fromUserId,
    this.fromUserName,
    required this.toUserId,
    this.toUserName,
    required this.amount,
  });

  factory Balance.fromJson(Map<String, dynamic> json) {
    return Balance(
      fromUserId: json['fromUserId'] ?? 0,
      fromUserName: json['fromUserName'],
      toUserId: json['toUserId'] ?? 0,
      toUserName: json['toUserName'],
      amount: (json['amount'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'fromUserId': fromUserId,
      'fromUserName': fromUserName,
      'toUserId': toUserId,
      'toUserName': toUserName,
      'amount': amount,
    };
  }
}
