part of 'message_parser.dart';

/// Regex patterns used for parsing WhatsApp export file lines
/// This class has public setters allowing patterns modification from outside:
/// * WhatsAppPatterns.messageFormats.add(...);
/// * WhatsAppPatterns.attachmentPattern = ...
class WhatsAppPatterns {
  /// Arabic date and time pattern (generator)
  static final String arabicDateTime = (() {
    final digit =
        r"[\u200F\u200E\u0621-\u064A\u0660-\u0669\d]"; // digit or rtl, ltr code

    // date
    final fourToOneDigits = r"(" +
        digit +
        r"{4}|" +
        digit +
        r"{3}|" +
        digit +
        r"{2}|" +
        digit +
        r"{1})";
    final dateSeparator = r"(\s|\-|_|\.|\/)";
    final datePattern = r"(?<date>" +
        fourToOneDigits +
        dateSeparator +
        fourToOneDigits +
        dateSeparator +
        fourToOneDigits +
        r")";

    // separator: Arabic comma and space
    final dateTimeSeparator = r"\u060C\s";

    // time
    final twoToOneDigits = r"(" + digit + r"{2}|" + digit + r"{1})";
    final hourFormat = r"\s?(\u00A0?(\u0635|\u0645))?"; // NBSP + AM|PM
    var timePattern = r"(?<time>" +
        twoToOneDigits +
        r":(" +
        twoToOneDigits +
        r":" +
        twoToOneDigits +
        r"|" +
        twoToOneDigits +
        r")" +
        hourFormat +
        r")";

    return datePattern + dateTimeSeparator + timePattern;
  })();

  /// Numeric date format regex pattern - 20/08/2022
  static const String date =
      r"(?<date>(\d{4}|\d{1,2})(?<separator>[.\/\-\s])\d{1,2}\k<separator>(\d{4}\sBE|\d{4}|\d{1,2}|[A-Za-z]\d))";

  /// Localized date format regex pattern - Tuesday, 20 August 2022
  static final String localeDate = (() {
    final word = r"\p{L}{3,16}"; // any word using unicode characters
    final weekDay = r"(" + word + r",\s)?"; // optional week day with separator
    // day, month and optional year
    final dmy = r"\d{1,2}\s" + word + r"(\s\d{4}|\d{1,2})?";
    // month, day and optional year
    final mdy = word + r"\s\d{1,2}" + r"(\s\d{4}|\d{1,2})?";
    // optional year, month, day
    final ymd = r"(\d{4}\s|\d{1,2}\s)?" + word + r"\s\d{1,2}";

    return r"(?<date>" + weekDay + r"(" + dmy + r"|" + mdy + r"|" + ymd + r"))";
  })();

  /// Time format regex pattern
  static const String time =
      r"(?<time>[0-9^\[\]]{1,2}[:.][0-9]{2}([:.][0-9]{2})?(\s[ap].?m.?|\sin the morning|\sin the afternoon)?)";

  /// Sender regex pattern
  static const String sender = r"(?<sender>[^\s\]\-][^:]+)";

  /// Content (message text) regex pattern
  static const String content = r"(?<content>(.|\n)+)";

  /// Start of line regex pattern
  static const String startOfLine = r"^\[?";

  /// End of line regex pattern
  static const String endOfLine = r"(\n|\r|\r\n|$)";

  /// Universal
  static const String universal = startOfLine +
      date +
      r"(,\s?|\s|،\s?)" +
      time +
      r"(\]\s?-?|:|\s-)\s" +
      sender +
      r":\s" +
      content +
      endOfLine;

  /// Time first, then date
  static const String timeFirst = startOfLine +
      time +
      r"(,\s?|\s|،\s?)" +
      date +
      r"(\]\s?-?|:|\s-)\s" +
      sender +
      r":\s" +
      content +
      endOfLine;

  /// Universal (localized date)
  static final String universalLocalized = startOfLine +
      localeDate +
      r"(,\s?|\s|،\s?)" +
      time +
      r"(\]\s?-?|:|\s-)\s" +
      sender +
      r":\s" +
      content +
      endOfLine;

  /// Time first, then date (localized date)
  static final String timeFirstLocalized = startOfLine +
      time +
      r"(,\s?|\s|،\s?)" +
      localeDate +
      r"(\]\s?-?|:|\s-)\s" +
      sender +
      r":\s" +
      content +
      endOfLine;

  /// Arabic message pattern (date and time changed from `universal`)
  static final String arabic = r"^\u200F?\[?" +
      arabicDateTime +
      r"(\]\s?-?|:|\s-)\s" +
      sender +
      r":\s" +
      content +
      endOfLine;

  /// Formats requiring [RegExp] running with `unicode` argument set to `true`
  static List<String> unicodeFormats = [
    universalLocalized,
    timeFirstLocalized,
    systemUniversalLocalized,
    systemTimeFirstLocalized,
  ];

  /// All regular message formats, extension is possible
  static List<String> messageFormats = [
    universal,
    timeFirst,
    universalLocalized,
    timeFirstLocalized,
    arabic,
  ];

  /// System Universal
  static const String systemUniversal = startOfLine +
      date +
      r"(,\s?|\s)" +
      time +
      r"(\]\s?-?|:|\s-)\s" +
      r"(" +
      sender +
      r":\s" +
      r")?" +
      content +
      endOfLine;

  /// System Time first, then date
  static const String systemTimeFirst = startOfLine +
      time +
      r"(,\s?|\s)" +
      date +
      r"(\]\s?-?|:|\s-)\s" +
      r"(" +
      sender +
      r":\s" +
      r")?" +
      content +
      endOfLine;

  /// System Universal (date localized)
  static final String systemUniversalLocalized = startOfLine +
      localeDate +
      r"(,\s?|\s)" +
      time +
      r"(\]\s?-?|:|\s-)\s" +
      r"(" +
      sender +
      r":\s" +
      r")?" +
      content +
      endOfLine;

  /// System Time first, then date (date localized)
  static final String systemTimeFirstLocalized = startOfLine +
      time +
      r"(,\s?|\s)" +
      localeDate +
      r"(\]\s?-?|:|\s-)\s" +
      r"(" +
      sender +
      r":\s" +
      r")?" +
      content +
      endOfLine;

  /// System Arabic message pattern (date and time changed from `systemUniversal`)
  static final String systemArabic = r"^\u200F?\[?" +
      arabicDateTime +
      r"(\]\s?-?|:|\s-)\s" +
      r"(" +
      sender +
      r":\s" +
      r")?" +
      content +
      endOfLine;

  /// All system message format, extension is possible
  static List<String> systemMessageFormats = [
    systemUniversal,
    systemTimeFirst,
    systemUniversalLocalized,
    systemTimeFirstLocalized,
    systemArabic,
  ];

  /// Message attachment regex pattern
  /// `iOS` - all languages collected from WhatsApp `v22.24.81` Localizable.strings for key `zQ+5d`
  /// Attachment can contain name/info before file uri:
  /// - Some file.txt ‎<attached: 00000001-Some file.txt>
  /// - Some.pdf • ‎2 pages ‎<attached: 00000002-Some.pdf>
  static const String _iosAttachmentPattern =
      r"^(?<name>[^\n|\r|\r\n]*)\s?<(المُرفق|attached|pièce jointe|‎прикреплено|‏پیوستہ,|allegato|anexo|adjunto|‎επισυνάφθηκε|‎додано|Anhang|‎附件|附件|đính kèm|eklendibifogat|príloha|załączono|atașare|anexado|bijgevoegd|vedlagt|dilampir|‎संलग्न केले|첨부됨|‎添付ファイル|csatolva|terlampir|priloženo|‎अटैच किया गया|‎જોડાયેલ|ceangailte|liite|‏پیوست|vedhæftet|příloha|adjunt|‎แนบ|‏מצורף|angehängt|прикреплено|επισυνάφθηκε|додано|‏پیوستہ|eklendi>|แนบ|bifogat|संलग्न केले| 첨부됨|添付ファイル|अटैच किया गया|જોડાયેલ): (?<file>.*)>" +
          endOfLine;

  /// `Android` - all languages collected from WhatsApp `2.8.4278` strings.xml for key - `email_file_attached`
  /// Caption may appear on the next line
  static const String _androidAttachmentPattern =
      r"^(?<file2>.*)\s\((file attached|fișier atașat|ఫైల్ జోడించబడినది|файл добавлен|nakalakip na file|附件檔案|file allegato|arxiu adjunt|soubor byl přiložen|文件附件|file terlampir|添付ファイル有り|συνημμένο αρχείο|pievienots fails|fil vedhæftet|फाइल संलग्न|қосымша файл|ફાઇલ જોડાયેલ|קובץ מצורף|fail dilampirkan|附件檔案|arquivo anexado|फाइल अटैच कर दी गई है|fayl biriktirildi|załączony plik|tệp đính kèm|skedë e ngjitur|bifogad fil|priložena datoteka|súbor pripojený|پیوستہ فائل|faili limeambatanishwa|dosya ekli|ணைக்கப்பட்டத|ไฟล์ที่แนบ| پیوست شد %|byla prisegta|vedlagt fil|קובץ מצורף|liitetiedosto|file terlampir|fichier joint|archivo adjuntado|fail lisatud|datoteka u privitku|fájl csatolva|bestand bijgevoegd|прикачен файл|ফাইল সংযুক্ত হয়েছে|lêer aangeheg|Datei angehängt|fayl əlavə olunub|파일 첨부됨|ഫയൽ ചേർത്തു|прикачен фајл|ಕಡತ ಸೇರಿಸಲಾಯಿತು|الملف مرفق|ficheiro anexado|файл додано|прикачена датотека|ਅਟੈਚ ਕੀਤੀ ਫਾਇਲ|文件附件)\)" +
          endOfLine +
          r"(?<caption>.*)";

