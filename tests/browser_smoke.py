"""Optional visual Web smoke test; install playwright and use local Chrome."""
from itertools import product
from pathlib import Path
import sys
from playwright.sync_api import sync_playwright
from PIL import Image

OUT = Path(__file__).parent / "screenshots"
OUT.mkdir(exist_ok=True)
EVENTS = [(5, 0, 0), (-3, 9, 0), (-2, 2, 8), (2, -3, 2), (-5, 4, 0)]


def simulate(seed, actions):
    oxygen, pollution, hunger, health = 65, 20, 25, 75
    for day, action in enumerate(actions, 1):
        eo, ep, eh = EVENTS[(seed + day * 3 + seed // 5) % 5]
        oxygen += -10 + eo
        pollution += 8 + ep
        hunger += 12 + eh
        if action == 0:
            hunger -= 39
            pollution += 8
        elif action == 1:
            oxygen += 36
            pollution += 2
        else:
            pollution -= 36
            oxygen += 4
        oxygen = max(0, min(100, oxygen))
        pollution = max(0, min(100, pollution))
        hunger = max(0, min(100, hunger))
        stress = 14 * (oxygen < 35) + 13 * (pollution > 60) + 13 * (hunger > 65)
        health = max(0, min(100, health - stress + (3 if not stress else 0)))
        if health <= 0 or oxygen <= 10 or pollution >= 95 or hunger >= 95:
            return "lost", day
    return ("won" if health >= 35 else "lost"), 7


with sync_playwright() as p:
    browser = p.chromium.launch(
        executable_path="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome",
        headless=True,
        args=["--enable-unsafe-swiftshader", "--use-angle=swiftshader"],
    )
    context = browser.new_context(viewport={"width": 390, "height": 700}, device_scale_factor=1)
    page = context.new_page()
    errors = []
    page.on("pageerror", lambda e: errors.append(str(e)))
    page.goto("http://127.0.0.1:8791/index.html")
    page.locator("#status").wait_for(state="detached", timeout=90000)
    page.wait_for_timeout(1000)
    page.screenshot(path=str(OUT / "title-mobile.png"))
    print("title", page.title(), page.locator("canvas").bounding_box(), flush=True)
    page.mouse.click(195, 608)
    page.wait_for_timeout(350)
    page.screenshot(path=str(OUT / "tutorial-mobile.png"))
    page.mouse.click(195, 651)
    page.wait_for_timeout(350)
    page.screenshot(path=str(OUT / "play-mobile.png"))
    page.keyboard.press("1")
    page.wait_for_timeout(2500)
    page.screenshot(path=str(OUT / "after-action-mobile.png"))
    print("db", page.evaluate("async () => await indexedDB.databases()"), flush=True)
    page.reload()
    page.locator("#status").wait_for(state="detached", timeout=90000)
    page.wait_for_timeout(350)
    page.screenshot(path=str(OUT / "resume-mobile.png"))
    page.mouse.click(195, 608)
    loss = simulate(30, [0] * 7)
    print("failure", loss, flush=True)
    for _ in range(loss[1] - 1):
        page.mouse.click(75, 580)
        page.wait_for_timeout(500)
    page.wait_for_timeout(350)
    page.screenshot(path=str(OUT / "failure-mobile.png"))
    page.mouse.click(195, 608)
    page.wait_for_timeout(300)
    page.screenshot(path=str(OUT / "restart-mobile.png"))
    page.mouse.click(195, 608)
    page.wait_for_timeout(300)
    page.mouse.click(195, 651)
    page.wait_for_timeout(350)
    success = next(seq for seq in product(range(3), repeat=7) if simulate(53, seq)[0] == "won")
    print("victory actions", success, flush=True)
    for action in success:
        page.mouse.click([75, 195, 310][action], 580)
        page.wait_for_timeout(500)
    page.wait_for_timeout(350)
    page.screenshot(path=str(OUT / "victory-mobile.png"))
    for name, target in [("failure-mobile.png", (255, 144, 122)), ("victory-mobile.png", (185, 217, 134))]:
        image = Image.open(OUT / name).convert("RGB")
        assert image.size == (390, 700), (name, image.size)
        matches = sum(
            all(abs(pixel[channel] - target[channel]) <= 4 for channel in range(3))
            for y in range(405, 445) for x in range(80, 310)
            for pixel in [image.getpixel((x, y))]
        )
        print(name, "result-color pixels", matches, flush=True)
        assert matches > 300, f"Expected result title not rendered: {name}"
    desktop = browser.new_context(viewport={"width": 1280, "height": 800}, device_scale_factor=1)
    large = desktop.new_page()
    large.goto("http://127.0.0.1:8791/index.html")
    large.locator("#status").wait_for(state="detached", timeout=90000)
    large.wait_for_timeout(350)
    large.screenshot(path=str(OUT / "title-desktop.png"))
    print("desktop", large.locator("canvas").bounding_box(), flush=True)
    large.mouse.click(640, 695)
    large.wait_for_timeout(300)
    large.screenshot(path=str(OUT / "tutorial-desktop.png"))
    large.mouse.click(640, 745)
    large.wait_for_timeout(300)
    large.screenshot(path=str(OUT / "play-desktop.png"))
    for _ in range(5):
        large.keyboard.press("1")
        large.wait_for_timeout(150)
    large.screenshot(path=str(OUT / "failure-desktop.png"))
    large.mouse.click(640, 690)
    large.wait_for_timeout(300)
    large.screenshot(path=str(OUT / "restart-desktop.png"))
    large.keyboard.press("Enter")
    large.keyboard.press("Enter")
    for action in (0, 0, 1, 1, 2, 2, 0):
        large.keyboard.press(str(action + 1))
        large.wait_for_timeout(150)
    large.screenshot(path=str(OUT / "victory-desktop.png"))
    narrow = browser.new_context(viewport={"width": 320, "height": 640}, device_scale_factor=1, is_mobile=True, has_touch=True)
    phone = narrow.new_page()
    phone.goto("http://127.0.0.1:8791/index.html")
    phone.locator("#status").wait_for(state="detached", timeout=90000)
    phone.wait_for_timeout(350)
    phone.screenshot(path=str(OUT / "title-320.png"))
    print("320", phone.locator("canvas").bounding_box(), flush=True)
    phone.touchscreen.tap(160, 532)
    phone.wait_for_timeout(300)
    phone.screenshot(path=str(OUT / "tutorial-320.png"))
    phone.touchscreen.tap(160, 566)
    phone.wait_for_timeout(300)
    phone.screenshot(path=str(OUT / "play-320.png"))
    phone.touchscreen.tap(61, 510)
    phone.wait_for_timeout(350)
    phone.screenshot(path=str(OUT / "after-touch-320.png"))
    phone.touchscreen.tap(61, 510)
    phone.wait_for_timeout(350)
    phone.screenshot(path=str(OUT / "after-second-touch-320.png"))
    # Each real Chrome touch must equal exactly one keyboard action, including
    # DAY 02 and the health/oxygen/pollution/hunger HUD. Exclude animated tank.
    reference = browser.new_context(viewport={"width": 320, "height": 640}, device_scale_factor=1, is_mobile=True, has_touch=True)
    ref = reference.new_page()
    ref.goto("http://127.0.0.1:8791/index.html")
    ref.locator("#status").wait_for(state="detached", timeout=90000)
    ref.touchscreen.tap(160, 532)
    ref.touchscreen.tap(160, 566)
    ref.keyboard.press("1")
    ref.wait_for_timeout(350)
    ref.screenshot(path=str(OUT / "day02-keyboard-reference-320.png"))
    ref.keyboard.press("1")
    ref.wait_for_timeout(350)
    ref.screenshot(path=str(OUT / "day03-keyboard-reference-320.png"))
    # Separate deterministic narrow run: all terminal states plus restart.
    for _ in range(3):
        ref.keyboard.press("1")
        ref.wait_for_timeout(150)
    ref.screenshot(path=str(OUT / "failure-320.png"))
    ref.keyboard.press("Enter")
    ref.wait_for_timeout(250)
    ref.screenshot(path=str(OUT / "restart-320.png"))
    ref.keyboard.press("Enter")
    ref.keyboard.press("Enter")
    for action in (0, 0, 1, 1, 2, 2, 0):
        ref.keyboard.press(str(action + 1))
        ref.wait_for_timeout(150)
    ref.screenshot(path=str(OUT / "victory-320.png"))
    for actual_name, expected_name, day in [
        ("after-touch-320.png", "day02-keyboard-reference-320.png", "02"),
        ("after-second-touch-320.png", "day03-keyboard-reference-320.png", "03"),
    ]:
        actual = Image.open(OUT / actual_name).convert("RGB")
        expected = Image.open(OUT / expected_name).convert("RGB")
        for region in [(15, 78, 305, 130), (15, 350, 305, 462)]:
            assert actual.crop(region).tobytes() == expected.crop(region).tobytes(), f"Real touch did not produce exactly DAY {day} and the matching gauges: {region}"
    print("Chrome successive touches == two keyboard actions: DAY 02 then DAY 03; matching health/oxygen/pollution/hunger", flush=True)
    print("JS errors", errors, flush=True)
    assert not errors
    browser.close()
