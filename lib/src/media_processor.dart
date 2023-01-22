part of 'message_parser.dart';

/// Helper class to work with mime types of filenames
final mimeTypeResolver = MimeTypeResolver()..addExtension("opus", "audio/opus");

/// Detect if message is media type, return updated [Message] object
Message? parseMedia(Message data) {
  final content = data.content;

  // process body to determine message type
  final attachmentMatch = WhatsAppPatterns._attachmentRegex.firstMatch(content);
  final attachment = attachmentMatch?.namedGroup("file") ?? attachmentMatch?.namedGroup("file2");
  final caption = attachmentMatch?.namedGroup("caption");
  if (attachment == null) {

    // check if location is present in body's text 
    String? location, place, longitude, latitude;
    
    // google link with coordinates
    final googleMatch = WhatsAppPatterns._googleLocationRegex.firstMatch(content);
    if (googleMatch != null) {
      location = googleMatch.namedGroup("link"); 
      longitude = googleMatch.namedGroup("longitude");
      latitude = googleMatch.namedGroup("latitude");
    }
    
    // foursquare link with optional text
    final line = content.replaceAll("\n", " "); // fix Android multiline location message
    final foursquareMatch = WhatsAppPatterns._foursquareLocationRegex.firstMatch(line);
    if (foursquareMatch != null) {
      location ??= foursquareMatch.namedGroup("link"); 
      place = foursquareMatch.namedGroup("place")?.trim();
      // remove trailing semicolon
      if (place != null && place.endsWith(":")) {
        place = place.substring(0, place.length - 1);
      } 
    }

    if (location != null) {
      // Location
      data.type = "location";
      data.fields = {
        "link": location,
        if (place != null) "text": place,
        if (longitude != null) "longitude": longitude,
        if (latitude != null) "latitude": latitude,
      };
    } else {
      // Text
      data.type = "text";
      data.fields = {
        "text": content,
      };
    }
  } else {
    // ignore: unnecessary_string_interpolations
    String filename = "$attachment"; 
    if (filename.length > 9 && int.tryParse(filename.substring(0, 8)) != null && filename[8] == "-") {
      // skip attachment id + `-` symbol
      filename = filename.substring(9);
    }

    String type;
    // try to get file type using WhatsApp file name
    if (filename.startsWith("PHOTO-") || filename.startsWith("IMG-")) {
      type = "image";
    } else if (filename.startsWith("GIF-")) {
      // GIF exported as mp4
      type = "gif";
    } else if (filename.startsWith("VIDEO-") || filename.startsWith("VID-")) {
      type = "video";
    } else if (filename.startsWith("AUDIO-") || filename.startsWith("PTT-")) {
      type = "audio";
    } else if (filename.startsWith("STICKER-") || filename.startsWith("STK-")) {
      type = "sticker";
    } else {
      // detect file type using mime package
      final mimeType = mimeTypeResolver.lookup(attachment);
      // headerBytes allow to detect type based on file header 

      // get file type using mime package
      if (mimeType?.startsWith("image") == true) {
        type = "image";
      } else if (mimeType?.startsWith("video") == true) {
        type = "video";
      } else if (mimeType?.startsWith("audio") == true) {
        type = "audio";
      } else {
        type = "file";
      }
    }

    data.type = type;
    data.fields = {
      // "name": filename,
      "uri": attachment,
      // "mime": mimeType
      if (caption != null && caption.trim().isNotEmpty) "text": caption
    };
  }

  return data;
}