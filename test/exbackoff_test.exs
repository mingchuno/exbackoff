defmodule ExbackoffTest do
  use ExUnit.Case, async: false
  use ExCheck
  doctest Exbackoff

  @doc """
  Increment operations are always returning bigger
  and bigger values, assuming positive integers
  """
  property :increment_increases do
    for_all x in pos_integer, do: Exbackoff.increment(x) > x
  end

  @doc """
  increments should never go higher than the max
  value allowed.
  """
  property :increment_ceiled_increases do
    for_all {x, y} in such_that({xx, yy} in {pos_integer, pos_integer} when xx < yy) do
      Exbackoff.increment(x, y) <= y
      and
      (Exbackoff.increment(x, y) > x or
        (Exbackoff.increment(x, y) === x and x === y))
    end
  end

  @doc """
  random increment operations are always returning bigger
  and bigger values, assuming positive integers
  """
  property :rand_increment_increases do
    for_all x in pos_integer do
      delay = Exbackoff.rand_increment(x)
      delay >= x and x * 3 >= delay
    end
  end

  @doc """
  random increments should never go higher than the max
  value allowed.
  """
  property :rand_increment_ceiled_increases do
    for_all {x, y} in such_that({xx, yy} in {pos_integer, pos_integer} when xx < yy) do
      delay = Exbackoff.rand_increment(x, y)
      delay <= y and
      x * 3 >= delay and
      (delay >= x or
        (x > div(y,3) and delay >= div(y,3) and delay >= 1)
      )
    end
  end

end
