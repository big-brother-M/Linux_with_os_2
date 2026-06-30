# B1-2 시스템 장애 분석 리포트

## 리포트 목록

- [01-oom-crash.md](01-oom-crash.md): Memory Leak / OOM Crash 분석과 Before/After 터미널 증거
- [02-cpu-latency.md](02-cpu-latency.md): CPU 과점유 / Watchdog 종료 분석과 Before/After 터미널 증거
- [03-deadlock.md](03-deadlock.md): Deadlock 무응답 분석과 Before/After 터미널 증거
- [04-scheduling-analysis.md](04-scheduling-analysis.md): 로그 패턴 기반 스케줄링 알고리즘 추론

세 장애 리포트의 `Evidence & Logs` 절에는 실제 iTerm2 캡처가 바로 표시되며, 각 이미지 아래에서 `run.env`, `monitor.csv`, `app.log`, `result.env` 원본도 열 수 있습니다.

## 실행 및 증거 수집 환경

- Host: macOS ARM64
- Runtime: Docker `ubuntu:24.04`, `linux/arm64`
- Binary: `B1-2/agent-app-leak/agent-leak-app-arm64`
- User: container 내부 non-root `agent`
- Evidence root: `B1-2/evidence/`
- Runner: `B1-2/scripts/run-case-in-docker.sh`
- Monitor: `B1-2/monitor.sh`

제공 바이너리는 디컴파일하거나 리버스 엔지니어링하지 않았고, 실행 로그와 Linux 표준 도구(`ps`, `top`, `pgrep`) 출력만 사용했습니다.

## 사용한 evidence 세트

| Case | Evidence directory |
| --- | --- |
| OOM before | [evidence/oom-before/20260604-062049/](../evidence/oom-before/20260604-062049/) |
| OOM after | [evidence/oom-after/20260604-061950/](../evidence/oom-after/20260604-061950/) |
| CPU before | [evidence/cpu-before/20260604-062432/](../evidence/cpu-before/20260604-062432/) |
| CPU after | [evidence/cpu-after/20260604-062541/](../evidence/cpu-after/20260604-062541/) |
| Deadlock before | [evidence/deadlock-before/20260604-062841/](../evidence/deadlock-before/20260604-062841/) |
| Deadlock after | [evidence/deadlock-after/20260604-063035/](../evidence/deadlock-after/20260604-063035/) |

## 재현 명령

```bash
B1-2/scripts/run-case-in-docker.sh oom-before
B1-2/scripts/run-case-in-docker.sh oom-after
B1-2/scripts/run-case-in-docker.sh cpu-before
B1-2/scripts/run-case-in-docker.sh cpu-after
B1-2/scripts/run-case-in-docker.sh deadlock-before
B1-2/scripts/run-case-in-docker.sh deadlock-after
```

리포트용 핵심 증거를 터미널에서 다시 확인하려면 다음 명령을 사용합니다.

```bash
B1-2/scripts/show-report-evidence.sh oom-before
B1-2/scripts/show-report-evidence.sh cpu-before
B1-2/scripts/show-report-evidence.sh deadlock-before
```
