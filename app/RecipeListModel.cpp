#include "RecipeListModel.hpp"

#include "Overloaded.hpp"
#include "appBackend.hpp"
#include "collation.hpp"
#include "core/Backend.hpp"
#include "core/Database.hpp"
#include "core/listEdits.hpp"
#include "core/recipeView.hpp"

#include <algorithm>
#include <stdexcept>
#include <string>
#include <utility>
#include <variant>

// Exceptions can't cross into QML. A failed write leaves memory unchanged, so
// the UI stays consistent and only has to report that saving failed. The store
// throws logic errors before changing anything, e.g. for an id QML kept after
// it went stale.
static RecipeListModel::Error guarded(auto&& action)
{
  try {
    action();
    return RecipeListModel::Error::NoError;
  } catch (const core::DatabaseError& error) {
    qCritical("Saving recipes failed: %s", error.what());
    return RecipeListModel::Error::StorageFailed;
  } catch (const std::logic_error& error) {
    qWarning("RecipeListModel: %s", error.what());
    return RecipeListModel::Error::InvalidRequest;
  }
}

RecipeListModel::RecipeListModel(QObject* parent)
  : RecipeListModel(app::backend().recipes(), parent)
{
}

RecipeListModel::RecipeListModel(core::RecipeStore& store, QObject* parent)
  : QAbstractListModel(parent)
  , m_store(store)
  , m_collator(app::nameCollator())
{
  m_rows = computeRows();
  m_store.addObserver(*this);
}

RecipeListModel::~RecipeListModel()
{
  m_store.removeObserver(*this);
}

int RecipeListModel::rowCount(const QModelIndex& parent) const
{
  return parent.isValid() ? 0 : static_cast<int>(m_rows.size());
}

QVariant RecipeListModel::data(const QModelIndex& index, int role) const
{
  if (!checkIndex(index,
                  CheckIndexOption::IndexIsValid |
                    CheckIndexOption::ParentIsInvalid)) {
    return {};
  }

  const Row& row = m_rows[index.row()];
  switch (role) {
    case RecipeIdRole:
      return row.recipeId;
    case TitleRole:
      return row.title;
  }
  return {};
}

QHash<int, QByteArray> RecipeListModel::roleNames() const
{
  return { { RecipeIdRole, "recipeId" }, { TitleRole, "title" } };
}

RecipeListModel::Error RecipeListModel::restore(const QString& recipeId)
{
  return guarded([&] { m_store.restore(recipeId.toStdString()); });
}

void RecipeListModel::recipeAboutToChange(const core::RecipeChange&) noexcept {}

void RecipeListModel::recipeChanged(const core::RecipeChange&) noexcept
{
  refresh();
}

std::vector<RecipeListModel::Row> RecipeListModel::computeRows() const
{
  const std::vector<core::Recipe>& recipes = m_store.recipes();
  std::vector<Row> rows;
  rows.reserve(recipes.size());
  for (const int index :
       core::recipesByTitle(recipes, app::nameLess(m_collator))) {
    const core::Recipe& recipe = recipes[index];
    rows.push_back({ QString::fromStdString(recipe.id),
                     QString::fromStdString(recipe.title) });
  }
  return rows;
}

void RecipeListModel::refresh()
{
  std::vector<Row> next = computeRows();
  const auto ids = [](const std::vector<Row>& rows) {
    std::vector<std::string> result;
    result.reserve(rows.size());
    for (const Row& row : rows) {
      result.push_back(row.recipeId.toStdString());
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
    if (m_rows[i].title != next[i].title) {
      m_rows[i] = std::move(next[i]);
      emit dataChanged(index(i), index(i), { TitleRole });
    }
  }

  if (rowCount() != countBefore) {
    emit countChanged();
  }
}
