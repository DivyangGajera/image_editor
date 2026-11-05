import 'package:image_editor/core/network/internet_check.dart';

/// [InternetCheck] with a fixed answer that tests can change.
class FakeInternetCheck implements InternetCheck {
  FakeInternetCheck({this.online = true});

  bool online;
  int checks = 0;

  @override
  Future<bool> isOnline() async {
    checks++;
    return online;
  }
}
