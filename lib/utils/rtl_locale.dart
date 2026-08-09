import 'package:flutter/material.dart';

const Set<String> _rtlLanguageCodes = {
  'ar',
};

bool isRtlLocale(Locale locale) {
  return _rtlLanguageCodes.contains(locale.languageCode.toLowerCase());
}

TextDirection textDirectionForLocale(Locale locale) {
  return isRtlLocale(locale) ? TextDirection.rtl : TextDirection.ltr;
}

TextAlign textAlignForLocale(
  Locale locale, {
  TextAlign ltr = TextAlign.left,
  TextAlign rtl = TextAlign.right,
}) {
  return isRtlLocale(locale) ? rtl : ltr;
}
