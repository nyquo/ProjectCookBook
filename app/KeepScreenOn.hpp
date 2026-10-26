#pragma once

#include "core/SettingStore.hpp"

#include <QObject>
#include <QtQml/qqmlregistration.h>

// A request to keep the display awake, created by QML: it holds while
// `active` and while the user's Keep screen on setting is on, and is released
// at once when either goes off or when it's destroyed. The display stays awake
// while any request holds. On Android that's the window's keep-screen-on flag;
// elsewhere it does nothing.
class KeepScreenOn
  : public QObject
  , private core::SettingObserver
{
  Q_OBJECT
  QML_ELEMENT

  Q_PROPERTY(bool active READ active WRITE setActive NOTIFY activeChanged FINAL)
  // Active, and the setting on
  Q_PROPERTY(bool holding READ holding NOTIFY holdingChanged FINAL)

public:
  explicit KeepScreenOn(QObject* parent = nullptr);
  explicit KeepScreenOn(core::SettingStore& settings,
                        QObject* parent = nullptr);
  ~KeepScreenOn() override;

  bool active() const { return m_active; }
  void setActive(bool active);
  bool holding() const { return m_holding; }

signals:
  void activeChanged();
  void holdingChanged();

private:
  void settingAboutToChange(std::string_view key) noexcept override;
  void settingChanged(std::string_view key) noexcept override;

  void update();
  // Counts this request in or out of the holders; the flag follows the count
  void setHolding(bool holding);

  core::SettingStore& m_settings;
  bool m_active = false;
  bool m_holding = false;
};
