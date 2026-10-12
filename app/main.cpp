#include "appBackend.hpp"
#include "core/Backend.hpp"
#include "core/Database.hpp"

#include <QDir>
#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QStandardPaths>

#include <optional>

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

  // Declared before the engine, so it outlives every model QML creates.
  std::optional<core::Backend> backend;
  try {
    backend.emplace(databasePath());
  } catch (const core::DatabaseError& error) {
    qCritical("Can't open the database: %s", error.what());
    return EXIT_FAILURE;
  }
  app::setBackend(*backend);

  QQmlApplicationEngine engine;
  QObject::connect(
    &engine,
    &QQmlApplicationEngine::objectCreationFailed,
    &app,
    [] { QCoreApplication::exit(EXIT_FAILURE); },
    Qt::QueuedConnection);
  engine.loadFromModule("ProjectCookbook", "Main");

  return QGuiApplication::exec();
}
