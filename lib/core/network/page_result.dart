import 'package:equatable/equatable.dart';

/// Spring-style page: `{ content, page, size, totalElements, totalPages }`.
class PageResult<T> extends Equatable {
  const PageResult({
    required this.content,
    required this.page,
    required this.size,
    required this.totalElements,
    required this.totalPages,
  });

  final List<T> content;
  final int page;
  final int size;
  final int totalElements;
  final int totalPages;

  bool get hasMore => page + 1 < totalPages;

  factory PageResult.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) itemFromJson,
  ) {
    final items = (json['content'] as List? ?? const [])
        .map((e) => itemFromJson(Map<String, dynamic>.from(e as Map)))
        .toList(growable: false);
    return PageResult<T>(
      content: items,
      page: (json['page'] as num?)?.toInt() ?? 0,
      size: (json['size'] as num?)?.toInt() ?? items.length,
      totalElements: (json['totalElements'] as num?)?.toInt() ?? items.length,
      totalPages: (json['totalPages'] as num?)?.toInt() ?? 1,
    );
  }

  @override
  List<Object?> get props => [content, page, size, totalElements, totalPages];
}
