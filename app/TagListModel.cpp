#include "TagListModel.hpp"

#include "Overloaded.hpp"
#include "appBackend.hpp"
#include "collation.hpp"
#include "core/Backend.hpp"
#include "core/Database.hpp"
#include "core/listEdits.hpp"
#include "core/tagView.hpp"

#include <algorithm>
#include <expected>
#include <optional>
#include <stdexcept>
#include <string>
#include <utility>
#include <variant>

static TagListModel::Error toError(core::TagError error)
{
  switch (error) {
    case core::TagError::EmptyName:
      return TagListModel::Error::EmptyName;
    case core::TagError::DuplicateName:
      return TagListModel::Error::DuplicateName;
  }
  std::unreachable();
}

template<typename T>
static TagListModel::Error toError(
  const std::expected<T, core::TagError>& result)
{
  return result ? TagListModel::Error::NoError : toError(result.error());
}

// Exceptions can't cross into QML. A failed write leaves memory unchanged, so
// the UI stays consistent and only has to report that saving failed. The store
// throws logic errors before changing anything, e.g. for an id QML kept after
// it went stale.
static TagListModel::Error guarded(auto&& action)
{
  try {
    return action();
  } catch (const core::DatabaseError& error) {
    qCritical("Saving tags failed: %s", error.what());
    return TagListModel::Error::StorageFailed;
  } catch (const std::logic_error& error) {
    qWarning("TagListModel: %s", error.what());
    return TagListModel::Error::InvalidRequest;
  }
}

static QString fromCode(std::string_view code)
{
  return QString::fromUtf8(code.data(), static_cast<qsizetype>(code.size()));
}

TagListModel::TagListModel(QObject* parent)
  : TagListModel(app::backend().tags(), app::backend().recipes(), parent)
{
}

TagListModel::TagListModel(core::TagStore& store,
                           core::RecipeStore& recipes,
                           QObject* parent)
  : QAbstractListModel(parent)
  , m_store(store)
  , m_recipes(recipes)
  , m_collator(app::nameCollator())
{
  m_rows = computeRows();
  m_store.addObserver(*this);
  m_recipes.addObserver(*this);
}

TagListModel::~TagListModel()
{
  m_recipes.removeObserver(*this);
  m_store.removeObserver(*this);
}

int TagListModel::rowCount(const QModelIndex& parent) const
{
  return parent.isValid() ? 0 : static_cast<int>(m_rows.size());
}

QVariant TagListModel::data(const QModelIndex& index, int role) const
{
  if (!checkIndex(index,
                  CheckIndexOption::IndexIsValid |
                    CheckIndexOption::ParentIsInvalid)) {
    return {};
  }

  const Row& row = m_rows[index.row()];
  switch (role) {
    case TagIdRole:
      return row.tagId;
    case NameRole:
      return row.name;
    case ColorKeyRole:
      return row.colorKey;
    case RecipeCountRole:
      return row.recipeCount;
  }
  return {};
}

QHash<int, QByteArray> TagListModel::roleNames() const
{
  return { { TagIdRole, "tagId" },
           { NameRole, "name" },
           { ColorKeyRole, "colorKey" },
           { RecipeCountRole, "recipeCount" } };
}

TagListModel::Error TagListModel::create(const QString& name)
{
  return guarded([&] { return toError(m_store.create(name.toStdString())); });
}

TagListModel::Error TagListModel::rename(const QString& tagId,
                                         const QString& name)
{
  return guarded([&] {
    return toError(m_store.rename(tagId.toStdString(), name.toStdString()));
  });
}

TagListModel::Error TagListModel::setColor(const QString& tagId,
                                           const QString& colorKey)
{
  const std::optional<core::TagFamily> color =
    core::tagFamilyFromCode(colorKey.toStdString());
  if (!color) {
    qWarning("TagListModel: unknown color %s", qPrintable(colorKey));
    return Error::InvalidRequest;
  }
  return guarded([&] {
    m_store.setColor(tagId.toStdString(), *color);
    return Error::NoError;
  });
}

TagListModel::Error TagListModel::remove(const QString& tagId)
{
  return guarded([&] {
    m_store.remove(tagId.toStdString());
    return Error::NoError;
  });
}

TagListModel::Error TagListModel::restore(const QString& tagId)
{
  return guarded([&] { return toError(m_store.restore(tagId.toStdString())); });
}

void TagListModel::tagAboutToChange(const core::TagChange&) noexcept {}

void TagListModel::tagChanged(const core::TagChange&) noexcept
{
  refresh();
}

void TagListModel::recipeAboutToChange(const core::RecipeChange&) noexcept {}

void TagListModel::recipeChanged(const core::RecipeChange&) noexcept
{
  refresh();
}

std::vector<TagListModel::Row> TagListModel::computeRows() const
{
  const std::vector<core::Tag>& tags = m_store.tags();
  std::vector<Row> rows;
  rows.reserve(tags.size());
  for (const int index : core::tagsByName(tags, app::nameLess(m_collator))) {
    const core::Tag& tag = tags[index];
    rows.push_back({ QString::fromStdString(tag.id),
                     QString::fromStdString(tag.name),
                     fromCode(core::tagFamilyCode(tag.color)),
                     m_recipes.recipeCount(tag.id) });
  }
  return rows;
}

void TagListModel::refresh()
{
  std::vector<Row> next = computeRows();
  const auto ids = [](const std::vector<Row>& rows) {
    std::vector<std::string> result;
    result.reserve(rows.size());
    for (const Row& row : rows) {
      result.push_back(row.tagId.toStdString());
    }
    return result;
  };
  const int countBefore = rowCount();

  for (const core::ListEdit& edit : core::listEdits(ids(m_rows), ids(next))) {
    const Overloaded apply{
      [&](const core::ListRemoved& e) {
        beginRemoveRows({}, e.index, e.index);
        m_rows.erase(m_rows.begin() + e.index);
        endRemoveRows();
      },
      [&](const core::ListInserted& e) {
        beginInsertRows({}, e.index, e.index);
        m_rows.insert(m_rows.begin() + e.index, next[e.index]);
        endInsertRows();
      },
      [&](const core::ListMoved& e) {
        // Qt wants the row it goes before, counted before the move
        beginMoveRows({}, e.from, e.from, {}, e.to > e.from ? e.to + 1 : e.to);
        const auto first = m_rows.begin();
        if (e.from < e.to) {
          std::rotate(first + e.from, first + e.from + 1, first + e.to + 1);
        } else {
          std::rotate(first + e.to, first + e.from, first + e.from + 1);
        }
        endMoveRows();
      },
    };
    std::visit(apply, edit);
  }

  for (int i = 0; i < rowCount(); ++i) {
    const Row& before = m_rows[i];
    const Row& after = next[i];
    QList<int> roles;
    const auto compare = [&]<typename T>(T Row::* member, int role) {
      if (before.*member != after.*member) {
        roles.append(role);
      }
    };
    compare(&Row::name, NameRole);
    compare(&Row::colorKey, ColorKeyRole);
    compare(&Row::recipeCount, RecipeCountRole);
    if (!roles.isEmpty()) {
      m_rows[i] = std::move(next[i]);
      emit dataChanged(index(i), index(i), roles);
    }
  }

  if (rowCount() != countBefore) {
    emit countChanged();
  }
}
