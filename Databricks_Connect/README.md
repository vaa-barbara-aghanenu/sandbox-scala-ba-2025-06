# Local Spark Pytest Harness (No Local Installs Required)

This repo lets any engineer clone the code and run Spark-backed `pytest` suites without installing Python, Java, or Spark on their machine. A PowerShell helper downloads an embeddable Python build, a Temurin JRE 17 zip, installs `pyspark` + `pytest`, and launches the tests—everything stays inside the repo’s `.tools/` folder.

## Prerequisites

- Windows with PowerShell 5+ (ships with Windows 10/11).
- Outbound internet access the first time you run the script (downloads ~400 MB).
- Enough disk space for the portable runtimes (~1 GB inside the repo).

## Quick start

```powershell
git clone <this repo> Databricks_Connect
cd Databricks_Connect
.\scripts\portable_pytest.ps1
```

The script will:

1. Download `python-3.11.9-embed-amd64.zip`, unpack it into `.tools/python`, enable `import site`, and install `pip`.
2. Download `OpenJDK17U-jre_x64_windows_hotspot_17.0.12_7.zip`, unpack it into `.tools/jdk`, and export `JAVA_HOME`.
3. Install everything from `requirements-dev.txt` using the embedded Python interpreter.
4. Run `python -m pytest` to execute the suite.

All downloads are cached so subsequent runs are fast and offline-friendly. To skip the pytest execution and only bootstrap the toolchain, pass `-BootstrapOnly`.

```powershell
.\scripts\portable_pytest.ps1 -BootstrapOnly
```

## Running different test selections

Forward any pytest selector via `-PytestArgs`. A few common examples:

```powershell
# Everything under tests/
.\scripts\portable_pytest.ps1

# Specific file, verbose output
.\scripts\portable_pytest.ps1 -PytestArgs @("tests/test_session_smoke.py", "-vv")

# Only tests whose names/markers match "spark_local" and not "slow"
.\scripts\portable_pytest.ps1 -PytestArgs @("-k", "spark_local and not slow")

# A single test function
.\scripts\portable_pytest.ps1 -PytestArgs @("tests/pipelines/test_jobs.py::TestDailyJob::test_happy_path")
```

Because the script always reuses the cached runtimes, you can run it multiple times back-to-back with different selectors and it will only spend time running pytest.

When corporate policies block script execution, wrap the command in a one-liner that temporarily bypasses the policy:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\portable_pytest.ps1 -PytestArgs @('-vv')
```

Use this variant in terminals where `.\scripts\portable_pytest.ps1` would otherwise fail with an execution-policy error; it launches a child PowerShell process with the needed permissions and then exits.

## Repository layout

| Path | Purpose |
| --- | --- |
| `scripts/portable_pytest.ps1` | Downloads portable Python + JRE, installs deps, and runs pytest. |
| `scripts/bootstrap_local_env.ps1` | Optional helper if someone wants a standard `.venv` using their system Python. |
| `.tools/` | Auto-created cache that stores the embedded runtimes. Safe to delete; the script recreates it. |
| `requirements-dev.txt` | Pins `pyspark`, `pytest`, and supporting libraries. |
| `tests/conftest.py` | Session-scoped `spark` fixture using `SparkSession.builder.master("local[2]")`. |
| `tests/test_session_smoke.py` | Minimal smoke test proving Spark works locally. |
| `pytest.ini` | Registers the `spark_local` marker to avoid warnings. |

## Rolling this out to a team

1. Share this repo and instruct engineers to run `scripts/portable_pytest.ps1`. They only need PowerShell and internet connectivity the first time.
2. Include the script in onboarding docs so new hires know they don’t have to install Python or Java by hand.
3. Cache the `.tools/` folder in CI (or rerun the script in pipelines) to ensure identical toolchains between laptops and automation.
4. Extend the `tests/` folder with real Spark logic, marking the ones that hit Spark using `@pytest.mark.spark_local`.

## Troubleshooting

| Symptom | Fix |
| --- | --- |
| Script blocked by execution policy | Run `powershell -ExecutionPolicy Bypass -File .\scripts\portable_pytest.ps1`. |
| Download failures | Ensure corporate proxies/firewalls allow `python.org`, `github.com`, and `bootstrap.pypa.io`, or host the zips internally and tweak the URLs in the script. |
| `JAVA_HOME` not detected | Delete `.tools/jdk` and rerun the script so it can re-extract the JRE. |
| Need to reclaim disk space | Delete `.tools/` and rerun the script when you next need Spark tests. |

## Optional: traditional virtual environment

If someone already has Python + Java installed locally, they can continue to use `.venv` via `scripts/bootstrap_local_env.ps1`. The portable workflow remains the default for everyone else.
