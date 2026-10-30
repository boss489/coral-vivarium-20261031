# 산호 수조 · Pocket Reef

Godot 4.7.2로 만든 한국어 싱글 플레이 웹 게임. **생물 사육 조언이 아닌 추상적 7일 퍼즐**입니다. 하루에 하나만 선택해 산소·오염·허기·건강을 관리합니다. 결과 뒤 다시 시작할 수 있으며 진행 중 수조, 플레이 횟수, 최고 건강 기록을 로컬 브라우저 저장소에 보관합니다.

## 실행

- Godot에서 `project.godot`을 열어 실행합니다.
- 정적 웹 빌드는 `docs/index.html`입니다. 로컬에서는 프로젝트 안에서 `python3 -m http.server 8791 --directory docs`를 실행하고 `http://127.0.0.1:8791/`로 접속합니다. `file://` 직접 열기는 WebAssembly 로딩 제한 때문에 지원하지 않습니다.
- 조작: 마우스/터치로 버튼 선택, 키보드 `1` 먹이 · `2` 환기 · `3` 청소. 타이틀/튜토리얼/결과에서는 Enter 또는 Space로 계속합니다.
- GitHub Pages를 사용한다면 배포 설정의 소스를 **이 프로젝트의 `docs/`**로 지정할 수 있습니다. 여기서는 배포하거나 Git을 초기화하지 않았습니다.

## 빌드와 테스트

```sh
godot --headless --path . --script res://tests/run.gd
godot --headless --path . --script res://tests/ui_flow.gd
python3 tests/font_coverage.py
godot --headless --path . --export-release Web docs/index.html
PYTHONPATH=/path/to/playwright python3 tests/browser_smoke.py
```

브라우저 테스트는 로컬 포트 8791에서 `docs/`를 제공하고 설치된 Google Chrome 및 Python Playwright/Pillow를 사용합니다. 모바일·데스크톱 캡처는 `tests/screenshots/`에 저장됩니다. 영속 데이터는 Godot `user://coral_save.cfg`에 있으며 브라우저마다 독립적입니다.

## 자산과 권리

- 산호, 물고기, 거품, 배경 및 UI 그래픽은 `scripts/main.gd`에서 직접 그린 독창적 벡터 그래픽입니다. 기존 게임의 그림·코드·음악은 사용하지 않았습니다.
- `assets/chime.wav`는 `tools/generate_chime.py`로 합성한 오리지널 효과음입니다.
- `assets/NanumGothic-Regular.ttf`는 NHN Corporation의 NanumGothic 글꼴이며 **SIL Open Font License 1.1**을 따릅니다. 저작권 고지와 라이선스 전문은 `assets/OFL.txt`에 있습니다. 소스 문자열 글리프 커버리지는 `tests/font_coverage.py`로 확인합니다.
- 전체 디자인 방향과 팔레트는 `ART_DIRECTION.md`에 기록했습니다.