  /// Combined pattern for iOS and Android
  static String _attachmentPattern =
      "($_iosAttachmentPattern|$_androidAttachmentPattern)";
  static String get attachmentPattern => _attachmentPattern;
  static set attachmentPattern(String pattern) {
    _attachmentPattern = pattern;
    _attachmentRegex = RegExp(pattern);
  }

  static RegExp _attachmentRegex = RegExp(_attachmentPattern);

  /// Message Google location link regex pattern
  /// "Location" starts with lower letter on Android - strings.xml key - `email_location_message`
  /// TODO: iOS "Location:" translations not found in Localizable.strings - `[^\s]+` additionally used for now, `\p{L}+` may be used as well, but unicode required to be true
  static RegExp _googleLocationRegex =
      RegExp(_googleLocationPattern, caseSensitive: false);
  // static String _googleLocationPattern = r"(location|[^\s]+):?\s(?<link>https://maps.google.com/\?q=(?<longitude>[0-9\.]*),(?<latitude>[0-9\.]*))" + _endOfLine;
  static String _googleLocationPattern =
      r"^(location|locație|స్థలం|местоположение|lokasyon|位置|posizione|ubicació|poloha|位|lokasi |位置情|τοποθεσία|atrašanās vieta|placering|स्थान|орналасуы|સ્થળ|מיקום|lokasi|位置|localização|स्थान |joylashuv|położenie|vị trí|Vendndodhja|plats|lokacija|poloha|مقام|Mahali|konum|இருப்பிடம|ตำแหน่งที่ตั้ง|موقعیت|buvimo vieta|posisjon|מיקום|sijainti|lokasi |localisation |ubicación|asukoht|lokacija|Helyzet|locatie|местоположение|অবস্থান|ligging|Standort|məkan|위치|സ്ഥലം|локација|ಸ್ಥಳ|الموقع|localização|місцезнаходження|локација |ਟਿਕਾਣਾ|位|[^\s]+):?\s(?<link>https://maps.google.com/\?q=(?<longitude>\-?[0-9\.]*),(?<latitude>\-?[0-9\.]*))" +
          endOfLine;
  static String get googleLocationPattern => _googleLocationPattern;
  static set googleLocation(String pattern) {
    _googleLocationPattern = pattern;
    _googleLocationRegex = RegExp(pattern, caseSensitive: false);
  }

  /// Message Foursquare location link regex pattern
  /// On Android location message is multilined
  static RegExp _foursquareLocationRegex =
      RegExp(_foursquareLocationPattern, multiLine: true);
  static String _foursquareLocationPattern =
      r"^(?<place>.*\(?.*\)?):?\s(?<link>https://foursquare.com.*)\b" +
          endOfLine;
  static String get foursquareLocationPattern => _foursquareLocationPattern;
  static set foursquareLocationPattern(String pattern) {
    _foursquareLocationPattern = pattern;
    _foursquareLocationRegex = RegExp(pattern, multiLine: true);
  }

