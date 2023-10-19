# imported by "spec_helper.sh"
# shellcheck shell=sh

shellspec_syntax 'shellspec_matcher_include_name'
shellspec_matcher_include_name() {
    shellspec_matcher__match() {
        SHELLSPEC_EXPECT="$1"
        SHELLSPEC_SUBJECT=$(echo "$SHELLSPEC_SUBJECT" | jq -r '.name')
        [ "$SHELLSPEC_EXPECT" == "$SHELLSPEC_EXPECT" ] || return 1
        expr "$SHELLSPEC_SUBJECT" : "$SHELLSPEC_EXPECT" > /dev/null || return 1
        return 0
    }

    # Message when the matcher fails with "should"
    shellspec_matcher__failure_message() {
        shellspec_putsn "expected: $1 match $2"
    }

    # Message when the matcher fails with "should not"
    shellspec_matcher__failure_message_when_negated() {
        shellspec_putsn "expected: $1 not match $2"
    }

    # checking for parameter count
    shellspec_syntax_param count [ $# -eq 1 ] || return 0
    shellspec_matcher_do_match "$@"
}

shellspec_syntax 'shellspec_matcher_include_location'
shellspec_matcher_include_location() {
    shellspec_matcher__match() {
        SHELLSPEC_EXPECT="$1"
        SHELLSPEC_SUBJECT=$(echo "$SHELLSPEC_SUBJECT" | jq -r '.location')
        [ "$SHELLSPEC_EXPECT" = "$SHELLSPEC_EXPECT" ] || return 1
        expr "$SHELLSPEC_SUBJECT" : "$SHELLSPEC_EXPECT" > /dev/null || return 1
        return 0
    }

    # Message when the matcher fails with "should"
    shellspec_matcher__failure_message() {
        shellspec_putsn "expected: $1 match $2"
    }

    # Message when the matcher fails with "should not"
    shellspec_matcher__failure_message_when_negated() {
        shellspec_putsn "expected: $1 not match $2"
    }

    # checking for parameter count
    shellspec_syntax_param count [ $# -eq 1 ] || return 0
    shellspec_matcher_do_match "$@"
}

shellspec_syntax 'shellspec_matcher_include_json'
shellspec_matcher_include_json() {
    shellspec_matcher__match() {
        SHELLSPEC_EXPECT="$2"
        SHELLSPEC_SUBJECT=$(echo "$SHELLSPEC_SUBJECT" | jq -r $1)
        [ "$SHELLSPEC_EXPECT" = "$SHELLSPEC_EXPECT" ] || return 1
        expr "$SHELLSPEC_SUBJECT" : "$SHELLSPEC_EXPECT" > /dev/null || return 1
        return 0
    }

    # Message when the matcher fails with "should"
    shellspec_matcher__failure_message() {
        shellspec_putsn "expected: $1 match $2"
    }

    # Message when the matcher fails with "should not"
    shellspec_matcher__failure_message_when_negated() {
        shellspec_putsn "expected: $1 not match $2"
    }

    # checking for parameter count
    shellspec_syntax_param count [ $# -eq 2 ] || return 0
    shellspec_matcher_do_match "$@"
}
