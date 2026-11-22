"""Unit tests for the primes package."""

import pytest

from primes import add, is_prime, primes_up_to

# Silence unnecessary docstring warnings for test functions
# since pytest tests are self-documenting by name.
# pylint: disable=missing-function-docstring


# ---------------------
# add
# ---------------------


@pytest.mark.parametrize(
    "a, b, expected",
    [
        (0, 0, 0),
        (1, 2, 3),
        (-5, 5, 0),
        (123, 456, 579),
        (-10, -20, -30),
    ],
)
def test_add(a, b, expected):
    assert add(a, b) == expected


def test_add_type_errors():
    with pytest.raises(TypeError):
        add(1.0, 2)  # type: ignore[arg-type]
    with pytest.raises(TypeError):
        add(1, "2")  # type: ignore[arg-type]


# ---------------------
# is_prime
# ---------------------


@pytest.mark.parametrize(
    "n, expected",
    [
        (-10, False),
        (0, False),
        (1, False),
        (2, True),
        (3, True),
        (4, False),
        (5, True),
        (9, False),
        (25, False),
        (29, True),
        (97, True),
        (100, False),
        (101, True),
    ],
)
def test_is_prime_examples(n, expected):
    assert is_prime(n) is expected


def test_is_prime_type_error():
    with pytest.raises(TypeError):
        is_prime(3.14)  # type: ignore[arg-type]


# ---------------------
# primes_up_to
# ---------------------


def test_primes_up_to_small():
    assert not primes_up_to(1)
    assert primes_up_to(2) == [2]
    assert primes_up_to(10) == [2, 3, 5, 7]
    assert primes_up_to(30) == [2, 3, 5, 7, 11, 13, 17, 19, 23, 29]


def test_primes_up_to_type_error():
    with pytest.raises(TypeError):
        primes_up_to("30")  # type: ignore[arg-type]


def test_primes_up_to_consistency():
    n = 200
    ps = primes_up_to(n)
    # Every listed number is prime, and all primes <= n are listed
    assert all(is_prime(p) for p in ps)
    assert ps == [k for k in range(2, n + 1) if is_prime(k)]
