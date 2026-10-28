#include "sampleRecipes.hpp"

#include "PhotoStore.hpp"
#include "core/Backend.hpp"
#include "core/text.hpp"

#include <QColor>
#include <QDate>
#include <QImage>
#include <QLinearGradient>
#include <QPainter>
#include <QRadialGradient>
#include <QRandomGenerator>

#include <algorithm>
#include <initializer_list>
#include <stdexcept>

using core::Unit;

// Words of a step's text that name an ingredient
struct SampleMention
{
  std::string_view words;
  // In the draft's ingredients
  int ingredient;
  std::optional<double> quantity = std::nullopt;
};

// A step whose mentions are found by their words in the text
static core::StepDraft step(std::string text,
                            std::initializer_list<SampleMention> mentions)
{
  core::StepDraft draft{ std::move(text) };
  const std::string_view whole = draft.text;
  for (const SampleMention& mention : mentions) {
    const std::size_t at = whole.find(mention.words);
    if (at == std::string_view::npos) {
      qWarning("Sample recipes: no \"%s\" in a step",
               std::string(mention.words).c_str());
      continue;
    }
    draft.mentions.push_back(
      { mention.ingredient,
        static_cast<int>(core::codePointCount(whole.substr(0, at))),
        static_cast<int>(core::codePointCount(mention.words)),
        mention.quantity });
  }
  return draft;
}

// The live tag with this name; created if there's none
static std::string tagId(core::TagStore& tags, std::string_view name)
{
  const std::string canonical = core::canonicalName(name);
  const auto& all = tags.tags();
  const auto it = std::ranges::find(all, canonical, &core::Tag::canonicalName);
  if (it != all.end()) {
    return it->id;
  }
  return tags.create(name).value_or(std::string());
}

static std::chrono::year_month_day localDate(const QDate& date)
{
  return { std::chrono::year(date.year()),
           std::chrono::month(static_cast<unsigned>(date.month())),
           std::chrono::day(static_cast<unsigned>(date.day())) };
}

// A stand-in for a photo of a gratin: a warm gradient under golden and browned
// spots. The fixed seed paints the same picture, so the same file, each time.
static QImage paintedPhoto()
{
  QImage image(1600, 1200, QImage::Format_RGB32);
  QPainter painter(&image);
  painter.setRenderHint(QPainter::Antialiasing);
  QLinearGradient background(0, 0, image.width(), image.height());
  background.setColorAt(0, QColor(0xf3, 0xc5, 0x6b));
  background.setColorAt(0.6, QColor(0xd8, 0x86, 0x2e));
  background.setColorAt(1, QColor(0x93, 0x45, 0x16));
  painter.fillRect(image.rect(), background);

  QRandomGenerator random(7);
  painter.setPen(Qt::NoPen);
  for (int i = 0; i < 90; ++i) {
    const QPointF center(random.bounded(image.width()),
                         random.bounded(image.height()));
    const qreal radius = 40 + random.bounded(110);
    const QColor tone = i % 3 == 0 ? QColor(0x7a, 0x34, 0x0e, 110)
                                   : QColor(0xfd, 0xe6, 0xa8, 120);
    QRadialGradient spot(center, radius);
    spot.setColorAt(0, tone);
    spot.setColorAt(1, QColor(tone.red(), tone.green(), tone.blue(), 0));
    painter.setBrush(spot);
    painter.drawEllipse(center, radius, radius);
  }
  painter.end();
  return image;
}

// Logs instead of throwing: a bad sample shouldn't keep the app from starting
static void add(core::RecipeStore& recipes, const core::RecipeDraft& draft)
{
  try {
    if (!recipes.create(draft)) {
      qWarning("Sample recipes: \"%s\" is invalid", draft.title.c_str());
    }
  } catch (const std::logic_error& error) {
    qWarning("Sample recipes: \"%s\": %s", draft.title.c_str(), error.what());
  }
}

