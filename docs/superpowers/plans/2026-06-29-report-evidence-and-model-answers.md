# 장애 리포트 증거 및 평가 모범답안 구현 계획

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 세 장애 리포트에 실제 터미널 증거 캡처와 원본 링크를 추가하고 평가 항목 1~4 전체의 모범답안을 작성한다.

**Architecture:** 기존 evidence 파일은 변경하지 않고 조회 전용 증거 원본으로 사용한다. macOS 터미널에서 원본 파일 조회 명령을 실행해 Before/After 캡처 6장을 만들고, Markdown은 이미지·원본 링크·검색 가능한 텍스트 증거를 함께 제공한다.

**Tech Stack:** Bash, macOS Terminal, Markdown, PNG, 기존 Linux `ps`/`top` evidence

---

### Task 1: 캡처 명령과 증거 항목 확정

**Files:**
- Read: `evidence/*/*/{app.log,monitor.csv,process_snapshot.txt,result.env,run.env}`
- Read: `monitor.sh`

- [x] **Step 1: 각 케이스의 실행 조건·PID·핵심 로그·종료 상태 추출**

Run:

```bash
for case_dir in \
  evidence/oom-before/20260604-062049 \
  evidence/oom-after/20260604-061950 \
  evidence/cpu-before/20260604-062432 \
  evidence/cpu-after/20260604-062541 \
  evidence/deadlock-before/20260604-062841 \
  evidence/deadlock-after/20260604-063035; do
  printf '%s\n' "### $case_dir"
  sed -n '1,4p' "$case_dir/monitor.csv"
  cat "$case_dir/result.env"
done
```

Expected: 여섯 케이스의 PID·타임스탬프와 `STATE`가 표시된다.

- [x] **Step 2: 문서에 인용할 수치가 원본과 일치하는지 확인**

Run:

```bash
rg -n 'Memory limit exceeded|Self-terminating|CPU Threshold Violated|Peak reached|WAITING|All tasks completed' evidence/{oom-before/20260604-062049,oom-after/20260604-061950,cpu-before/20260604-062432,cpu-after/20260604-062541,deadlock-before/20260604-062841,deadlock-after/20260604-063035}/app.log
```

Expected: OOM, CPU, Deadlock Before/After 핵심 로그가 모두 조회된다.

### Task 2: 실제 터미널 증거 캡처 6장 생성

**Files:**
- Create: `reports/assets/oom-before-terminal.png`
- Create: `reports/assets/oom-after-terminal.png`
- Create: `reports/assets/cpu-before-terminal.png`
- Create: `reports/assets/cpu-after-terminal.png`
- Create: `reports/assets/deadlock-before-terminal.png`
- Create: `reports/assets/deadlock-after-terminal.png`

- [x] **Step 1: `reports/assets` 디렉터리 생성**

Run:

```bash
mkdir -p reports/assets
```

Expected: `reports/assets`가 존재한다.

- [x] **Step 2: 터미널에서 Before/After 원본 조회 명령 실행 및 캡처**

각 화면은 `run.env`, `monitor.csv`, `app.log`, `result.env`를 `sed`, `head`, `tail`, `rg`로 조회한다. 터미널 창에는 조회 명령과 원본 출력이 함께 보여야 한다.

- [x] **Step 3: 이미지 해상도와 텍스트 식별 가능 여부 확인**

Run:

```bash
sips -g pixelWidth -g pixelHeight reports/assets/*-terminal.png
```

Expected: PNG 6개가 존재하고 각 파일의 너비와 높이가 0보다 크다.

### Task 3: 장애 리포트 3건에 증거 삽입

**Files:**
- Modify: `reports/01-oom-crash.md`
- Modify: `reports/02-cpu-latency.md`
- Modify: `reports/03-deadlock.md`

- [x] **Step 1: OOM 리포트에 Before/After 이미지와 원본 링크 추가**

이미지 경로는 `assets/oom-before-terminal.png`, `assets/oom-after-terminal.png`를 사용한다. 원본 링크는 `../evidence/oom-*/.../` 상대 경로로 연결한다.

- [x] **Step 2: CPU 리포트에 Before/After 이미지와 원본 링크 추가**

앱 내부 `Current Load`와 OS `ps/top`의 `%CPU`가 서로 다른 측정값임을 명시한다.

- [x] **Step 3: Deadlock 리포트에 Before/After 이미지와 원본 링크 추가**

PID 38 생존, 마지막 로그 시각, CPU 0.0%, AB/BA 자원 대기 관계가 한 절에서 확인되도록 배치한다.

- [x] **Step 4: 공통 GitHub Issue 구조 확인**

Run:

```bash
for f in reports/0{1,2,3}-*.md; do
  rg -n '^## [1-4]\. (Description|Evidence & Logs|Root Cause Analysis|Workaround & Verification)' "$f"
done
```

Expected: 파일마다 네 절이 모두 검색된다.

### Task 4: 평가 문항 전체 모범답안 작성

**Files:**
- Create: `reports/05-evaluation-model-answers.md`

- [x] **Step 1: 항목 1의 리포트·증거 충족 답안 작성**

OOM, CPU, Deadlock의 Before/After와 GitHub Issue 구조, PID·타임스탬프·핵심 로그의 위치를 질문별로 답한다.

- [x] **Step 2: 항목 2의 명령·옵션·진단 순서 답안 작성**

`kill -0`, `ps -p`, `ps -L`, `top -b -n 1 -p`, `awk`, `date`, `sleep`의 역할과 `RSS`, `VSZ`, `NLWP`, `%CPU`, `STAT` 의미를 실제 `monitor.sh` 흐름에 맞춰 설명한다.

- [x] **Step 3: 항목 3의 운영체제 원리 답안 작성**

메모리 보호, CPU 시스템 보호, 상호 배제·점유 대기·비선점·순환 대기, AB/BA 로그 추적을 evidence에 연결한다.

- [x] **Step 4: 항목 4의 개선·우선순위·코드 수정 답안 작성**

운영 모니터 개선, 가장 치명적인 장애와 근거, OOM+Deadlock 동시 대응 순서, 장애별 코드 수준 개선, 재수행 방법을 구체적으로 작성한다.

### Task 5: 색인 갱신 및 최종 검증

**Files:**
- Modify: `reports/README.md`
- Verify: `reports/*.md`
- Verify: `reports/assets/*.png`

- [x] **Step 1: README에 모범답안과 증거 캡처 안내 추가**

`05-evaluation-model-answers.md` 링크와 여섯 evidence 세트의 클릭 가능한 링크를 제공한다.

- [x] **Step 2: Markdown 상대 링크 대상 검증**

Run: Markdown의 `](relative-path)` 및 `](<relative-path>)`를 추출해 파일 존재 여부를 검사한다.

Expected: 누락된 로컬 링크 0개.

- [x] **Step 3: 평가 질문 커버리지 검증**

Run:

```bash
rg -n '^### 질문' reports/05-evaluation-model-answers.md
```

Expected: 사용자 평가표의 모든 질문과 일대일 대응하는 질문 제목이 출력된다.

- [x] **Step 4: 원본 수치 대조**

Run: 리포트와 답안의 PID, 타임스탬프, 메모리, CPU, 생존 시간을 evidence의 원문과 대조한다.

Expected: 불일치 0건.
