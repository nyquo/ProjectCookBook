#include "AppearanceSettings.hpp"
#include "PhotoStore.hpp"
#include "appBackend.hpp"
#include "core/Backend.hpp"
#include "core/Database.hpp"
#include "core/appearance.hpp"
#include "sampleRecipes.hpp"

#include <QDir>
#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQuickStyle>
#include <QSet>
#include <QStandardPaths>
#include <QTranslator>
#include <QtQml/QQmlExtensionPlugin>

#include <optional>

// Registers the static QML modules; otherwise the linker drops them
Q_IMPORT_QML_PLUGIN(PlatingPlugin)
Q_IMPORT_QML_PLUGIN(CookbookUiPlugin)

// The app's private data folder
static QDir dataFolder()
{
  const QString path =
    QStandardPaths::writableLocation(QStandardPaths::AppDataLocation);
  QDir().mkpath(path);
  return QDir(path);
}

// The photos of live recipes; the others' files can go
static QSet<QString> livePhotoIds(const core::RecipeStore& recipes)
{
  QSet<QString> ids;
  for (const core::Recipe& recipe : recipes.recipes()) {
    if (recipe.photoId) {
      ids.insert(QString::fromStdString(*recipe.photoId));
    }
  }
  return ids;
}

int main(int argc, char* argv[])
{
  QGuiApplication app(argc, argv);
  QGuiApplication::setApplicationDisplayName(QStringLiteral(APP_DISPLAY_NAME));
  QGuiApplication::setApplicationVersion(QStringLiteral(APP_VERSION));

  // The texts are written in English; this file only gives their plural forms
  // ("1 piece", "6 pieces"), whatever the user's language.
  QTranslator plurals;
  if (plurals.load(QStringLiteral(":/i18n/projectcookbook_en.qm"))) {
    QCoreApplication::installTranslator(&plurals);
  } else {
    qWarning("Can't load the English plural forms");
  }

  // Declared before the engine, so they outlive every model QML creates
  std::optional<core::Backend> backend;
  std::optional<PhotoStore> photos;
  QString startupError;
  try {
    const QDir folder = dataFolder();
    backend.emplace(folder.filesystemAbsolutePath() / "data.db");
    app::setBackend(*backend);
    photos.emplace(folder.absoluteFilePath(QStringLiteral("photos")));
    app::setPhotoStore(*photos);
#ifndef NDEBUG
    app::addSampleRecipes(*backend, *photos);
#endif
    photos->removeAllBut(livePhotoIds(backend->recipes()));
    // Before the first frame, so the app never shows the wrong theme
    AppearanceSettings::applyColorScheme(core::themeMode(backend->settings()));
  } catch (const core::DatabaseError& error) {
    qCritical("Can't open the database: %s", error.what());
    startupError = QString::fromUtf8(error.what());
    backend.reset();
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
