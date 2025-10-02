class ProductsQuery {
  final int? categoryId;
  final String? searchQuery;
  final bool? isAvailable;
  final bool? isFeatured;
  final int? limit;
  final int? offset;
  final String? sortBy;
  final String? sortOrder;

  const ProductsQuery({
    this.categoryId,
    this.searchQuery,
    this.isAvailable,
    this.isFeatured,
    this.limit,
    this.offset,
    this.sortBy,
    this.sortOrder,
  });

  Map<String, dynamic> toJson() {
    return {
      if (categoryId != null) 'category_id': categoryId,
      if (searchQuery != null) 'search_query': searchQuery,
      if (isAvailable != null) 'is_available': isAvailable,
      if (isFeatured != null) 'is_featured': isFeatured,
      if (limit != null) 'limit': limit,
      if (offset != null) 'offset': offset,
      if (sortBy != null) 'sort_by': sortBy,
      if (sortOrder != null) 'sort_order': sortOrder,
    };
  }

  ProductsQuery copyWith({
    int? categoryId,
    String? searchQuery,
    bool? isAvailable,
    bool? isFeatured,
    int? limit,
    int? offset,
    String? sortBy,
    String? sortOrder,
  }) {
    return ProductsQuery(
      categoryId: categoryId ?? this.categoryId,
      searchQuery: searchQuery ?? this.searchQuery,
      isAvailable: isAvailable ?? this.isAvailable,
      isFeatured: isFeatured ?? this.isFeatured,
      limit: limit ?? this.limit,
      offset: offset ?? this.offset,
      sortBy: sortBy ?? this.sortBy,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }
}
