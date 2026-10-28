#pragma once

#include "core/SettingStore.hpp"
#include "core/TagStore.hpp"

#include <QCollator>
#include <QObject>
#include <QStringList>
#include <QtQml/qqmlregistration.h>

// The filters the recipes list opens with, for QML as the
// DefaultFilterSettings singleton. A change is saved at once. Follows the
// app's TagStore: a deleted tag leaves the defaults, and comes back with Undo.
class DefaultFilterSettings
  : public QObject
  , private core::SettingObserver
  , private core::TagObserver
{
  Q_OBJECT
  QML_ELEMENT
  QML_SINGLETON

  Q_PROPERTY(bool favoritesOnly READ favoritesOnly WRITE setFavoritesOnly NOTIFY
               favoritesOnlyChanged FINAL)
  // Live tags only, sorted by name like TagListModel
  Q_PROPERTY(QStringList tagIds READ tagIds NOTIFY tagsChanged FINAL)
  // Their names, joined as the user's language lists them: "Vegetarian and
  // Weeknight"
  Q_PROPERTY(QString tagNames READ tagNames NOTIFY tagsChanged FINAL)

public:
  explicit DefaultFilterSettings(QObject* parent = nullptr);
  DefaultFilterSettings(core::SettingStore& settings,
                        core::TagStore& tags,
                        QObject* parent = nullptr);
  ~DefaultFilterSettings() override;

  bool favoritesOnly() const { return m_favoritesOnly; }
  // A failed save keeps the current value
  void setFavoritesOnly(bool on);
  QStringList tagIds() const { return m_tagIds; }
  QString tagNames() const { return m_tagNames; }

  // A failed save, or a tag that's gone, changes nothing
  Q_INVOKABLE void setTagSelected(const QString& tagId, bool selected);

signals:
  void favoritesOnlyChanged();
  void tagsChanged();

private:
  void settingAboutToChange(std::string_view key) noexcept override;
  void settingChanged(std::string_view key) noexcept override;
  void tagAboutToChange(const core::TagChange& change) noexcept override;
  void tagChanged(const core::TagChange& change) noexcept override;

  // Reads the settings again, and notifies what changed
  void refresh();

  core::SettingStore& m_settings;
  core::TagStore& m_tags;
  QCollator m_collator;
  bool m_favoritesOnly = false;
  QStringList m_tagIds;
  QString m_tagNames;
};
