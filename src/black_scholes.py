"""Transparent Black--Scholes analytics for a non-dividend-paying stock."""

from math import erf, pi, sqrt

import numpy as np


def _normal_pdf(x):
    x = np.asarray(x, dtype=float)
    return np.exp(-0.5 * x**2) / sqrt(2.0 * pi)


def _normal_cdf(x):
    x = np.asarray(x, dtype=float)
    values = np.vectorize(
        lambda value: 0.5 * (1.0 + erf(value / sqrt(2.0))),
        otypes=[float],
    )(x)
    return values


def _d1_d2(spot, strike, maturity, rate, volatility):
    spot = np.asarray(spot, dtype=float)
    if np.any(spot <= 0) or strike <= 0 or maturity <= 0 or volatility <= 0:
        raise ValueError("spot, strike, maturity, and volatility must be positive")

    root_t = sqrt(maturity)
    d1 = (
        np.log(spot / strike)
        + (rate + 0.5 * volatility**2) * maturity
    ) / (volatility * root_t)
    return d1, d1 - volatility * root_t


def call_price(spot, strike, maturity, rate, volatility):
    """Black--Scholes European call value."""
    spot = np.asarray(spot, dtype=float)
    d1, d2 = _d1_d2(spot, strike, maturity, rate, volatility)
    return spot * _normal_cdf(d1) - strike * np.exp(-rate * maturity) * _normal_cdf(d2)


def call_delta(spot, strike, maturity, rate, volatility):
    """Call delta with respect to spot."""
    d1, _ = _d1_d2(spot, strike, maturity, rate, volatility)
    return _normal_cdf(d1)


def call_gamma(spot, strike, maturity, rate, volatility):
    """Call gamma with respect to spot."""
    spot = np.asarray(spot, dtype=float)
    d1, _ = _d1_d2(spot, strike, maturity, rate, volatility)
    return _normal_pdf(d1) / (spot * volatility * sqrt(maturity))


def call_vega(spot, strike, maturity, rate, volatility):
    """Call vega per unit change in volatility (1.00 = 100 vol points)."""
    spot = np.asarray(spot, dtype=float)
    d1, _ = _d1_d2(spot, strike, maturity, rate, volatility)
    return spot * _normal_pdf(d1) * sqrt(maturity)


def call_theta(spot, strike, maturity, rate, volatility):
    """Calendar-time call theta per year."""
    spot = np.asarray(spot, dtype=float)
    d1, d2 = _d1_d2(spot, strike, maturity, rate, volatility)
    diffusion = -(spot * _normal_pdf(d1) * volatility) / (2.0 * sqrt(maturity))
    carry = -rate * strike * np.exp(-rate * maturity) * _normal_cdf(d2)
    return diffusion + carry


def finite_difference_greeks(
    spot,
    strike,
    maturity,
    rate,
    volatility,
    *,
    spot_bump=0.10,
    volatility_bump=1.0e-4,
):
    """Central finite-difference delta, gamma, and vega."""
    base = call_price(spot, strike, maturity, rate, volatility)
    up = call_price(spot + spot_bump, strike, maturity, rate, volatility)
    down = call_price(spot - spot_bump, strike, maturity, rate, volatility)
    vol_up = call_price(spot, strike, maturity, rate, volatility + volatility_bump)
    vol_down = call_price(spot, strike, maturity, rate, volatility - volatility_bump)

    return {
        "delta": (up - down) / (2.0 * spot_bump),
        "gamma": (up - 2.0 * base + down) / spot_bump**2,
        "vega": (vol_up - vol_down) / (2.0 * volatility_bump),
    }

