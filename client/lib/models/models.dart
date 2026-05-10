
library models;

/// 所有数据模型

class ApiResponse<T> {
  final int code;
  final String message;
  final T? data;

  ApiResponse({required this.code, required this.message, this.data});

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic)? fromData,
  ) {
    return ApiResponse(
      code: json['code'] as int,
      message: json['message'] as String,
      data: fromData != null && json['data'] != null
          ? fromData(json['data'])
          : null,
    );
  }
}

class AuthData {
  final String accessToken;
  final String tokenType;
  final UserInfo user;

  AuthData({
    required this.accessToken,
    required this.tokenType,
    required this.user,
  });

  factory AuthData.fromJson(Map<String, dynamic> json) {
    return AuthData(
      accessToken: json['access_token'] as String,
      tokenType: json['token_type'] as String? ?? 'bearer',
      user: UserInfo.fromJson(json['user'] as Map<String, dynamic>),
    );
  }
}

class UserInfo {
  final int id;
  final String username;
  final String? createdAt;

  UserInfo({required this.id, required this.username, this.createdAt});

  factory UserInfo.fromJson(Map<String, dynamic> json) {
    return UserInfo(
      id: json['id'] as int,
      username: json['username'] as String,
      createdAt: json['created_at'] as String?,
    );
  }
}

class AnimeProgress {
  final int id;
  final String title;
  final String? coverUrl;
  final int? totalEpisodes;
  final int watchedEpisodes;
  final String status;
  final int? rating;
  final String? notes;
  final String? createdAt;
  final String? updatedAt;

  AnimeProgress({
    required this.id,
    required this.title,
    this.coverUrl,
    this.totalEpisodes,
    required this.watchedEpisodes,
    required this.status,
    this.rating,
    this.notes,
    this.createdAt,
    this.updatedAt,
  });

  factory AnimeProgress.fromJson(Map<String, dynamic> json) {
    return AnimeProgress(
      id: json['id'] as int,
      title: json['title'] as String,
      coverUrl: json['cover_url'] as String?,
      totalEpisodes: json['total_episodes'] as int?,
      watchedEpisodes: json['watched_episodes'] as int? ?? 0,
      status: json['status'] as String? ?? 'watching',
      rating: json['rating'] as int?,
      notes: json['notes'] as String?,
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
    );
  }

  Map<String, dynamic> toCreateJson() {
    return {
      'title': title,
      'total_episodes': totalEpisodes,
      'watched_episodes': watchedEpisodes,
      'status': status,
      'rating': rating,
      'notes': notes,
    };
  }

  Map<String, dynamic> toUpdateJson() {
    return {
      'title': title,
      'total_episodes': totalEpisodes,
      'watched_episodes': watchedEpisodes,
      'status': status,
      'rating': rating,
      'notes': notes,
    };
  }

  double get progress {
    if (totalEpisodes != null && totalEpisodes! > 0) {
      return (watchedEpisodes / totalEpisodes!).clamp(0.0, 1.0);
    }
    return 0.0;
  }

  String get episodeText {
    if (totalEpisodes != null) {
      return '$watchedEpisodes/$totalEpisodes';
    }
    return '$watchedEpisodes 集';
  }

  static const statusWatching = 'watching';
  static const statusCompleted = 'completed';
  static const statusPlanToWatch = 'plan_to_watch';
  static const statusOnHold = 'on_hold';
  static const statusDropped = 'dropped';

  static const allStatuses = [
    statusWatching,
    statusCompleted,
    statusPlanToWatch,
    statusOnHold,
    statusDropped,
  ];

  static String statusLabel(String status) {
    switch (status) {
      case statusWatching: return '在看';
      case statusCompleted: return '已看完';
      case statusPlanToWatch: return '想看';
      case statusOnHold: return '搁置';
      case statusDropped: return '弃番';
      default: return status;
    }
  }
}
