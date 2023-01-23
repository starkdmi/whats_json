import 'dart:collection';
import 'dart:io';
import 'dart:convert';
import 'package:path/path.dart';
import 'package:xml/xml.dart';

/// Get original translation of system messages:
/// Download WhatsApp IPA - https://github.com/ahmadmokaddam/Whatsapp-Revael
/// Open IPA and go to de.lproj then run:
/// plutil -convert json Localizable.strings
const iosDirectory = "./tools/data/iOS Localizables/";

/// Translations files can be found at:
/// - https://github.com/HassanSardar/GBWhatsApp_Raw - 2017
/// - https://github.com/JaapSuter/Niets - 2012
/// - https://github.com/adamkhribeche/whatsap - 2019 
/// - https://github.com/sebasroldanm/RA-WA_8.15_iOS_Unclone - 2020
/// 
/// Update:
/// Download official APK file - https://www.whatsapp.com/android 
/// assets/cldr_strings.pack - translations file
const androidDirectory = "./tools/data/Android Strings/";

void main() async => await collectAll();

Future<void> collectAll() async {
  /// attached - `zQ+5d`
  var pattern = await collectOneOrMany(["zQ+5d"]); 
  print("ATTACHED\n$pattern\n"); // TODO: add manually - `angehängt`

  /// Messages and calls are end-to-end encrypted (Android) - combined with iOS values
  final encrypted = await getAndroidTranlsationsFor("settings_security_info");
  final encryptedValues = encrypted.values.map((e) => e.replaceAll("\"", ""));
  /// Messages and calls are end-to-end encrypted - `_i3PG`
  pattern = await collectOneOrMany(["_i3PG"], append: encryptedValues, end: r").?"); 
  print("ENCRYPTED\n$pattern\n");

  /// This message was deleted (Android) - combined with iOS values
  final deleted = await getAndroidTranlsationsFor("revoked_msg_incoming");
  /// This message was deleted - `qBly]` 
  pattern = await collectOneOrMany(["qBly]"], append: deleted.values); 
  print("DELETED\n$pattern\n");

  /// You deleted this message (Android) - combined with iOS values
  final youDeleted = await getAndroidTranlsationsFor("revoked_msg_outgoing");
  /// You deleted this message - `GHe7G` and `S?EA5`
  pattern = await collectOneOrMany(["GHe7G", "S?EA5"], append: youDeleted.values ); 
  print("DELETED BY YOU\n$pattern\n");

  /// Missed voice call (Android) - combined with iOS values
  final missedVoiceCall = await getAndroidTranlsationsFor("missed_voice_call");
  /// Missed voice call - `A),w/` and `f/]I7` 
  pattern = await collectOneOrMany(["A),w/", "f/]I7"], append: missedVoiceCall.values); 
  print("MISSED VOICE CALL\n$pattern\n");

  /// Missed video call (Android) - combined with iOS values
  final missedVideoCall = await getAndroidTranlsationsFor("video_missed_call");
  /// Missed video call - "PnA`x"
  pattern = await collectOneOrMany(["PnA`x"], append: missedVideoCall.values); 
  print("MISSED VIDEO CALL\n$pattern\n");

  /// Image omitted - `n*sq0`
  pattern = await collectOneOrMany(["n*sq0"], start: r"^\<?(", end: r")\>?.?" + endOfLine); 
  print("IMAGE OMITTED\n$pattern\n");

  /// Video omitted - `I4|vp`
  pattern = await collectOneOrMany(["I4|vp"], start: r"^\<?(", end: r")\>?.?" + endOfLine); 
  print("VIDEO OMITTED\n$pattern\n");

  /// Audio omitted - `a86Wu`
  pattern = await collectOneOrMany(["a86Wu"], start: r"^\<?(", end: r")\>?.?" + endOfLine); 
  print("AUDIO OMITTED\n$pattern\n");

  /// Sticker omitted - `2K_mB`
  pattern = await collectOneOrMany(["2K_mB"], start: r"^\<?(", end: r")\>?.?" + endOfLine); 
  print("STICKER OMITTED\n$pattern\n");

  /// GIF omitted - `~.KLq`
  pattern = await collectOneOrMany(["~.KLq"], start: r"^\<?(", end: r")\>?.?" + endOfLine); 
  print("GIF OMITTED\n$pattern\n");

  /// Contact card omitted - `Sk+0p`
  pattern = await collectOneOrMany(["Sk+0p"], start: r"^\<?(", end: r")\>?.?" + endOfLine); 
  print("CONTACT CARD OMITTED\n$pattern\n");

  /// Document omitted - `StaLC`
  pattern = await collectOneOrMany(["StaLC"], start: r"^\<?(", end: r")\>?.?" + endOfLine); // sometimes appear after the file name
  pattern = r"(^|\s)" + pattern.substring(1);
  print("DOCUMENT OMITTED\n$pattern\n");

  /// Your security code with ... changed combined from two keys `G)W)p` and `7<vSf`
  final security = await collectAllValuesForKeys(["G)W)p"]);
  final more = await collectAllValuesForKeys(["7<vSf"]);
  String securityPattern = "^(";
  for (var i = 0; i < security.length; i++) {
    var part1 = security[i].replaceAll("%@", r"[^\n|\r|\r\n]+"); // [^\s]+
    if (part1.endsWith(".")) {
      part1 = part1.substring(0, part1.length - 1);
    }
    var part2 = more[i];
    if (part2.endsWith(".")) {
      part2 = part2.substring(0, part2.length - 1);
    }
    securityPattern += "$part1.?\\s?$part2|";
  }
  securityPattern = securityPattern.substring(0, securityPattern.length - 1); // remove dot at the end
  securityPattern += ").?" + endOfLine;
  securityPattern = escape(securityPattern);
  print("SECURITY CODE CHANGED\n$securityPattern\n");

  /// MOVED TO [ANDROID] IMPLEMENTATION
  /// <Media omitted> not found in iOS Localizable.strings but appear in some _chat.txt files
  /// take "media" translation from here - `R>~3|`:"‎Media, Links, and Docs" - DE "‎Medien, Links und Doks"
  /// and "omitted" translation from `I4|vp`:"‎video omitted" - DE "Video weggelassen"
  /*var media = await collectAllValuesForKeys(["R>~3|"]);
  media = media.toSet().map((e) => e.split(",").first).toList();

  var omitted = await collectAllValuesForKeys(["I4|vp"]);
  omitted = omitted.toSet().map((e) => e.split(" ").last).toList();

  String mediaOmittedPattern = r"^<\s?(";
  for (var i = 0; i < media.length; i++) {
    mediaOmittedPattern += "${media[i]} ${omitted[i]}|";
  }
  // additional know values from Android translations
  mediaOmittedPattern += r"המדיה הוסרה|המדיה לא נכללה|Без медиафайлов|Média manquante|Media mancante|Mídia omitida|Αποχρεωτική παραλαβή μέσων|Медіа відсутня|Medien fehlen|ملفات مفقودة).?\s?>"; // +endOfLine - optional end of line
  mediaOmittedPattern = escape(mediaOmittedPattern);
  print("MEDIA OMITTED\n$mediaOmittedPattern\n");*/

  // Android specific keys
  final mediaOmittedValues = await getAndroidTranlsationsFor("email_media_omitted");
  final mediaOmitted = mediaOmittedValues.values.map((e) {
    e = e.substring(1, e.length - 1); // <Media omitted>
    e = e.replaceAll("/", r"\/"); // some of rtl languages has unescaped backslash in translation
    return e;
  }); 
  final mediaOmittedPattern = escape(r"^<\s?(Media omitted|" + mediaOmitted.join("|") + r")\s?>" + endOfLine);
  print("MEDIA OMITTED (ANDROID)\n$mediaOmittedPattern\n");

  final attachedValues = await getAndroidTranlsationsFor("email_file_attached");
  final attached = attachedValues.values.map((e) => e.substring(4, e.length - 1)); // %s (file attached)
  final attachedPattern = escape(r"^(?<file>.*)\s\((file attached|" + attached.join("|") + r")\)" + endOfLine);
  print("FILE ATTACHED (ANDROID)\n$attachedPattern\n");

  final locationValues = await getAndroidTranlsationsFor("email_location_message");
  final location = locationValues.values.map((e) => e.substring(0, e.length - 4)); // location: %s
  final locationPattern = escape(r"^(location|" + location.join("|") + r"):?\s(?<link>https://maps.google.com/\?q=(?<longitude>[0-9\.]*),(?<latitude>[0-9\.]*))" + endOfLine);
  print("LOCATION (ANDROID)\n$locationPattern\n");
  // TODO: For iOS add additionally `[^\s]+`

  final liveLocation = await getAndroidTranlsationsFor("email_live_location_message");
  final liveLocationPattern = escape(r"^(live location shared|" + liveLocation.values.join("|") + r")" + endOfLine);
  print("LIVE LOCATION (ANDROID)\n$liveLocationPattern\n");
}

