#include "RecipeModel.hpp"

#include "AmountFormat.hpp"
#include "PhotoStore.hpp"
#include "appBackend.hpp"
#include "collation.hpp"
#include "core/Backend.hpp"
#include "core/Database.hpp"
#include "core/ShownAmount.hpp"
#include "core/recipeView.hpp"

#include <QDate>
#include <QLocale>
#include <QStringList>
#include <QVariantMap>

#include <algorithm>
#include <stdexcept>
#include <utility>

// Exceptions can't cross into QML. A failed write leaves memory unchanged, so
// the UI stays consistent and only has to report that saving failed. The store
// throws logic errors before changing anything, e.g. for a recipe deleted
// meanwhile.
static RecipeModel::Error guarded(auto&& action)
{
  try {
    action();
    return RecipeModel::Error::NoError;
  } catch (const core::DatabaseError& error) {
    qCritical("Saving the recipe failed: %s", error.what());
    return RecipeModel::Error::StorageFailed;
  } catch (const std::logic_error& error) {
    qWarning("RecipeModel: %s", error.what());
    return RecipeModel::Error::InvalidRequest;
  }
}

static QString text(const std::optional<std::string>& value)
{
  return value ? QString::fromStdString(*value) : QString();
}

// The user's local date
static std::chrono::year_month_day today()
{
  const QDate date = QDate::currentDate();
  return { std::chrono::year(date.year()),
           std::chrono::month(static_cast<unsigned>(date.month())),
           std::chrono::day(static_cast<unsigned>(date.day())) };
}

// "40 min", "1 h", "1 h 05"
static QString duration(int minutes)
{
  if (minutes < 60) {
    return RecipeModel::tr("%Ln min", nullptr, minutes);
  }
  const int hours = minutes / 60;
  if (minutes % 60 == 0) {
    return RecipeModel::tr("%Ln h", nullptr, hours);
  }
  return RecipeModel::tr("%1 h %2", "hours, then minutes on two digits")
    .arg(QLocale().toString(hours),
         QStringLiteral("%1").arg(minutes % 60, 2, 10, QLatin1Char('0')));
}

// "or 20 cl crème fraîche, full fat"
static QString alternative(const core::RecipeIngredient& line,
                           const QString& amount)
{
  const QString name = QString::fromStdString(line.name);
  const QString text =
    amount.isEmpty()
      ? RecipeModel::tr("or %1", "a substitute without an amount").arg(name)
      : RecipeModel::tr("or %1 %2", "a substitute's amount, then its name")
          .arg(amount, name);
  if (!line.note) {
    return text;
  }
  return RecipeModel::tr("%1, %2", "a substitute, then its note")
    .arg(text, QString::fromStdString(*line.note));
}

RecipeModel::RecipeModel(QObject* parent)
  : RecipeModel(app::backend().recipes(),
                app::backend().tags(),
                app::backend().settings(),
                app::photoStore(),
                parent)
{
}

RecipeModel::RecipeModel(core::RecipeStore& recipes,
                         core::TagStore& tags,
                         core::SettingStore& settings,
                         const PhotoStore& photos,
                         QObject* parent)
  : QObject(parent)
  , m_recipes(recipes)
  , m_tagStore(tags)
  , m_settings(settings)
  , m_photos(photos)
  , m_collator(app::nameCollator())
  , m_unitSystem(core::unitSystem(settings))
  , m_ingredientRows({ "quantity", "name", "optional", "note", "alternatives" })
  , m_stepRows({ "number", "segments", "amounts" })
{
  m_recipes.addObserver(*this);
  m_tagStore.addObserver(*this);
  m_settings.addObserver(*this);
}

RecipeModel::~RecipeModel()
{
  m_settings.removeObserver(*this);
  m_tagStore.removeObserver(*this);
  m_recipes.removeObserver(*this);
}

QString RecipeModel::recipeId() const
{
  return QString::fromStdString(m_recipe.id);
}

void RecipeModel::setRecipeId(const QString& recipeId)
{
  const std::string id = recipeId.toStdString();
  if (id == m_recipe.id) {
    return;
  }
  const auto& recipes = m_recipes.recipes();
  const auto it = std::ranges::find(recipes, id, &core::Recipe::id);
  if (it != recipes.end()) {
    m_recipe = *it;
  } else {
    qWarning("RecipeModel: no live recipe with id %s", qPrintable(recipeId));
    m_recipe = {};
    m_recipe.id = id;
  }
  m_servings = std::clamp(m_recipe.baseServings, 1, maxServings());
  m_cookedBefore.reset();
  m_tags = computeTags();
  updateRows();

  emit recipeIdChanged();
  emit fieldsChanged();
  emit tagsChanged();
  emit favoriteChanged();
  emit servingsChanged();
  emit cookingHistoryChanged();
}

