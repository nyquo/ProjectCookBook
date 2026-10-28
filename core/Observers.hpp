#pragma once

#include <algorithm>
#include <vector>

namespace core {

// A store's observers, and the two calls every store makes for a change: each
// observer gets `before` while memory still holds the old state, memory
// changes, then each one still registered gets `after`. Observers may register
// or unregister others while notified: one registered by the end of the
// `before` calls saw the old state, so it gets both calls; one registered
// during the `after` calls gets neither.
template<typename Observer>
class Observers
{
public:
  // Not owned: an observer must unregister before it's destroyed
  void add(Observer& observer) { m_observers.push_back(&observer); }
  void remove(Observer& observer) { std::erase(m_observers, &observer); }

  // True during notify(): memory is mid-change, so a nested write would act on
  // stale state
  bool notifying() const { return m_notifying; }

  // noexcept: the write has committed, so if memory or an observer can't
  // follow, terminating beats running on, out of sync; the next launch reloads
  // the database.
  template<typename Before, typename Mutation, typename After>
  void notify(Before before, Mutation mutate, After after) noexcept
  {
    m_notifying = true;
    std::vector<Observer*> notified;
    const auto nextToNotify = [&]() -> Observer* {
      for (Observer* observer : m_observers) {
        if (std::ranges::find(notified, observer) == notified.end()) {
          return observer;
        }
      }
      return nullptr;
    };
    while (Observer* observer = nextToNotify()) {
      notified.push_back(observer);
      before(*observer);
    }
    mutate();
    for (Observer* observer : notified) {
      if (std::ranges::find(m_observers, observer) != m_observers.end()) {
        after(*observer);
      }
    }
    m_notifying = false;
  }

private:
  std::vector<Observer*> m_observers;
  bool m_notifying = false;
};

}
