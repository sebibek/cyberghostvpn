import re
from playwright.sync_api import Playwright, sync_playwright, expect


def run(playwright: Playwright) -> None:
    browser = playwright.chromium.launch(headless=False)
    context = browser.new_context(storage_state="cookies.json")
    page = context.new_page()
    page.goto("https://my.cyberghostvpn.com/products-vpn/manage-devices")
    # delete all devices
    while page.get_by_role("link", name="Delete"):#.is_visible():
        page.get_by_role("link", name="Delete").click()
        page.get_by_role("button", name="OK").click()
    # ---------------------
    context.close()
    browser.close()


with sync_playwright() as playwright:
    run(playwright)
