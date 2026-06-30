# B1-2 평가문항 모범답안

이 문서는 [OOM 리포트](01-oom-crash.md), [CPU 리포트](02-cpu-latency.md), [Deadlock 리포트](03-deadlock.md), 실제 evidence와 `monitor.sh`를 근거로 작성한 발표·질의응답용 모범답안이다. 평가문항의 `MULTITHREAD_ENABLE` 표기는 실제 바이너리가 사용하는 `MULTI_THREAD_ENABLE`로 바로잡아 답한다.

## 항목 1. 리포트와 증거

### 질문 1-1. [OOM] 메모리 사용량이 선형적으로 증가하다가 프로세스가 강제 종료되는 패턴이 로그에 기록되어 있는가?

그렇다. Before 실행의 PID는 39다. 앱 로그에서 Heap이 `06:20:51.748`의 25MB에서 `06:20:54.775`의 50MB로 증가했고, 바로 다음 로그에 `Memory limit exceeded (50MB >= 50MB)`와 `Self-terminating process 39`가 기록되었다. `monitor.csv`에서도 RSS가 17,104KB에서 42,708KB로 증가했고 `result.env`는 `STATE=exited`, `LAUNCHER_EXIT=137`을 기록했다. 따라서 “지속 증가 → 제한 도달 → MemoryGuard 강제 종료” 순서가 확인된다. 다만 이것은 불특정한 Linux OOM Killer가 아니라 애플리케이션 내부 MemoryGuard의 보호 동작이다.

근거: [OOM Before 화면](assets/oom-before-terminal.png), [app.log](../evidence/oom-before/20260604-062049/app.log), [monitor.csv](../evidence/oom-before/20260604-062049/monitor.csv), [result.env](../evidence/oom-before/20260604-062049/result.env)

### 질문 1-2. [OOM] `MEMORY_LIMIT` 조정 후 생존 시간이 늘어난 Before & After 결과가 있는가?

있다. Before는 `MEMORY_LIMIT=50`에서 프로세스 시작 로그 `06:20:49.724`부터 종료 로그 `06:20:54.776`까지 약 5.1초 생존했다. After는 `MEMORY_LIMIT=128`에서 `06:19:51.020`부터 `06:20:08.132`까지 약 17.1초 생존했다. 생존 시간은 약 12초, 약 3.4배 늘었고, 최대 관측 RSS도 42,708KB에서 145,116KB로 증가했다. 그러나 Heap 증가 자체는 계속되어 After도 150MB에서 종료되었으므로 제한 상향은 임시 조치이지 누수 해결이 아니다.

