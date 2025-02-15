import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseHelper {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> saveHealthData(Map<String, dynamic> data) async {
    await _firestore.collection("health_data").add(data);
  }
}
