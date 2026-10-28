#pragma once

class PhotoStore;

namespace core {
class Backend;
}

namespace app {

// For debug builds: when the recipe table has no row at all, deleted ones
// included, adds sample recipes that show every part of the recipe screen,
// with their tags, their dictionary ingredients and a painted photo. Throws
// core::DatabaseError if writing fails.
void addSampleRecipes(core::Backend& backend, PhotoStore& photos);

}
