/// 每日选书策略
enum BookPickStrategy {
  roundRobin('轮询在读书'),
  longestUnread('最久未读'),
  random('随机'),
  manual('手动指定');

  const BookPickStrategy(this.label);
  final String label;

  static BookPickStrategy fromName(String? name) {
    return BookPickStrategy.values.firstWhere(
      (s) => s.name == name,
      orElse: () => BookPickStrategy.roundRobin,
    );
  }
}
