#include "core/recipeView.hpp"
#include "testSupport.hpp"

#include <doctest/doctest.h>

#include <string>
#include <vector>

using namespace std::chrono_literals;
using core::CookedAge;
using Period = core::CookedAge::Period;
using core::StepAmount;
using core::StepSegment;
using core::Unit;

namespace {

core::RecipeIngredient line(std::string id,
                            std::optional<double> quantity,
                            std::optional<std::string> parentId = {})
{
  return { std::move(id),
           std::move(parentId),
           "Name",
           "dictionary-id",
           quantity,
           quantity ? std::optional<core::RecipeUnit>(Unit::Cloves)
                    : std::nullopt,
           std::nullopt,
           false };
}

core::StepMention mention(std::string ingredientId,
                          int start,
                          int length,
                          std::optional<double> quantity = {})
{
  return { "mention-id", std::move(ingredientId), start, length, quantity };
}

// Garlic (2 cloves) with a substitute, salt (to taste), oil (3 tbsp)
core::Recipe recipe()
{
  core::Recipe recipe;
  recipe.ingredients = { line("garlic", 2),
                         line("shallot", 1, "garlic"),
                         line("salt", std::nullopt),
                         line("oil", 3) };
  return recipe;
}

core::Step step(std::string text, std::vector<core::StepMention> mentions)
{
  return { "step-id", std::move(text), std::move(mentions) };
}

bool byteLess(std::string_view a, std::string_view b)
{
  return a < b;
}

std::chrono::year_month_day daysBefore(std::chrono::year_month_day date,
                                       int days)
{
  return std::chrono::sys_days(date) - std::chrono::days(days);
}

}

TEST_CASE("A step's text is cut at its mentions, keeping every character")
{
  // "Émincez l’ail et l’huile": É and ’ take more than one byte
  const core::Step text =
    step("\xc3\x89mincez l\xe2\x80\x99"
         "ail et l\xe2\x80\x99huile",
         { mention("garlic", 8, 5), mention("oil", 17, 7) });

  CHECK(core::stepSegments(recipe(), text) ==
        std::vector<StepSegment>{ { "\xc3\x89mincez " },
                                  { "l\xe2\x80\x99"
                                    "ail",
                                    true },
                                  { " et " },
                                  { "l\xe2\x80\x99huile", true } });
}

TEST_CASE("A step without mentions is one plain segment")
{
  CHECK(core::stepSegments(recipe(), step("Bake for an hour.", {})) ==
        std::vector<StepSegment>{ { "Bake for an hour." } });
  CHECK(
    core::stepSegments(recipe(), step("Garlic", { mention("garlic", 0, 6) })) ==
    std::vector<StepSegment>{ { "Garlic", true } });
}

TEST_CASE("Mentions of a substitute or an unknown ingredient are plain text")
{
  const core::Step text =
    step("Add the shallot and the herbs.",
         { mention("shallot", 8, 7), mention("deleted", 24, 5) });
  CHECK(core::stepSegments(recipe(), text) ==
        std::vector<StepSegment>{ { "Add the shallot and the herbs." } });
  CHECK(core::stepAmounts(recipe(), text).empty());
}

TEST_CASE("Step amounts: an ingredient split across steps")
{
  const core::Step first =
    step("Crush a garlic clove.", { mention("garlic", 8, 12, 1) });
  const core::Step second = step("Rub the dish with the remaining garlic.",
                                 { mention("garlic", 18, 20, 1) });

  CHECK(core::stepAmounts(recipe(), first) ==
        std::vector<StepAmount>{ { 0, 1.0 } });
  CHECK(core::stepAmounts(recipe(), second) ==
        std::vector<StepAmount>{ { 0, 1.0 } });
}

TEST_CASE("Step amounts: mentions of one ingredient add up")
{
  const core::Step text =
    step("Add half the oil, then the rest of the oil.",
         { mention("oil", 4, 12, 1.5), mention("oil", 23, 19, 1.5) });
  CHECK(core::stepAmounts(recipe(), text) ==
        std::vector<StepAmount>{ { 3, 3.0 } });
}

