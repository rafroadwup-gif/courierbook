import '../models/booking.dart';
import '../services/supabase_service.dart';

class BookingRepository {
  static const String _tableName = 'bookings';
  final _supabase = SupabaseService.instance;

  // Save booking to Supabase
  Future<void> saveBooking(Booking booking) async {
    try {
      final client = _supabase.client;
      await client
          .from(_tableName)
          .insert(booking.toMap())
          .then((_) {
        debugPrint('✓ Booking saved: ${booking.id}');
      });
    } catch (e) {
      debugPrint('✗ Error saving booking: $e');
      rethrow;
    }
  }

  // Get all bookings from Supabase
  Future<List<Booking>> getAllBookings() async {
    try {
      final client = _supabase.client;
      final response = await client
          .from(_tableName)
          .select()
          .order('createdAt', ascending: false);

      final List<Booking> bookings = [];
      for (final item in response as List) {
        bookings.add(Booking.fromMap(item as Map<String, dynamic>));
      }
      debugPrint('✓ Loaded ${bookings.length} bookings');
      return bookings;
    } catch (e) {
      debugPrint('✗ Error loading bookings: $e');
      return [];
    }
  }

  // Get booking by ID
  Future<Booking?> getBookingById(String id) async {
    try {
      final client = _supabase.client;
      final response = await client
          .from(_tableName)
          .select()
          .eq('id', id)
          .single();

      return Booking.fromMap(response as Map<String, dynamic>);
    } catch (e) {
      debugPrint('✗ Error fetching booking: $e');
      return null;
    }
  }

  // Update booking
  Future<void> updateBooking(Booking booking) async {
    try {
      final client = _supabase.client;
      await client
          .from(_tableName)
          .update(booking.toMap())
          .eq('id', booking.id);
      debugPrint('✓ Booking updated: ${booking.id}');
    } catch (e) {
      debugPrint('✗ Error updating booking: $e');
      rethrow;
    }
  }

  // Delete booking
  Future<void> deleteBooking(String id) async {
    try {
      final client = _supabase.client;
      await client.from(_tableName).delete().eq('id', id);
      debugPrint('✓ Booking deleted: $id');
    } catch (e) {
      debugPrint('✗ Error deleting booking: $e');
      rethrow;
    }
  }
}
