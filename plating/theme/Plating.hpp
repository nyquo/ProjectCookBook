#pragma once

#include <QPointer>
#include <QQuickAttachedPropertyPropagator>
#include <QtQml/qqmlregistration.h>

// Plating.theme: the UiTheme an object and everything below it use. Set it on
// any Item, Window or Popup; children, child windows and popups inherit it. A
// popup inherits from its window, not from the item that declares it (Qt's
// propagation rule). An explicit value wins over the inherited one; assigning
// undefined or null returns to the inherited one. Without any, the theme is the
// DefaultLightTheme singleton.
//
// The type is QObject* because a UiTheme is defined in QML: read it through a
// typed property, `readonly property UiTheme theme: Plating.theme as UiTheme`.
class Plating : public QQuickAttachedPropertyPropagator
{
  Q_OBJECT
  Q_PROPERTY(QObject* theme READ theme WRITE setTheme RESET resetTheme NOTIFY
               themeChanged FINAL)
  QML_ELEMENT
  QML_ATTACHED(Plating)
  QML_UNCREATABLE("Plating is only available as an attached property.")

public:
  explicit Plating(QObject* parent = nullptr);

  static Plating* qmlAttachedProperties(QObject* object);

  QObject* theme() const;
  void setTheme(QObject* theme);
  void resetTheme();

signals:
  void themeChanged();

protected:
  void attachedParentChange(
    QQuickAttachedPropertyPropagator* newParent,
    QQuickAttachedPropertyPropagator* oldParent) override;

private:
  void inheritTheme(QObject* theme);
  // Sets the theme and hands it down to the children that don't set their own
  void applyTheme(QObject* theme);
  // The attached parent's theme, or the default one without a parent
  QObject* inheritedTheme() const;

  // Whether theme was set on this very object, rather than inherited
  bool m_explicitTheme = false;
  QPointer<QObject> m_theme;
};