TEST_CASE("Step amounts: a mention without quantity uses all of it")
{
  const core::Step text = step("Add the oil.", { mention("oil", 4, 7) });
  CHECK(core::stepAmounts(recipe(), text) ==
        std::vector<StepAmount>{ { 3, 3.0 } });

  // It adds to the other mentions
  const core::Step twice =
    step("Add oil, then more oil.",
         { mention("oil", 4, 3, 1), mention("oil", 19, 3) });
  CHECK(core::stepAmounts(recipe(), twice) ==
        std::vector<StepAmount>{ { 3, 4.0 } });
}

TEST_CASE("Step amounts: an ingredient without quantity is to taste")
{
  const core::Step text =
    step("Season with salt, then salt again.",
         { mention("salt", 12, 4, 1), mention("salt", 23, 4) });
  CHECK(core::stepAmounts(recipe(), text) ==
        std::vector<StepAmount>{ { 2, std::nullopt } });
}

TEST_CASE("Step amounts: one per ingredient, in order of first mention; "
          "dropped mentions skipped")
{
  const core::Step text = step("Oil, garlic, herbs, oil, salt.",
                               { mention("oil", 0, 3, 1),
                                 mention("garlic", 5, 6),
                                 mention("deleted", 13, 5),
                                 mention("oil", 20, 3, 1),
                                 mention("salt", 25, 4) });
  CHECK(core::stepAmounts(recipe(), text) ==
        std::vector<StepAmount>{ { 3, 2.0 }, { 0, 2.0 }, { 2, std::nullopt } });
}

TEST_CASE("The cooked age counts days, weeks, 30-day months, then years")
{
  const std::chrono::year_month_day today = 2026y / 10 / 28;
  const auto age = [&](int days) {
    return core::cookedAge(daysBefore(today, days), today);
  };

  CHECK(age(0) == CookedAge{ Period::Today });
  CHECK(age(-3) == CookedAge{ Period::Today });
  CHECK(age(1) == CookedAge{ Period::Yesterday });
  CHECK(age(2) == CookedAge{ Period::Days, 2 });
  CHECK(age(6) == CookedAge{ Period::Days, 6 });
  CHECK(age(7) == CookedAge{ Period::Weeks, 1 });
  CHECK(age(29) == CookedAge{ Period::Weeks, 4 });
  CHECK(age(30) == CookedAge{ Period::Months, 1 });
  CHECK(age(150) == CookedAge{ Period::Months, 5 });
  CHECK(age(364) == CookedAge{ Period::Months, 12 });
  CHECK(age(365) == CookedAge{ Period::Years, 1 });
  CHECK(age(800) == CookedAge{ Period::Years, 2 });
}

TEST_CASE("Recipes show by title, ties by id")
{
  std::vector<core::Recipe> recipes(3);
  recipes[0].id = "1";
  recipes[0].title = "Toast";
  recipes[1].id = "3";
  recipes[1].title = "Curry";
  recipes[2].id = "2";
  recipes[2].title = "Curry";

  CHECK(core::recipesByTitle(recipes, byteLess) == std::vector{ 2, 1, 0 });
}

TEST_CASE("A recipe shows its live tags by name")
{
  const std::vector<core::Tag> tags{
    { "1", "Weeknight", "weeknight", core::TagFamily::Mint, test::seedTime },
    { "2", "Brunch", "brunch", core::TagFamily::Sky, test::seedTime },
    { "3", "Vegetarian", "vegetarian", core::TagFamily::Peach, test::seedTime }
  };
  core::Recipe tagged;
  // "4" is a deleted tag's: not among the live tags
  tagged.tagIds = { "1", "4", "2" };

  CHECK(core::recipeTags(tagged, tags, byteLess) == std::vector{ 1, 0 });
}
