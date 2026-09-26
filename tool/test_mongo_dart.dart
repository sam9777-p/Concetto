import 'package:mongo_dart/mongo_dart.dart';

void main() async {
  const uri = 'mongodb://concettoapp:lS6Wa1mjNF_nZZNzcCuI1cdwDNiITEaPrM6vwBb6UeqBAfZD@f4a6506a-05dc-49cf-90c6-30e3b01ee57e.asia-south2.firestore.goog:443/concetto?loadBalanced=true&tls=true&authMechanism=SCRAM-SHA-256&retryWrites=false';
  try {
    final db = await Db.create(uri);
    await db.open();
  } catch (e, st) {
    print('Exception: $e');
    print('StackTrace: $st');
  }
}
