# 장애 리포트 증거 표시 및 평가 모범답안 설계

## 목표

OOM, CPU 과점유, Deadlock 리포트를 GitHub에서 열었을 때 실제 터미널 증거를 바로 확인할 수 있게 하고, 평가 항목 1~4의 모든 질문에 답할 수 있는 별도 모범답안 문서를 제공한다.

## 산출물

- `reports/assets/`에 장애별 Before/After 실제 터미널 캡처 6장
- `reports/01-oom-crash.md`, `reports/02-cpu-latency.md`, `reports/03-deadlock.md`에 캡처 이미지, 원본 증거 링크, 핵심 텍스트 증거
- `reports/05-evaluation-model-answers.md`에 평가 항목 1~4 전체의 질문별 모범답안
- `reports/README.md`에 새 문서와 증거 이미지 안내

## 증거 캡처 방식

각 캡처는 macOS 터미널에서 원본 evidence 파일을 조회한 실제 화면으로 만든다. 명령과 출력이 함께 보이도록 하며 이미지 내용을 임의로 합성하거나 로그 값을 수정하지 않는다.

각 장애의 Before/After 화면에는 다음 내용을 포함한다.

1. 실행 환경변수(`run.env` 또는 `app.log` 부트 출력)
2. PID와 관측 시각(`monitor.csv` 또는 `process_snapshot.txt`)
3. 핵심 장애·회복 로그(`app.log`)
4. 종료 여부와 종료 시각(`result.env`)

리포트에는 이미지만 넣지 않고 이미지 아래에 원본 파일 상대 링크와 핵심 텍스트 발췌를 유지한다. 이미지 확인이 어려운 환경과 검색·복사를 모두 지원하기 위해서다.

## 리포트 구조

세 문서는 공통으로 다음 순서를 따른다.

1. 현상(Description)
2. 증거(Evidence & Logs)
3. 원인(Root Cause Analysis)
4. 조치 및 검증(Workaround & Verification)

증거 절에는 Before/After 캡처, 원본 파일 링크, 비교 표를 배치한다. OOM은 RSS 선형 증가와 MemoryGuard 종료, CPU는 임계치 위반과 cooldown 생존, Deadlock은 PID 생존·CPU 정체·AB/BA 순환 대기를 각각 증명한다.

## 모범답안 구조

`reports/05-evaluation-model-answers.md`는 평가표와 동일한 항목 번호를 사용한다.

- 항목 1: 세 리포트의 증거 충족 여부와 근거 위치
- 항목 2: `monitor.sh`, `ps`, `top`, `kill -0`, 스레드 조회의 명령·옵션·판단 순서
- 항목 3: MemoryGuard와 시스템 보호, CPU 과점유 보호, Deadlock의 상호 배제·순환 대기, AB/BA 추적
- 항목 4: 운영 모니터 개선, 가장 치명적인 장애 선택과 예방, OOM+Deadlock 동시 대응 순서, 코드 수준 개선, 재수행 시 접근 개선

답변은 일반론에 그치지 않고 OOM·CPU의 PID 39와 Deadlock의 PID 38, 실제 타임스탬프, 환경변수와 관측값을 인용한다. 앱 로그의 내부 `Current Load`와 `ps`의 프로세스 CPU 비율처럼 의미가 다른 지표는 구분한다.

## 검증 기준

- Markdown 이미지 경로와 모든 원본 파일 링크가 실제 파일을 가리킨다.
- 캡처 6장이 생성되고 각 이미지에 PID, 시각, 핵심 로그 또는 상태가 보인다.
- 평가 질문을 체크리스트로 변환해 모든 질문에 대응하는 답변이 존재하는지 확인한다.
- 세 리포트의 수치와 모범답안의 수치가 원본 evidence와 일치한다.
- Markdown 제목·코드 펜스·상대 링크의 문법 오류가 없다.
