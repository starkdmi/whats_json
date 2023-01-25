/// Convert WhatsApp export messages to JSON format
///
/// Supports Android and iOS
library whats_json;

export 'src/message_parser.dart' show whatsAppGetMessages, WhatsAppPatterns;
export 'src/helpers/logger.dart' show ParserLogger, SimpleLogger;
