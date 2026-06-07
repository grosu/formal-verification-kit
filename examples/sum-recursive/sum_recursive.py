def sum_recursive(n):
    """Return the sum of the natural numbers from 1 up to n, computed recursively.

    Args:
        n: A natural number (non-negative integer). sum_recursive(0) is 0.

    Returns:
        The sum 1 + 2 + ... + n.

    Raises:
        ValueError: If n is negative.
        TypeError: If n is not an integer.
    """
    if not isinstance(n, int) or isinstance(n, bool):
        raise TypeError(f"n must be an integer, got {type(n).__name__}")
    if n < 0:
        raise ValueError(f"n must be a natural number (>= 0), got {n}")

    # Base case: the sum up to 0 is 0.
    if n == 0:
        return 0
    # Recursive case: n plus the sum of everything below it.
    return n + sum_recursive(n - 1)


if __name__ == "__main__":
    for n in (0, 1, 5, 10, 100):
        print(f"sum_recursive({n}) = {sum_recursive(n)}")
