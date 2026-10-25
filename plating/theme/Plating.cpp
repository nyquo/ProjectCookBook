#include "Plating.hpp"

#include <QQmlEngine>
#include <QQuickItem>

// Qt looks for an item's attached parent up to the first popup above it, and
// stops there even if that popup has no attached object. Basic popups never
// create one, so their content wouldn't inherit: create it. (QQuickPopup is
// private API, hence the class name.)
static void attachEnclosingPopup(QObject* attachee)
{
  const auto* item = qobject_cast<QQuickItem*>(attachee);
  for (QQuickItem* ancestor = item ? item->parentItem() : nullptr; ancestor;
       ancestor = ancestor->parentItem()) {
    QObject* owner = ancestor->parent();
    if (owner && owner->inherits("QQuickPopup")) {
      qmlAttachedPropertiesObject<Plating>(owner, true);
      return;
    }
  }
}

// Singletons belong to an engine, so the fallback comes from the engine that
// created the attachee. Qt also attaches one Plating to the engine itself, as
// the root of the objects that have no attached ancestor. Null without an
// engine, e.g. for items a control creates in C++.
static QObject* defaultTheme(QObject* attachee)
{
  QQmlEngine* engine = qobject_cast<QQmlEngine*>(attachee);
  if (!engine) {
    engine = qmlEngine(attachee);
  }
  return engine
           ? engine->singletonInstance<QObject*>("Plating", "DefaultLightTheme")
           : nullptr;
}

Plating::Plating(QObject* parent)
  : QQuickAttachedPropertyPropagator(parent)
  // Set before initialize(): without an attached parent, this is what it hands
  // to the attached children it finds.
  , m_theme(defaultTheme(parent))
{
  attachEnclosingPopup(parent);
  initialize();
  if (!m_theme) {
    qWarning("Plating: no theme for %s: it has no attached parent and no QML "
             "engine",
             parent ? parent->metaObject()->className() : "null");
  }
}

Plating* Plating::qmlAttachedProperties(QObject* object)
{
  return new Plating(object);
}

QObject* Plating::theme() const
{
  return m_theme;
}

void Plating::setTheme(QObject* theme)
{
  if (!theme) {
    resetTheme();
    return;
  }
  // Explicit even if the value doesn't change: it stops inheriting
  m_explicitTheme = true;
  applyTheme(theme);
}

void Plating::resetTheme()
{
  if (!m_explicitTheme) {
    return;
  }
  m_explicitTheme = false;
  applyTheme(inheritedTheme());
}

void Plating::attachedParentChange(QQuickAttachedPropertyPropagator* newParent,
                                   QQuickAttachedPropertyPropagator* oldParent)
{
  Q_UNUSED(newParent);
  Q_UNUSED(oldParent);
  inheritTheme(inheritedTheme());
}

void Plating::inheritTheme(QObject* theme)
{
  if (!m_explicitTheme) {
    applyTheme(theme);
  }
}

void Plating::applyTheme(QObject* theme)
{
  if (m_theme == theme) {
    return;
  }
  m_theme = theme;
  const auto children = attachedChildren();
  for (QQuickAttachedPropertyPropagator* child : children) {
    if (auto* plating = qobject_cast<Plating*>(child)) {
      plating->inheritTheme(theme);
    }
  }
  emit themeChanged();
}

QObject* Plating::inheritedTheme() const
{
  if (auto* parentPlating = qobject_cast<Plating*>(attachedParent())) {
    if (QObject* theme = parentPlating->theme()) {
      return theme;
    }
  }
  // An object being destroyed has already lost its engine: keeping its theme
  // spares its last bindings a null one
  QObject* fallback = defaultTheme(parent());
  return fallback ? fallback : m_theme.data();
}