  /// Messages and calls are end-to-end encrypted (system message) with Localizable key - `_i3PG` on iOS and `settings_security_info` on Android
  /// Sometimes message also has `Tap to learn more.` at the end - so checking for end of line is skipped
  static String encrypted =
      r"^(Messages and calls are end-to-end encrypted. No one outside of this chat, not even WhatsApp, can read or listen to them|‏ההודעות והשיחות מוצפנות מקצה-לקצה. לאף אחד מחוץ לצ'אט זה, גם לא ל-WhatsApp, אין אפשרות לקרוא אותן או להאזין להן|Сообщения и звонки защищены сквозным шифрованием. Третьи лица, включая WhatsApp, не могут прочитать ваши сообщения или прослушать звонки|Les messages et les appels sont chiffrés de bout en bout. Aucun tiers, pas même WhatsApp, ne peut les lire ou les écouter|I messaggi e le chiamate sono crittografati end-to-end. Nessuno al di fuori di questa chat, nemmeno WhatsApp, può leggerne o ascoltarne il contenuto|As mensagens e chamadas são encriptadas ponto a ponto. Ninguém fora desta conversa, nem mesmo o WhatsApp, pode ler ou ouvi-las|Los mensajes y las llamadas están cifrados de extremo a extremo. Nadie fuera de este chat, ni siquiera WhatsApp, puede leerlos ni escucharlos|Τα μηνύματα και οι κλήσεις κρυπτογραφούνται πλήρως. Κανένας εκτός αυτής της συνομιλίας, ούτε το WhatsApp, δεν μπορεί να τα διαβάσει ή να τις ακούσει|Повідомлення й дзвінки захищено наскрізним шифруванням. Прочитати чи прослухати їх не зможе жодна стороння особа, навіть із WhatsApp|Nachrichten und Anrufe sind Ende-zu-Ende-verschlüsselt. Niemand außerhalb dieses Chats kann sie lesen oder anhören, nicht einmal WhatsApp|‏الرسائل والمكالمات مشفرة تمامًا بين الطرفين، بحيث لا يستطيع أحد خارج هذه الدردشة، ولا حتى شركة واتساب نفسها، قراءتها أو الاستماع إليها|মেসেজ এবং কল এন্ড-টু-এন্ড এনক্রিপ্টেড থাকে। এই চ্যাটে থাকা ব্যক্তি ছাড়া অন্য কেউ এমনকি WhatsApp-ও সেগুলি পড়তে বা শুনতে পারবে না।|訊息和通話經端對端加密。對話以外的任何人 (即使是 WhatsApp) 均無法查看或聆聽那些內容。|訊息已受端對端加密保護。此對話以外所有人，包括 WhatsApp 在內，都無法讀取或聽取。|消息和通话都进行端到端加密。对话之外的任何人，甚至包含 WhatsApp，都无法读取或收听。|Tin nhắn và cuộc gọi được mã hóa đầu cuối. Những người bên ngoài cuộc trò chuyện này, kể cả WhatsApp, sẽ không đọc hoặc nghe được|‏میسجز اور کالز اینڈ ٹو اینڈ اینکرپشن کے ذریعے محفوظ ہیں۔ اس چیٹ کی بات چیت کو باہر کا کوئی بھی شخص پڑھ یا سن نہیں سکتا، WhatsApp بھی نہیں۔|Mesajlar ve aramalar uçtan uca şifrelidir. WhatsApp da dahil olmak üzere bu sohbetin dışında bulunan hiç kimse mesaj ve aramalarınızı okuyamaz ve dinleyemez|ข้อความและการโทรได้รับการเข้ารหัสจากต้นทางถึงปลายทาง ผู้ที่ไม่ได้อยู่ในแชทนี้จะไม่สามารถอ่านหรือฟังได้แม้แต่ WhatsApp เอง|Meddelanden och samtal är komplett krypterade. Ingen utanför denna chatt, inte ens WhatsApp, kan läsa dem eller lyssna på dem|Správy a hovory sú zabezpečené šifrovaním počas celého spojenia. Nemôže si ich vypočuť ani vidieť nikto, kto nie je ich účastníkom. Dokonca ani WhatsApp|Wiadomości i połączenia są w pełni zaszyfrowane. Nikt spoza czatu, nawet WhatsApp, nie może ich odczytać ani odsłuchać|Mesajele și apelurile sunt criptate integral. Nicio persoană care nu participă la această conversație, nici măcar WhatsApp, nu le poate citi sau asculta|As mensagens e as chamadas são protegidas com a criptografia de ponta a ponta e ficam somente entre você e os participantes desta conversa. Nem mesmo o WhatsApp pode ler ou ouvi-las|Berichten en gesprekken worden end-to-end versleuteld. Niemand buiten deze chat kan ze lezen of beluisteren, zelfs WhatsApp niet|Meldinger og samtaler er ende-til-ende-krypterte. Ingen utenfor samtalen, ikke engang WhatsApp, kan lese eller høre på dem|Mesej dan panggilan disulitkan hujung ke hujung. Tiada orang luar daripada sembang ini dapat membaca atau mendengar mesej, walaupun WhatsApp sendiri|मेसेजेस आणि कॉल्स एन्ड-टू-एन्ड एन्क्रिप्शनने सुरक्षित केलेले असतात. या चॅटमध्ये सहभागी असलेल्या व्यक्तींखेरीज इतर कोणीही, अगदी WhatsApp देखील ते वाचू किंवा ऐकू शकत नाही|메시지 및 전화는 종단간 암호화되어 안전합니다. 아무도 엿보거나 들을 수 없습니다. WhatsApp에게도 이러한 권한이 없습니다|メッセージと通話はエンドツーエンド暗号化されています。チャットの参加者以外は、たとえWhatsAppでも読んだり聞いたりすることはできません。|Az üzenetek és hívások végpontok közötti titkosítással vannak védve. A csevegés résztvevőin kívül senki, még a WhatsApp sem tudja elolvasni és meghallgatni azokat|Pesan dan panggilan terenkripsi secara end-to-end. Tidak seorang pun di luar chat ini, termasuk WhatsApp, yang dapat membaca atau mendengarkannya|Poruke i pozivi zaštićeni su potpunom enkripcijom. Nitko izvan ovog razgovora, čak ni WhatsApp, ne može ih pročitati niti poslušati|मैसेजेस और कॉल्स एंड-टू-एंड एन्क्रिप्टेड हैं. इस चैट में शामिल लोगों के अलावा कोई भी इन्हें पढ़ या सुन नहीं सकता, WhatsApp भी नहीं|મેસેજ અને કૉલ શરૂથી અંત સુધી સુરક્ષિત છે. આ ચેટની બહારની કોઈ વ્યક્તિ તેને વાંચી કે સાંભળી શકતી નથી, WhatsApp પણ નહિ|Déantar criptiúchán ó cheann go ceann ar theachtaireachtaí agus ar ghlaonna. Ní féidir le héinne lasmuigh den chomhrá iad a léamh ná éisteacht leo, fiú WhatsApp|Viestit ja puhelut salataan täysin. Kukaan tämän keskustelun ulkopuolinen, ei edes WhatsApp, voi lukea tai kuunnella niitä|‏پیام‌ها و تماس‌ها سرتاسر رمزگذاری شده‌اند. هیچ شخصی خارج از این گفتگو، حتی واتساپ، نمی‌تواند آن‌ها را بخواند یا بشنود|Beskeder og opkald er end-to-end-krypterede. Ingen uden for denne chat, selv ikke WhatsApp, kan læse eller høre dem|Zprávy a hovory jsou opatřeny koncovým šifrováním. Nikdo, kdo není přímým účastníkem této konverzace, ji nemůže sledovat ani poslouchat. Dokonce ani WhatsApp|Els missatges i les trucades estan xifrats d'extrem a extrem. Ningú de fora d'aquest xat, ni tan sols el WhatsApp, els pot llegir o escoltar|Mesajele dvs. și apelurile sunt securizate prin criptare integrală, ceea ce înseamnă că WhatsApp și terții nu le pot citi sau asculta.|మీ సందేశాలు మరియు కాల్స్ ఇది WhatsApp మరియు మూడవ పార్టీలు చదివిన లేదా వాటిని వినడానికి కాదు అంటే ఎండ్ టు ఎండ్ ఎన్క్రిప్షన్ తో సురక్షితం ఉంటాయి.|Ваши сообщения и звонки защищены сквозным шифрованием. Таким образом, у WhatsApp и третьих лиц нет к ним доступа.|Ang inyong mga mensahe at tawag ay secured gamit ang end-to-end encryption, hindi ito mababasa o madidinig ng WhatsApp pati na rin ng mga third-parties.|您傳送的訊息和通話都會進行端對端的加密。這意味著所有對話內容只有您和您的聊天對象才能看到或聽見，WhatsApp 和其他人都不能。|I tuoi messaggi e le tue chiamate sono protetti con la crittografia end-to-end, il che significa che WhatsApp e terze parti non possono leggerli o ascoltarli.|Els vostres missatges i trucades estan assegurades amb una encriptació d'extrem a extrem, això significa que ni WhatsApp ni altri els pot llegir o escoltar.|Vaše zprávy a hovory jsou zabezpečeny koncovým šifrováním. To znamená, že WhatsApp ani třetí strany je nemohou číst nebo poslouchat.|您发送的信息和通话都会进行端对端的加密。这意味着所有对话内容只有您和您的聊天对象才能看到或听见，WhatsApp 和其他人都不能。|Pesan-pesan dan panggilan Anda diamankan dengan enkripsi end-to-end, yang berarti WhatsApp dan pihak ketiga tidak dapat membacanya atau mendengarkannya.|メッセージと通話は、エンドツーエンドの暗号化によって保護されています。WhatsAppと第三者がそのメッセージを読んだり聞いたりすることはできません。|Τα μηνύματα και οι κλήσεις σας είναι ασφαλή με κρυπτογράφηση, το οποίο σημαίνει ότι ούτε το WhatsApp αλλά ούτε και κάποιος τρίτος μπορούν να τα δουν ή να τις ακούσουν.|Jūsu ziņas un zvani ir aizsargāti ar pilnīgu šifrēšanu, kas nozīmē, ka ne WhatsApp, ne trešajām pusēm nav iespējas tās lasīt vai noklausīties zvanus.|Dine beskeder og opkald er sikret med kryptering, som betyder at WhatsApp og tredjeparter ikke kan læse eller høre dem.|तुम्ही पाठवलेले संदेश आणि तुमचे कॉल्स संपूर्णपणे कूटबद्ध करून सुरक्षित केलेले आहेत, याचा अर्थ WhatsApp आणि तृतीय पक्ष त्यांना वाचू अथवा ऐकू शकणार नाही.|Сіздің хаттарыңыз және қоңырауларыңыз толығымен шифрлау арқылы қауіпсіз етілді. Сондықтан WhatsApp және үшінші тараптар оларды оқи немесе тыңдай алмайды.|તમારા સંદેશાઓ અને કૉલ્સ શરૂઆતથી અંત સુધી ગુપ્તીકરણ દ્વારા સુરક્ષિત છે, અર્થાત WhatsApp અને તૃતિય પક્ષો તેમને વાંચી કે સાંભળી શકતા નથી.|ההודעות שהנך שולח/ת והשיחות הקוליות שהנך מבצע/ת מאובטחות עם הצפנה מקצה לקצה, כך ש-WhatsApp או גורמי צד שלישי אינם יכולים לקרוא או להאזין להן.|Mesej-mesej dan panggilan anda selamat dengan penyulitan hujung ke hujung, yang bermakna WhatsApp dan pihak ketiga tidak dapat membaca atau mendengarnya.|Suas chamadas e mensagens estão seguras com criptografia de ponta-a-ponta, o que significa que o WhatsApp ou terceiros não podem lê-las ou ouví-las.|आपके द्वारा भेजे हुए सन्देश और कॉल्स शुरू से अंत तक एन्क्रिप्शन से सुरक्षित की जाती हैं. इसका मतलब WhatsApp और तीसरा पक्ष उन्हें पढ़ और सुन नहीं सकते.|Xabarlaringiz va qo‘ng‘iroqlaringiz boshidan oxirigacha shifrlash bilan himoyalanadi, ya’ni WhatsApp va uchinchi tomonlar ularni o‘qiy yoki tinglay olishmaydi.|Twoje wiadomości oraz połączenia są zabezpieczone przez pełne szyfrowanie, co oznacza, że WhatsApp ani osoby trzecie nie mogą ich odczytać.|Những tin nhắn và những cuộc gọi đã được bảo mật với mã hoá đầu-cuối, điều này có nghĩa WhatsApp hoặc bất cứ bên thứ ba nào sẽ không thể xem chúng.|Mesazhet dhe thirrjet tuaja janë të koduara fund-e-krye. Kjo do të thotë se ato nuk mund të lexohen apo të përgjohen nga WhatsApp dhe as nga palët e treta.|Dina meddelanden och samtal är säkrade med komplett kryptering, vilket betyder att WhatsApp och tredje part inte kan läsa eller lyssna på dem.|Vaša sporočila in klici so zavarovani s šifriranjem od konca do konca, kar pomeni, da jih WhatsApp in tretje osebe ne morejo videti oz. jih slišati.|Vaše správy a hovory sú zabezpečené šifrovaním počas celého spojenia. To znamená, že WhatsApp a tretie strany ich nemôžu čítať alebo počúvať.|آپ کے پیغامات اور کالس شروع سے آخر تک رمزکاری کے ذریعے محفوظ ہیں، جس کا یہ مطلب ہے کہ WhatsApp اور فریق ثالث انہیں پڑھ یا سن نہیں سکتے۔|Jumbe zako na simu unazopiga zipo salama kwa ufumbaji wa mwisho-kwa-mwisho, hii inamaanisha WhatsApp na watu wengine hawawezi kusoma wala kusikiliza.|Mesajlarınız artık uçtan uca şifreleme ile korunmaktadır, yani WhatsApp ve üçüncü parti uygulamalar mesajları okuyamaz veya dinleyemez.|தங்கள் தகவல்களும் அழைப்புகளும் முழு மறையாக்கத்துடன் பாதுகாக்கப்படுகிறது, அதாவது WhatsApp அல்லது வேறு எவராலும் படிக்கவோ, கேட்கவோ இயலாது.|ข้อความที่คุณส่งถึงแชทและการโทรนี้มีความปลอดภัยด้วยการเข้ารหัสจากต้นทางถึงปลายทาง ซึ่งหมายความว่า WhatsApp และบุคคลที่สามไม่สามารถอ่านและฟังได้|پیام ها و تماس های شما رمزگذاری سرتاسری شده اند، یعنی واتساپ و طرف های ثالث نمی توانند آنها را بخوانند یا به آنها گوش دهند.|Jūsų žinutės ir skambučiai yra apsaugoti ištisiniu šifravimu, o tai reiškia, kad WhatsApp ir trečios šalys negali jų perskaityti arba klausytis.|Dine meldinger og samtaler er sikret med kryptering fra ende til ende, som betyr at WhatsApp og andre tredjeparti ikke kan lese eller høre på dem.|Viestit ja puhelut salataan täysin, mikä tarkoittaa, että WhatsApp ja kolmannet osapuolet eivät voi lukea tai kuunnella niitä.|Vos messages et vos appels sont protégés avec le chiffrement de bout en bout. Cela signifie que WhatsApp et les tiers ne peuvent pas les voir ni les écouter.|Tus mensajes y llamadas ahora están protegidos con cifrado de extremo a extremo, lo que significa que ni WhatsApp ni terceros pueden leerlos ni escucharlos.|Sinu saadetavad sõnumid ja kõned on kaitstud otsast otsani krüpteerimisega, mis tähendab, et WhatsApp ja kolmandad osapooled ei saa neid lugeda, ega kuulata.|Vaši pozivi i poruke koje pošaljete šifrirane su end-to-end metodom, što znači da ih WhatsApp i treće strane nisu u mogućnosti preslušavati niti čitati.|A csevegéseid és hívásaid automatikusan titkosítottak a végpontok között, ami azt jelenti, hogy a WhatsApp és egyéb alkalmazások nem láthatják vagy hallgathatják meg azokat.|Uw oproepen en berichten zijn beveiligd met end-to-end encryptie. Dit houdt in dat WhatsApp en derde partijen ze niet lezen of beluisteren.|Съобщенията и обажданията ви са подсигурени с криптиране от край до край, това означава, че WhatsApp и трети страни не могат да ги прочетат или прослушат.|আপনার বার্তা এবং কল দুই দিক থেকে এনক্রিপশানের মাধ্যমে নিরাপদ, যার মানে হল WhatsApp এবং তৃতীয়পক্ষ এগুলো পড়তে বা শুনতে পারবে না।|Jou boodskappe en oproepe word beveilig met end-tot-end enkripsie wat beteken dat WhatsApp en derde partye dit nie kan lees of daarna luister nie.|Deine Nachrichten und Anrufe werden automatisch mit Ende-zu-Ende-Verschlüsselung geschützt, was bedeutet, dass weder WhatsApp noch Dritte sie lesen oder hören können.|Sizin göndərdiyiniz ismarıclar və zənglərinizin bir başdan digərinə qədər şifrələnir, bu da o deməkdir ki WhatsApp və üçüncü tərəflər bunu görməyəcəkdir.|메시지 및 전화는 암호화되어 안전합니다. WhatsApp 또는 제3자가 읽거나 들을 수 없습니다.|നിങ്ങളുടെ സന്ദേശങ്ങളും വിളികളും ആദ്യാവസാന എൻക്രിപ്ഷൻ വഴി സുരക്ഷിതമാണ്, എന്നതിനർത്ഥം WhatsApp നോ മറ്റു മൂന്നാം കക്ഷികൾക്കോ അവ വായിക്കാനോ കേൾക്കാനോ സാധ്യമല്ലെന്നാണ്.|Твоите пораки и повици се обезбедени со шифрирање крај-до-крај, што значи дека WhatsApp и трети лица не можат да ги читаат или слушаат.|ನಿಮ್ಮ ಸಂದೇಶಗಳು ಮತ್ತು ಕರೆಗಳು ಕೊನೆಯಿಂದ-ಕೊನೆವರೆಗೆ ಎನ್ಕ್ರಿಪ್ಷನ್ ನಿಂದ ಭದ್ರಪಡಿಸಲ್ಪಟ್ಟಿವೆ, ಅಂದರೆ WhatsApp ಮತ್ತು ಮೂರನೇ ವರ್ಗದವರು ಅವುಗಳನ್ನು ಓದಲು ಅಥವಾ ಕೇಳಲು ಸಾಧ್ಯವಿಲ್ಲ.|إن الرسائل التي ترسلها والمكالمات التي تجريها ضمن واتساب محمية من خلال التشفير التام بين الطرفين مما يعني أنّ واتساب أو أي طرف آخر لا يستطيع قراءة محتوى دردشاتك ولا التنصت على مكالماتك.|Quando é possível, as mensagens que enviar e as chamadas que efetuar são completamente encriptadas automaticamente, o que significa que não podem ser consultadas pelo WhatsApp, nem por terceiros.|Ваші повідомлення та дзвінки захищено наскрізним шифруванням - ані WhatsApp, ані треті сторони не можуть їх прочитати чи прослухати.|Твоје поруке и позиви су обезбеђени са шифровањем од почетка-до-краја, што значи да WhatsApp и треће стране не могу да их читају или слушају.|ਤੁਹਾਡੇ ਸੁਨੇਹੇ ਅਤੇ ਕਾਲਾਂ ਸਿਰੇ ਤੋਂ ਸਿਰੇ ਤੱਕ ਇੰਕ੍ਰਿਪਸ਼ਨ ਨਾਲ ਸੁਰੱਖਿਅਤ ਕੀਤਾ ਹੈ, ਜਿਸ ਦਾ ਅਰਥ ਹੈ ਕਿ WhatsApp ਤੇ ਤੀਜੀਆਂ ਧਿਰਾਂ ਉਹਨਾਂ ਨੂੰ ਪੜ੍ਹ ਜਾਂ ਸੁਣ ਨਹੀਂ ਸਕਦੀਆਂ ਹਨ।).?";
  static bool isEncryptedSystemMessage(String message) =>
      _hasMatch(message, encrypted);

