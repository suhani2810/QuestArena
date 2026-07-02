import 'package:cloud_firestore/cloud_firestore.dart';

class ShopRepository {
  final FirebaseFirestore _firestore;

  ShopRepository(this._firestore);

  Future<void> purchaseItem({
    required String userId,
    required int cost,
    int? oneOptionLifelinesInc,
    int? twoOptionLifelinesInc,
    int? rankProtectionMatchesInc,
  }) async {
    final userRef = _firestore.collection('users').doc(userId);

    return _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(userRef);

      if (!snapshot.exists) {
        throw Exception('User does not exist');
      }

      final userData = snapshot.data()!;
      final currentCoins = userData['coins'] ?? 0;

      if (currentCoins < cost) {
        throw Exception('Insufficient coins');
      }

      transaction.update(userRef, {
        'coins': FieldValue.increment(-cost),
        if (oneOptionLifelinesInc != null)
          'oneOptionLifelines': FieldValue.increment(oneOptionLifelinesInc),
        if (twoOptionLifelinesInc != null)
          'twoOptionLifelines': FieldValue.increment(twoOptionLifelinesInc),
        if (rankProtectionMatchesInc != null)
          'rankProtectionMatches': FieldValue.increment(rankProtectionMatchesInc),
      });
    });
  }
}
