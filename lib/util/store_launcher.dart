import 'package:flutter/foundation.dart';
import 'package:netdrop/config/constants.dart';
import 'package:url_launcher/url_launcher.dart';

Future<bool> openPlayStoreListing() async {
  final uri = defaultTargetPlatform == TargetPlatform.android
      ? Uri.parse('market://details?id=$androidPackageName')
      : Uri.parse(playStoreListingUrl);

  if (await canLaunchUrl(uri)) {
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  final webUri = Uri.parse(playStoreListingUrl);
  if (await canLaunchUrl(webUri)) {
    return launchUrl(webUri, mode: LaunchMode.externalApplication);
  }

  return false;
}