  /// This message was deleted with Localizable key - `qBly]` on iOS and `revoked_msg_incoming` on Android
  static String deleted =
      r"^(This message was deleted|‏הודעה זו נמחקה|Данное сообщение удалено|Ce message a été supprimé|Questo messaggio è stato eliminato|Esta mensagem foi apagada|Se eliminó este mensaje|Αυτό το μήνυμα διαγράφηκε|Це повідомлення було видалено|Diese Nachricht wurde gelöscht|‏تم حذف هذه الرسالة|এই মেসেজটি বাদ দেওয়া হয়েছে।|此訊息已刪除。|这条消息已被删除。|Tin nhắn này đã bị xóa|‏یہ میسج حذف کر دیا گیا ہے۔|Bu mesaj silindi|ข้อความนี้ถูกลบแล้ว|Det här meddelandet raderades|Táto správa bola odstránená|Ta wiadomość została usunięta|Acest mesaj a fost șters|Mensagem apagada|Dit bericht is verwijderd|Denne meldingen ble slettet|Mesej ini telah dipadam|हा मेसेज हटवण्यात आला|이 메시지는 삭제되었습니다|このメッセージは削除されました。|Ez az üzenet törlésre került|Pesan ini dihapus|Ova je poruka izbrisana|यह मैसेज डिलीट कर दिया गया है|આ મેસેજ ડિલીટ કરાયો|Scriosadh an teachtaireacht seo|Tämä viesti poistettiin|‏این پیام حذف شده است|Denne besked er blevet slettet|Tato zpráva byla smazána|Aquest missatge s'ha suprimit|Acest mesaj a fost șters|Данное сообщение удалено|Itong mensahe ay binura na|此訊息已刪除。|Questo messaggio è stato eliminato|Aquest missatge està esborrat|Tato zpráva byla odstraněna|信息已删除|Pesan ini telah dihapus|このメッセージは削除されました|Αυτό το μήνυμα διαγράφηκε|Šī ziņa tika izdzēsta|Denne besked blev slettet.|हा संदेश हटविण्यात आला होता.|Бұл хат жойылды|આ સંદેશ રદ્દ કરાયો|הודעה זו נמחקה|Mesej ini telah dipadam|Esta mensagem foi apagada|यह संदेश मिटाया गया|Ushbu xabar o‘chirildi|Ta wiadomość została usunięta|Tin nhắn này đã bị xoá|Detta meddelande raderades|To sporočilo je bilo izbrisano|Táto správa bola odstránená|یہ پیغام حذف کیا گیا|Ujumbe huu ulifutwa|Bu mesaj silindi|இத்தகவல் திரும்பப்பெறப்பட்டது|ข้อความนี้ได้ถูกลบ|این پیام حذف شد|Ši žinutė buvo ištrinta|Denne meldingen ble slettet.|Tämä viesti poistettiin.|Ce message a été supprimé|Este mensaje fue eliminado|See sõnum on kustutatud|Ova poruka je izbrisana|Ez az üzenet törlésre került|Dit bericht is verwijderd|Съобщението беше изтрито|এই বার্তাটি মুছে ফেলা হয়েছে|Hierdie boodskap was uitgevee|Diese Nachricht wurde gelöscht|Bu ismarıc silindi|이 메시지는 삭제되었습니다|ഈ സന്ദേശം ഇല്ലാതാക്കിയതാണ്|Оваа порака беше избришана|ಈ ಸಂದೇಶವು ಅಳಿಸಲ್ಪಟ್ಟಿದೆ|تم حذف هذه الرسالة|Esta mensagem foi apagada pelo remetente.|Це повідомлення було видалено|Ова порука је обрисана|ਇਸ ਸੁਨੇਹੇ ਨੂੰ ਹਟਾਇਆ ਗਿਆ).?" +
          endOfLine;
  static bool isDeletedMessage(String message) => _hasMatch(message, deleted);

