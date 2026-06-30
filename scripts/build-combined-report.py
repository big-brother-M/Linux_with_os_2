#!/usr/bin/env python3
from __future__ import annotations

from datetime import datetime
from pathlib import Path

import markdown


ROOT = Path(__file__).resolve().parents[1]
REPORT_DIR = ROOT / "reports"
REPORTS = [
    REPORT_DIR / "01-oom-crash.md",
    REPORT_DIR / "02-cpu-latency.md",
    REPORT_DIR / "03-deadlock.md",
    REPORT_DIR / "04-scheduling-analysis.md",
]


def main() -> None:
    sections: list[str] = []
    for report in REPORTS:
        body = markdown.markdown(
            report.read_text(encoding="utf-8"),
            extensions=["fenced_code", "tables", "toc"],
            output_format="html5",
        )
        sections.append(f'<section class="report" data-source="{report.name}">{body}</section>')

    generated_at = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    html = f"""<!doctype html>
<html lang="ko">
<head>
  <meta charset="utf-8">
  <title>B1-2 System Failure Analysis</title>
  <style>
    @page {{
      size: A4;
      margin: 15mm 14mm;
    }}
    * {{
      box-sizing: border-box;
    }}
    body {{
      margin: 0;
      color: #15171a;
      font-family: -apple-system, BlinkMacSystemFont, "Apple SD Gothic Neo", "Noto Sans CJK KR", "Malgun Gothic", Arial, sans-serif;
      font-size: 10.5pt;
      line-height: 1.58;
      background: #fff;
    }}
    .cover {{
      min-height: 240mm;
      display: flex;
      flex-direction: column;
      justify-content: center;
      border-bottom: 1px solid #d7dce2;
    }}
    .cover h1 {{
      margin: 0 0 10mm;
      font-size: 28pt;
      line-height: 1.18;
      letter-spacing: 0;
    }}
    .cover p {{
      margin: 0 0 3mm;
      color: #4a5563;
      font-size: 12pt;
    }}
    .report {{
      break-before: page;
    }}
    h1 {{
      margin: 0 0 7mm;
      font-size: 20pt;
      line-height: 1.25;
      letter-spacing: 0;
      color: #0f172a;
    }}
    h2 {{
      margin: 9mm 0 3mm;
      padding-bottom: 1.5mm;
      border-bottom: 1px solid #d7dce2;
      font-size: 14pt;
      line-height: 1.35;
      letter-spacing: 0;
      color: #172033;
    }}
    h3 {{
      margin: 6mm 0 2mm;
      font-size: 12pt;
    }}
    p {{
      margin: 0 0 3.2mm;
    }}
    ul, ol {{
      margin: 0 0 3.5mm 6mm;
      padding: 0;
    }}
    li {{
      margin: 0 0 1.3mm;
    }}
    table {{
      width: 100%;
      margin: 4mm 0 5mm;
      border-collapse: collapse;
      font-size: 9.5pt;
    }}
    th, td {{
      border: 1px solid #cfd6df;
      padding: 2mm;
      vertical-align: top;
    }}
    th {{
      background: #eef2f6;
      font-weight: 700;
    }}
    code {{
      font-family: "SFMono-Regular", Consolas, "Liberation Mono", Menlo, monospace;
      font-size: 9pt;
    }}
    pre {{
      margin: 3mm 0 4mm;
      padding: 3mm;
      overflow-wrap: anywhere;
      white-space: pre-wrap;
      border: 1px solid #d7dce2;
      border-radius: 4px;
      background: #f6f8fa;
      font-size: 8.2pt;
      line-height: 1.42;
    }}
    a {{
      color: #1d4ed8;
      text-decoration: none;
    }}
    .meta {{
      margin-top: 12mm;
      color: #6b7280;
      font-size: 10pt;
    }}
  </style>
</head>
<body>
  <section class="cover">
    <h1>B1-2 시스템 장애 분석 리포트</h1>
    <p>OOM Crash, CPU Latency, Deadlock, Scheduling Analysis</p>
    <p>Evidence root: <code>B1-2/evidence/</code></p>
    <p>Generated: {generated_at}</p>
    <p class="meta">Linux Docker 환경에서 제공 바이너리를 실행하고, 로그와 표준 프로세스 도구 출력만 사용했습니다.</p>
  </section>
  {"".join(sections)}
</body>
</html>
"""
    output = REPORT_DIR / "B1-2-system-failure-analysis.html"
    output.write_text(html, encoding="utf-8")
    print(output)


if __name__ == "__main__":
    main()
