/// Class internally used for transfering message data from fucntion to function
class Message {
  Message({
    required this.type,
    this.sender,
    required this.content,
    required this.dateString,
    required this.timeString,
  });

  /// Chat type, i.e. `system`, `image`, `text` atd.
  String type;

  /// Sender, `null` for system messages
  String? sender;

  /// Raw message text
  String content;

  /// Date value in seconds since epoch
  int? date;

  /// Original date string
  String dateString;

  /// Time value in seconds since epoch
  int? time;

  /// Original time string
  String timeString;

  /// Date and Time seconds since epoch combined, `0` for unknown [dateTime]
  int dateTime = 0;

  /// Custom fields used for media message type
  Map<String, dynamic> fields = {};

  /// Indicatex if message is system
  bool get isSystem => type == "system";

  /// Convert message object to Map type
  Map<String, dynamic> toMap() => {
        "type": type,
        if (isSystem) "text": content,
        if (sender != null && sender != "") "author": sender,
        if (dateTime != 0) "date": dateTime,
        if (dateString != "") "dateString": dateString,
        if (timeString != "") "timeString": timeString,
        ...fields
      };
}
