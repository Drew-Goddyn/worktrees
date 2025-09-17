#!/usr/bin/env bats

# Unit tests for FeatureName validation rules
# Tests the validation logic in src/models/feature_name.sh

setup() {
    export FEATURE_NAME_MODEL="/Users/drewgoddyn/projects/claude-worktrees/src/models/feature_name.sh"
    export TEMP_DIR="${BATS_TMPDIR}/feature_name_test_$$"
    mkdir -p "$TEMP_DIR"
}

teardown() {
    rm -rf "$TEMP_DIR"
}

# Valid feature name tests - should all pass validation
@test "valid feature name: minimal format 001-test" {
    run "$FEATURE_NAME_MODEL" validate "001-test"
    [ "$status" -eq 0 ]
}

@test "valid feature name: standard format 123-valid-feature-name" {
    run "$FEATURE_NAME_MODEL" validate "123-valid-feature-name"
    [ "$status" -eq 0 ]
}

@test "valid feature name: single character after dash 999-a" {
    run "$FEATURE_NAME_MODEL" validate "999-a"
    [ "$status" -eq 0 ]
}

@test "valid feature name: with numbers 001-feature-with-numbers-123" {
    run "$FEATURE_NAME_MODEL" validate "001-feature-with-numbers-123"
    [ "$status" -eq 0 ]
}

@test "valid feature name: with multiple dashes 001-feature-with-dashes-ok" {
    run "$FEATURE_NAME_MODEL" validate "001-feature-with-dashes-ok"
    [ "$status" -eq 0 ]
}

@test "valid feature name: maximum length 40 chars after dash" {
    run "$FEATURE_NAME_MODEL" validate "999-this-is-exactly-forty-characters-long"
    [ "$status" -eq 0 ]
}

# Invalid feature name format tests - should all fail validation
@test "invalid feature name: no number prefix" {
    run "$FEATURE_NAME_MODEL" validate "invalid-name"
    [ "$status" -eq 2 ]
    [[ "$output" =~ "must match pattern" ]]
}

@test "invalid feature name: uppercase letters not allowed" {
    run "$FEATURE_NAME_MODEL" validate "001-UPPERCASE"
    [ "$status" -eq 2 ]
    [[ "$output" =~ "must match pattern" ]]
}

@test "invalid feature name: only 1 digit prefix" {
    run "$FEATURE_NAME_MODEL" validate "1-short"
    [ "$status" -eq 2 ]
    [[ "$output" =~ "must match pattern" ]]
}

@test "invalid feature name: only 2 digit prefix" {
    run "$FEATURE_NAME_MODEL" validate "12-short"
    [ "$status" -eq 2 ]
    [[ "$output" =~ "must match pattern" ]]
}

@test "invalid feature name: too many digits in prefix" {
    run "$FEATURE_NAME_MODEL" validate "0001-too-many-digits"
    [ "$status" -eq 2 ]
    [[ "$output" =~ "must match pattern" ]]
}

@test "invalid feature name: no name after dash" {
    run "$FEATURE_NAME_MODEL" validate "001-"
    [ "$status" -eq 2 ]
    [[ "$output" =~ "must match pattern" ]]
}

@test "invalid feature name: no dash separator" {
    run "$FEATURE_NAME_MODEL" validate "001"
    [ "$status" -eq 2 ]
    [[ "$output" =~ "must match pattern" ]]
}

@test "invalid feature name: exceeds 40 character limit after dash" {
    run "$FEATURE_NAME_MODEL" validate "001-this-feature-name-is-way-too-long-to-be-valid-and-exceeds-forty-characters"
    [ "$status" -eq 2 ]
    [[ "$output" =~ "must match pattern" ]]
}

@test "invalid feature name: special characters not allowed" {
    run "$FEATURE_NAME_MODEL" validate "001-special@chars"
    [ "$status" -eq 2 ]
    [[ "$output" =~ "must match pattern" ]]
}

@test "invalid feature name: underscore not allowed" {
    run "$FEATURE_NAME_MODEL" validate "001-feature_underscore"
    [ "$status" -eq 2 ]
    [[ "$output" =~ "must match pattern" ]]
}

@test "invalid feature name: empty string" {
    run "$FEATURE_NAME_MODEL" validate ""
    [ "$status" -eq 2 ]
    [[ "$output" =~ "must match pattern" ]]
}

# Reserved name tests - should detect reserved names
@test "reserved name: main is reserved" {
    run "$FEATURE_NAME_MODEL" is_reserved "main"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "true" ]]
}

