class IslamicVideoItem {
  final String id;
  final String title;
  final String description;
  final String videoUrl;
  final String imageUrl;
  final String language;
  final String author;
  final String size;
  final List<String> tags;
  int likesCount;
  bool isLiked;

  IslamicVideoItem({
    required this.id,
    required this.title,
    required this.description,
    required this.videoUrl,
    required this.imageUrl,
    this.language = 'en',
    this.author = 'IslamHouse Scholars',
    this.size = '',
    this.tags = const ['Islamic Guidance', 'Hikmah', 'Sunnah'],
    this.likesCount = 128,
    this.isLiked = false,
  });

  factory IslamicVideoItem.fromJson(Map<String, dynamic> json, {String defaultLang = 'en'}) {
    // Extract video attachments
    String videoUrl = '';
    String size = '';
    final attachments = json['attachments'];
    if (attachments is List && attachments.isNotEmpty) {
      for (final att in attachments) {
        if (att is Map<String, dynamic>) {
          final ext = (att['extension_type'] ?? '').toString().toUpperCase();
          final url = (att['url'] ?? '').toString();
          if (ext == 'MP4' || url.endsWith('.mp4')) {
            videoUrl = url;
            size = (att['size'] ?? '').toString();
            break;
          }
        }
      }
      // Fallback to first attachment url if no MP4 explicitly matched
      if (videoUrl.isEmpty && attachments.first is Map<String, dynamic>) {
        videoUrl = (attachments.first['url'] ?? '').toString();
        size = (attachments.first['size'] ?? '').toString();
      }
    }

    // Extract author / speaker name
    String authorName = 'IslamHouse';
    final preparedBy = json['prepared_by'];
    if (preparedBy is List && preparedBy.isNotEmpty) {
      for (final p in preparedBy) {
        if (p is Map<String, dynamic> && p['title'] != null && p['title'].toString().trim().isNotEmpty) {
          authorName = p['title'].toString().trim();
          break;
        }
      }
    }

    final rawTitle = (json['title'] ?? 'Islamic Reflection').toString().trim();
    final rawDesc = (json['description'] ?? json['full_description'] ?? '').toString().trim();
    final rawImage = (json['image'] ?? '').toString().trim();
    final lang = (json['source_language'] ?? json['translated_language'] ?? defaultLang).toString();
    final itemId = (json['id'] ?? json['source_id'] ?? DateTime.now().millisecondsSinceEpoch).toString();

    // Derive relevant Islamic tags from title/description
    final derivedTags = <String>['Islamic Guidance'];
    final lowerTitle = rawTitle.toLowerCase();
    if (lowerTitle.contains('umrah') || lowerTitle.contains('hajj')) {
      derivedTags.add('Hajj & Umrah');
    }
    if (lowerTitle.contains('pray') || lowerTitle.contains('salah') || lowerTitle.contains('salat')) {
      derivedTags.add('Salah');
    }
    if (lowerTitle.contains('wudu') || lowerTitle.contains('ablution') || lowerTitle.contains('taharah')) {
      derivedTags.add('Purity & Wudu');
    }
    if (lowerTitle.contains('quran') || lowerTitle.contains('surah') || lowerTitle.contains('ayah')) {
      derivedTags.add("Holy Qur'an");
    }
    if (lowerTitle.contains('ramadan') || lowerTitle.contains('fasting') || lowerTitle.contains('sawm')) {
      derivedTags.add('Fasting');
    }
    if (derivedTags.length == 1) {
      derivedTags.add('Hikmah');
      derivedTags.add('Sunnah');
    }

    // Deterministic initial like count based on ID hash
    final baseLikes = 85 + (itemId.hashCode.abs() % 415);

    return IslamicVideoItem(
      id: itemId,
      title: rawTitle.isNotEmpty ? rawTitle : 'Beneficial Islamic Clip',
      description: rawDesc,
      videoUrl: videoUrl,
      imageUrl: rawImage,
      language: lang,
      author: authorName,
      size: size,
      tags: derivedTags,
      likesCount: baseLikes,
      isLiked: false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'videoUrl': videoUrl,
      'imageUrl': imageUrl,
      'language': language,
      'author': author,
      'size': size,
      'tags': tags,
      'likesCount': likesCount,
      'isLiked': isLiked,
    };
  }
}