  /// You deleted this message with Localizable keys - `GHe7G` and `S?EA5` on iOS and `revoked_msg_outgoing` on Android
  static String youDeleted =
      r"^(You deleted this message|‏מחקת את ההודעה הזו|Вы удалили это сообщение|Вы удалили данное сообщение|Vous avez supprimé ce message|Hai eliminato questo messaggio|Apagou esta mensagem|Eliminaste este mensaje|Διαγράψατε αυτό το μήνυμα|Διαγράψατε το μήνυμα|Ви видалили це повідомлення|Du hast diese Nachricht gelöscht|‏لقد حذَفت هذه الرسالة|আপনি এই মেসেজটি বাদ দিয়েছেন|আপনি এই মেসেজটি বাদ দিয়েছেন।|您已刪除此訊息|您已刪除此訊息。|您已删除这条消息|您已删除这条消息。|Bạn đã xóa tin nhắn này|Bạn đã xoá tin nhắn này|‏آپ نے یہ میسج حذف کر دیا ہے|‏آپ نے یہ میسج حذف کر دیا ہے۔|Bu mesajı sildiniz|คุณได้ลบข้อความนี้|Du har tagit bort meddelandet|Du raderade det här meddelandet|Túto správu ste odstránili|Usunąłeś(-ęłaś) tę wiadomość|Ați șters acest mesaj|Mensagem apagada|U hebt dit bericht verwijderd|Du slettet denne meldingen|Anda telah memadamkan mesej ini|तुम्ही हा मेसेज हटवला|삭제한 메시지입니다|이 메시지를 삭제했습니다|このメッセージを削除しました|このメッセージを削除しました。|Ezt az üzenetet törölted|Törölted ezt az üzenetet|Anda menghapus pesan ini|Izbrisali ste ovu poruku|आपने यह मैसेज डिलीट किया|તમે આ મેસેજ ડિલીટ કર્યો|Scrios tú an teachtaireacht seo|Poistit tämän viestin|‏شما این پیام را حذف کردید|Du har slettet denne besked|Tuto zprávu jste smazal/a|Has suprimit aquest missatge|Ați șters acest mesaj|Вы удалили данное сообщение|Binura mo itong mensahe|您已刪除此訊息|Hai eliminato questo messaggio|Has esborrat aquest missatge|Tuto zprávu jste odstranil/a|您删除这个信息|Anda telah menghapus pesan ini|このメッセージを削除しました|Διαγράψατε αυτό το μήνυμα|Jūs izdzēsāt šo ziņu|Du slettede denne besked|आपण हा संदेश हटविलात.|Сіз бұл хатты жойдыңыз|તમે આ સંદેશને રદ્દ કર્યો|מחקת הודעה זו|Anda telah memadamkan mesej ini|Você apagou esta mensagem|आपने यह संदेश मिटाया|Siz ushbu xabarni o‘chirdingiz|Usunąłeś(aś) tę wiadomość|Bạn đã xoá tin nhắn này|Du raderade detta meddelande|To sporočilo ste izbrisali|Túto správu ste odstránili|آپ نے اس پیغام کو حذف کیا|Umefuta ujumbe huu|Bu mesajı sildiniz|இத்தகவலை தாங்கள் அழித்தீர்கள்|คุณลบข้อความนี้|شما این پیام را حذف کردید.|Jūs ištrynėte šią žinutę|Du slettet denne meldingen|Poistit tämän viestin|Vous avez supprimé ce message|Eliminaste este mensaje|Kustutasid selle sõnumi|Izbrisali ste ovu poruku|Törölted ezt az üzenetet|U hebt dit bericht verwijderd|Изтрихте това съобщение|আপনি এই বার্তাটি মুছে ফেলেছেন|Jy het boodskap uitgevee|Du hast diese Nachricht gelöscht|Siz bu ismarıcı sildiniz|삭제한 메시지입니다|ഈ സന്ദേശം നിങ്ങൾ ഇല്ലാതാക്കി|Ја избриша оваа порака|ನೀವು ಈ ಸಂದೇಶವನ್ನು ಅಳಿಸಿದ್ದೀರಿ|Esta mensagem foi apagada.|Ви видалили це повідомлення.|Обрисао/ла си ову поруку|ਤੁਸੀਂ ਇਹ ਸੁਨੇਹਾ ਹਟਾਇਆ|‏أنت حذفت هذه الرسالة).?" +
          endOfLine;
  static bool isDeletedByYouMessage(String message) =>
      _hasMatch(message, youDeleted);

  /// Your security code with ... changed combined from two keys `G)W)p` and `7<vSf`
  /// TODO: Android translations missed
  static String securityCodeChanged =
      r"\u200F?^\u200F?(Your security code with [^\n|\r|\r\n]+ changed.?\s?Tap to learn more|‏קוד האבטחה עם [^\n|\r|\r\n]+ שונה.?\s?‏יש להקיש לקבלת פרטים נוספים|Ваш код безопасности с контактом [^\n|\r|\r\n]+ изменился.?\s?Подробнее|Votre code de sécurité avec [^\n|\r|\r\n]+ a changé.?\s?Appuyez pour en savoir plus|Il tuo codice di sicurezza con [^\n|\r|\r\n]+ è cambiato.?\s?Tocca per saperne di più|O seu código de segurança partilhado com [^\n|\r|\r\n]+ mudou.?\s?Toque para saber mais|Cambió tu código de seguridad con [^\n|\r|\r\n]+.?\s?Pulsa para obtener más información|Ο κωδικός ασφαλείας σας με [^\n|\r|\r\n]+ άλλαξε.?\s?Πατήστε για να μάθετε περισσότερα|Код безпеки з контактом [^\n|\r|\r\n]+ змінився.?\s?Торкніться, щоб дізнатися більше|Deine Sicherheitsnummer für [^\n|\r|\r\n]+ hat sich geändert.?\s?Tippe, um mehr zu erfahren|‏تغيّر رمز أمانك المُستخدَم مع [^\n|\r|\r\n]+.?\s?‏انقر هنا لمعرفة المزيد|[^\n|\r|\r\n]+-এর সাথে আপনার নিরাপত্তা কোড পরিবর্তিত হয়েছে।.?\s?আরও জানতে ট্যাপ করুন।|您與[^\n|\r|\r\n]+之間的安全代碼已變更。.?\s?點按以瞭解詳情。|您與 [^\n|\r|\r\n]+ 的安全碼已變更。.?\s?點擊以了解更多。|您和 [^\n|\r|\r\n]+ 的安全代码已更改。.?\s?点击了解更多。|Mã bảo mật của bạn với [^\n|\r|\r\n]+ đã thay đổi.?\s?Nhấn để tìm hiểu thêm|‏[^\n|\r|\r\n]+ کے ساتھ آپ کا سیکیورٹی کوڈ تبدیل ہوگیا ہے۔.?\s?‏مزید جاننے کیلئے ٹیپ کریں۔|[^\n|\r|\r\n]+ ile aranızdaki güvenlik kodu değişti.?\s?Daha fazla bilgi edinmek için dokunun|รหัสความปลอดภัยของคุณกับ [^\n|\r|\r\n]+ มีการเปลี่ยนแปลง.?\s?แตะเพื่อเรียนรู้เพิ่มเติม|För att kontrollera en kontakts säkerhetskod öppnar du sidan för deras Kontaktinfo och trycker “[^\n|\r|\r\n]+”.?\s?Tryck för att läsa mer|Bezpečnostný kód, ktorý zdieľate s používateľom [^\n|\r|\r\n]+, bol zmenený.?\s?Klepnite pre viac informácií|Twój kod zabezpieczeń z użytkownikiem [^\n|\r|\r\n]+ zmienił się.?\s?Stuknij, aby dowiedzieć się więcej|Codul dvs. de securitate cu [^\n|\r|\r\n]+ s-a schimbat.?\s?Atingeți pentru a afla mai multe|Seu código de segurança com [^\n|\r|\r\n]+ mudou.?\s?Toque para saber mais|Uw beveiligingscode voor [^\n|\r|\r\n]+ is gewijzigd.?\s?Tik voor meer informatie|Sikkerhetskoden med [^\n|\r|\r\n]+ ble endret.?\s?Trykk for å lære mer|Kod keselamatan anda dengan [^\n|\r|\r\n]+ telah berubah.?\s?Ketik untuk mengetahui lebih lanjut|तुमचा [^\n|\r|\r\n]+ संबंधित सुरक्षा कोड बदलला आहे.?\s?अधिक जाणून घेण्यासाठी टॅप करा|[^\n|\r|\r\n]+님과의 보안 코드가 변경되었습니다.?\s?더 알아보려면 탭하세요|[^\n|\r|\r\n]+とのセキュリティコードが変更されました。.?\s?タップして詳細を表示。|[^\n|\r|\r\n]+ biztonsági kódja megváltozott.?\s?További információért koppints|Kode keamanan Anda dengan [^\n|\r|\r\n]+ telah berubah.?\s?Ketuk untuk info selengkapnya|Vaš sigurnosni kôd za kontakt [^\n|\r|\r\n]+ promijenio se.?\s?Dodirnite da biste saznali više|[^\n|\r|\r\n]+ के लिए आपका सुरक्षा कोड बदल गया है.?\s?ज़्यादा जानने के लिए टैप करें|[^\n|\r|\r\n]+ સાથેનો તમારો સુરક્ષા કોડ બદલાઈ ગયો.?\s?વધુ જાણવા માટે અહીં દબાવો|Athraíodh an cód slándála atá agat le [^\n|\r|\r\n]+.?\s?Tapáil le haghaidh tuilleadh faisnéise|Turvanumerosi muuttui henkilön [^\n|\r|\r\n]+ kanssa.?\s?Napauta saadaksesi lisätietoja|‏کد امنیتی شما با [^\n|\r|\r\n]+ تغییر کرد.?\s?‏برای کسب اطلاعات بیشتر، ضربه بزنید|Din sikkerhedskode for [^\n|\r|\r\n]+ har ændret sig.?\s?Tryk for at læse mere|Ο κωδικός ασφαλείας σας με [^\n|\r|\r\n]+ άλλαξε.?\s?Πατήστε για να μάθετε περισσότερα|Bezpečnostní kód mezi vámi a uživatelem [^\n|\r|\r\n]+ byl změněn.?\s?Další informace zobrazíte klepnutím|El teu codi de seguretat amb [^\n|\r|\r\n]+ ha canviat.?\s?Toca per obtenir més informació).?" +
          endOfLine;
  static bool isSecurityCodeChangedMessage(String message) =>
      _hasMatch(message, securityCodeChanged);

