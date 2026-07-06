/// Téléchargement fichier — stub (mobile/desktop natif : copie uniquement).
void downloadTextFile(String filename, String content, {String mimeType = 'text/plain;charset=utf-8'}) {
  throw UnsupportedError('Utilisez la copie dans le presse-papiers sur cette plateforme.');
}

bool get canDownloadFile => false;
