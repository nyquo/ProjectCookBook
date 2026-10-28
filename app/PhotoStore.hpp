#pragma once

#include <QDir>
#include <QImage>
#include <QSet>
#include <QString>
#include <QUrl>

// The recipes' photos: JPEG files in a folder of the app's private data, each
// named after the SHA-256 of its bytes, "<sha256>.jpg". A recipe stores only
// that hash, its photo id. Not thread-safe: the main thread uses it, like the
// stores.
class PhotoStore
{
public:
  // Photos are at most this many pixels on their long side
  static constexpr int maxSide = 2048;
  static constexpr int jpegQuality = 80;

  // Creates the folder if needed
  explicit PhotoStore(const QString& folder);

  // Scales the image down to maxSide, encodes it as JPEG and writes it,
  // unless a photo with the same bytes is there already. Returns its id, or
  // "" if it couldn't be written.
  QString save(const QImage& image);
  // The photo's file, for an Image; empty for an empty id
  QUrl url(const QString& photoId) const;
  // Deletes the photos whose id isn't in `kept`; other files stay
  void removeAllBut(const QSet<QString>& kept);

private:
  QDir m_folder;
};
