defmodule ExBackoff do
  use Bitwise

  @moduledoc """
  ExBackoff is an Elixir library to deal with exponential backoffs and timers
  to be used within OTP processes when dealing with cyclical events, such as
  reconnections, or generally retrying things.
  """

  @typep max :: pos_integer | :infinity

  defstruct [start: nil,
             max: nil,
             current: nil,
             type: :normal,
             value: nil,
             dest: nil]

  @typedoc """
  struct contain state of the backoff module including the start, current and
  max value. Type of the backoff `:normal` or `:jitter`. Value to send and the
  destination when need to fire off message whe :timeout
  """
  @type backoff :: %__MODULE__{ start: pos_integer,
                                max: max,
                                current: pos_integer,
                                type: :normal | :jitter,
                                value: any,
                                dest: pid}

  @doc """
  Just do the increments by hand!
  """
  @spec increment(pos_integer) :: pos_integer
  def increment(n) when is_integer(n), do: n <<< 1

  @doc """
  Increments the value (but won't excess the max value).
  """
  @spec increment(pos_integer, pos_integer) :: pos_integer
  def increment(n, max), do: min(increment(n), max)

  @doc """
  Just do the random increments by hand!
  Choose delay uniformly from [0.5 * Time, 1.5 * Time] as recommended in:
  Sally Floyd and Van Jacobson, The Synchronization of Periodic Routing Messages,
  April 1994 IEEE/ACM Transactions on Networking.
  http://ee.lbl.gov/papers/sync_94.pdf
  """
  @spec rand_increment(pos_integer) :: pos_integer
  def rand_increment(n) do
    #  New delay chosen from [N, 3N], i.e. [0.5 * 2N, 1.5 * 2N]
    width = n <<< 1
    n + :random.uniform(width + 1) - 1
  end

  @doc """
  Do the random increments. It wont excess the max value
  """
  @spec rand_increment(pos_integer, pos_integer) :: pos_integer
  def rand_increment(n, max) do
    # The largest interval for [0.5 * Time, 1.5 * Time] with maximum Max is
    # [Max div 3, Max].
    max_min_delay = div max, 3
    cond do
      max_min_delay === 0 ->
        :random.uniform(max)
      n > max_min_delay ->
        rand_increment(max_min_delay)
      true ->
        rand_increment(n)
    end
  end

  # Increments + Timer support

  @doc """
  init function when the user doesn't feel like using a timer
  provided by this library
  """
  @spec init(pos_integer, max) :: backoff
  def init(start, max), do: init(start, max, :nil, :nil)

  @doc """
  init function when the user feels like using a timer
  provided by this library
  """
  @spec init(pos_integer, max, pid | nil, any | nil) :: backoff
  def init(start, max, dest, value) do
    %ExBackoff{start: start, current: start, max: max, value: value, dest: dest}
  end

  @doc """
  Starts a timer from the `backoff()' argument, using erlang:start_timer/3.
  No reference tracking is done, and this is left to the user. This function
  is purely a convenience function.
  """
  @spec fire(backoff) :: reference
  def fire(%ExBackoff{current: delay, value: value, dest: dest}) do
    :erlang.start_timer(delay, dest, value)
  end

  @doc """
  Reads the current backoff value.
  """
  @spec get(backoff) :: pos_integer
  def get(%ExBackoff{current: delay}), do: delay

  @doc """
  Swaps between the states of the backoff.
  """
  @spec type(backoff, :normal | :jitter) :: backoff
  def type(b = %ExBackoff{}, :jitter), do: %{b | type: :jitter}
  def type(b = %ExBackoff{}, :normal), do: %{b | type: :normal}

  @doc """
  Increments the value and return the new state with the `new_delay`
  """
  @spec fail(backoff) :: {pos_integer, backoff}
  def fail(b = %ExBackoff{current: delay, max: :infinity, type: :normal}) do
    new_delay = increment(delay)
    {new_delay,  %{b | current: new_delay}}
  end
  def fail(b = %ExBackoff{current: delay, max: max, type: :normal}) do
    new_delay = increment(delay, max)
    {new_delay, %{b | current: new_delay}}
  end
  def fail(b = %ExBackoff{current: delay, max: :infinity, type: :jitter}) do
    new_delay = rand_increment(delay)
    {new_delay, %{b | current: new_delay}}
  end
  def fail(b = %ExBackoff{current: delay, max: max, type: :jitter}) do
    new_delay = rand_increment(delay, max)
    {new_delay, %{b | current: new_delay}}
  end

  @doc """
  resets the values
  """
  @spec succeed(backoff) :: {pos_integer, backoff}
  def succeed(b = %ExBackoff{start: start}) do
    {start, %{b | current: start}}
  end
end
