#!/usr/bin/env python3
import glob
import os
import re
import shutil
import subprocess
import sys

COLOR_GREEN = "\033[92m"
COLOR_RED = "\033[91m"
COLOR_BLUE = "\033[94m"
COLOR_RESET = "\033[0m"

INCLUDE_RE = re.compile(r'^\s*include\s+"([^"]+)"')


def print_success(message):
    print(f"{COLOR_GREEN}[PASS] {message}{COLOR_RESET}")


def print_failure(message, details=None):
    print(f"{COLOR_RED}[FAIL] {message}{COLOR_RESET}")
    if details:
        print(details)


def print_info(message):
    print(f"{COLOR_BLUE}[INFO] {message}{COLOR_RESET}")


def expand_asm(src_path, out):
    with open(src_path, encoding="utf-8") as handle:
        for line in handle:
            match = INCLUDE_RE.match(line)
            if match:
                expand_asm(match.group(1), out)
            else:
                out.write(line)


def assemble(src_path, bin_path):
    if shutil.which("sjasmplus"):
        return ["sjasmplus", f"--raw={bin_path}", src_path]
    if shutil.which("z80asm"):
        return ["z80asm", src_path, "-o", bin_path]
    raise FileNotFoundError("need sjasmplus or z80asm")


def run_test(asm_path):
    base_name = os.path.splitext(os.path.basename(asm_path))[0]
    expanded_path = os.path.join("bin", f"{base_name}.asm")
    bin_path = os.path.join("bin", f"{base_name}.bin")

    os.makedirs("bin", exist_ok=True)

    with open(expanded_path, "w", encoding="utf-8") as out:
        expand_asm(asm_path, out)

    try:
        compile_cmd = assemble(expanded_path, bin_path)
    except FileNotFoundError as e:
        print_failure(f"Assembler not found for {asm_path}", str(e))
        return False

    try:
        compile_res = subprocess.run(compile_cmd, capture_output=True, text=True)
        if compile_res.returncode != 0:
            print_failure(
                f"Compilation failed for {asm_path}",
                compile_res.stderr or compile_res.stdout,
            )
            return False
    except Exception as e:
        print_failure(f"Error executing assembler for {asm_path}", str(e))
        return False

    run_cmd = ["z88dk-ticks", "-iochar=1", "-l", "0", "-pc", "0", bin_path]
    try:
        run_res = subprocess.run(
            run_cmd, input="abc\rxy\r", capture_output=True, text=True, timeout=5
        )
        stdout = run_res.stdout
        stderr = run_res.stderr

        for path in (bin_path, expanded_path):
            if os.path.exists(path):
                os.remove(path)

        if "SUCCESS" in stdout and "FAIL" not in stdout:
            print_success(base_name)
            return True

        details = f"Stdout:\n{stdout}\nStderr:\n{stderr}" if stdout or stderr else "No output"
        print_failure(base_name, details)
        return False
    except subprocess.TimeoutExpired as e:
        for path in (bin_path, expanded_path):
            if os.path.exists(path):
                os.remove(path)
        stdout = e.stdout.decode() if isinstance(e.stdout, bytes) else (e.stdout or "")
        stderr = e.stderr.decode() if isinstance(e.stderr, bytes) else (e.stderr or "")
        details = f"Stdout (before timeout):\n{stdout}\nStderr:\n{stderr}"
        print_failure(f"{base_name} - Execution timed out", details)
        return False
    except Exception as e:
        for path in (bin_path, expanded_path):
            if os.path.exists(path):
                os.remove(path)
        print_failure(f"{base_name} - Error executing emulator", str(e))
        return False


def main():
    root_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    os.chdir(root_dir)

    tests = sorted(glob.glob("tests/*_test.asm"))
    total_tests = len(tests)
    if total_tests == 0:
        print_info("No test cases found.")
        sys.exit(0)

    print_info(f"Discovered {total_tests} test case(s). Running...")
    print("-" * 60)

    passed = 0
    failed = 0

    for test in tests:
        if run_test(test):
            passed += 1
        else:
            failed += 1

    print("-" * 60)
    print_info("Test Execution Summary:")
    print_info(f"  Total:  {total_tests}")
    print_info(f"  Passed: {COLOR_GREEN}{passed}{COLOR_RESET}")
    if failed > 0:
        print_info(f"  Failed: {COLOR_RED}{failed}{COLOR_RESET}")
        sys.exit(1)

    print_info(f"  Failed: {failed}")
    sys.exit(0)


if __name__ == "__main__":
    main()
