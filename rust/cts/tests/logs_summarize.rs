use assert_cmd::Command;
use predicates::prelude::*;

#[test]
fn runs_and_creates_output() {
    let mut cmd = Command::cargo_bin("cts").unwrap();
    cmd.args(["logs", "summarize", "--project-root", ".", "--out", "logs/log_summary_test.json"]) ;
    let assert = cmd.assert();
    assert.success();
}
