# Serves the built help app. The repo is bind-mounted at /repo by compose, and
# `deno task build` is run on the host first so _fresh is on that mount.
FROM denoland/deno:2.9.0
WORKDIR /repo/examples/help-app
EXPOSE 8000
CMD ["deno", "run", "--allow-read", "--allow-env", "--allow-net", "scripts/start.ts"]
