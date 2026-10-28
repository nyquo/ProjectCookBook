#pragma once

#include "core/SettingStore.hpp"

#include <QObject>
#include <QtQml/qqmlregistration.h>

// The cooking settings, for QML as the CookingSettings singleton. A change is
// saved at once.
class CookingSettings
  : public QObject
  , private core::SettingObserver
{
  Q_OBJECT
  QML_ELEMENT
  QML_SINGLETON

  // An open recipe keeps the display awake; see KeepScreenOn
  Q_PROPERTY(bool keepScreenOn READ keepScreenOn WRITE setKeepScreenOn NOTIFY
               keepScreenOnChanged FINAL)

public:
  explicit CookingSettings(QObject* parent = nullptr);
  explicit CookingSettings(core::SettingStore& settings,
                           QObject* parent = nullptr);
  ~CookingSettings() override;

  bool keepScreenOn() const { return m_keepScreenOn; }
  // A failed save keeps the current value
  void setKeepScreenOn(bool on);

signals:
  void keepScreenOnChanged();

private:
  void settingAboutToChange(std::string_view key) noexcept override;
  void settingChanged(std::string_view key) noexcept override;

  core::SettingStore& m_settings;
  bool m_keepScreenOn;
};
