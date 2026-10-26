#pragma once

#include "core/SettingStore.hpp"
#include "core/unitSystem.hpp"

#include <QObject>
#include <QStringList>
#include <QtQml/qqmlregistration.h>

// The unit system setting, for QML as the UnitSettings singleton. A change is
// saved at once. It changes how amounts are shown and which units are offered,
// never the amounts stored.
class UnitSettings
  : public QObject
  , private core::SettingObserver
{
  Q_OBJECT
  QML_ELEMENT
  QML_SINGLETON

  Q_PROPERTY(
    System system READ system WRITE setSystem NOTIFY systemChanged FINAL)
  // The unit codes offered where the user picks one, in the order shown
  Q_PROPERTY(
    QStringList unitChoices READ unitChoices NOTIFY systemChanged FINAL)

public:
  // As in core
  enum class System
  {
    Metric,
    Us
  };
  Q_ENUM(System)

  explicit UnitSettings(QObject* parent = nullptr);
  explicit UnitSettings(core::SettingStore& settings,
                        QObject* parent = nullptr);
  ~UnitSettings() override;

  System system() const;
  // A failed save keeps the current value
  void setSystem(System system);
  QStringList unitChoices() const;

signals:
  void systemChanged();

private:
  void settingAboutToChange(std::string_view key) noexcept override;
  void settingChanged(std::string_view key) noexcept override;

  core::SettingStore& m_settings;
  core::UnitSystem m_system;
};
