// Lightweight date formatter — replaces the `intl` package dependency.
// Formats DateTime as "26 Feb 2026, 5:41 PM"
String formatInvoiceDate(DateTime d) {
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];
  final hour = d.hour % 12 == 0 ? 12 : d.hour % 12;
  final minute = d.minute.toString().padLeft(2, '0');
  final amPm = d.hour >= 12 ? 'PM' : 'AM';
  final day = d.day.toString().padLeft(2, '0');
  return '$day ${months[d.month - 1]} ${d.year}, $hour:$minute $amPm';
}
