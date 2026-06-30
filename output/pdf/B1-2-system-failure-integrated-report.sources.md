# B1-2 종합 보고서 소스 노트

## 보고 목적

- 대상 독자: 기술 독자
- 질문: `reports/`의 Markdown을 종합했을 때 확인되는 장애 원인, 완화 효과, 운영 위험, 근본 개선 우선순위는 무엇인가?
- 범위: `README.md`, `01-oom-crash.md`, `02-cpu-latency.md`, `03-deadlock.md`, `04-scheduling-analysis.md`, `05-evaluation-model-answers.md`
- 증거 시점: 2026-06-04
- 비교 기준: 장애별 핵심 환경변수 Before/After

## 구조 매핑

| 기술 보고서 요구 역할 | 최종 보고서 절 |
| --- | --- |
| Title | 표지 |
| Technical summary | 가장 큰 운영 위험은 "살아 있지만 멈추는" 데드락이다 |
| Key findings with visual evidence | OOM, CPU, Deadlock 개별 절과 터미널 캡처 |
| Scope, data, metric definitions | 로그와 표준 Linux 관측값을 분리해 해석했다 |
| Methodology | Before/After 증거는 방향성을 지지하지만 반복성과 소스 수준 원인은 남아 있다 |
| Limitations, uncertainty, robustness | 동일 절의 한계와 불확실성 표 |
| Recommended next steps | 탐지 공백을 먼저 닫고 자원 수명과 동시성 구조를 수정해야 한다 |
| Further questions | 다음 검증이 근본 수정의 완료 조건이다 |

## 핵심 판정과 출처

- OOM 자체 종료 및 5.1초 -> 17.1초 생존 시간 변화: `01-oom-crash.md`, `05-evaluation-model-answers.md`
- CPU 내부 부하 53.77%, OS 관측 최대 8.8%, After 90초 생존: `02-cpu-latency.md`, `05-evaluation-model-answers.md`
- Deadlock 약 80초 무진행, CPU 0.0%, RSS 13,772KB: `03-deadlock.md`, `05-evaluation-model-answers.md`
- Round-Robin 추론: `04-scheduling-analysis.md`
- 환경과 증거 범위: `README.md`

## 한계

- 각 조건의 반복 횟수가 제시되지 않아 재현 확률과 분산을 정량화하지 않았다.
- 소스 코드, heap dump, thread dump가 없어 allocation/lock의 정확한 코드 위치는 확정하지 않았다.
- CpuWorker 내부 부하의 계산식이 공개되지 않아 OS `%CPU`와 직접 환산하지 않았다.
- Round-Robin은 애플리케이션 로그 패턴에 대한 추론이며 커널 스케줄러 측정 결과가 아니다.

## 시각 자료

- 차트는 생성하지 않았다. 정량 비교는 표와 metric card로 표현했다.
- `reports/assets/`의 Before/After 터미널 캡처 6개를 원문 증거로 사용했다.
