/// Internal contract headline, derived identically in create and edit.
String autoTitle(String text) {
  final t = text.trim().replaceAll(RegExp(r'\s+'), ' ');
  if (t.isEmpty) return '';
  final cut = t.split(RegExp(r'[.!?\n]')).first.trim();
  final s = cut.length < 5 ? t : cut;
  return s.length <= 90 ? s : '${s.substring(0, 87).trimRight()}…';
}
