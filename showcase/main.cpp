#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQuickStyle>
#include <QtQml/QQmlExtensionPlugin>

// Registers the static QML modules; otherwise the linker drops them
Q_IMPORT_QML_PLUGIN(PlatingPlugin)
Q_IMPORT_QML_PLUGIN(CookbookUiPlugin)

// Run with --capture <folder> to save every page, in both themes, as PNG files
// and quit.
int main(int argc, char* argv[])
{
  QGuiApplication app(argc, argv);

  // Before any QML loads, as in the app
  QQuickStyle::setStyle(QStringLiteral("Plating"));

  QQmlApplicationEngine engine;
  QObject::connect(
    &engine,
    &QQmlApplicationEngine::objectCreationFailed,
    &app,
    [] { QCoreApplication::exit(EXIT_FAILURE); },
    Qt::QueuedConnection);
  engine.loadFromModule("Showcase", "Main");

  return QGuiApplication::exec();
}
