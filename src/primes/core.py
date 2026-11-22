"""Core functions for integer addition, primality checks, and prime generation."""

from __future__ import annotations

from math import isqrt


def add(a: int, b: int) -> int:
    """Return a + b."""
    if not isinstance(a, int) or not isinstance(b, int):
        raise TypeError("add expects two ints")
    return a + b


def is_prime(n: int) -> bool:
    """
    Return True if n is prime.
    """
    if not isinstance(n, int):
        raise TypeError("n must be an int")

    if n < 2:
        return False
    if n % 2 == 0:
        return n == 2

    limit = isqrt(n)  # floor(sqrt(n))
    i = 3
    while i <= limit:
        if n % i == 0:
            return False
        i += 2
    return True


def primes_up_to(n: int) -> list[int]:
    """
    Return all primes p with 2 <= p <= n by calling is_prime(i) for each i.
    """
    if not isinstance(n, int):
        raise TypeError("n must be an int")
    out: list[int] = []
    for i in range(2, n + 1):
        if is_prime(i):
            out.append(i)
    return out
