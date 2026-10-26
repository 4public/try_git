# Hello World Container + Local Registry

A minimal Docker project: a tiny "Hello world" container image built from [Dockerfile](Dockerfile), published to a local Docker registry, and run from that registry.

## Components

| Piece | What it is |
|---|---|
| [`Dockerfile`](Dockerfile) | Multi-stage-free, 3-line image based on `alpine:3.19`. Prints `Hello world`, then stays alive via `tail -f /dev/null`. |
| `localhost:5000` | A local registry running the official `registry:2` image (Docker Distribution — the reference implementation of the registry/OCI pull-push API). |
| `hello` | The long-running container, pulled from the local registry as `localhost:5000/hello:latest`. |

### Dockerfile

```dockerfile
FROM alpine:3.19

CMD ["sh", "-c", "echo Hello world; tail -f /dev/null"]
```

- `alpine:3.19` — small base image (~8 MB).
- `CMD` — prints `Hello world` on startup, then idles with `tail -f /dev/null` so the container keeps running.

## Quick start

### 1. Start the local registry

```bash
docker run -d --rm --name local-registry -p 5000:5000 registry:2
```

Check it's healthy:

```bash
curl -s http://localhost:5000/v2/_catalog   # → {"repositories":[]}
```

### 2. Build and push the image

```bash
docker build -t hello:latest .
docker tag hello:latest localhost:5000/hello:latest
docker push localhost:5000/hello:latest
```

The `docker tag` step is required — `docker push` only works on images that already carry the registry's hostname in their name.

### 3. Run it from the registry

```bash
docker run -d --name hello localhost:5000/hello:latest
docker logs hello        # → Hello world
```

## Verify

```bash
docker images                          # hello:latest + localhost:5000/hello:latest
docker ps --format 'table {{.Names}}\t{{.Image}}\t{{.Status}}'
curl -s http://localhost:5000/v2/_catalog      # {"repositories":["hello"]}
curl -s http://localhost:5000/v2/hello/tags/list  # {"name":"hello","tags":["latest"]}
```

## Teardown

```bash
docker stop hello
docker stop local-registry
```

## Notes

- **Registry data is ephemeral.** The stock `registry:2` setup stores blobs in the container's filesystem; stopping it with `--rm` deletes everything. For persistence, mount a volume: `-v ./registry-data:/var/lib/registry` (drop `--rm` in that case).
- **HTTP, no TLS.** Local `localhost` is allowed to speak plain HTTP to Docker; anything remote needs TLS or a Docker daemon config marking the host as insecure.
- **What `registry:2` is.** The official Docker Hub image `docker.io/library/registry`, built from the [distribution/distribution](https://github.com/distribution/distribution) project (Apache 2.0). It's the reference implementation of the registry HTTP API (`/v2/...`) that `docker push`/`pull` and OCI tools use.
- **Troubleshooting: `docker images` empty?** You're likely talking to a different Docker daemon — check `docker context ls` (look for the `*`), `which docker`, and `echo $DOCKER_HOST`. In the session that built this project, the active context was `desktop-linux` (Docker Desktop, `unix:///Users/pavel/.docker/run/docker.sock`).
