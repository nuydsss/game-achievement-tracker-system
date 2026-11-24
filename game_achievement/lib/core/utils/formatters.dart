String formatHours(double hours) {
  final whole = hours == hours.roundToDouble();
  return '${whole ? hours.toInt() : hours.toStringAsFixed(1)} h';
}

String formatDate(DateTime? date) {
  if (date == null) return '-';
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  return '${months[date.month - 1]} ${date.day}, ${date.year}';
}
