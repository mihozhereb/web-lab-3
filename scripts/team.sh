#!/bin/sh

set -eu

ANT_CMD="${1:-./ant}"
RESULT_DIR="${2:-build-ant/team}"

PROJECT_ROOT="$(pwd)"
RESULT_PATH="$PROJECT_ROOT/$RESULT_DIR"
WARS_PATH="$RESULT_PATH/wars"

mkdir -p "$RESULT_PATH"
mkdir -p "$WARS_PATH"

COMMITS="$(git rev-list --first-parent --max-count=2 --skip=1 HEAD)"

COUNT="$(printf '%s\n' "$COMMITS" | sed '/^$/d' | wc -l | tr -d ' ')"

if [ "$COUNT" -lt 2 ]; then
    echo "Need at least two previous revisions. Make at least 3 commits in the repository."
    exit 1
fi

for COMMIT in $COMMITS; do
    SHORT="$(printf '%s' "$COMMIT" | cut -c1-7)"

    echo "Building previous revision $SHORT..."

    TEMP_DIR="$RESULT_PATH/rev-$SHORT"
    ARCHIVE_FILE="$RESULT_PATH/rev-$SHORT.tar"

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
        "$PROJECT_ROOT/$ANT_CMD" -f "$TEMP_DIR/build.xml" clean build
    )

    WAR_SOURCE="$TEMP_DIR/build-ant/dist/web-lab-3.war"
    WAR_DEST="$WARS_PATH/web-lab-3-$SHORT.war"

    if [ ! -f "$WAR_SOURCE" ]; then
        echo "WAR file was not created for revision $SHORT."
        exit 1
    fi

    cp "$WAR_SOURCE" "$WAR_DEST"
done

ZIP_RESULT="$RESULT_PATH/team-revisions.zip"

rm -f "$ZIP_RESULT"

(
    cd "$WARS_PATH"
    jar cf "$ZIP_RESULT" ./*.war
)

echo "Created archive: $ZIP_RESULT"