근거: [OOM After 화면](assets/oom-after-terminal.png), [Before/After 표](01-oom-crash.md#4-workaround--verification-조치-및-검증)

### 질문 1-3. [CPU] CPU 사용률이 임계치를 초과해 프로세스가 종료되는 패턴이 기록되어 있는가?

있다. PID 39의 앱 내부 부하 지표 `CpuWorker Current Load`가 5.00%에서 53.77%까지 올라간 뒤 `06:25:02.680`에 `CPU Threshold Violated! (53.77%)`와 `Terminated`가 기록되었다. `result.env`도 `STATE=exited`다. 단, `monitor.csv`의 `ps %CPU` 최대 8.8%는 OS가 관측한 프로세스 CPU 비율이고, 53.77%는 애플리케이션이 계산한 내부 부하 값이다. 두 지표의 의미가 다르므로 “OS 관측값이 53.77%였다”고 표현하면 안 된다.

근거: [CPU Before 화면](assets/cpu-before-terminal.png), [app.log](../evidence/cpu-before/20260604-062432/app.log), [monitor.csv](../evidence/cpu-before/20260604-062432/monitor.csv)

### 질문 1-4. [CPU] `CPU_MAX_OCCUPY` 조정 후 종료 여부나 생존 시간이 달라졌는가?

달라졌다. Before의 `CPU_MAX_OCCUPY=100`에서는 내부 부하가 53.77%까지 상승해 약 30초 만에 종료되었다. After의 `CPU_MAX_OCCUPY=10`에서는 10.00% 도달 시 `Peak reached`로 cooldown에 들어가고 5.00%까지 낮춘 뒤 다시 증가했다. 이 사이클을 반복하면서 90초 관찰 시간 동안 자체 종료하지 않았고 `STATE=running_after_timeout`이 기록되었다. After 로그 끝의 `Terminated`는 장애 종료가 아니라 runner가 90초 수집을 마친 뒤 보낸 종료 신호다.

근거: [CPU After 화면](assets/cpu-after-terminal.png), [result.env](../evidence/cpu-after/20260604-062541/result.env)

### 질문 1-5. [Deadlock] PID는 존재하지만 CPU·메모리 변화와 로그가 멈춘 상태를 식별했는가?

식별했다. Before의 PID 38은 마지막 대기 로그 `06:28:50.604` 이후에도 `06:30:10`의 `monitor.csv`와 `06:30:11`의 프로세스 스냅샷에 존재했다. 마지막 두 샘플은 `STAT=SNl`, CPU 0.0%, 메모리 0.1%, RSS 13,772KB로 동일했다. 약 80초 동안 의미 있는 앱 로그가 추가되지 않았고 `STATE=running_after_timeout`이므로 프로세스는 죽은 것이 아니라 진행이 정지한 상태다.

근거: [Deadlock Before 화면](assets/deadlock-before-terminal.png), [process_snapshot.txt](../evidence/deadlock-before/20260604-062841/process_snapshot.txt), [monitor.csv](../evidence/deadlock-before/20260604-062841/monitor.csv)

### 질문 1-6. [Deadlock] `MULTI_THREAD_ENABLE` 조정 후 재현·회피 비교가 있는가?

있다. Before의 `MULTI_THREAD_ENABLE=true`에서는 두 워커가 서로의 자원을 기다리며 `WAITING ... BLOCKED`에서 멈췄다. After의 `MULTI_THREAD_ENABLE=false`에서는 `06:30:37.738`에 스케줄러가 초기화되고 `06:30:38.855`에 `All tasks completed`가 기록되었으며, 90초 동안 프로세스가 생존했다. 즉 단일 스레드 경로로 우회하면 재현되지 않았다. 이 설정은 회피책이며, 근본 해결은 락 순서 통일과 timeout/rollback이다.

근거: [Deadlock After 화면](assets/deadlock-after-terminal.png), [Before/After 표](03-deadlock.md#4-workaround--verification-조치-및-검증)

### 질문 1-7. 세 리포트가 GitHub Issue 구조를 갖추고 있는가?

그렇다. 세 문서 모두 제목을 `[Bug]`로 시작하고 `1. Description(현상) → 2. Evidence & Logs(증거) → 3. Root Cause Analysis(원인) → 4. Workaround & Verification(조치·검증)` 순서를 사용한다. 따라서 평가 기준의 “현상 → 증거 → 원인 → 조치” 구조와 일치한다.

### 질문 1-8. PID, 타임스탬프, 핵심 로그가 포함된 증거가 첨부되어 있는가?

그렇다. 각 리포트에는 Before/After 실제 iTerm2 화면 두 장과 원본 파일 링크가 있다. OOM·CPU 화면에는 PID 39, Deadlock Before에는 PID 38이 표시된다. 모든 화면에는 `2026-06-04` 타임스탬프와 MemoryGuard, CPU Threshold, `WAITING ... BLOCKED`, `All tasks completed` 같은 핵심 메시지가 포함되어 있다. 이미지가 보이지 않는 환경에서도 바로 아래의 원본 `run.env`, `monitor.csv`, `app.log`, `result.env`, 스냅샷 링크와 텍스트 발췌로 같은 내용을 검증할 수 있다.

## 항목 2. 명령어와 진단 흐름

### 질문 2-1. `monitor.sh`에서 메모리 증가를 어떤 명령과 방법으로 추적했는가?

`monitor.sh`는 인자로 PID와 샘플 간격을 받고, 기본 1초마다 아래 흐름을 반복한다.

```bash
while kill -0 "$pid" 2>/dev/null; do
  ts="$(date '+%Y-%m-%d %H:%M:%S')"
  ps -p "$pid" -o pid=,stat=,pcpu=,pmem=,rss=,vsz=,nlwp=,comm=
  sleep "$interval"
done
```

- `kill -0 PID`는 신호를 보내지 않고 해당 PID에 신호를 보낼 수 있는지 확인해 반복 지속 여부를 결정한다.
- `date`는 앱 로그와 자원 샘플을 대조할 타임스탬프를 만든다.
- `ps -p PID`는 한 프로세스만 선택한다.
- `rss`는 현재 물리 메모리에 올라온 상주 메모리(KB), `vsz`는 가상 주소 공간(KB), `pmem`은 물리 메모리 대비 비율이다.
- `awk`는 공백 기반 `ps` 출력을 `timestamp,pid,...,rss_kb,...` CSV로 변환한다.

메모리 추세는 CSV의 1열 시각과 6열 `rss_kb`를 뽑아 확인했다.

```bash
awk -F, 'NR > 1 { print $1, $6 }' monitor.csv
awk -F, 'NR == 2 { first=$6 } NR > 1 { last=$6; if ($6 > max) max=$6 } END { print first, last, max }' monitor.csv
```

OOM After에서는 RSS가 17,096 → 42,700 → 68,304 → 93,908 → 119,512 → 145,116KB로 계단형이지만 일정 간격으로 계속 증가했다. 앱 Heap 로그도 3초마다 25MB씩 증가하므로 일시적 스파이크가 아니라 지속적인 증가 패턴으로 판단했다.

### 질문 2-2. CPU 사용률 확인 도구와 옵션의 의미는 무엇인가?

시간 계열 수집에는 파싱하기 쉬운 `ps`, 교차 확인에는 Linux batch `top`, 스레드 확인에는 `ps -L`을 사용했다.

```bash
ps -p "$pid" -o pid=,stat=,pcpu=,pmem=,rss=,vsz=,nlwp=,comm=
top -b -n 1 -p "$pid"
ps -L -p "$pid" -o pid,tid,stat,pcpu,pmem,comm
```

- `ps -p`: 대상 PID만 선택한다.
- `-o`: 출력할 필드를 직접 정한다. 뒤의 `=`는 헤더를 제거해 CSV 변환을 쉽게 한다.
- `pcpu`: Linux `ps`가 계산한 프로세스 CPU 비율, `stat`: 실행·수면 상태와 nice·멀티스레드 플래그, `nlwp`: 스레드 수다.
- `top -b`: 대화형 화면이 아닌 batch 텍스트 출력, `-n 1`: 한 번만 측정, `-p PID`: 대상 PID로 제한한다.
- `ps -L`: 프로세스의 LWP/TID를 행별로 펼쳐 어느 스레드가 CPU를 쓰는지 본다.

앱 로그의 `CpuWorker Current Load`는 앱 내부 부하 모델이고 `ps/top %CPU`는 OS가 관측한 CPU 소비량이다. CPU Before 종료 판단은 전자의 53.77%와 `CPU Threshold Violated`를 근거로 했고, `ps/top`은 OS 관점 보조 증거로 사용했다.

### 질문 2-3. “살아 있지만 멈춘 상태”를 어떤 순서로 진단했는가?

판단 흐름은 다음과 같다.

1. `kill -0 PID`와 `ps -p PID`로 프로세스 존재를 확인했다. Deadlock Before의 PID 38은 90초 뒤에도 존재했다.
2. `tail`로 앱 로그의 마지막 시각과 메시지를 확인했다. `06:28:50.604 WAITING ... BLOCKED` 이후 진행 로그가 없었다.
3. `monitor.csv`의 처음과 마지막을 비교했다. 마지막 두 행에서 CPU 0.0%, RSS 13,772KB가 고정되었다.
4. `ps -L`로 메인 스레드를 포함한 3개 스레드가 존재하지만 모두 CPU 0.0%인 것을 확인했다.
5. `top -b -n 1 -p PID`로 프로세스 전체도 소비 없이 수면 상태인 것을 교차 확인했다.
6. 마지막으로 앱 로그의 락 획득·대기 순서를 연결해 단순 idle이 아니라 순환 대기임을 확정했다.

실제 운영이라면 이 단계 다음에 언어별 thread dump, `pstack/gdb`, `strace -f -p PID` 또는 eBPF로 futex 대기를 수집한다. 이번 미션에서는 제공된 로그와 `ps/top` 증거만 사용했으므로 이러한 도구를 실제 사용했다고 주장하지 않는다.

## 항목 3. 운영체제 원리

### 질문 3-1. 메모리 누수 때 보호 정책이 프로세스를 강제 종료하는 이유는 무엇인가?

누수는 요청이 끝나도 객체 참조나 버퍼가 해제되지 않아 프로세스 RSS가 계속 증가하는 현상이다. 이를 방치하면 가용 메모리가 줄고 reclaim과 swap이 늘어 전체 서버 지연이 커진다. 더 진행되면 커널 OOM Killer가 어떤 프로세스를 희생할지 선택하게 되어 장애 범위가 예측 불가능해진다. 애플리케이션 MemoryGuard는 정해진 메모리 예산을 넘은 문제 프로세스 하나를 먼저 종료해 호스트 전체 장애로 번지는 것을 막는다. 이번 로그의 `Self-terminating process 39 to prevent system instability`가 그 정책을 직접 보여준다. 단, 종료는 누수의 근본 수정이 아니라 피해를 제한하는 fail-fast 조치다.

### 질문 3-2. CPU 과점유 프로세스 하나를 종료하는 것이 왜 시스템 보호에 필요한가?

CPU를 계속 점유하는 프로세스는 run queue를 늘려 같은 호스트의 다른 요청, 모니터링, SSH, 데이터베이스 작업의 스케줄링을 지연시킨다. 컨테이너나 cgroup 제한이 없으면 하나의 결함이 서비스 전체의 tail latency와 처리량을 악화시킬 수 있다. 따라서 cooldown, nice, rate limit, cgroup quota로 먼저 제한하고 회복되지 않으면 해당 프로세스만 재시작하는 것이 장애 격리에 유리하다. 이번 앱은 내부 부하가 보호 임계치를 넘자 종료해 더 넓은 자원 고갈을 막았다. 다만 운영 설계에서는 즉시 종료보다 throttling과 graceful shutdown을 우선하는 것이 보통 더 안전하다.

### 질문 3-3. Deadlock을 상호 배제와 순환 대기로 설명하면?

`Shared_Memory_A`와 `Socket_Pool_B`는 한 번에 한 스레드만 점유할 수 있으므로 상호 배제 자원이다. Thread-1은 A를 가진 채 B를 기다리고, Thread-2는 B를 가진 채 A를 기다린다. 상대가 가진 락을 강제로 빼앗을 수 없으므로 둘 다 기존 락을 놓지 않은 채 대기한다. 대기 그래프는 `Thread-1 → B → Thread-2 → A → Thread-1`로 닫힌 고리를 만들며 이것이 순환 대기다. 상호 배제, 점유 대기, 비선점, 순환 대기의 네 조건이 동시에 성립해 어느 스레드도 진행하지 못한다.

### 질문 3-4. 로그에서 AB/BA 순환 의존을 어떻게 추적했는가?

같은 스레드 이름을 기준으로 시간순 사건을 묶었다.

1. `06:28:48.593`: Thread-1이 A(`Shared_Memory_A`)를 획득했다.
2. 같은 시각: Thread-2가 B(`Socket_Pool_B`)를 획득했다.
3. `06:28:50.595~596`: Thread-1이 B가 필요하다며 `BLOCKED`가 되었다. 즉 A를 보유한 채 B를 기다린다.
4. `06:28:50.604`: Thread-2가 A가 필요하다며 `BLOCKED`가 되었다. 즉 B를 보유한 채 A를 기다린다.

따라서 획득 순서는 Thread-1이 A→B, Thread-2가 B→A로 반대다. 이후 락 해제나 완료 로그가 없고 PID만 생존하므로 AB/BA 순환 의존을 Deadlock 원인으로 판정했다.

## 항목 4. 운영 개선과 종합 판단

### 질문 4-1. 운영 서버라면 메모리 누수를 사전에 찾도록 `monitor.sh`를 어떻게 개선할 것인가?

현재 스크립트는 원시 샘플 수집에는 충분하지만 알림과 예측이 없다. 다음을 추가한다.

1. 최근 5~15분 RSS의 선형 회귀 기울기와 증가 지속 횟수를 계산한다. 단순 임계값뿐 아니라 `RSS 증가율 > X MB/min`을 탐지한다.
2. 현재 RSS와 제한값으로 `time_to_limit = (limit - rss) / slope`를 계산하고, 제한 도달 예상 시간이 30분 이하이면 조기 경보한다.
3. 순간 스파이크를 누수로 오인하지 않도록 N회 연속 상승, 이동평균, GC 전후 최저점이 계속 높아지는지 함께 본다.
4. PID 재사용을 피하도록 `/proc/PID/stat`의 시작 시각과 command line을 기록하고, `/proc/PID/smaps_rollup`의 RSS/PSS/private dirty를 수집한다.
5. 컨테이너에서는 cgroup의 `memory.current`, `memory.events`, `memory.max`, CPU throttling 지표를 함께 수집한다.
6. Prometheus node/process exporter 또는 애플리케이션 메트릭으로 전송해 Grafana 추세, Alertmanager 알림, 재시작 이력을 남긴다.
7. 로그 heartbeat와 마지막 로그 경과 시간, 스레드별 CPU도 함께 수집해 OOM과 Deadlock을 구분한다.
8. 모니터 자체의 파일 회전, 디스크 사용량 제한, 실패 시 알림, 종료 사유와 exit code 기록을 추가한다.

핵심은 “현재 80%를 넘었는가”뿐 아니라 “계속 증가하는가, 언제 제한에 닿는가”를 판단하는 것이다.

### 질문 4-2. 세 장애 중 실제 서비스에서 가장 치명적인 것은 무엇이며 어떻게 예방할 것인가?

이 서비스 형태에서는 Deadlock이 가장 치명적이라고 판단한다. OOM과 CPU 보호 종료는 프로세스가 죽어 supervisor나 Kubernetes가 재시작할 수 있지만, Deadlock은 PID와 포트가 살아 있어 단순 liveness check를 통과하면서 실제 요청만 무기한 멈출 수 있다. 연결과 작업 큐가 쌓여 연쇄 timeout이 발생하고 탐지도 늦다.

근본 예방은 모든 코드가 동일한 전역 락 순서(A 후 B)를 지키게 하고, 중첩 락을 줄이며, `try_lock`/timeout 실패 시 이미 잡은 락을 해제하고 재시도하도록 만드는 것이다. 가능하면 공유 가변 상태를 actor/message queue 또는 단일 소유 워커로 바꾼다. 테스트에서는 락 순서를 검사하고 반복·스트레스·fault injection으로 재현하며, 운영에서는 실제 작업 완료를 확인하는 readiness와 progress heartbeat를 사용한다. 단, 결제처럼 데이터 무결성이 우선인 서비스나 메모리가 매우 작은 공용 노드에서는 OOM의 위험도가 더 클 수 있으므로 최종 우선순위는 서비스 특성에 맞춰야 한다.

### 질문 4-3. OOM과 Deadlock이 동시에 발생했다면 어떤 순서로 대응할 것인가?

호스트 전체로 번질 수 있는 메모리 압박을 먼저 안정화하되, 재시작 전에 Deadlock 증거를 짧게 확보한다.

1. `free`, cgroup 메모리, RSS 증가율로 실제 메모리 긴급도를 확인하고 PID·시각·마지막 로그를 기록한다.
2. 수 초 안에 `ps -L`과 thread dump를 확보한다. 프로세스를 먼저 죽이면 순환 대기 증거가 사라지기 때문이다.
3. 가용 메모리가 위험하면 트래픽을 다른 인스턴스로 우회하고 문제 프로세스를 graceful stop 후 강제 종료한다. cgroup limit으로 호스트를 보호한다.
4. 정상 인스턴스를 제한된 트래픽으로 재기동해 서비스를 복구한다.
5. 보존한 dump로 락 순환과 메모리 보유 관계를 분석한다. Deadlock 때문에 정리 코드가 실행되지 않아 메모리가 쌓였는지도 확인한다.

즉 분석 우선순위는 “가벼운 Deadlock 증거 보존 → OOM 확산 방지와 서비스 복구 → 상세 Deadlock 원인 분석”이다. 메모리가 이미 임계 상태라면 증거 수집 시간을 제한하고 즉시 종료한다.

### 질문 4-4. 소스 코드를 수정할 수 있다면 장애별로 무엇을 개선할 것인가?

| 장애 | 코드 수준 개선 |
| --- | --- |
| OOM | 요청 종료 시 참조·버퍼를 해제하고, 무제한 리스트/맵을 bounded collection으로 바꾸며, 캐시에 TTL·LRU·크기 상한을 둔다. 대용량 데이터는 streaming 처리하고 queue에 backpressure를 적용한다. heap profile과 allocation stack으로 누수 지점을 회귀 테스트한다. MemoryGuard는 종료 전 진단 dump와 graceful cleanup을 남긴다. |
| CPU | busy loop를 blocking wait/event 기반으로 바꾸고 작업을 작은 단위로 분할한다. 워커 수, 큐 소비량, 요청 rate에 상한을 두고 cooperative cancellation을 넣는다. profiler로 hot path와 불필요한 직렬화·재시도를 제거한다. 임계치 접근 시 cooldown/throttle하고 지속 초과일 때만 종료한다. |
| Deadlock | 모든 락에 전역 획득 순서를 정의하고 RAII/context manager로 해제를 보장한다. 중첩 임계구역을 축소하고 `try_lock(timeout)` 실패 시 보유 락을 풀어 rollback/backoff한다. 가능하면 두 락을 하나의 소유자 또는 actor/message passing으로 대체한다. AB/BA 동시 실행 테스트와 lock-order 검사를 CI에 넣는다. |

환경변수 변경은 증상 발생 조건만 늦추거나 우회한다. 위 수정처럼 자원 수명, 작업량, 동시성 구조를 바꿔야 근본 해결이다.

### 질문 4-5. 미션을 다시 한다면 무엇을 다르게 접근할 것인가?

먼저 정상 기준선을 한 번 수집하고 장애별 가설과 판정 기준을 표로 만든다. 그다음 한 번에 환경변수 하나만 바꾸고 각 조건을 최소 3회 반복해 우연성을 줄인다. 실행 시작 시각, PID, 환경변수, 바이너리 해시, 종료 code를 자동 기록하고 `monitor.sh`, 앱 로그, cgroup 지표를 같은 monotonic timeline으로 맞춘다. Deadlock은 “PID 생존 + 마지막 progress 경과 시간 + 스레드 CPU 0 + 대기 그래프”를 판정식으로 정의하고, OOM은 RSS 기울기와 time-to-limit, CPU는 OS 사용률과 앱 내부 부하를 분리한다. 마지막으로 실험 직후 자동으로 Before/After 표와 증거 링크를 생성해 수동 복사 오류를 줄이고, 평가 체크리스트 20개를 제출 전에 역검증한다.

## 발표용 핵심 요약

- OOM: PID 39, Heap 25→50MB 후 MemoryGuard 종료. 제한 50→128MB로 생존 약 5.1→17.1초 증가했지만 누수는 유지됐다.
- CPU: PID 39, 앱 내부 부하 53.77%에서 임계치 위반 종료. 목표 100→10% 조정 후 cooldown으로 90초 생존했다.
- Deadlock: PID 38, A→B와 B→A 순환 대기 후 약 80초 정체. 멀티스레드를 끄면 작업이 완료됐다.
- 임시 설정 변경과 근본 수정은 다르다. 근본 수정은 메모리 수명 관리, CPU 작업량 제한, 일관된 락 순서다.
