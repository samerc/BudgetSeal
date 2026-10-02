import 'package:flutter_riverpod/flutter_riverpod.dart';

/// "See all" from an account or envelope: open the Activity tab across all
/// months, filtered to that account or category. `MainScreen` switches tab
/// and `TransactionsScreen` applies and clears the request.
typedef ActivityFilter = ({
  String? accountId,
  String? categoryId,
  String? categoryName,
});

class ActivityFilterRequest extends Notifier<ActivityFilter?> {
  @override
  ActivityFilter? build() => null;

  void request(ActivityFilter filter) => state = filter;
  void clear() => state = null;
}

final activityFilterRequestProvider =
    NotifierProvider<ActivityFilterRequest, ActivityFilter?>(
        ActivityFilterRequest.new);
