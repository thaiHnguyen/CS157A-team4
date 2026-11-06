#!/usr/bin/env bash
# build.sh -- compile src/main/java into src/main/webapp/WEB-INF/classes
# so VS Code's exploded Tomcat deployment can load the DAO classes.
# Run:  ./build.sh   (from anywhere), then Publish Server (Full).
set -euo pipefail
cd "$(dirname "$0")"

OUT=src/main/webapp/WEB-INF/classes
JAVAC="${JAVA_HOME:+$JAVA_HOME/bin/}javac"

# start clean so deleted/renamed classes don't linger
rm -rf "$OUT" && mkdir -p "$OUT" build
mkdir -p src/main/java
find src/main/java -name '*.java' | sed 's/.*/"&"/' > build/sources.txt
[ -s build/sources.txt ] || { echo "No .java files in src/main/java, nothing to compile."; exit 0; }

"$JAVAC" --release 21 -encoding UTF-8 -d "$OUT" @build/sources.txt
echo "Compiled into $OUT. Now right-click Tomcat -> Publish Server (Full)."
