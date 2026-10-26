#pragma once

#include "core/SettingStore.hpp"
#include "core/appearance.hpp"

#include <QObject>
#include <QtQml/qqmlregistration.h>

// The theme and accent settings, for QML as the AppearanceSettings singleton.
// A change is saved at once. The theme mode also goes to QStyleHints, which on
// Android keeps the system bars' icons readable over the app's theme.
class AppearanceSettings
  : public QObject
  , private core::SettingObserver
{
  Q_OBJECT
  QML_ELEMENT
  QML_SINGLETON

  Q_PROPERTY(ThemeMode themeMode READ themeMode WRITE setThemeMode NOTIFY
               themeModeChanged FINAL)
  Q_PROPERTY(
    Accent accent READ accent WRITE setAccent NOTIFY accentChanged FINAL)

public:
  // As in core
  enum class ThemeMode
  {
    System,
    Light,
    Dark
  };
  Q_ENUM(ThemeMode)

  // As in core, and in UiTheme.Accent order: the colors are the theme's
  enum class Accent
  {
    Raspberry,
    Spirulina,
    Blueberry,
    Saffron,
    Basil
  };
  Q_ENUM(Accent)

  explicit AppearanceSettings(QObject* parent = nullptr);
  explicit AppearanceSettings(core::SettingStore& settings,
                              QObject* parent = nullptr);
  ~AppearanceSettings() override;

  ThemeMode themeMode() const;
  // A failed save keeps the current value
  void setThemeMode(ThemeMode mode);
  Accent accent() const;
  void setAccent(Accent accent);

  // Gives QStyleHints the color scheme the mode asks for. main() calls it
  // before loading QML, so the first frame already has the saved theme.
  static void applyColorScheme(core::ThemeMode mode);

signals:
  void themeModeChanged();
  void accentChanged();

private:
  void settingAboutToChange(std::string_view key) noexcept override;
  void settingChanged(std::string_view key) noexcept override;

  core::SettingStore& m_settings;
  core::ThemeMode m_themeMode;
  core::Accent m_accent;
};