// A photo, three tags of different colors, a cost, a cooking history, notes,
// a plain-text source; an optional ingredient, one with a note, two without a
// quantity, a substitute; kg, cl, g, clove and pinch; the garlic split across
// two steps, a mention without a quantity, a step without mentions
static core::RecipeDraft gratin(core::TagStore& tags, PhotoStore& photos)
{
  core::RecipeDraft draft;
  draft.title = "Gratin dauphinois";
  draft.description = "Thin slices of potato baked slowly in cream and "
                      "garlic until golden on top.";
  const QString photo = photos.save(paintedPhoto());
  if (!photo.isEmpty()) {
    draft.photoId = photo.toStdString();
  }
  draft.baseServings = 6;
  draft.prepMinutes = 20;
  draft.cookMinutes = 75;
  draft.costCents = 850;
  draft.source = "Mémé Jeanne's notebook";
  draft.notes = "Keep the slices the same thickness so they cook evenly. It "
                "keeps two days in the fridge; reheat it covered.";
  draft.cookCount = 4;
  draft.lastCooked = localDate(QDate::currentDate().addDays(-150));
  draft.ingredients = {
    { .name = "Potatoes",
      .quantity = 1.2,
      .unit = Unit::Kilograms,
      .note = "Firm-fleshed, such as Charlotte" },
    { .name = "Whole milk", .quantity = 50, .unit = Unit::Centiliters },
    { .name = "Heavy cream", .quantity = 20, .unit = Unit::Centiliters },
    { .name = "crème fraîche",
      .quantity = 20,
      .unit = Unit::Centiliters,
      .substituteFor = 2 },
    { .name = "Garlic", .quantity = 2, .unit = Unit::Cloves },
    { .name = "Butter", .quantity = 30, .unit = Unit::Grams },
    { .name = "Gruyère",
      .quantity = 80,
      .unit = Unit::Grams,
      .optional = true },
    { .name = "Nutmeg", .quantity = 1, .unit = Unit::Pinches },
    { .name = "Salt" },
    { .name = "Black pepper" },
  };
  draft.steps = {
    step("Heat the oven to 160 °C. Peel the potatoes and slice them thin; "
         "don't rinse them, their starch thickens the cream.",
         { { "potatoes", 0 } }),
    step("Bring the milk and the cream to a simmer with a crushed garlic "
         "clove, the nutmeg, salt and pepper.",
         { { "milk", 1 },
           { "cream", 2 },
           { "garlic clove", 4, 1 },
           { "nutmeg", 7 },
           { "salt", 8 },
           { "pepper", 9 } }),
    step("Rub the dish with the remaining garlic, then butter it generously.",
         { { "the remaining garlic", 4, 1 }, { "butter", 5 } }),
    step("Layer the slices in the dish, pour the hot cream over them and "
         "scatter the cheese on top.",
         { { "the cheese", 6 } }),
    step("Bake for 1 h 15, until golden and tender. Let it rest 10 minutes "
         "before serving.",
         {}),
  };
  draft.tagIds = { tagId(tags, "Vegetarian"),
                   tagId(tags, "Oven"),
                   tagId(tags, "Sunday") };
  return draft;
}

// No photo, never cooked, no cost, no notes; tsp, tbsp and can; a link as its
// source; the same ingredient mentioned twice in one step
static core::RecipeDraft curry(core::TagStore& tags)
{
  core::RecipeDraft draft;
  draft.title = "Chickpea and spinach curry";
  draft.description = "A weeknight curry from the pantry, simmered in spiced "
                      "coconut milk.";
  draft.baseServings = 4;
  draft.prepMinutes = 10;
  draft.cookMinutes = 25;
  draft.source = "https://www.example.com/recipes/chickpea-spinach-curry";
  draft.ingredients = {
    { .name = "Olive oil", .quantity = 1, .unit = Unit::Tablespoons },
    { .name = "Onion", .quantity = 1, .unit = Unit::Pieces },
    { .name = "Curry powder", .quantity = 2, .unit = Unit::Tablespoons },
    { .name = "Ground cumin", .quantity = 1, .unit = Unit::Teaspoons },
    { .name = "Chickpeas",
      .quantity = 2,
      .unit = Unit::Cans,
      .note = "Drained" },
    { .name = "Coconut milk", .quantity = 1, .unit = Unit::Cans },
    { .name = "Spinach", .quantity = 200, .unit = Unit::Grams },
    { .name = "Salt" },
  };
  draft.steps = {
    step("Warm the oil in a large pan and soften the chopped onion for 5 "
         "minutes.",
         { { "the oil", 0 }, { "the chopped onion", 1 } }),
    step("Stir in half the curry powder and the cumin, cook for a minute, "
         "then add the rest of the curry powder.",
         { { "half the curry powder", 2, 1 },
           { "the cumin", 3 },
           { "the rest of the curry powder", 2, 1 } }),
    step("Add the chickpeas and the coconut milk, then simmer for 15 minutes.",
         { { "the chickpeas", 4 }, { "the coconut milk", 5 } }),
    step("Stir in the spinach until it wilts, and season with salt.",
         { { "the spinach", 6 }, { "salt", 7 } }),
  };
  draft.tagIds = { tagId(tags, "Weeknight"), tagId(tags, "Vegetarian") };
  return draft;
}

