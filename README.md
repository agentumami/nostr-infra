# nostr-infra

A reference skeleton for running a self-hosted **nostr** relay with separate
**persona** containers that sign events via `nak`.

This is the minimum viable shape — not a finished stack. It's the framework
the rest of the work hangs off of.

## What's here

| File | Purpose |
|---|---|
| `install-nak.sh` | One-shot host install of [`nak`](https://github.com/fiatjaf/nak) at `/usr/local/bin/nak`. |
| `compose.yaml` | A `strfry` relay + two example personas on a shared network. |
| `compose.override.yaml.example` | Per-developer overrides (source mounts, debug ports, etc.). Copy to `compose.override.yaml`. |
| `persona.Dockerfile` | Minimal persona image. Does **not** install `nak` — it's mounted in from the host. |
| `persona-entrypoint.sh` | Stub that proves the host bind-mounts work. Replace with the real persona runtime. |

## Decisions baked in (don't fight these without updating the docs)

- **`nak` is installed once on the host**, then mounted read-only into
  personas at `/usr/local/bin/nak`. Personas don't install it.
- **DoT state lives at `/etc/nostr/dot/<persona>/` on the host** and is
  bind-mounted rw into personas at `/etc/nostr/dot`. Per-persona namespacing
  so they don't trample each other.
- **`strfry` auth stays on.** No "trusted LAN" carve-out.
- **No bunker-style auth, no Python signing lib.** Punt to a later version.
- **Personas reach the relay by service name** (`strfry:7777`) over the
  shared `nostr` compose network.

## Quick start (host)

```bash
# 1. Install nak once on the host.
sudo ./install-nak.sh

# 2. Make sure /etc/nostr/dot/<persona>/ exists for every persona you run.
sudo mkdir -p /etc/nostr/dot/persona-a /etc/nostr/dot/persona-b

# 3. Bring the stack up.
docker compose up -d

# 4. Confirm mounts landed.
docker compose exec persona-a /usr/local/bin/persona-entrypoint.sh --check-nak
```

You should see lines like:

```
[persona] nak present: nak ...
[persona] /etc/nostr/dot writable
```

If the second line errors, the bind-mount is missing. Check the host path.

## What's not here (yet)

- A real DoT daemon. `compose.yaml` only declares the mount point.
- A real persona runtime. The entrypoint is a `sleep infinity` stub.
- A `strfry.conf`. The image default is used.
- Bunker auth, fine-grained signing lib, etc. — see *Decisions* above.

These are deliberately out of scope for the initial commit.

## Layout

```
.
├── README.md
├── LICENSE
├── .gitignore
├── install-nak.sh
├── compose.yaml
├── compose.override.yaml.example
├── persona.Dockerfile
└── persona-entrypoint.sh
```

## License

MIT.