# [Analysis] 로그 패턴 분석을 통한 스케줄링 알고리즘 추론

## 1. 로그 관찰 개요

정상 실행 케이스(`B1-2/evidence/cpu-after/20260604-062541/app.log`)에서 `Scheduler`가 `Thread-A`, `Thread-B`, `Thread-C`를 등록하고 실행한다. 각 스레드는 20%, 40%까지 진행한 뒤 `Preempted`되고, 이후 다른 스레드가 실행된다.

## 2. 증거 자료

핵심 로그:

```text
2026-06-04 06:25:43,725 [INFO] [Thread-A] Task Started. Calculating... (20%)
2026-06-04 06:25:43,776 [INFO] [Thread-A] Calculating... (40%)
2026-06-04 06:25:43,829 [INFO] [Thread-A] Preempted. Progress saved at (40%)
2026-06-04 06:25:43,880 [INFO] [Thread-B] Task Started. Calculating... (20%)
2026-06-04 06:25:43,935 [INFO] [Thread-B] Calculating... (40%)
2026-06-04 06:25:43,990 [INFO] [Thread-B] Preempted. Progress saved at (40%)
2026-06-04 06:25:44,046 [INFO] [Thread-C] Task Started. Calculating... (20%)
2026-06-04 06:25:44,102 [INFO] [Thread-C] Calculating... (40%)
2026-06-04 06:25:44,156 [INFO] [Thread-C] Preempted. Progress saved at (40%)
2026-06-04 06:25:44,213 [INFO] [Thread-A] Resumed. Calculating... (60%)
2026-06-04 06:25:44,265 [INFO] [Thread-A] Calculating... (80%)
2026-06-04 06:25:44,316 [INFO] [Thread-A] Preempted. Progress saved at (80%)
2026-06-04 06:25:44,370 [INFO] [Thread-B] Resumed. Calculating... (60%)
2026-06-04 06:25:44,421 [INFO] [Thread-B] Calculating... (80%)
2026-06-04 06:25:44,476 [INFO] [Thread-B] Preempted. Progress saved at (80%)
2026-06-04 06:25:44,531 [INFO] [Thread-C] Resumed. Calculating... (60%)
2026-06-04 06:25:44,582 [INFO] [Thread-C] Calculating... (80%)
2026-06-04 06:25:44,636 [INFO] [Thread-C] Preempted. Progress saved at (80%)
2026-06-04 06:25:44,688 [INFO] [Thread-A] Resumed. Calculating... (100%)
2026-06-04 06:25:44,744 [INFO] [Thread-B] Resumed. Calculating... (100%)
2026-06-04 06:25:44,798 [INFO] [Thread-C] Resumed. Calculating... (100%)
2026-06-04 06:25:44,857 [INFO] [Scheduler] All tasks completed.
```

## 3. 패턴 분석 및 결론

관찰된 실행 순서는 A -> B -> C -> A -> B -> C -> A -> B -> C이다. 하나의 스레드가 100%까지 끝난 뒤 다음 스레드를 시작하지 않고, 40%와 80% 지점에서 선점되어 다른 스레드로 넘어간다.

따라서 FCFS는 아니다. FCFS라면 Thread-A가 완료된 뒤 Thread-B, Thread-C가 순차 실행되어야 한다.

Priority 방식으로 보기도 어렵다. 특정 스레드가 계속 우선 실행되거나 더 많은 CPU 시간을 배정받는 패턴이 없고, A/B/C가 같은 진행률 단위로 반복 실행된다.

최종 결론은 Round-Robin에 가장 가깝다. 각 작업에 작은 time slice가 주어지고, 진행 상태를 저장한 뒤 다음 작업으로 제어권을 넘기는 방식이다.

## 4. 장단점 및 적합한 아키텍처

Round-Robin의 장점은 작업 간 공정성이 높고, 한 작업이 전체 실행 흐름을 독점하지 않는다는 점이다. 사용자 요청을 번갈아 처리해야 하는 웹 서버, 채팅 서버, interactive agent처럼 응답성이 중요한 서비스에 적합하다.

단점은 context switch 비용이 있고, 처리량만 중요한 배치 작업에서는 FCFS나 우선순위 기반 큐보다 비효율적일 수 있다는 점이다. 또한 time slice가 너무 짧으면 전환 오버헤드가 커지고, 너무 길면 응답성이 떨어진다.

이 앱의 로그 패턴은 장애 분석 미션에서 스레드 선점과 공정성 개념을 보여주기 위한 Round-Robin 시뮬레이션으로 판단된다.
