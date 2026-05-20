# ddev-supabase

DDEV addon that runs the full [Supabase](https://supabase.com) stack alongside your DDEV project.

This addon includes: Studio dashboard, Kong API gateway, GoTrue auth, PostgREST, Realtime, Storage, pg-meta, Edge Functions, Logflare analytics, Vector log aggregation, and Supavisor connection pooler.

## Requirements

- DDEV v1.24.0+
- 4 GB RAM minimum (8 GB recommended) - Supabase runs 10+ containers

## Installation

```bash
ddev add-on get Farkie/ddev-supabase
ddev restart
```

After installation, customize your config:

```bash
# Edit to set your own passwords, JWT secrets, etc.
$EDITOR .ddev/supabase/.env
ddev restart
```

## Accessing Supabase

Show connection info at any time:

```bash
ddev supabase
```

| Service | URL / Connection |
|---------|----------------|
| Studio dashboard | http://localhost:8000 |
| REST API | http://localhost:8000/rest/v1/ |
| Auth | http://localhost:8000/auth/v1/ |
| Storage | http://localhost:8000/storage/v1/ |
| Realtime | ws://localhost:8000/realtime/v1/ |
| Database (Postgres) | localhost:54322 |
| Database (pooler/transaction) | localhost:54323 |

**Default credentials:**
- Studio: `supabase` / `this_password_is_insecure_and_should_be_updated`
- Postgres: `postgres` / `your-super-secret-and-long-postgres-password`

Change both in `.ddev/supabase/.env` before sharing your project.

## Supabase JS client

```javascript
import { createClient } from '@supabase/supabase-js'

const supabase = createClient(
  'http://localhost:8000',
  'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...' // anon key from .ddev/supabase/.env
)
```

## Connecting from your app container

From inside the DDEV `web` container, use these internal hostnames:

| Service | Internal URL |
|---------|-------------|
| Kong API | http://kong:8000 |
| Postgres | supabase-db:5432 |
| Auth | http://auth:9999 |
| REST | http://rest:3000 |

## Email

By default, SMTP is configured to use DDEV's built-in [mailpit](https://mailpit.axllent.org/) service. Check caught emails at the DDEV mailpit URL (run `ddev describe` to find it).

## Configuration

All Supabase settings are in `.ddev/supabase/.env`. This file is created from `.ddev/supabase/.env.example` on first install and is never overwritten by addon updates.

Key settings to change for any non-trivial use:

| Variable | Description |
|----------|-------------|
| `SUPABASE_POSTGRES_PASSWORD` | Postgres password |
| `JWT_SECRET` | JWT signing secret (min 32 chars) |
| `ANON_KEY` | Supabase anon JWT |
| `SERVICE_ROLE_KEY` | Supabase service role JWT |
| `DASHBOARD_PASSWORD` | Studio dashboard password |
| `SECRET_KEY_BASE` | App secret key |
| `VAULT_ENC_KEY` | 32-char encryption key |

To generate new JWT keys, use the [Supabase JWT generator](https://supabase.com/docs/guides/self-hosting#api-keys) or `node -e "console.log(require('crypto').randomBytes(32).toString('hex'))"`.

## Edge Functions

Place your Deno edge functions in `.ddev/supabase/volumes/functions/`. They are served at `http://localhost:8000/functions/v1/{function-name}`.

## Removing the addon

```bash
ddev add-on remove ddev-supabase
```

This removes the addon files but leaves your `.ddev/supabase/.env` intact. To also remove Docker volumes (all data):

```bash
docker volume rm $(docker volume ls -q | grep supabase-)
```

## Upgrading Supabase versions

Edit `.ddev/docker-compose.supabase.yaml` and update the image tags, then run `ddev restart`.

## Troubleshooting

**Services take a long time to start** - normal on first run while pulling images. Studio waits for analytics to be healthy before starting.

**Port 8000 already in use** - another service is using port 8000. Stop it, or edit `docker-compose.supabase.yaml` to change the Kong port mapping.

**Database connection refused** - Postgres may still be initializing. Wait 30-60 seconds and try again.

**View service logs:**
```bash
docker logs supabase-db
docker logs supabase-kong
docker logs supabase-auth
docker logs supabase-studio
```
