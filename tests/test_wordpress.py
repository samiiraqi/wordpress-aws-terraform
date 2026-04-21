import pytest
import requests

BASE_URL = "http://localhost:80"


def test_homepage_returns_200():
    response = requests.get(BASE_URL, timeout=10)
    assert response.status_code == 200


def test_login_page_returns_200():
    response = requests.get(f"{BASE_URL}/wp-login.php", timeout=10)
    assert response.status_code == 200


def test_rest_api_returns_200():
    response = requests.get(f"{BASE_URL}/wp-json/wp/v2/", timeout=10)
    assert response.status_code == 200


def test_wp_admin_redirects():
    response = requests.get(f"{BASE_URL}/wp-admin/", timeout=10, allow_redirects=False)
    assert response.status_code == 302
# test
