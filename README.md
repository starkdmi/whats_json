# whats_json
> Dart package and cli tool for extracting messages from WhatsApp **_chat.txt** file and convert them to **JSON** format.<br/>

## Features
- Supports personal and group chats, [iOS](https://faq.whatsapp.com/iphone/chats/how-to-back-up-to-icloud/) and [Android](https://faq.whatsapp.com/1180414079177245) export formats
- Works with attachments and locations
- Detect system messages regardless of language
- Process dates in multiple calendars and locales
- Crossplatform with power of [Dart](https://dart.dev/)

## Command line tool
Simple command line application provide interface to convert exported **_chat.txt** to **JSON** file. [More](/cli/README.md)
```Bash
dart cli.dart -i chat.txt -o chat.json
```

## Package
Dart package support all the platforms including Web. Simply include latest version from [pub.dev](https://pub.dev/packages/whats_json) to `pubspec.yaml`
```Dart
// read file
final stream = File("_chat.txt")
    .openRead()
    .transform(const Utf8Decoder())
    .transform(const LineSplitter());
      
// get messages
List<Map<String, dynamic>> messages = await whatsAppGetMessages(stream);
```

## Fields
When messages are processed the following fields can appear in results
|Name|Required|Data type|Description|
|---|---|---|---|
|_type_|**yes**|`text`, `image`, `video`, `audio`, `gif`, `sticker`, `file`, `location`, `system`|Message type, based on that field optional fields are present or absence|
|_text_|**required** for `Text` and `System` messages, **optional** for `Location` and `Media` messages|any `string`|Plain text|
|_author_|**optional** for `System` messages <ins>only</ins>, **required** for other|any `string`|Sender name or phone number|
|_date_|when `date` is *empty*, `dateString` and `timeString` fields will appear|positive `int`|Seconds since epoch in `UTC`|
|_dateString_|exists only when `date` is empty|any `string`|Original date string|
|_timeString_|exists only when `date` is empty|any `string`|Original time string|
|_uri_|**required** for `Media` messages|any `string`|Media filename|
|_link_|**required** for `Location` messages|valid https link `string`|Google Maps or Foursquare location link|
|_longitude_|**optional**|valid longitude `string`|Longitude value parsed from Google Maps link|
|_latitude_|**optional**|valid latitude `string`|Latitude value parsed from Google Maps link|

## Date Formats and Calendars
Library supports simple date formats like `4/25/2022`, `25-04-2022`, `2022.04.25` as well as localized `Tuesday, 25 April 2022`.<br/>
Additionally to Gregorian the Buddhist `3/18/2565 BE` and Japanese Imperial `3/18/R4` calendars are supported.<br/>
Arabic right-to-left dates are also works by default ```٢٧‏/٣‏/٢٠٢٢، ٩:٥٣:٥٦ م```.

## Message Types
Messages are divided to `Text`, `Image`, `Video`, `Audio`, `GIF`, `Sticker`, `File`, `Location` and `System`

### Text Message
Multiline plain text messages<br/>
```Text
[3/27/22, 21:41:35] Elon Musk: Hello, Space!
``` 
processed into
```JSON
{
    "type": "text",
    "author": "Elon Musk",
    "date": 1648417295,
    "text": "Hello, Space!"
}
```

### Attachment Message: Image, Video, Audio, GIF, Sticker, File
Attachments type detected based on file name first - `IMG-20220327-WA0001`, then on file extension using [mime](https://pub.dev/packages/mime) package<br/>

**iOS**
```Text
[3/27/22, 21:41:55] Elon Musk: <attached: 00000001-PHOTO-2022-03-27-21-41-55.jpg>
```
**Android**
```Text
27/03/2022, 21:41:55 - Elon Musk: IMG-20220327-WA0001.jpg (file attached)
```

Where `attached` and `file attached` can appear in any language. For example in Czech `file attached` is `soubor byl přiložen`.

**JSON**
```JSON
{
    "type": "image",
    "author": "Elon Musk",
    "date": 1648417315, 
    "uri": "00000001-PHOTO-2022-03-27-21-41-55.jpg"
}
```
Type is lowercased - `image`, `video`, `audio`, `gif`, `sticker`, `file`.

### Location
Location message has two formats depending on which service is used, *Google Maps* or *Foursquare*.<br/>

**iOS**
```Text
[3/27/22, 21:56:45] Elon Musk: Location: https://maps.google.com/?q=51.5021456,-0.127397
[3/27/22, 21:46:03] Elon Musk: Pimlico Gardens (London, United Kingdom): https://foursquare.com/v/4e89af95e5fa82ad4c0aa03b
```
**Android**
```Text
27/03/2022, 21:56:45 - Elon Musk: location: https://maps.google.com/?q=51.50214569326172,-0.12739796972656
```

**JSON (Google Maps)**
```JSON
{
    "type": "location",
    "author": "Elon Musk",
    "date": 1648418205,
    "link": "https://maps.google.com/?q=51.5021456,-0.127397",
    "longitude": "51.5021456",
    "latitude": "-0.127397"
}
```
**JSON (Foursquare)**
```JSON
{
    "type": "location",
    "author": "Elon Musk",
    "date": 1648417563,
    "link": "https://foursquare.com/v/4e89af95e5fa82ad4c0aa03b",
    "text": "Pimlico Gardens (London, United Kingdom)"
}
```

### System
All system messages translated and exported in user locale. Those translations collected from original WhatsApp localizable strings for iOS and Android, for more info check out [the patterns generator](/tools/patterns_generator/patterns_generator.dart). <br/>
```Text
[3/18/22, 14:56:01] Elon Musk: Messages and calls are end-to-end encrypted. No one outside of this chat, not even WhatsApp, can read or listen to them.
[1/7/23, 23:32:30] Elon Musk: Your security code with Elon changed. Tap to learn more.
```
processed into
```JSON
{
    "type": "system",
    "text": "Messages and calls are end-to-end encrypted. No one outside of this chat, not even WhatsApp, can read or listen to them.",
    "author": "Elon Musk",
    "date": 1647615361
},
{
    "type": "system",
    "text": "Your security code with Elon changed. Tap to learn more.",
    "author": "Elon Musk",
    "date": 1673134350
},
```
System messages can have no `author` field (mostly in group chats).

## Chat Export
Follow official chat export intructions for [iOS](https://faq.whatsapp.com/iphone/chats/how-to-back-up-to-icloud/) and [Android](https://faq.whatsapp.com/1180414079177245/).<br/>
Current implementation supports most of formats from official WhatsApp applications released before `Jan 1 2023` and will be updated for future versions.

## TODO
- [ ] Improve perfomance. Unicode regex matching takes a lot of time. Usually 100 chats proceed in 2 minutes
- [ ] Collect more data and create more tests (chat, chat with media and group chat for every language)
- [ ] Config - allow to set less locales, date and time formats, optionally disable date processing

## Why
There is a lot of packages on Github which parse WhatsApp _chat.txt files but many of them are too simple and do not cover every edge case due to simplicity. The good one is [whatsapp-chat-parser](https://github.com/Pustur/whatsapp-chat-parser) while it still do not divide messages by attachment types, do not detects text system messages and is written in Node.js, which doesn't suit my needs.

## More info
- **Size** - Source code is about 100KB uncompressed, while the [patterns.dart](/lib/src/patterns.dart) is ~75KB due to all unicode characters from every translations

- **Research** - Collected _chat.txt files are splitted to five categories - `ios`, `android`, `languages`, `calendars` and `all chats combined`.
[chats_unique](/test/data/chats_unique) directory contained more that 400 unique chats, most of them were collected on Github using search api. The files from Github are markered by file name which combines github username, repository and full file path separated by space

## License
This project is **free** for personal use. This package was developed for commercial application and it's not allowed to use to compete with it, contact me at `starkdev@icloud.com` for business use cases.