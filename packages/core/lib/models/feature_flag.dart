class FeatureRollout {
  const FeatureRollout({
    required this.strategy,
    this.percentage,
    this.roles = const <String>[],
    this.branches = const <int>[],
    this.segment,
  });

  factory FeatureRollout.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return const FeatureRollout(strategy: 'all');
    }

    final strategy = (json['strategy'] as String?)?.toLowerCase() ?? 'all';
    final rawRoles = json['roles'] as List<dynamic>?;
    final rawBranches = json['branches'] as List<dynamic>?;

    return FeatureRollout(
      strategy: strategy,
      percentage: json['percentage'] is num
          ? (json['percentage'] as num).clamp(0, 100).toInt()
          : null,
      roles: rawRoles == null
          ? const <String>[]
          : rawRoles.map((role) => role.toString()).toList(growable: false),
      branches: rawBranches == null
          ? const <int>[]
          : rawBranches
              .map((value) => value is num ? value.toInt() : int.tryParse(value.toString()) ?? -1)
              .where((value) => value >= 0)
              .toList(growable: false),
      segment: json['segment'] as String?,
    );
  }

  final String strategy;
  final int? percentage;
  final List<String> roles;
  final List<int> branches;
  final String? segment;

  bool get isGradual => strategy == 'percentage';

  Map<String, dynamic> toJson() => {
        'strategy': strategy,
        if (percentage != null) 'percentage': percentage,
        if (roles.isNotEmpty) 'roles': roles,
        if (branches.isNotEmpty) 'branches': branches,
        if (segment != null) 'segment': segment,
      };
}

class FeatureFlag {
  const FeatureFlag({
    required this.key,
    this.description = '',
    this.enabled = false,
    this.evaluation = false,
    this.activeSource = 'unknown',
    this.rollout = const FeatureRollout(strategy: 'all'),
    this.tags = const <String>[],
    this.owner,
    this.since,
    this.notes,
    this.defaultEnabled = false,
    this.environments = const <String>[],
    this.sources = const <String, dynamic>{},
    this.updatedAt,
    this.updatedBy,
    this.updatedByName,
  });

  factory FeatureFlag.fromJson(Map<String, dynamic> json) {
    final rawTags = json['tags'] as List<dynamic>?;
    final rawEnvironments = json['environments'] as List<dynamic>?;

    return FeatureFlag(
      key: json['key'] as String,
      description: json['description'] as String? ?? '',
      enabled: json['enabled'] as bool? ?? false,
      evaluation: json['evaluation'] as bool? ?? json['enabled'] as bool? ?? false,
      activeSource: json['activeSource'] as String? ?? 'unknown',
      rollout: FeatureRollout.fromJson(json['rollout'] as Map<String, dynamic>?),
      tags: rawTags == null
          ? const <String>[]
          : rawTags.map((value) => value.toString()).toList(growable: false),
      owner: json['owner'] as String?,
      since: json['since'] as String?,
      notes: json['notes'] as String?,
      defaultEnabled: json['defaultEnabled'] as bool? ?? false,
      environments: rawEnvironments == null
          ? const <String>[]
          : rawEnvironments.map((value) => value.toString()).toList(growable: false),
      sources: (json['sources'] as Map<String, dynamic>?) ?? const <String, dynamic>{},
      updatedAt: json['updatedAt'] != null ? DateTime.tryParse(json['updatedAt'] as String) : null,
      updatedBy: json['updatedBy'] is num ? (json['updatedBy'] as num).toInt() : null,
      updatedByName: json['updatedByName'] as String?,
    );
  }

  factory FeatureFlag.fallback(String key) => FeatureFlag(key: key);

  final String key;
  final String description;
  final bool enabled;
  final bool evaluation;
  final String activeSource;
  final FeatureRollout rollout;
  final List<String> tags;
  final String? owner;
  final String? since;
  final String? notes;
  final bool defaultEnabled;
  final List<String> environments;
  final Map<String, dynamic> sources;
  final DateTime? updatedAt;
  final int? updatedBy;
  final String? updatedByName;

  bool get isEnabled => evaluation;

  FeatureFlag copyWith({
    bool? enabled,
    bool? evaluation,
    FeatureRollout? rollout,
    String? activeSource,
    String? notes,
  }) {
    return FeatureFlag(
      key: key,
      description: description,
      enabled: enabled ?? this.enabled,
      evaluation: evaluation ?? this.evaluation,
      activeSource: activeSource ?? this.activeSource,
      rollout: rollout ?? this.rollout,
      tags: tags,
      owner: owner,
      since: since,
      notes: notes ?? this.notes,
      defaultEnabled: defaultEnabled,
      environments: environments,
      sources: sources,
      updatedAt: updatedAt,
      updatedBy: updatedBy,
      updatedByName: updatedByName,
    );
  }
}
