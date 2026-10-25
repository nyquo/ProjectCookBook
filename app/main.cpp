#include "appBackend.hpp"
#include "core/Backend.hpp"
#include "core/Database.hpp"

#include <QDir>
#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQuickStyle>
#include <QStandardPaths>
#include <QtQml/QQmlExtensionPlugin>

#include <optional>

// Registers the static QML modules; otherwise the linker drops them
Q_IMPORT_QML_PLUGIN(PlatingPlugin)
Q_IMPORT_QML_PLUGIN(CookbookUiPlugin)

static std::filesystem::path databasePath()
{
  const QString dir =
    QStandardPaths::writableLocation(QStandardPaths::AppDataLocation);
  QDir().mkpath(dir);
  return QDir(dir).filesystemAbsolutePath() / "data.db";
}

int main(int argc, char* argv[])
{
  QGuiApplication app(argc, argv);
  QGuiApplication::setApplicationDisplayName(QStringLiteral(APP_DISPLAY_NAME));
  QGuiApplication::setApplicationVersion(QStringLiteral(APP_VERSION));

  // Declared before the engine, so it outlives every model QML creates
  std::optional<core::Backend> backend;
  QString startupError;
  try {
    backend.emplace(databasePath());
    app::setBackend(*backend);
  } catch (const core::DatabaseError& error) {
    qCritical("Can't open the database: %s", error.what());
    startupError = QString::fromUtf8(error.what());
  }

  // Before any QML loads, so a stray `import QtQuick.Controls` gets Plating
  // rather than Material, Android's default style.
  QQuickStyle::setStyle(QStringLiteral("Plating"));

  QQmlApplicationEngine engine;
  QObject::connect(
    &engine,
    &QQmlApplicationEngine::objectCreationFailed,
    &app,
    [] { QCoreApplication::exit(EXIT_FAILURE); },
    Qt::QueuedConnection);
  if (backend) {
    engine.loadFromModule("ProjectCookbook", "Main");
  } else {
    // Without a window, the app would just vanish on Android
    engine.setInitialProperties({ { "details", startupError } });
    engine.loadFromModule("ProjectCookbook", "StartupError");
  }

  return QGuiApplication::exec();
}
