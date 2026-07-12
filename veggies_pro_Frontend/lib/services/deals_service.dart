import '../core/dio_client.dart';
import '../models/deal.dart';

class DealsService {
  static Future<({List<Deal> deals, DateTime dealEndsAt})> fetchTodaysDeals() async {
    final response = await DioClient().dio.get('/deals/today');

    if (response.statusCode == 200 && response.data['success'] == true) {
      final List<dynamic> raw = response.data['data'];
      final deals = raw.map((json) => Deal.fromJson(json)).toList();

      final dealEndsAt = DateTime.parse(response.data['dealEndsAt']).toLocal();
      return (deals: deals, dealEndsAt: dealEndsAt);
    }

    throw Exception('Failed to fetch today\'s deals');
  }
}
