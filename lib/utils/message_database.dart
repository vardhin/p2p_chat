import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:p2p_chat/models/message.dart';

class MessageDatabase {
  static final MessageDatabase _instance = MessageDatabase._internal();
  factory MessageDatabase() => _instance;
  MessageDatabase._internal();

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'messages.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: (Database db, int version) async {
        await db.execute('''
          CREATE TABLE messages (
            id TEXT PRIMARY KEY,
            conversation_id TEXT NOT NULL,
            sender_id TEXT NOT NULL,
            sender_name TEXT NOT NULL,
            content TEXT NOT NULL,
            timestamp TEXT NOT NULL,
            is_read INTEGER NOT NULL DEFAULT 0,
            status TEXT NOT NULL DEFAULT 'sent'
          )
        ''');
        await db.execute('''
          CREATE INDEX idx_conversation ON messages(conversation_id)
        ''');
        await db.execute('''
          CREATE INDEX idx_timestamp ON messages(timestamp)
        ''');
      },
    );
  }

  /// Insert a new message
  Future<void> insertMessage(ChatMessage message) async {
    final db = await database;
    await db.insert(
      'messages',
      message.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Get all messages for a conversation
  Future<List<ChatMessage>> getConversationMessages(String conversationId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'messages',
      where: 'conversation_id = ?',
      whereArgs: [conversationId],
      orderBy: 'timestamp DESC',
    );

    return List.generate(maps.length, (i) => ChatMessage.fromJson(maps[i]));
  }

  /// Get paginated messages for a conversation
  Future<List<ChatMessage>> getConversationMessagesPaginated(
    String conversationId,
    int limit,
    int offset,
  ) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'messages',
      where: 'conversation_id = ?',
      whereArgs: [conversationId],
      orderBy: 'timestamp DESC',
      limit: limit,
      offset: offset,
    );

    return List.generate(maps.length, (i) => ChatMessage.fromJson(maps[i]));
  }

  /// Update message status
  Future<void> updateMessageStatus(String messageId, MessageStatus status) async {
    final db = await database;
    await db.update(
      'messages',
      {'status': status.toString()},
      where: 'id = ?',
      whereArgs: [messageId],
    );
  }

  /// Mark message as read
  Future<void> markAsRead(String messageId) async {
    final db = await database;
    await db.update(
      'messages',
      {'is_read': 1},
      where: 'id = ?',
      whereArgs: [messageId],
    );
  }

  /// Mark all messages in conversation as read
  Future<void> markConversationAsRead(String conversationId) async {
    final db = await database;
    await db.update(
      'messages',
      {'is_read': 1},
      where: 'conversation_id = ?',
      whereArgs: [conversationId],
    );
  }

  /// Get unread message count for a conversation
  Future<int> getUnreadCount(String conversationId) async {
    final db = await database;
    final List<Map<String, dynamic>> result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM messages WHERE conversation_id = ? AND is_read = 0',
      [conversationId],
    );
    return result.first['count'] as int;
  }

  /// Delete a message
  Future<void> deleteMessage(String messageId) async {
    final db = await database;
    await db.delete(
      'messages',
      where: 'id = ?',
      whereArgs: [messageId],
    );
  }

  /// Delete all messages for a conversation
  Future<void> deleteConversation(String conversationId) async {
    final db = await database;
    await db.delete(
      'messages',
      where: 'conversation_id = ?',
      whereArgs: [conversationId],
    );
  }

  /// Clear all messages
  Future<void> clearAll() async {
    final db = await database;
    await db.delete('messages');
  }

  /// Get message count for a conversation
  Future<int> getMessageCount(String conversationId) async {
    final db = await database;
    final List<Map<String, dynamic>> result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM messages WHERE conversation_id = ?',
      [conversationId],
    );
    return result.first['count'] as int;
  }

  /// Get latest message for a conversation
  Future<ChatMessage?> getLatestMessage(String conversationId) async {
    final db = await database;
    final List<Map<String, dynamic>> result = await db.query(
      'messages',
      where: 'conversation_id = ?',
      whereArgs: [conversationId],
      orderBy: 'timestamp DESC',
      limit: 1,
    );

    if (result.isEmpty) return null;
    return ChatMessage.fromJson(result.first);
  }
}