QString RecipeModel::title() const
{
  return QString::fromStdString(m_recipe.title);
}

QString RecipeModel::description() const
{
  return text(m_recipe.description);
}

QUrl RecipeModel::photo() const
{
  return m_photos.url(text(m_recipe.photoId));
}

QString RecipeModel::initial() const
{
  const QList<uint> codePoints = title().toUcs4();
  const auto it = std::ranges::find_if(
    codePoints, [](uint c) { return QChar::isLetterOrNumber(c); });
  if (it == codePoints.end()) {
    return {};
  }
  const char32_t letter = *it;
  return QLocale().toUpper(QString::fromUcs4(&letter, 1));
}

void RecipeModel::setServings(int servings)
{
  servings = std::clamp(servings, 1, maxServings());
  if (servings == m_servings) {
    return;
  }
  m_servings = servings;
  updateRows();
  emit servingsChanged();
}

QString RecipeModel::prepTime() const
{
  return m_recipe.prepMinutes ? duration(*m_recipe.prepMinutes) : QString();
}

QString RecipeModel::cookTime() const
{
  return m_recipe.cookMinutes ? duration(*m_recipe.cookMinutes) : QString();
}

QString RecipeModel::costPerServing() const
{
  if (!m_recipe.costCents) {
    return {};
  }
  const double euros = static_cast<double>(*m_recipe.costCents) / 100 /
                       std::max(1, m_recipe.baseServings);
  // Costs are in euros, whatever the locale: only the format follows it
  return QLocale().toCurrencyString(euros, QString(QChar(0x20ac)));
}

QString RecipeModel::cookedCount() const
{
  if (m_recipe.cookCount == 0) {
    return tr("Never");
  }
  return tr("%Ln×", "times cooked", m_recipe.cookCount);
}

QString RecipeModel::lastCooked() const
{
  if (m_recipe.cookCount == 0 || !m_recipe.lastCooked) {
    return {};
  }
  using Period = core::CookedAge::Period;
  const core::CookedAge age = core::cookedAge(*m_recipe.lastCooked, today());
  switch (age.period) {
    case Period::Today:
      return tr("Today");
    case Period::Yesterday:
      return tr("Yesterday");
    case Period::Days:
      return tr("%Ln d ago", nullptr, age.count);
    case Period::Weeks:
      return tr("%Ln wk ago", nullptr, age.count);
    case Period::Months:
      return tr("%Ln mo ago", nullptr, age.count);
    case Period::Years:
      return tr("%Ln yr ago", nullptr, age.count);
  }
  std::unreachable();
}

QString RecipeModel::notes() const
{
  return text(m_recipe.notes);
}

QString RecipeModel::source() const
{
  return text(m_recipe.source);
}

QUrl RecipeModel::sourceUrl() const
{
  if (!m_recipe.source) {
    return {};
  }
  const QUrl url(QString::fromStdString(*m_recipe.source), QUrl::StrictMode);
  const QString scheme = url.scheme();
  const bool web = scheme == u"http" || scheme == u"https";
  return url.isValid() && web && !url.host().isEmpty() ? url : QUrl();
}

QString RecipeModel::sourceHost() const
{
  QString host = sourceUrl().host();
  if (host.startsWith(QLatin1StringView("www."))) {
    host.remove(0, 4);
  }
  return host;
}

RecipeModel::Error RecipeModel::setFavorite(bool favorite)
{
  return guarded([&] { m_recipes.setFavorite(m_recipe.id, favorite); });
}

RecipeModel::Error RecipeModel::markCooked()
{
  return guarded(
    [&] { m_cookedBefore = m_recipes.markCooked(m_recipe.id, today()); });
}

RecipeModel::Error RecipeModel::undoCooked()
{
  if (!m_cookedBefore) {
    qWarning("RecipeModel: nothing to undo");
    return Error::InvalidRequest;
  }
  const Error error =
    guarded([&] { m_recipes.setCookingHistory(m_recipe.id, *m_cookedBefore); });
  if (error == Error::NoError) {
    m_cookedBefore.reset();
  }
  return error;
}

RecipeModel::Error RecipeModel::remove()
{
  return guarded([&] { m_recipes.remove(m_recipe.id); });
}

void RecipeModel::recipeAboutToChange(const core::RecipeChange&) noexcept {}

