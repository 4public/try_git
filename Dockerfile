FROM alpine:3.24

CMD ["sh", "-c", "echo Hello world; trap 'exit 0' TERM; tail -f /dev/null & wait"]