const String endOfLine = r"(\n|\r|\r\n|$)";

/// escape hidden characters
String escape(String text) {
  // final clearRunes = text.runes.where((rune) => 
  //   rune != "\u202D".runes.first && 
  //   rune != "\u202E".runes.first && 
  //   rune != 8206
  // );
  // text = String.fromCharCodes(clearRunes);
  text = text.replaceAll(RegExp(r'\u{200e}', unicode: true), '');
  text = text.replaceAll(RegExp(r'\u{00a0}', unicode: true), ' '); 
  return text;
}

/// Get one-line all translations regex: (omitted|absente)
Future<String> collectOneOrMany(List<String> keys, {Iterable<String> append = const [], String? start, String? end}) async {
  final values = await collectAllValuesForKeys(keys);

  final unique = values.toSet().map((e) {
    // used in <attached %@>
    e = e.replaceAll("<", "").replaceAll(": %@>", ""); 

    // dot at the end not always exists - remove
    if (!e.endsWith(".")) return e; 
    return e.substring(0, e.length - 1);
  });

  String joined;
  if (append.isNotEmpty) {
    final extended = LinkedHashSet<String>(
      equals: (p0, p1) => p0.toLowerCase() == p1.toLowerCase(), 
      hashCode: (p) => hash(p.toLowerCase())
    );
    extended.addAll(unique);
    extended.addAll(append);
    joined = extended.join("|");
  } else {
    joined = unique.join("|");
  }

  // ignore: prefer_if_null_operators
  final string = "${start != null ? start : "^("}$joined${end != null ? end : ").?$endOfLine"}"; 
  return escape(string);
}

