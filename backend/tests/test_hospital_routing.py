import pytest

from app.services.hospital_routing import _haversine


def test_haversine_same_point():
    d = _haversine(19.42, -99.13, 19.42, -99.13)
    assert d == pytest.approx(0.0, abs=0.001)


def test_haversine_known_distance():
    # Mexico City to Guadalajara ~460 km
    d = _haversine(19.4326, -99.1332, 20.6597, -103.3496)
    assert 450 < d < 480


def test_haversine_symmetry():
    d1 = _haversine(19.4, -99.1, 20.6, -103.3)
    d2 = _haversine(20.6, -103.3, 19.4, -99.1)
    assert d1 == pytest.approx(d2, rel=1e-9)