  /// Missed voice call with Localizable keys - `A),w\/` and `f\/]I7` on iOS and `missed_voice_call` on Android
  static String missedCall =
      r"^(Missed voice call|‏שיחה קולית שלא נענתה|Пропущенный аудиозвонок|Appel vocal manqué|Chiamata vocale persa|Chamada de voz perdida|Llamada perdida|Αναπάντητη φωνητική κλήση|Αναπάντητη βιντεοκλήση|Пропущений аудіодзвінок|Verpasster Sprachanruf|‏مكالمة صوتية فائتة|ভয়েস কল মিস করেছেন|未接語音通話|未接语音通话|Cuộc gọi nhỡ|‏مسڈ وائس کال|Cevapsız sesli arama|สายที่ไม่ได้รับ|Missat röstsamtal|Missat samtal|Zmeškaný hovor|Nieodebrane poł. głosowe|Nieodebrane poł|Apel vocal ratat|Gemist spraakgesprek|Tapt taleanrop|Panggila suara terlepas|Panggilan Suara Terlepas|मिस्ड व्हॉइस कॉल|부재중 전화|音声通話不在着信|Nem fogadott hanghívás|Panggilan suara tak terjawab|Tak Terjawab|Propušteni glasovni poziv|वॉइस कॉल मिस हुई|मिस्ड वॉइस कॉल|છૂટી ગયેલો વોઇસ કૉલ|છૂટેલો વોઇસ કૉલ|Guthghlao caillte|Glao Gutha Caillte|Vastaamaton äänipuhelu|‏تماس صوتی پاسخ داده نشده|Ubesvaret taleopkald|Trucada de veu perduda|Apel vocal nepreluat|మిస్సేడ్ వాయిస్ కాల్|Пропущенный аудиозвонок|Nakaligtaang voice call|未接語音通話|Chiamata vocale persa|Trucada de veu perduda|Zmeškaný hlasový hovor|未接语音通话|Panggilan suara tak terjawab|不在着信|Αναπάντητη κλήση|Neatbildēts balss zvans|Mistet opkald|मिस्ड व्हॉइस कॉल|Жауапсыз қоңырау|છૂટી ગયેલ ધ્વનિ કૉલ|שיחה קולית שלא נענתה|Panggilan suara terlepas|Chamada de voz perdida|छूटी हुई ध्वनि कॉल|O‘tkazib yub. ovozli qo‘ng‘iroq|Nieodebrane połączenie|Cuộc gọi nhỡ|Thirrje e shmangur|Missat röstsamtal|Zgrešen klic|چھوٹی ہوئی صوتی کال|Simu ya sauti uliyoikosa|Cevapsız sesli arama|தவறிய குரல் அழைப்பு|สายที่ไม่ได้รับ|تماس صوتی پاسخ داده نشده|Praleistas balso skambutis|Tapt taleanrop|Vastaamaton äänipuhelu|Appel vocal manqué|Llamada de voz perdida|Vastamata häälkõne|Propušten glasovni poziv|Nem fogadott hanghívás|Gemiste spraakoproep|Пропуснато гласово обаждане|মিসড ভয়েস কল|Stemoproep gemis|Verpasster Sprachanruf|Buraxılmış zəng|부재중 전화|വിളി നഷ്ടപ്പെട്ടു|Пропуштен гласовен повик|ತಪ್ಪಿದ ಧ್ವನಿ ಕರೆ|مكالمة صوتية فائتة|Пропущений аудіодзвінок|Пропуштен гласовни позив|ਮਿਸ ਹੋਈ ਆਵਾਜ਼ ਕਾਲ).?" +
          endOfLine;
  static bool isMissedCallMessage(String message) =>
      _hasMatch(message, missedCall);

  /// Missed video call with Localizable keys - "PnA`x" on iOS and "video_missed_call" on Android
  static String missedVideoCall =
      r"^(Missed video call|‏שיחת וידאו שלא נענתה|Пропущенный видеозвонок|Appel vidéo manqué|Videochiamata persa|Videochamada perdida|Videollamada perdida|Αναπάντητη βιντεοκλήση|Пропущений відеодзвінок|Verpasster Videoanruf|‏مكالمة فيديو فائتة|ভিডিও কল মিস করেছেন|未接視像通話|未接视频通话|Cuộc gọi nhỡ video|‏مسڈ ویڈیو کال|Cevapsız görüntülü arama|วิดีโอคอลที่ไม่ได้รับ|Missat videosamtal|Zmeškaný videohovor|Nieodebrane poł. wideo|Apel video ratat|Chamada de vídeo perdida|Gemist videogesprek|Tapt videoanrop|Panggilan video terlepas|मिस्ड व्हिडिओ कॉल|부재중 영상통화|ビデオ通話不在着信|Nem fogadott videohívás|Panggilan video tak terjawab|Propušteni videopoziv|मिस्ड वीडियो कॉल|છૂટી ગયેલ વિડિયો કૉલ|Físghlao caillte|Vastaamaton videopuhelu|‏تماس تصویری بی‌پاسخ|Ubesvaret videoopkald|Videotrucada perduda|Apel video nepreluat|తప్పిన వీడియోకాల్|Пропущенный видеозвонок|Nakaligtaang video call|未接視像通話|Videochiamata persa|Trucada de vídeo perduda|Zmeškaný videohovor|未接视频通话|Panggilan video tak terjawab|ビデオ通話不在着信|Αναπάντητη βιντεοκλήση|Neatbildēts video zvans|Mistede video opkald|मिस्ड व्हिडिओ कॉल|Жауапсыз видео қоңырау|છૂટી ગયેલ વિડિઓ કૉલ|שיחת וידאו שלא נענתה|Panggilan video terlepas|Chamada de vídeo perdida|छूटी हुई विडियो कॉल|O‘tkazib yub. videoqo‘ng‘iroq|Nieodebrane poł. wideo|Cuộc gọi nhỡ video|Videothirrje e shmangur|Missat videosamtal|Neodgovorjen video klic|چھوٹی ہوئی ویڈیو کال|Simu ya video uliyoikosa|Cevapsız görüntülü arama|தவறிய காணொலி அழைப்பு|สายโทรวิดีโอที่ไม่ได้รับ|تماس تصویری پاسخ داده نشده|Praleistas video skambutis|Tapt videosamtale|Vastaamaton videopuhelu|Appel vidéo manqué|Videollamada perdida|Vastamata videokõne|Propušten video poziv|Nem fogadott videóhívás|Gemiste video-oproep|Пропуснато видео обаждане|মিস করা ভিডিও কল|Video-oproep gemis|Verpasster Videoanruf|Buraxılmış video zəng|부재중 영상통화|നഷ്ടമായ വീഡിയോ കാൾ|Пропуштен видео повик|ತಪ್ಪಿದ ದೃಶ್ಯ ಕರೆ|مكالمة فيديو فائتة|Videochamada perdida|Пропущений відеодзвінок|Пропуштен видео позив|ਮਿਸ ਹੋਈ ਵੀਡੀਓ ਕਾਲ).?" +
          endOfLine;
  static bool isMissedVideoCallMessage(String message) =>
      _hasMatch(message, missedVideoCall);

  /// Localizable.strings JSON key: `n*sq0`
  static String imageOmitted =
      r"^\<?(image omitted|‏התמונה הושמטה|изображение отсутствует|image absente|immagine omessa|imagem não revelada|imagen omitida|εικόνα παραλείφθηκε|зображення відсутнє|Bild weggelassen|‏لم يتم إدراج الصورة|ইমেজ বাদ দেওয়া হয়েছে|圖片已略去|圖像已省略|照片已忽略|đã bỏ qua hình ảnh|‏تصویر نکال دی گئی ہے|görüntü dahil edilmedi|ไม่มีรูปภาพ|bild utesluten|obrázok vynechaný|obraz pominięty|Imagine omisă|imagem ocultada|afbeelding weggelaten|bilde ikke inkludert|imej tidak dimasukkan|इमेज वगळली|이미지 생략됨|画像は含まれていません|kép küldése sikertelen|gambar tidak disertakan|slika izostavljena|फ़ोटो हटाई गई|છબી પડતી મૂકાઈ|íomhá ligthe ar lár|ei kuvaa|‏تصویر حذف شد|billede udeladt|obrázek vynechán|Imatge omesa|\s?‏لم يتم إدراج الصورة).?\>?" +
          endOfLine;
  static bool isImageOmittedMessage(String message) =>
      _hasMatch(message, imageOmitted);

  /// Localizable.strings JSON key: `I4|vp`
  static String videoOmitted =
      r"^\<?(video omitted|‏סרטון הווידאו הושמט|видео отсутствует|vidéo absente|video omesso|vídeo não revelado|Video omitido|βίντεο παραλείφθηκε|відео відсутнє|Video weggelassen|‏لم يتم إدراج الفيديوهات|ভিডিও বাদ দেওয়া হয়েছে|影片已略去|影片已省略|视频已忽略|đã bỏ video|‏ویڈیو نظرانداز|video dahil edilmedi|วิดีโอถูกลบ|video utesluten|video vynechané|wideo pominięte|clip video omis|vídeo omitido|video weggelaten|video utelatt|video tidak dimasukkan|व्हिडीओ वगळला|비디오 생략됨|ビデオは含まれていません|Videó kihagyva|video tidak disertakan|video izostavljen|वीडियो छोड़ा गया|વિડિયો પડતી મુકાઈ|físeán ligthe ar lár|videota ei sisällytetä|‏ویدیو حذف شد|video udeladt|video vynecháno|vídeo omès).?\>?" +
          endOfLine;
  static bool isVideoOmittedMessage(String message) =>
      _hasMatch(message, videoOmitted);