@test "reserved name: master is reserved" {
    run "$FEATURE_NAME_MODEL" is_reserved "master"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "true" ]]
}

@test "reserved name: MAIN is reserved (case insensitive)" {
    run "$FEATURE_NAME_MODEL" is_reserved "MAIN"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "true" ]]
}

@test "reserved name: Master is reserved (mixed case)" {
    run "$FEATURE_NAME_MODEL" is_reserved "Master"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "true" ]]
}

@test "not reserved name: 001-test is not reserved" {
    run "$FEATURE_NAME_MODEL" is_reserved "001-test"
    [ "$status" -eq 1 ]
    [[ "$output" =~ "false" ]]
}

@test "not reserved name: develop is not reserved" {
    run "$FEATURE_NAME_MODEL" is_reserved "develop"
    [ "$status" -eq 1 ]
    [[ "$output" =~ "false" ]]
}

# Normalization tests - should convert to lowercase
@test "normalize: converts uppercase to lowercase" {
    run "$FEATURE_NAME_MODEL" normalize "001-TEST-FEATURE"
    [ "$status" -eq 0 ]
    [[ "$output" == "001-test-feature" ]]
}

@test "normalize: preserves lowercase" {
    run "$FEATURE_NAME_MODEL" normalize "001-test-feature"
    [ "$status" -eq 0 ]
    [[ "$output" == "001-test-feature" ]]
}

@test "normalize: handles mixed case" {
    run "$FEATURE_NAME_MODEL" normalize "001-MiXeD-CaSe-FeAtUrE"
    [ "$status" -eq 0 ]
    [[ "$output" == "001-mixed-case-feature" ]]
}

# Full validation tests - combines format and reserved name checks
@test "full validation: valid non-reserved name passes" {
    run "$FEATURE_NAME_MODEL" validate_full "001-test-feature"
    [ "$status" -eq 0 ]
}

@test "full validation: reserved name main fails" {
    run "$FEATURE_NAME_MODEL" validate_full "main"
    [ "$status" -eq 2 ]
    [[ "$output" =~ "reserved" ]]
}

@test "full validation: reserved name master fails" {
    run "$FEATURE_NAME_MODEL" validate_full "master"
    [ "$status" -eq 2 ]
    [[ "$output" =~ "reserved" ]]
}

@test "full validation: invalid format fails" {
    run "$FEATURE_NAME_MODEL" validate_full "invalid_name"
    [ "$status" -eq 2 ]
    [[ "$output" =~ "must match pattern" ]]
}

@test "full validation: case insensitive reserved check fails" {
    run "$FEATURE_NAME_MODEL" validate_full "MAIN"
    [ "$status" -eq 2 ]
    [[ "$output" =~ "reserved" ]]
}

# Edge cases and boundary tests
@test "boundary: exactly 40 characters after dash is valid" {
    # This is exactly 40 characters: "this-is-exactly-forty-characters-long"
    run "$FEATURE_NAME_MODEL" validate "001-this-is-exactly-forty-characters-long"
    [ "$status" -eq 0 ]
}

@test "boundary: 41 characters after dash is invalid" {
    # This is 41 characters: "this-is-exactly-forty-one-characters-long"
    run "$FEATURE_NAME_MODEL" validate "001-this-is-exactly-forty-one-characters-long"
    [ "$status" -eq 2 ]
    [[ "$output" =~ "must match pattern" ]]
}

@test "boundary: minimum valid name length" {
    run "$FEATURE_NAME_MODEL" validate "001-a"
    [ "$status" -eq 0 ]
}

@test "error messages: provide helpful examples" {
    run "$FEATURE_NAME_MODEL" validate "invalid"
    [ "$status" -eq 2 ]
    [[ "$output" =~ "Examples:" ]]
    [[ "$output" =~ "001-build-tool" ]]
}

# CLI interface error handling
@test "CLI: missing arguments show usage" {
    run "$FEATURE_NAME_MODEL"
    [ "$status" -eq 1 ]
    [[ "$output" =~ "Usage:" ]]
    [[ "$output" =~ "Commands:" ]]
}

@test "CLI: unknown command shows error" {
    run "$FEATURE_NAME_MODEL" unknown_command "test"
    [ "$status" -eq 1 ]
    [[ "$output" =~ "Unknown command" ]]
}

@test "CLI: validate command with no arguments shows error" {
    run "$FEATURE_NAME_MODEL" validate
    [ "$status" -eq 1 ]
    [[ "$output" =~ "requires exactly one argument" ]]
}