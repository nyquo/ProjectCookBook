#include "AppearanceSettings.hpp"

#include "appBackend.hpp"
#include "core/Backend.hpp"
#include "core/Database.hpp"

#include <QGuiApplication>
#include <QStyleHints>

#include <stdexcept>

AppearanceSettings::AppearanceSettings(QObject* parent)
  : AppearanceSettings(app::backend().settings(), parent)
{
}

AppearanceSettings::AppearanceSettings(core::SettingStore& settings,
                                       QObject* parent)
  : QObject(parent)
  , m_settings(settings)
  , m_themeMode(core::themeMode(settings))
  , m_accent(core::accent(settings))
{
  m_settings.addObserver(*this);
}

AppearanceSettings::~AppearanceSettings()
{
  m_settings.removeObserver(*this);
}

AppearanceSettings::ThemeMode AppearanceSettings::themeMode() const
{
  return static_cast<ThemeMode>(m_themeMode);
}

void AppearanceSettings::setThemeMode(ThemeMode mode)
{
  // Also spares the store a write from a binding that follows the setting,
  // which would otherwise come during the store's notification
  if (mode == themeMode()) {
    return;
  }
  try {
    core::setThemeMode(m_settings, static_cast<core::ThemeMode>(mode));
  } catch (const core::DatabaseError& error) {
    qCritical("Saving the theme failed: %s", error.what());
  } catch (const std::logic_error& error) {
    qWarning("AppearanceSettings: %s", error.what());
  }
}

AppearanceSettings::Accent AppearanceSettings::accent() const
{
  return static_cast<Accent>(m_accent);
}

void AppearanceSettings::setAccent(Accent accent)
{
  if (accent == this->accent()) {
    return;
  }
  try {
    core::setAccent(m_settings, static_cast<core::Accent>(accent));
  } catch (const core::DatabaseError& error) {
    qCritical("Saving the accent failed: %s", error.what());
  } catch (const std::logic_error& error) {
    qWarning("AppearanceSettings: %s", error.what());
  }
}

void AppearanceSettings::applyColorScheme(core::ThemeMode mode)
{
  QStyleHints* hints = QGuiApplication::styleHints();
  // Set while waiting for the system's scheme after leaving a forced one
  static QMetaObject::Connection restoringBars;
  QObject::disconnect(restoringBars);

  switch (mode) {
    case core::ThemeMode::Light:
      hints->setColorScheme(Qt::ColorScheme::Light);
      return;
    case core::ThemeMode::Dark:
      hints->setColorScheme(Qt::ColorScheme::Dark);
      return;
    case core::ThemeMode::System:
      hints->unsetColorScheme();
#ifdef Q_OS_ANDROID
      // Qt sets the system bars' icons for a forced scheme, but leaves them as
      // they are when the override goes, until the system's mode changes:
      // back from a forced dark to a light system, they would stay light on
      // light. Once the system's scheme is reported, ask for it explicitly,
      // which sets the icons, then let it follow the system again.
      restoringBars = QObject::connect(hints,
                                       &QStyleHints::colorSchemeChanged,
                                       hints,
                                       [hints](Qt::ColorScheme scheme) {
                                         QObject::disconnect(restoringBars);
                                         hints->setColorScheme(scheme);
                                         hints->unsetColorScheme();
                                       });
#endif
      return;
  }
}

void AppearanceSettings::settingAboutToChange(std::string_view) noexcept {}

void AppearanceSettings::settingChanged(std::string_view) noexcept
{
  const core::ThemeMode mode = core::themeMode(m_settings);
  if (mode != m_themeMode) {
    m_themeMode = mode;
    applyColorScheme(mode);
    emit themeModeChanged();
  }
  const core::Accent accent = core::accent(m_settings);
  if (accent != m_accent) {
    m_accent = accent;
    emit accentChanged();
  }
}
