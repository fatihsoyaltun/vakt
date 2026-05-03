class RamadanPrayer {
  final int dayIndex;
  final String title;
  final String arabic;
  final String turkish;

  const RamadanPrayer({
    required this.dayIndex,
    required this.title,
    required this.arabic,
    required this.turkish,
  });

  factory RamadanPrayer.fromJson(Map<String, dynamic> json) {
    return RamadanPrayer(
      dayIndex: json['day_index'] as int,
      title: json['title'] as String,
      arabic: json['arabic'] as String,
      turkish: json['turkish'] as String,
    );
  }
}
