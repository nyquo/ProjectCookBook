#include "KeepScreenOn.hpp"

#include "appBackend.hpp"
#include "core/Backend.hpp"
#include "core/cooking.hpp"

#ifdef Q_OS_ANDROID
#include <QJniObject>
#include <QtCore/qcoreapplication_platform.h>

Q_DECLARE_JNI_CLASS(Window, "android/view/Window")
#endif

// Requests that hold, across every KeepScreenOn. Only the main thread touches
// it, like the stores.
static int s_holders = 0;

static void setWindowKeepsScreenOn([[maybe_unused]] bool on)
{
#ifdef Q_OS_ANDROID
  // Window flags may only change on Android's UI thread. Posted calls run in
  // order, so the last one wins.
  QNativeInterface::QAndroidApplication::runOnAndroidMainThread([on] {
    if (!QNativeInterface::QAndroidApplication::isActivityContext()) {
      return;
    }
    const QJniObject activity =
      QNativeInterface::QAndroidApplication::context();
    const auto window = activity.callMethod<QtJniTypes::Window>("getWindow");
    if (!window.isValid()) {
      qWarning("KeepScreenOn: the activity has no window");
      return;
    }
    // WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON
    constexpr jint keepScreenOnFlag = 0x00000080;
    if (on) {
      window.callMethod<void>("addFlags", keepScreenOnFlag);
    } else {
      window.callMethod<void>("clearFlags", keepScreenOnFlag);
    }
  });
#endif
}

KeepScreenOn::KeepScreenOn(QObject* parent)
  : KeepScreenOn(app::backend().settings(), parent)
{
}

KeepScreenOn::KeepScreenOn(core::SettingStore& settings, QObject* parent)
  : QObject(parent)
  , m_settings(settings)
{
  m_settings.addObserver(*this);
}

KeepScreenOn::~KeepScreenOn()
{
  m_settings.removeObserver(*this);
  setHolding(false);
}

void KeepScreenOn::setActive(bool active)
{
  if (active == m_active) {
    return;
  }
  m_active = active;
  emit activeChanged();
  update();
}

void KeepScreenOn::settingAboutToChange(std::string_view) noexcept {}

void KeepScreenOn::settingChanged(std::string_view) noexcept
{
  update();
}

void KeepScreenOn::update()
{
  const bool holding = m_active && core::keepScreenOn(m_settings);
  if (holding == m_holding) {
    return;
  }
  setHolding(holding);
  emit holdingChanged();
}

void KeepScreenOn::setHolding(bool holding)
{
  if (holding == m_holding) {
    return;
  }
  m_holding = holding;
  s_holders += holding ? 1 : -1;
  if (s_holders == (holding ? 1 : 0)) {
    setWindowKeepsScreenOn(holding);
  }
}