  /// Localizable.strings JSON key: `a86Wu`
  static String audioOmitted =
      r"^\<?(audio omitted|‏קטע קול הושמט|аудиофайл отсутствует|audio omis|audio omesso|ficheiro de áudio não revelado|audio omitido|ήχος παραλείφθηκε|аудіо відсутнє|Audio weggelassen|‏لم يتم إدراج المقاطع الصوتية|অডিও বাদ দেওয়া হয়েছে|音訊已略去|音訊已省略|音频已忽略|bỏ qua tệp âm thanh|‏آڈیو نظرانداز|ses dahil edilmedi|ไม่มีไฟล์เสียง|ljud utelslutet|zvuk vynechaný|audio pominięte|fără audio|áudio ocultado|audio weggelaten|lyd utelatt|audio tidak dimasukkan|ऑडिओ वगळला|오디오 생략됨|音声は含まれていません|Hang kihagyása|audio tidak disertakan|zvuk izostavljen|ऑडियो हटाई गयी|ઓડિયો ફાઇલ શામેલ કરી નથી|comhad fuaime ar lár|äänitiedostoa ei sisällytetä|‏صدا حذف شد|lyd udeladt|zvukový soubor vynechán|Àudio omès).?\>?" +
          endOfLine;
  static bool isAudioOmittedMessage(String message) =>
      _hasMatch(message, audioOmitted);

  /// Localizable.strings JSON key: `2K_mB`
  static String stickerOmitted =
      r"^\<?(sticker omitted|‏סטיקר הושמט|стикер не добавлен|sticker omis|sticker non incluso|sticker não revelado|sticker omitido|αυτοκόλλητο παραλήφθηκε|Наклейку не додано|Sticker weggelassen|‏تم حذف الملصقات|স্টিকার বাদ দেওয়া হয়েছে|貼圖已略去|貼圖已忽略|贴图已省略|đã bỏ sticker|‏اسٹیکر نظرانداز|Çıkartma dahil edilmedi|ไม่มีสติกเกอร์|sticker utesluten|nálepka vynechaná|pominięto naklejkę|figurinha omitida|sticker weggelaten|klistremerke utelatt|pelekat tidak disertakan|स्टिकर वगळले|스티커 제외됨|スタンプは含まれていません|matrica kihagyva|stiker tidak disertakan|naljepnica izostavljena|स्टिकर छोड़ा गया|સ્ટીકર પડતું મુકાયું|fágadh an greamán ar lár|tarraa ei sisällytetty|‏استیکر حذف شد|klistermærke udeladt|nálepka vynechána|adhesiu omès).?\>?" +
          endOfLine;
  static bool isStickerOmittedMessage(String message) =>
      _hasMatch(message, stickerOmitted);

  /// Localizable.strings JSON key: `~.KLq`
  static String gifOmitted =
      r"^\<?(GIF omitted|‏GIF הושמט|GIF отсутствует|GIF retiré|GIF esclusa|GIF não revelada|GIF omitido|Παράληψη GIF|GIF-анімацію пропущено|GIF weggelassen|‏لم يتم إدراج صورة GIF|জিআইএফ বাদ দেওয়া হয়েছে|GIF 已略去|GIF 圖片已被省略|GIF 动态图已被忽略|Đã bỏ qua ảnh GIF|‏GIF  نظرانداز|GIF dahil edilmedi|ละเว้น GIF|GIF utesluten|GIF vynechaný|Plik GIF pominięty|GIF omis|GIF weggelaten|GIF utelatt|GIF tidak dimasukkan|GIF वगळले|GIF 생략됨|GIFは含まれていません|GIF fájl kihagyása|GIF tidak disertakan|GIF izostavljen|GIF छोड़ा गया|GIF પડતી મૂકાઈ|GIF ligthe ar lár|GIF-animaatio jätetty pois|‏GIF حذف شد|GIF udeladt|GIF vynechán|GIF omès).?\>?" +
          endOfLine;
  static bool isGIFOmittedMessage(String message) =>
      _hasMatch(message, gifOmitted);

  /// Localizable.strings JSON key: `Sk+0p`
  static String contactCardOmitted =
      r"^\<?(Contact card omitted|‏כרטיס איש קשר הושמט|Карточка контакта отсутствует|Fiche contact manquante|Scheda contatto omessa|Contacto não revelado|Tarjeta de contacto omitida|Η κάρτα επαφής παραλήφθηκε|Картка контакту відсутня|Kontaktkarte ausgelassen|‏لم يتم إدراج بطاقة جهة اتصال|পরিচিতির কার্ড বাদ দেওয়া হয়েছে|聯絡人卡片已略去|聯絡人卡片已省略|联系人卡片已忽略|Bỏ qua thẻ liên lạc|‏رابطہ کارڈ نظر انداز|Kişi kartı dahil edilmedi|บัตรรายชื่อที่ละเว้น|Kontaktkort uteslutet|Karta kontaktu vynechaná|Pominięta wizytówka kontaktu|Carte de vizită contact omisă|Cartão do contato omitido|Visitekaartje weggelaten|Kontaktkort sløyfet|Kad kenalan tidak dimasukkan|संपर्क कार्ड वगळले|연락처 카드 생략됨|連絡先カードを省略|Névjegykártya kihagyva|Kartu kontak tidak disertakan|Posjetnica izostavljena|कॉन्टैक्ट कार्ड छोड़ा गया|સંપર્કનું કાર્ડ પડતું મૂકાયું|Cárta teagmhála ar lár|Yhteystietokortti jätettiin pois|‏برگ مخاطب حذف شد|Kontaktkort udeladt|Vizitka vynechána|Targeta de contacte omesa).?\>?" +
          endOfLine;
  static bool isContactCardOmittedMessage(String message) =>
      _hasMatch(message, contactCardOmitted);

  /// Localizable.strings JSON key: `StaLC`
  /// document omitted may appear after the file name
  static String documentOmitted =
      r"(^|\s)\<?(document omitted|‏מסמך הושמט|документ отсутствует|document manquant|documento omesso|documento não revelado|documento omitido|έγγραφο παραλείφθηκε|документ пропущено|Dokument weggelassen|‏لم يتم إدراج المستند|ডকুমেন্ট বাদ দেওয়া হয়েছে|文件已略去|文件已忽略|文档已省略|đã bỏ qua tài liệu|‏دستاویز نظرانداز|belge dahil edilmedi|ละเว้นเอกสาร|dokument uteslutet|dokument vynechaný|dokument pominięty|document omis|document weggelaten|utelatt dokument|dokumen tidak dimasukkan|डॉक्युमेंट वगळले|문서 생략됨|ドキュメントは含まれていません|dokumentum kihagyva|dokumen tidak disertakan|dokument izostavljen|डॉक्यूमेंट छोड़ा गया|ડોક્યુમેન્ટ સામેલ કર્યું નહિ|cáipéis ligthe ar lár|dokumenttia ei sisällytetä|‏سند حذف شد|dokument udeladt|dokument vynechán|Document omès).?\>?" +
          endOfLine;
  static bool isDocumentOmittedMessage(String message) =>
      _hasMatch(message, documentOmitted);

  /// Android-only media ommited message
  /// strings.xml key is `export_media_omitted`
  /// Media caption placed on new line
  static String mediaOmitted =
      r"^\<\s?(Media omitted|Conținut media omis|మాధ్యమం విస్మరించబడింది|Файл пропущен|Без медиафайлов|Walang kalakip na media|忽略多媒體檔|Media omesso|Mitjans omesos|Média vynechána|Média vynechány|省略多媒体文件|Media tidak disertakan|メディアは含まれていません|Εξαίρεση πολυμέσων|Bez multivides|Mediefil udeladt|मीडिया वगळले|Файл қосылған жоқ|મીડિયા અવગણાયું|מדיה הושמטה|Media disingkirkan|忽略多媒體檔|Mídia omitida|मीडिया के बिना|Fayl o‘tkazib yuborildi|pliki pominięto|Bỏ qua Media|Pa media|Media har utelämnats|Medij izpuščen|Médiá vynechané|میڈیا چھوڑ دیا گیا|Media imerukwa|Medya atlanmış| ஊடகங்கள் நீக்கப்பட்டது |สื่อถูกลบ| پيوست نما/آهنگ حذف شد |Praleistas medijos turinys|Uten vedlegg|מדיה הושמטה|Media jätetty pois|Media tidak disertakan|Fichier omis|Archivo omitido|Meedia ära jäetud|Medijski zapis izostavljen|Hiányzó médiafájl|Media weggelaten|Без файл|মিডিয়া বাদ দেওয়া হয়েছে|Media weggelaat|Medien weggelassen|Media çıxarılmışdır|미디어 파일을 생략한 대화내용|മീഡിയ ഒഴിവാക്കി|Без фајл|ಮೀಡಿಯಾ ಕೈಬಿಡಲಾಗಿದೆ|تم استبعاد الوسائط|Ficheiro não revelado|Медіа пропущено|медији су изостављени|ਮੀਡੀਆ ਛੱਡਿਆ ਗਿਆ|省略多媒体文件|‏מדיה הושמט|Медиа отсутствует|Médias absente|Ficheiros e ligações revelado|Archivos omitido|Αρχεία παραλείφθηκε|Медіафайли відсутнє|‏الوسائط والروابط والمستندات الفيديوهات|মিডিয়া হয়েছে|媒體、連結和文件 影片已略去|媒体、链接和文件 影片已省略|Tệp phương tiện 视频已忽略|‏میڈیا، لنکس، اور دستاویزات video|Medya نظرانداز|สื่อ ลิงก์ และเอกสาร edilmedi|Media วิดีโอถูกลบ|Médiá utesluten|Multimedia vynechané|Media pominięte|Mídia omis|Media omitido|Medier weggelaten|Media utelatt|मीडिया फाइल्स dimasukkan|미디어 वगळला|メディア、リンク、ドキュメント 생략됨|Média ビデオは含まれていません|Media kihagyva.|Medijski zapisi disertakan|मीडिया izostavljen|મીડિયા गया|Meáin મુકાઈ|Mediat lár|‏رسانه‌ها، پیوندها و اسناد sisällytetä|Medier شد|Média udeladt|Contingut multimèdia vynecháno|המדיה הוסרה|המדיה לא נכללה|Média manquante|Media mancante|Αποχρεωτική παραλαβή μέσων|Медіа відсутня|Medien fehlen|ملفات مفقودة)\s?\>" +
          endOfLine;
  static bool isMediaOmittedMessage(String message) =>
      _hasMatch(message, mediaOmitted);

