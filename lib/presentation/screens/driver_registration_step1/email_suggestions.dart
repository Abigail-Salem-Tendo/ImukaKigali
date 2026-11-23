/// The email services most people in Rwanda use, in the order they are
/// suggested.
const List<String> commonEmailDomains = [
  'gmail.com',
  'yahoo.com',
  'outlook.com',
  'hotmail.com',
  'icloud.com',
  'yahoo.fr',
];

/// Returns full email addresses that finish what the driver has typed.
/// Nothing is suggested until "@" is typed. After it, every common domain
/// that starts with the letters typed so far is suggested, so "jean@g"
/// gives "jean@gmail.com". An address that is already complete gives none.
List<String> emailSuggestions(String typed) {
  final text = typed.trim();
  final at = text.indexOf('@');
  if (at <= 0 || at != text.lastIndexOf('@')) {
    return const [];
  }
  final name = text.substring(0, at);
  final domain = text.substring(at + 1).toLowerCase();
  return [
    for (final option in commonEmailDomains)
      if (option.startsWith(domain) && option != domain) '$name@$option',
  ];
}
