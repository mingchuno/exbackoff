# Exbackoff

[![Build Status](https://travis-ci.org/mingchuno/exbackoff.svg?branch=master)](https://travis-ci.org/mingchuno/exbackoff)
[![Hex Version](http://img.shields.io/hexpm/v/exbackoff.svg)](https://hex.pm/packages/exbackoff)
[![Inline docs](http://inch-ci.org/github/mingchuno/exbackoff.svg?branch=master)](http://inch-ci.org/github/mingchuno/exbackoff)

Exbackoff is an Erlang library to deal with exponential backoffs and timers to
be used within OTP processes when dealing with cyclical events, such as
reconnections, or generally retrying things. This is port of Erlang counterpart
in [ferd/backoff](https://github.com/ferd/backoff).

## Installation

[Available in Hex](https://hex.pm/packages/exbackoff), the package can be installed as:

  1. Add exbackoff to your list of dependencies in `mix.exs`:

        [{:exbackoff, "~> 0.1.0"}]

  2. Ensure exbackoff is started before your application:

        [applications: [:exbackoff]]


## Modes of Operation

Backoff can be used in 3 main ways:

1. a simple way to calculate exponential backoffs
2. calculating exponential backoffs with caps and state tracking
3. using it to fire timeout events

## Simple Backoffs

Simple backoffs work by calling the functions `increment/1-2`. The function
with one argument will grow in an unbounded manner:

    1> 1 |> Exbackoff.increment
    2
    2> 1 |> Exbackoff.increment |> Exbackoff.increment
    4
    3> 1 |> Exbackoff.increment |> Exbackoff.increment |> Exbackoff.increment
    8

The version with 2 arguments specifies a ceiling to the value:

    4> 2 |> Exbackoff.increment |> Exbackoff.increment |> Exbackoff.increment
    16
    5> 2 |> Exbackoff.increment(10) |> Exbackoff.increment |> Exbackoff.increment
    10

## Simple Backoffs with jitter

Jitter based incremental backoffs increase the back off period for each retry attempt using a randomization function that grows exponentially. They work by calling the functions `rand_increment/1-2`. The function with one argument will grow in an unbounded manner:

    1> 1 |> Exbackoff.rand_increment
    3
    2> 1 |> Exbackoff.rand_increment |> Exbackoff.rand_increment
    7
    3> 1 |> Exbackoff.rand_increment |> Exbackoff.rand_increment |> Exbackoff.rand_increment
    19
    4> 1 |> Exbackoff.rand_increment |> Exbackoff.rand_increment |> Exbackoff.rand_increment
    14
    5> 1 |> Exbackoff.rand_increment |> Exbackoff.rand_increment |> Exbackoff.rand_increment
    17

The version with 2 arguments specifies a ceiling to the value. If the
delay is close to the ceiling the new delay will also be close to the
ceiling and may be less than the previous delay.

    6> 2 |> Exbackoff.rand_increment |> Exbackoff.rand_increment |> Exbackoff.rand_increment
    21
    7> 2 |> Exbackoff.rand_increment(10) |> Exbackoff.rand_increment |> Exbackoff.rand_increment
    10

## State Backoffs

State backoffs keep track of the current value, the initial value, and the
maximal value for you. A backoff of that kind is initialized by calling
`init(Start,Max)` and returns an opaque data type to be used with `get/1`
(fetches the current timer value), `fail/1` (increments the value), and
`succeed/1` (resets the value):

    6> b0 = Exbackoff.init(2, 10)
    ...
    7> {_, b1} = Exbackoff.fail(Bb)
    {4, ...}
    8> Exbackoff.get(b1)
    4
    9> {_, b2} = Exbackoff.fail(b1)
    {8, ...}
    10> {_, b3} = Exbackoff.fail(b2)
    {10, ...}
    11> {_, _} = Exbackoff.fail(b3)
    {10, ...}

And here we've hit the cap with the failures. Now to succeed again:

    12> {_, b4} = Exbackoff.succeed(b3).
    {2, ...}
    13> Exbackoff.get(b4)
    2

That way, backoffs carry all their relevant state.

If what you want are unbound exponential backoffs, you can initiate them with:

    14> Exbackoff.init(start, :infinity)

And still use them as usual. The increments will have no upper limit.

## State Backoffs with jitter

You can enable a jitter based incremental backoff by calling `type/2`
that swaps the state of the backoff:

    1> b0 = Exbackoff.init(2, 30)
    {:backoff,2,30,2,:normal,nil,nil}
    2> b1 = Exbackoff.type(b0, jitter)
    {:backoff,2,30,2,:jitter,nil,nil}
    3> {_, b2} = Exbackoff.fail(b1)
    {7, ...}
    4> {_, b3} = Exbackoff.fail(b2)
    {12, ...}

Calling `type/2` with argument `:normal` will swap the backoff state back
to its default behavior:

    5> b4 = Exbackoff.type(b3, :normal)
    {:backoff,2,30,12,:normal,nil,nil}
    6> {_, b5} = Exbackoff.fail(b4)
    {24, ...}

## Timeout Events

A very common usage for exponential backoffs are with timer events, to be used
when driving reconnections or retries to certain sources. Most implementations
of this will call `erlang:start_timer(Delay, Dest, Message)` to do this, and
re-use the same values all the time.

Given we want Backoff to carry us the whole way there, additional arguments can
be given to the `init` function to deal with such state and fire events
whenever necessary. We first initialize the backoff with `init(start, max,
dest, message)`:

    1> b = Exbackoff.init(5000, 20000, self(), :hello_world).
    ...

Then by entering:

    2> Exbackoff.fire(B). :timer.sleep(2500), flush(). :timer.sleep(3000), flush().

and pressing enter, the following sequence of events will unfold:

    3> Exbackoff.fire(B). :timer.sleep(2500), flush(). :timer.sleep(3000), flush().
    #Ref<0.0.0.719>
    4> :timer.sleep(2500), flush(). :timer.sleep(3000), flush().
    ok
    5> :timer.sleep(3000), flush().
    Shell got {timeout,#Ref<0.0.0.719>,hello_world}
    ok

Showing that `Exbackoff.fire/1` generates a new timer, and returns the timer
reference. This reference can be manipulated with `erlang:cancel_timer(Ref)`
and `erlang:read_timer(Ref)`.

The shell then sleeps (2000 ms), receives nothing, then sleeps some more (3000
ms) and finally receives the timeout event as a regular Erlang timeout message.

Do note that Backoff will *not* track the timer references given there can be
enough use cases with multiple timers, event cancellation, and plenty of other
things that can happen with them. Backoff makes it easy to fire them for
the right interval, but *it is not* a wrapper around Erlang timers for all
operations.

## TODO

1. publish
2. add common task in readme