#include "CookingSettings.hpp"

#include "appBackend.hpp"
#include "core/Backend.hpp"
#include "core/Database.hpp"
#include "core/cooking.hpp"

#include <stdexcept>

CookingSettings::CookingSettings(QObject* parent)
  : CookingSettings(app::backend().settings(), parent)
{
}

CookingSettings::CookingSettings(core::SettingStore& settings, QObject* parent)
  : QObject(parent)
  , m_settings(settings)
  , m_keepScreenOn(core::keepScreenOn(settings))
{
  m_settings.addObserver(*this);
}

CookingSettings::~CookingSettings()
{
  m_settings.removeObserver(*this);
}

void CookingSettings::setKeepScreenOn(bool on)
{
  // Also spares the store a write from a binding that follows the setting,
  // which would otherwise come during the store's notification
  if (on == m_keepScreenOn) {
    return;
  }
  try {
    core::setKeepScreenOn(m_settings, on);
  } catch (const core::DatabaseError& error) {
    qCritical("Saving Keep screen on failed: %s", error.what());
  } catch (const std::logic_error& error) {
    qWarning("CookingSettings: %s", error.what());
  }
}

void CookingSettings::settingAboutToChange(std::string_view) noexcept {}

void CookingSettings::settingChanged(std::string_view) noexcept
{
  const bool on = core::keepScreenOn(m_settings);
  if (on != m_keepScreenOn) {
    m_keepScreenOn = on;
    emit keepScreenOnChanged();
  }
}
