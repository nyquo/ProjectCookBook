#include "DefaultFilterSettings.hpp"

#include "appBackend.hpp"
#include "collation.hpp"
#include "core/Backend.hpp"
#include "core/Database.hpp"
#include "core/defaultFilters.hpp"
#include "core/tagView.hpp"

#include <QLocale>

#include <algorithm>
#include <stdexcept>
#include <string>
#include <vector>

DefaultFilterSettings::DefaultFilterSettings(QObject* parent)
  : DefaultFilterSettings(app::backend().settings(),
                          app::backend().tags(),
                          parent)
{
}

DefaultFilterSettings::DefaultFilterSettings(core::SettingStore& settings,
                                             core::TagStore& tags,
                                             QObject* parent)
  : QObject(parent)
  , m_settings(settings)
  , m_tags(tags)
  , m_collator(app::nameCollator())
{
  refresh();
  m_settings.addObserver(*this);
  m_tags.addObserver(*this);
}

DefaultFilterSettings::~DefaultFilterSettings()
{
  m_tags.removeObserver(*this);
  m_settings.removeObserver(*this);
}

void DefaultFilterSettings::setFavoritesOnly(bool on)
{
  // Also spares the store a write from a binding that follows the setting,
  // which would otherwise come during the store's notification
  if (on == m_favoritesOnly) {
    return;
  }
  try {
    core::setDefaultFavoritesOnly(m_settings, on);
  } catch (const core::DatabaseError& error) {
    qCritical("Saving the default filters failed: %s", error.what());
  } catch (const std::logic_error& error) {
    qWarning("DefaultFilterSettings: %s", error.what());
  }
}

void DefaultFilterSettings::setTagSelected(const QString& tagId, bool selected)
{
  try {
    core::setDefaultTagSelected(
      m_settings, m_tags, tagId.toStdString(), selected);
  } catch (const core::DatabaseError& error) {
    qCritical("Saving the default filters failed: %s", error.what());
  } catch (const std::logic_error& error) {
    qWarning("DefaultFilterSettings: %s", error.what());
  }
}

void DefaultFilterSettings::settingAboutToChange(std::string_view) noexcept {}

void DefaultFilterSettings::settingChanged(std::string_view) noexcept
{
  refresh();
}

void DefaultFilterSettings::tagAboutToChange(const core::TagChange&) noexcept {}

void DefaultFilterSettings::tagChanged(const core::TagChange&) noexcept
{
  refresh();
}

void DefaultFilterSettings::refresh()
{
  const bool favoritesOnly = core::defaultFavoritesOnly(m_settings);
  if (favoritesOnly != m_favoritesOnly) {
    m_favoritesOnly = favoritesOnly;
    emit favoritesOnlyChanged();
  }

  const std::vector<std::string> selected =
    core::defaultTagIds(m_settings, m_tags);
  const std::vector<core::Tag>& tags = m_tags.tags();
  QStringList ids;
  QStringList names;
  for (const int index : core::tagsByName(tags, app::nameLess(m_collator))) {
    const core::Tag& tag = tags[index];
    if (std::ranges::find(selected, tag.id) != selected.end()) {
      ids.append(QString::fromStdString(tag.id));
      names.append(QString::fromStdString(tag.name));
    }
  }
  const QString joined = QLocale().createSeparatedList(names);
  if (ids != m_tagIds || joined != m_tagNames) {
    m_tagIds = ids;
    m_tagNames = joined;
    emit tagsChanged();
  }
}