// US units: cups, oz, lb, fl oz; a free-text unit; an ingredient with two
// substitutes; no tags; a cook time only
static core::RecipeDraft pancakes()
{
  core::RecipeDraft draft;
  draft.title = "Blueberry pancakes";
  draft.description = "Fluffy buttermilk pancakes for a slow morning.";
  draft.baseServings = 4;
  draft.cookMinutes = 20;
  draft.ingredients = {
    { .name = "Flour", .quantity = 2, .unit = Unit::Cups },
    { .name = "Sugar", .quantity = 2, .unit = Unit::Tablespoons },
    { .name = "Baking powder", .quantity = 2, .unit = Unit::Teaspoons },
    { .name = "Buttermilk", .quantity = 16, .unit = Unit::FluidOunces },
    { .name = "milk",
      .quantity = 16,
      .unit = Unit::FluidOunces,
      .note = "with 1 tbsp lemon juice",
      .substituteFor = 3 },
    { .name = "plain yogurt",
      .quantity = 1.5,
      .unit = Unit::Cups,
      .note = "thinned with a little milk",
      .substituteFor = 3 },
    { .name = "Eggs", .quantity = 2, .unit = Unit::Pieces },
    { .name = "Butter", .quantity = 2, .unit = Unit::Ounces, .note = "Melted" },
    { .name = "Blueberries",
      .quantity = 2,
      .unit = core::RecipeUnit(std::string("handfuls")) },
    { .name = "Bacon",
      .quantity = 1,
      .unit = Unit::Pounds,
      .note = "To serve",
      .optional = true },
  };
  draft.steps = {
    step(
      "Whisk the flour, the sugar and the baking powder in a large bowl.",
      { { "the flour", 0 }, { "the sugar", 1 }, { "the baking powder", 2 } }),
    step("In another bowl, beat the buttermilk with the eggs and the melted "
         "butter.",
         { { "the buttermilk", 3 },
           { "the eggs", 6 },
           { "the melted butter", 7 } }),
    step("Fold the wet mix into the dry one, then the blueberries. A few lumps "
         "are fine.",
         { { "the blueberries", 8 } }),
    step("Cook ladlefuls in a hot pan, about 2 minutes a side. Serve with the "
         "bacon.",
         { { "the bacon", 9 } }),
  };
  return draft;
}

// A title, one serving, one ingredient in pieces, no steps
static core::RecipeDraft toast()
{
  core::RecipeDraft draft;
  draft.title = "Toast";
  draft.baseServings = 1;
  draft.ingredients = {
    { .name = "Slices of sourdough", .quantity = 2, .unit = Unit::Pieces },
  };
  return draft;
}

void app::addSampleRecipes(core::Backend& backend, PhotoStore& photos)
{
  core::RecipeStore& recipes = backend.recipes();
  if (recipes.hasRows()) {
    return;
  }
  core::TagStore& tags = backend.tags();
  add(recipes, gratin(tags, photos));
  add(recipes, curry(tags));
  add(recipes, pancakes());
  add(recipes, toast());
}
