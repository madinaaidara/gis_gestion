import 'dart:html' as html;

void downloadTextFile(String filename, String content, {String mimeType = 'text/plain;charset=utf-8'}) {
  final bytes = content;
  final blob = html.Blob([bytes], mimeType);
  final url = html.Url.createObjectUrlFromBlob(blob);
  html.AnchorElement(href: url)
    ..setAttribute('download', filename)
    ..click();
  html.Url.revokeObjectUrl(url);
}

bool get canDownloadFile => true;
