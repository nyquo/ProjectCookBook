#pragma once

// One callable from several lambdas, for std::visit
template<typename... Handlers>
struct Overloaded : Handlers...
{
  using Handlers::operator()...;
};