/// WhatsApp iOS Locallizable strings collector
Future<List<String>> collectAllValuesForKeys(List<String> keys) async {
  const languages = [ 
    "EN", "HE", "RU", "FR", "IT", "PT-PT", "ES-SP", "GR-EL", "UKR", "DE", "AR",  "BN", "ZH-HK", "ZH-Hant", "ZH-Hans", "VI", "UR", "TR", "TH", "SV", "SK", "PL", "RO", "PT-BR", "NL", "NB", "MS", "MR", "KO", "JA", "HU", "ID", "HR", "HI", "GU", "GA", "FI", "FA", "DA", "EL", "CS", "CA"
  ];

  List<String> values = [];
  for (final lang in languages) {
    final string = await File("$iosDirectory$lang.strings").readAsString();
    final content = jsonDecode(string);

    for (final key in keys) {
      values.add(content[key]);
    }
  }
  return values;
}

/// Get all translations for [key] for Android
/// 
/// Examples:
/// <string name="email_media_omitted">&lt;Media omitted></string>
/// <string name="email_file_attached">%s (soubor byl přiložen)</string>
Future<Map<String, String>> getAndroidTranlsationsFor(String key) async {
  Map<String, String> translations = {};

  // loop over all Android app locals
  await for (final entry in Directory(androidDirectory).list()) {
    final name = basename(entry.path);
    if (!name.startsWith("values-")) continue; 

    final lang = name.substring(7); // skip "values-"

    final file = File("${entry.path}/strings.xml");
    if (!file.existsSync()) continue;
    
    final string = await file.readAsString();
    final document = XmlDocument.parse(string);

    final resources = document.getElement("resources");
    if (resources == null) continue;

    // loop over localizable strings
    for (final child in resources.children) {
      if (child.attributes.isEmpty) continue;
      if (child.attributes.first.value == key) {
        final value = child.text;
        // save value and finish with current file
        translations[lang] = value;
        break;
      }
    }
  }
  return translations;
}