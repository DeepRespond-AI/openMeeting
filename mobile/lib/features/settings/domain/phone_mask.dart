/// Masks the middle of a phone number: `13800138000` → `138****8000`.
/// Numbers too short to mask keep their digits.
String maskPhone(String phone, {required int visiblePrefix, required int visibleSuffix}) {
  const maskChar = '*';
  final hidden = phone.length - visiblePrefix - visibleSuffix;
  if (hidden <= 0) return phone;
  return phone.substring(0, visiblePrefix) +
      maskChar * hidden +
      phone.substring(phone.length - visibleSuffix);
}