  /// Android-only live location shared system messsage
  /// strings.xml key - `email_live_location_message`
  static String liveLocation =
      r"^(live location shared|locație în timp real distribuită|ప్రత్యక్ష స్థాన భాగస్వామ్యం|Геоданные отправлены|ibinahagi ang live na lokasyon|實時位置已分享|posizione attuale condivisa|Ubicació en directe compartida|byla sdílena aktuální poloha|共享实时位置|Lokasi terkini dibagikan|ライブロケーション共有|η τωρινή τοποθεσία κοινοποιήθηκε|reāllaika atrašanās vieta|live placering delt|सध्याचे थेट ठिकाण शेअर केले|қазіргі орынмен бөлісті|જીવંત સ્થાન શેર કરાયું|משתף מיקום בשידור חי|lokasi terkini dikongsi|實時位置已分享|localização atual compartilhada|लाइव स्थान साझा किया गया|jonli joylashuv ulashildi|udostępniona transmisja położenia|vị trí hiện thời được chia sẻ|vendnodhja aktuale u shpërnda|liveposition delad|lokacija v živo je bila deljena|bola zdieľaná aktuálna poloha|جاری مقام کا اشتراک ہوا|mahali mubashara pameshirikishwa|Mevcut konum paylaşıldı|இடம் நேரலையாக பகிரபட்டது|ตำแหน่งปัจจุบันถูกแบ่งปัน|مکان زنده به اشتراک گذاشته شد|tiesioginė vieta bendrinama|posisjon i sanntid delt|משתף מיקום בשידור חי|live-sijainti jaettu|Lokasi terkini dibagikan|Localisation en direct partagée|ubicación en tiempo real compartida|hetke asukoht jagatud|trenutna lokacija podijeljena|tartózkodási hely megosztva|live locatie gedeeld|местоположение в реално време споделено|লাইভ অবস্থান শেয়ার করা হয়েছে|regstreekse ligging gedeel|Live-Standort wird geteilt|canlı məkan paylaşılıb|공유한 실시간 위치|ലൈവ് ലൊക്കേഷൻ പങ്കിട്ടു|споделено локација во живо|ನೇರ ಸ್ಥಳ ಹಂಚಿಕೊಳ್ಳಲಾಗಿದೆ|تمت مشاركة الموقع المباشر|Está a partilhar a sua localização|геодані надіслано|Локација уживо подељена|ਮੌਜੂਦਾ ਟਿਕਾਣਾ ਸਾਂਝਾ ਕੀਤਾ|共享实时位置)" +
          endOfLine;
  static bool isDocumentLiveLocationMessage(String message) =>
      _hasMatch(message, liveLocation);

  /// Null message on Android
  /// Appear for deleted View-one-time photo (not sure) - `null`
  /// Example: 27/03/2022, 21:51 - Dmitry S: null
  /// May have false positives for "null" text message
  static String nullMessage = r"^null" + endOfLine;
  static bool isNullMessage(String message) =>
      _hasMatch(message, nullMessage, caseSensitive: true);

  /// Group System Messages (Android messages variants may be missing)
  /// Those messages caught by our main system message pattern as they have no sender
  ///
  /// Group created
  /// "epN1D": "‎Group creator created group “%@”"
  /// "aD=R{": "‎%1$@ created group “%2$@”"
  /// "(K2R*": "‎You created group “%@”"
  ///
  /// You joined using invite link
  /// ")H04Q": "‎You joined using this group's invite link"
  ///
  /// User joined using invite link
  /// "2vBON": "‎%@ joined using this group's invite link"
  ///
  /// User added you to group
  /// "VN:JW": "‎%1$@ added you"
  /// "L0?X-": "‎%@ added you"
  ///
  /// You promoted to admin
  /// "yuV:O": "‎You're now an admin"
  ///
  /// Removed from group - %@ name may have whitespaces (!)
  /// "Ys<&L": "‎%@ removed you"
  /// "clKkp": "‎You removed %@"
  ///
  /// Group's settings changes
  /// "Or&p|": "‎You changed this group's settings to allow only admins to edit this group's info"
  /// "VC.,_": "‎%1$@ changed this group's settings to allow only admins to edit this group's info"
  ///
  /// "Ft?s_": "‎%1$@ changed this group's settings to allow only admins to send messages to this group"
  /// "FCtvm": "‎You changed this group's settings to allow only admins to send messages to this group"
  ///
  /// Group subject
  /// ")(=-_": "‎You changed the subject to “%@”"
  /// "o18be": "‎%1$@ changed the subject to “%2$@”"
  /// "Kt-&~": "‎A participant changed the subject to “%@”"
  ///
  /// Message deletiontimer
  /// "u'[LH": "‎You updated the message timer."
  /// "jm_F}": "‎%@ updated the message timer."
  ///
  /// Disappearing messages - ON
  /// "&Pn,j@=": "‎%1$@ turned on disappearing messages. All new messages will disappear from this chat %2$u hours after they’re sent. Click to change"
  /// "YN*rr@=": "‎%1$@ turned on disappearing messages. All new messages will disappear from this chat %2$u seconds after they’re sent. Click to change"
  /// "&Pn,j!=": "‎%1$@ turned on disappearing messages. All new messages will disappear from this chat %2$u hour after they’re sent. Click to change"
  /// "Q+35z!": "‎%1$@ turned on disappearing messages. All new messages will disappear from this chat %2$u minute after they’re sent. Tap to change"
  /// "Y-tFj": "‎You turned on disappearing messages." ???
  /// "Z<_pb!": "‎You turned on disappearing messages. All new messages will disappear from this chat %u second after they’re sent."
  /// "s_}5S@": "‎You turned on disappearing messages. All new messages will disappear from this chat %u hours after they’re sent."
  ///
  /// Disappearing messages - OFF
  /// "&V})g=": "‎%@ turned off disappearing messages. Click to change"
  /// "&V})g": "‎%@ turned off disappearing messages. Tap to change"
  /// "q9q)]": "‎%@ turned off disappearing messages."
  /// "B8::;": "‎%@ turned off disappearing messages."
  /// "5nQ'1=": "‎You turned off disappearing messages. Click to change"
  /// "5nQ'1": "‎You turned off disappearing messages. Tap to change"
  /// "4:+Uq": "‎You turned off disappearing messages."
  /// "lYXkI":" ‎You turned off disappearing messages."
  ///
  /// Group description
  /// "5wa(v": "‎%1$@ changed the group description"
  /// "gsc-f": "‎A participant changed the group description. Tap to view."
  /// "YSguP=": "‎You changed the group description. Click to view."
  ///
  /// Group icon
  /// "D>1ci": "‎%@ changed this group's icon"
  /// "p6IFz": "‎You changed this group's icon"
  ///
  /// Deleted message
  /// "zD*5p": "‎This message was deleted by an admin."
  /// "SUYSe": "‎This message was deleted by admin %@."
  /// "W*,Ww": "‎You deleted this message as admin"
  ///
  /// Admin approval
  /// ")zIkT": "‎%1$@ turned off admin approval to join this group"
  /// "hvwR+": "‎%1$@ turned on admin approval to join this group. Tap to change."
  ///
  /// Username left
  /// Username1 changed to Username2
  ///
  /// +40 002 50 30 changed their phone number to a new number. ‎Tap to message or add the new number.

  /// Run regex processing and return `true` if any match found, otherwise `false`
  static bool _hasMatch(String text, String pattern,
      {bool caseSensitive = false}) {
    final regex =
        RegExp(pattern, caseSensitive: caseSensitive); // unicode: true
    final match = regex.firstMatch(text);
    return match != null;
  }

  /// Check if message text contains system message like `image omitted` or `This message was deleted`
  static bool isSystemMessageText(String message) {
    return WhatsAppPatterns.isEncryptedSystemMessage(message) ||
        WhatsAppPatterns.isDeletedMessage(message) ||
        WhatsAppPatterns.isDeletedByYouMessage(message) ||
        WhatsAppPatterns.isSecurityCodeChangedMessage(message) ||
        WhatsAppPatterns.isMissedCallMessage(message) ||
        WhatsAppPatterns.isMissedVideoCallMessage(message) ||
        WhatsAppPatterns.isImageOmittedMessage(message) ||
        WhatsAppPatterns.isVideoOmittedMessage(message) ||
        WhatsAppPatterns.isAudioOmittedMessage(message) ||
        WhatsAppPatterns.isStickerOmittedMessage(message) ||
        WhatsAppPatterns.isGIFOmittedMessage(message) ||
        WhatsAppPatterns.isDocumentOmittedMessage(message) ||
        WhatsAppPatterns.isMediaOmittedMessage(message) ||
        WhatsAppPatterns.isContactCardOmittedMessage(message) ||
        WhatsAppPatterns.isDocumentLiveLocationMessage(message) ||
        WhatsAppPatterns.isNullMessage(message);
  }
}
