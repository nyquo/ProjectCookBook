#include "PhotoStore.hpp"

#include <QBuffer>
#include <QByteArray>
#include <QCryptographicHash>
#include <QImageWriter>
#include <QSaveFile>

#include <algorithm>

static constexpr QLatin1StringView suffix(".jpg");

// 64 lowercase hex digits, as the recipe table's photo_id
static bool isPhotoId(const QString& text)
{
  return text.size() == 64 && std::ranges::all_of(text, [](QChar c) {
           return (c >= u'0' && c <= u'9') || (c >= u'a' && c <= u'f');
         });
}

PhotoStore::PhotoStore(const QString& folder)
  : m_folder(folder)
{
  if (!m_folder.mkpath(QStringLiteral("."))) {
    qWarning("PhotoStore: can't create %s", qPrintable(folder));
  }
}

QString PhotoStore::save(const QImage& image)
{
  if (image.isNull()) {
    return {};
  }
  const QImage scaled =
    std::max(image.width(), image.height()) > maxSide
      ? image.scaled(
          maxSide, maxSide, Qt::KeepAspectRatio, Qt::SmoothTransformation)
      : image;

  QByteArray bytes;
  QBuffer buffer(&bytes);
  buffer.open(QIODevice::WriteOnly);
  QImageWriter writer(&buffer, "jpg");
  writer.setQuality(jpegQuality);
  if (!writer.write(scaled)) {
    qWarning("PhotoStore: can't encode a photo: %s",
             qPrintable(writer.errorString()));
    return {};
  }

  const QString id = QString::fromLatin1(
    QCryptographicHash::hash(bytes, QCryptographicHash::Sha256).toHex());
  const QString path = m_folder.filePath(id + suffix);
  if (QFile::exists(path)) {
    return id;
  }
  // Written whole or not at all
  QSaveFile file(path);
  if (!file.open(QIODevice::WriteOnly) || file.write(bytes) != bytes.size() ||
      !file.commit()) {
    qWarning("PhotoStore: can't write %s: %s",
             qPrintable(path),
             qPrintable(file.errorString()));
    return {};
  }
  return id;
}

QUrl PhotoStore::url(const QString& photoId) const
{
  if (photoId.isEmpty()) {
    return {};
  }
  return QUrl::fromLocalFile(m_folder.filePath(photoId + suffix));
}

void PhotoStore::removeAllBut(const QSet<QString>& kept)
{
  const QStringList files =
    m_folder.entryList({ QStringLiteral("*.jpg") }, QDir::Files);
  for (const QString& name : files) {
    const QString id = name.chopped(suffix.size());
    if (isPhotoId(id) && !kept.contains(id) && !m_folder.remove(name)) {
      qWarning("PhotoStore: can't delete %s", qPrintable(name));
    }
  }
}