void RecipeModel::recipeChanged(const core::RecipeChange&) noexcept
{
  const auto& recipes = m_recipes.recipes();
  const auto it = std::ranges::find(recipes, m_recipe.id, &core::Recipe::id);
  // Deleted: it keeps showing as it was
  if (it == recipes.end() || *it == m_recipe) {
    return;
  }

  const core::Recipe before = std::exchange(m_recipe, *it);
  if (m_recipe.favorite != before.favorite) {
    emit favoriteChanged();
  }
  if (m_recipe.cookCount != before.cookCount ||
      m_recipe.lastCooked != before.lastCooked) {
    emit cookingHistoryChanged();
  }
  // Anything else: it came back from a deletion, possibly changed
  core::Recipe rest = before;
  rest.favorite = m_recipe.favorite;
  rest.cookCount = m_recipe.cookCount;
  rest.lastCooked = m_recipe.lastCooked;
  rest.modifiedAt = m_recipe.modifiedAt;
  if (rest != m_recipe) {
    m_tags = computeTags();
    updateRows();
    emit fieldsChanged();
    emit tagsChanged();
  }
}

void RecipeModel::tagAboutToChange(const core::TagChange&) noexcept {}

void RecipeModel::tagChanged(const core::TagChange&) noexcept
{
  QVariantList tags = computeTags();
  if (tags != m_tags) {
    m_tags = std::move(tags);
    emit tagsChanged();
  }
}

void RecipeModel::settingAboutToChange(std::string_view) noexcept {}

void RecipeModel::settingChanged(std::string_view) noexcept
{
  const core::UnitSystem system = core::unitSystem(m_settings);
  if (system != m_unitSystem) {
    m_unitSystem = system;
    updateRows();
  }
}

QVariantList RecipeModel::computeTags() const
{
  QVariantList result;
  const std::vector<core::Tag>& tags = m_tagStore.tags();
  for (const int index :
       core::recipeTags(m_recipe, tags, app::nameLess(m_collator))) {
    const core::Tag& tag = tags[index];
    const std::string_view key = core::tagFamilyCode(tag.color);
    result.append(QVariantMap{
      { QStringLiteral("name"), QString::fromStdString(tag.name) },
      { QStringLiteral("colorKey"),
        QString::fromUtf8(key.data(), static_cast<qsizetype>(key.size())) } });
  }
  return result;
}

void RecipeModel::updateRows()
{
  const core::Servings servings{ m_servings,
                                 std::max(1, m_recipe.baseServings) };
  const auto shown = [&](std::optional<double> quantity,
                         const std::optional<core::RecipeUnit>& unit) {
    return app::formatShownAmount(
      core::shownAmount(quantity, unit, servings, m_unitSystem));
  };

  // A main ingredient's substitutes follow it
  const std::vector<core::RecipeIngredient>& lines = m_recipe.ingredients;
  std::vector<QVariantList> ingredients;
  for (std::size_t i = 0; i < lines.size(); ++i) {
    const core::RecipeIngredient& line = lines[i];
    if (line.parentId) {
      continue;
    }
    QStringList alternatives;
    for (std::size_t j = i + 1; j < lines.size() && lines[j].parentId; ++j) {
      alternatives.append(
        alternative(lines[j], shown(lines[j].quantity, lines[j].unit)));
    }
    ingredients.push_back({ shown(line.quantity, line.unit),
                            QString::fromStdString(line.name),
                            line.optional,
                            text(line.note),
                            alternatives });
  }
  m_ingredientRows.setRows(std::move(ingredients));

  std::vector<QVariantList> steps;
  for (std::size_t i = 0; i < m_recipe.steps.size(); ++i) {
    const core::Step& step = m_recipe.steps[i];
    QVariantList segments;
    for (const core::StepSegment& segment :
         core::stepSegments(m_recipe, step)) {
      segments.append(QVariantMap{
        { QStringLiteral("text"), QString::fromStdString(segment.text) },
        { QStringLiteral("ingredient"), segment.mention } });
    }
    QVariantList amounts;
    for (const core::StepAmount& amount : core::stepAmounts(m_recipe, step)) {
      const core::RecipeIngredient& line = lines[amount.ingredient];
      amounts.append(QVariantMap{
        { QStringLiteral("quantity"), shown(amount.quantity, line.unit) },
        { QStringLiteral("name"), QString::fromStdString(line.name) } });
    }
    steps.push_back(
      { QLocale().toString(static_cast<int>(i) + 1), segments, amounts });
  }
  m_stepRows.setRows(std::move(steps));
}
