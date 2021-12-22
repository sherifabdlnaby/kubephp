#!/bin/sh
# Reference: https://github.com/facile-it/terminable-loop-command
# When running a PHP application, you may encounter the need of a background command that runs continuously.
# You can try to write it as a long running process, but it can be prone to memory leaks and other issues.
#
# With this small Shell+PHP combination, you can have a simple loop that:
#   1. starts the command
#   2. does something
#   3. sleeps for a custom amount of time
#   4. shuts down and restarts back again
#  5. The shell script intercepts SIGTERM/SIGINT signals so, when they are received, the PHP script is stopped ASAP but gracefully,
#     since the execution of the body of the command is never truncated.

# This means that you can easily obtain a daemon PHP script without running in memory issues; if you run this in a Kubernetes environment this will be very powerful, since the orchestrator will take care of running the script,
# and at the same time it will apply the proper restart policies in case of crashes. Last but not least, the signal handling will play nice with shutdown requests, like during the roll out of a new deployment.

echo "Starting command: $@";

# Send Termination to Child
_term() {
  kill -TERM $CHILD 2>/dev/null
  wait $CHILD
}

# If we received termination signal we need to pass it to child
trap _term TERM

while true; do
    # Start Command in BG
    $@ &

    # Get It's PID
    CHILD=$!

    # Wait for it to be finished
    wait $CHILD

    # Get its status code and break if it exited.
    STATUS=$?
    if [ $STATUS -ne 0 ]; then
        echo "Command exited with status code $STATUS, loop interrupted. shutting down...";
        exit $STATUS;
    fi

    # Add 0.5 Sec sleep to avoid instant shutdowns
    sleep 0.5
done