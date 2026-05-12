#!/bin/sh

set -eu

ANT_CMD="${1:-./ant}"
RESULT_DIR="${2:-build-ant/history}"

PROJECT_ROOT="$(pwd)"
RESULT_PATH="$PROJECT_ROOT/$RESULT_DIR"

mkdir -p "$RESULT_PATH"

COMMITS="$(git rev-list --first-parent HEAD)"

if [ -z "$COMMITS" ]; then
    echo "Git history is empty."
    exit 1
fi

GOOD_COMMIT=""
GOOD_INDEX=-1
INDEX=0

for COMMIT in $COMMITS; do
    SHORT="$(printf '%s' "$COMMIT" | cut -c1-7)"

    echo "Checking revision $SHORT..."

    TEMP_DIR="$RESULT_PATH/check-$SHORT"
    ARCHIVE_FILE="$RESULT_PATH/check-$SHORT.tar"

    rm -rf "$TEMP_DIR" "$ARCHIVE_FILE"
    mkdir -p "$TEMP_DIR"

    git archive --format=tar -o "$ARCHIVE_FILE" "$COMMIT"
    tar -xf "$ARCHIVE_FILE" -C "$TEMP_DIR"

    cp "$PROJECT_ROOT/build.xml" "$TEMP_DIR/build.xml"
    cp "$PROJECT_ROOT/build.properties" "$TEMP_DIR/build.properties"
    cp "$PROJECT_ROOT/MANIFEST.MF" "$TEMP_DIR/MANIFEST.MF"

    if [ -d "$PROJECT_ROOT/tools/apache-ant" ]; then
        mkdir -p "$TEMP_DIR/tools"
        cp -R "$PROJECT_ROOT/tools/apache-ant" "$TEMP_DIR/tools/apache-ant"
    fi

    if [ -f "$PROJECT_ROOT/ant" ]; then
        cp "$PROJECT_ROOT/ant" "$TEMP_DIR/ant"
        chmod +x "$TEMP_DIR/ant"
    fi

    (
        cd "$TEMP_DIR"
        "$PROJECT_ROOT/$ANT_CMD" -f "$TEMP_DIR/build.xml" clean compile
    )

    if [ $? -eq 0 ]; then
        GOOD_COMMIT="$COMMIT"
        GOOD_INDEX="$INDEX"
        break
    fi

    INDEX=$((INDEX + 1))
done

if [ -z "$GOOD_COMMIT" ]; then
    echo "No compilable revision was found."
    exit 1
fi

GOOD_SHORT="$(printf '%s' "$GOOD_COMMIT" | cut -c1-7)"

echo "Last compilable revision: $GOOD_SHORT"

printf '%s\n' "$GOOD_COMMIT" > "$RESULT_PATH/last-working.txt"

if [ "$GOOD_INDEX" -eq 0 ]; then
    echo "Current revision compiles. Diff is not needed."
    printf 'Current revision compiles: %s\n' "$GOOD_COMMIT" > "$RESULT_PATH/history-result.txt"
else
    BAD_INDEX=$((GOOD_INDEX - 1))
    BAD_COMMIT="$(printf '%s\n' "$COMMITS" | sed -n "$((BAD_INDEX + 1))p")"
    BAD_SHORT="$(printf '%s' "$BAD_COMMIT" | cut -c1-7)"

    echo "Creating diff between $GOOD_SHORT and next revision $BAD_SHORT..."

    git diff "$GOOD_COMMIT" "$BAD_COMMIT" > "$RESULT_PATH/history.diff"

    {
        printf 'Last working: %s\n' "$GOOD_COMMIT"
        printf 'Next revision: %s\n' "$BAD_COMMIT"
        printf 'Diff: history.diff\n'
    } > "$RESULT_PATH/history-result.txt"
fi