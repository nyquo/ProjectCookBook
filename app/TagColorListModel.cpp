#include "TagColorListModel.hpp"

#include "appBackend.hpp"
#include "core/Backend.hpp"

#include <QColor>

static QColor toQColor(core::Rgb color)
{
  return QColor(color.red, color.green, color.blue);
}

TagColorListModel::TagColorListModel(QObject* parent)
  : TagColorListModel(app::backend().tagColors(), parent)
{
}

TagColorListModel::TagColorListModel(const core::TagColorStore& store,
                                     QObject* parent)
  : QAbstractListModel(parent)
  , m_store(store)
{
}

int TagColorListModel::rowCount(const QModelIndex& parent) const
{
  return parent.isValid() ? 0 : static_cast<int>(m_store.tagColors().size());
}

QVariant TagColorListModel::data(const QModelIndex& index, int role) const
{
  if (!checkIndex(index,
                  CheckIndexOption::IndexIsValid |
                    CheckIndexOption::ParentIsInvalid)) {
    return {};
  }

  const core::TagColor& tagColor = m_store.tagColors()[index.row()];
  switch (role) {
    case NameRole:
      return QString::fromStdString(tagColor.name);
    case FillRole:
      return toQColor(tagColor.colors.fill);
    case InkRole:
      return toQColor(tagColor.colors.ink);
    case DarkFillRole:
      return toQColor(tagColor.colors.darkFill);
    case DarkInkRole:
      return toQColor(tagColor.colors.darkInk);
  }
  return {};
}

QHash<int, QByteArray> TagColorListModel::roleNames() const
{
  return { { NameRole, "name" },
           { FillRole, "fill" },
           { InkRole, "ink" },
           { DarkFillRole, "darkFill" },
           { DarkInkRole, "darkInk" } };
}
