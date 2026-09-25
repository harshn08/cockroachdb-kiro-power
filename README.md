# CockroachDB Power for Kiro

> **Status: WIP / pre-release.** Personal staging repo; intended to move to a Cockroach Labs org before public listing.

Give your Kiro agent CockroachDB expertise on demand. When you mention CockroachDB (or related terms like `crdb`, `multi-region`, `molt`), Kiro activates this power and loads:

- **CockroachDB Cloud managed MCP server** (`https://cockroachlabs.cloud/mcp`) — list databases/tables, inspect schemas and indexes, run read-only SQL and `EXPLAIN`, and (with explicit write consent) create databases/tables and insert rows. Sign in with OAuth in the browser, or use a service account API key.
- **CockroachDB Agent Skills** — schema & SQL best practices, transaction/retry design, multi-region patterns, local cluster setup, MOLT migrations, statement profiling, and cluster health reviews.

## Layout

This power uses Kiro's recommended [Agent Plugins 1.0.0 format](https://kiro.dev/docs/powers/create/).

```
.
├── plugin.json              # Manifest: name, description, activation keywords
├── mcp.json                 # cockroachdb-cloud managed MCP server
├── skills.manifest          # Upstream skills to vendor
├── scripts/sync-skills.sh   # Copies upstream skills into ./skills
└── skills/
    ├── cockroachdb-getting-started/   # Native to this power (onboarding + MCP guardrails)
    ├── cockroachdb-cluster-scope/     # Native to this power (cluster-scope guardrail)
    └── <vendored skills>/             # From cockroachlabs/cockroachdb-skills
```

### Skills

| Skill | Source |
|---|---|
| `cockroachdb-getting-started` | this repo |
| `cockroachdb-cluster-scope` | this repo |
| `cockroachdb-sql` | [cockroachdb-skills](https://github.com/cockroachlabs/cockroachdb-skills) |
| `designing-application-transactions` | cockroachdb-skills |
| `designing-multi-region-applications` | cockroachdb-skills |
| `setting-up-local-cluster` | cockroachdb-skills |
| `molt-fetch`, `molt-verify` | cockroachdb-skills |
| `profiling-statement-fingerprints` | cockroachdb-skills |
| `reviewing-cluster-health` | cockroachdb-skills |

Vendored skills are kept in sync with upstream (source of truth) via:

```bash
./scripts/sync-skills.sh          # or UPSTREAM_REF=<tag> ./scripts/sync-skills.sh
git add skills && git commit -m "Sync skills from cockroachdb-skills@$(cat skills/.upstream-sha | cut -c1-7)"
```

`sync-skills.sh` only replaces the vendored skills listed in `skills.manifest`. The native skills (`cockroachdb-getting-started`, `cockroachdb-cluster-scope`) aren't touched.

## Install locally (for testing)

1. `git clone` this repo and run `./scripts/sync-skills.sh`.
2. In Kiro: **Powers panel → Add Custom Power → Import power from a folder** → select this directory → **Install**.
3. Pick an authentication method (see below). The default `mcp.json` uses OAuth.
4. Ask Kiro something like *"Connect to my CockroachDB cluster and list the tables in defaultdb"*.

Tip: start read-only against a staging cluster.

> **Changes don't apply automatically.** Kiro copies the power into `~/.kiro/powers/installed/cockroachdb-kiro-power/` when you install it. After you pull or edit the repo, reinstall the power and start a new chat. Config changes for your own setup (API key, cluster ID) go in that installed `mcp.json`, not the repo.

## Choose an authentication method

The managed MCP server supports two ways to sign in. Use one per connection.

| | **OAuth (default)** | **Service account API key** |
|---|---|---|
| **Who the agent acts as** | You, with all your CockroachDB Cloud permissions | A service account, with only the role you give it |
| **Which clusters it can reach** | Every cluster you can reach. `mcp-cluster-id` only guides the agent; it isn't a security boundary. | Only the clusters the service account's role covers. The server enforces this. |
| **Read/write** | You choose read and/or write on the consent screen | Set by the service account's role |
| **Secret on disk** | None | Yes, the API key (see below for how to keep it out of `mcp.json`) |
| **Setup** | Browser login, nothing to create | Org Admin creates the service account, role and key |

**Use OAuth when** you're a developer working in your own clusters on your own machine. It's the quickest start and there's no secret to manage.

**Use a service account API key when** the agent must not be able to reach other clusters, for example:
- demos, workshops and partner or customer sessions, where other clusters in the org shouldn't be visible;
- shared or lab machines;
- autonomous or scheduled agents, where no one is around to complete a browser login.

With a key, `list_clusters` only returns what the service account can access, and changing `mcp-cluster-id` to another cluster's ID doesn't grant access to it.

### Option A: OAuth (default)

Nothing to configure. When Kiro first calls the server, sign in to CockroachDB Cloud in the browser, pick the organization, and grant read and/or write access.

### Option B: Service account API key

1. **Create the service account.** In the Cloud Console, go to **Organization → Access Management → Service Accounts**, create an account (e.g. `kiro-<project>`), and give it a role **on the specific cluster(s) only**, not at the organization level. Create an API key and copy the secret; it's shown once.
2. **Store the key in an environment variable,** e.g. in `~/.zshrc`:
   ```bash
   export CRDB_MCP_API_KEY="<secret-key>"
   ```
3. **Reference it in the installed power's `mcp.json`** (`~/.kiro/powers/installed/cockroachdb-kiro-power/mcp.json`):
   ```json
   {
     "$schema": "https://agent-plugins.org/schemas/1.0.0/mcp.schema.json",
     "mcpServers": {
       "cockroachdb-cloud": {
         "type": "streamable-http",
         "url": "https://cockroachlabs.cloud/mcp",
         "headers": { "Authorization": "Bearer ${CRDB_MCP_API_KEY}" }
       }
     }
   }
   ```
4. **Make sure Kiro can see the variable.** On macOS, apps opened from the Dock or Spotlight don't load your shell profile. Quit Kiro and start it from a terminal where the variable is set (e.g. `kiro .`, if you installed the shell command).
5. **Approve the variable** when Kiro asks. Kiro only expands environment variables you've approved.
6. **Disconnect any earlier OAuth session** for `cockroachdb-cloud` in Kiro's MCP panel, then start a new chat.

**If Kiro opens a browser login or returns an authentication error,** the variable probably wasn't expanded. There's an open Kiro issue where `${VAR}` references in a power's `mcp.json` are sent to the server as literal text ([kirodotdev/Kiro#11258](https://github.com/kirodotdev/Kiro/issues/11258)). Until that's fixed, the fallback is to put the key directly in the installed `mcp.json`:
- Never commit it. The file lives outside the repo, but don't copy it back in.
- The agent can read that file, which would put the key into the chat. Use a short-lived key for the service account and revoke it when you're done.

**Why the repo's `mcp.json` doesn't include the `Authorization` header:** if the variable isn't set, Kiro sends a broken header instead of starting the OAuth login, which would break the default for everyone. The API key stays an opt-in change to your installed copy.

**Optionally combine it with `mcp-cluster-id`** (next section) if the service account can reach more than one cluster and you want Kiro to stick to one of them.

## Optional: scope to a single cluster

Add an `mcp-cluster-id` header so all tools operate on one cluster:

```json
{
  "$schema": "https://agent-plugins.org/schemas/1.0.0/mcp.schema.json",
  "mcpServers": {
    "cockroachdb-cloud": {
      "type": "streamable-http",
      "url": "https://cockroachlabs.cloud/mcp",
      "headers": { "mcp-cluster-id": "<your-cluster-id>" }
    }
  }
}
```

> `mcp.json` must validate against the Agent Plugins 1.0.0 schema: `$schema` and `type` are required, and fields like `disabled` are rejected (an invalid file disables all MCP servers for the power).

Things to know when scoping:

- **The header limits the agent, not the user.** It keeps Kiro working on one cluster. It isn't an access control. Anyone who can edit `mcp.json` can change it, and an OAuth login still has access to every cluster the user can reach. If other clusters must be off-limits, use a service account API key (Option B above).
- **Put the header in this power's `mcp.json`.** A `cockroachdb-cloud` entry in your Kiro user or workspace config is a *separate* server. Kiro may keep calling the power's unscoped server instead, and your scope is silently ignored. Keep one server entry.
- **The agent won't change the scope or reveal other clusters.** The `cockroachdb-cluster-scope` skill tells Kiro to check `mcp.json` first, skip `list_clusters`, never show other clusters' names or IDs, and never edit `mcp.json`. If you ask about a cluster outside the scope, it says which cluster the connection is limited to and stops. This is guidance to the agent, not something enforced, so keep file-edit approval on in Kiro.
- **To work with a different cluster**, get its ID from the Cloud Console and pick one:
  1. Change `mcp-cluster-id` yourself, reconnect the server, and start a new chat.
  2. Add a second, separately named server entry scoped to the other cluster.
  3. Remove the header for org-wide access.

## Known limitations (managed MCP server)

- `explain_query`: `SELECT` / `INSERT` / `CREATE TABLE` only; no `EXPLAIN ANALYZE`.
- `show_statement`: introspective `SHOW` only, max 100 rows.
- No access to `crdb_internal`, `system`, `pg_catalog`, `information_schema`, `pg_extension` — skills that need these fall back to `cockroach sql --url $DATABASE_URL`.
- **`list_clusters` ignores `mcp-cluster-id`.** With OAuth on a scoped connection, it still returns every cluster the user can reach, with names and IDs. In testing, Kiro called it during onboarding, showed several other clusters, and picked one of them (`hshah-aws-bedrock`, with its ID) as an example. The `cockroachdb-cluster-scope` skill tells Kiro not to call `list_clusters` on a scoped connection, but this can still slip through. If other clusters must stay hidden, use a service account API key. Upstream feedback for the MCP team: on a scoped connection, `list_clusters` should return only the pinned cluster.
- **Misleading out-of-scope error.** On a cluster-scoped connection, a call with another cluster's `cluster_id` is correctly rejected with `cluster_id is set in your MCP config; omit the cluster_id argument`. But agents read that as an instruction. In testing, Kiro:
  1. called `list_databases` with `j4-mr-demo`'s ID and was rejected;
  2. retried **without** `cluster_id`, as the error suggests, and got the *pinned* cluster's databases (`hshah-memori-demo`);
  3. read `mcp.json` and offered to rewrite `mcp-cluster-id` to `j4-mr-demo`.

  The `cockroachdb-cluster-scope` skill guards against this. Upstream feedback for the MCP team: word the error as a limit and don't suggest a retry, e.g. *"This connection is limited to cluster `<name>` (`<id>`). Requests for other clusters aren't allowed. To use a different cluster, the user must change the MCP configuration."*

## Roadmap

- [x] Run `sync-skills.sh` and commit vendored skills
- [x] Fix `mcp.json` schema compliance (Agent Plugins 1.0.0)
- [x] Add cluster-scope guardrail (`cockroachdb-cluster-scope` skill; report and stop, never edit `mcp.json`)
- [x] Confirm whether `list_clusters` respects `mcp-cluster-id` (it doesn't; see Known limitations)
- [x] Confirm service account API key works via the `Authorization` header
- [ ] Confirm `${CRDB_MCP_API_KEY}` expansion works in the power's `mcp.json` (see kirodotdev/Kiro#11258)
- [ ] With a cluster-scoped service account: confirm `list_clusters` returns only that cluster, and that setting `mcp-cluster-id` to another cluster fails
- [ ] Document the minimum service account role for read-only and for write access
- [ ] Confirm `get_cluster` works without `cluster_id` on a scoped connection
- [ ] Share feedback with the MCP team (#mcp-cross-team-collab): out-of-scope error wording, and `list_clusters` returning all clusters on a scoped connection
- [ ] Verify full managed-MCP tool list against a live staging cluster; update skill references
- [ ] Add `cockroach sql` fallback notes to observability skills that query `crdb_internal`
- [ ] Add CockroachDB Docs MCP server to `mcp.json` (confirm endpoint)
- [ ] Add verified `ccloud` CLI examples to `cockroachdb-getting-started`
- [ ] Test keyword activation doesn't collide with Neon / Supabase / Aurora powers
- [ ] Add LICENSE, Privacy Policy link, and support contact (required for Kiro registry submission)
- [ ] Move to Cockroach Labs org, make public, add "Add to Kiro" button
- [ ] Submit to the curated registry at [kiro.dev/powers/submit](https://kiro.dev/powers/submit/)

## References

- [Kiro: Create powers](https://kiro.dev/docs/powers/create/)
- [Kiro: MCP configuration (environment variables)](https://kiro.dev/docs/mcp/configuration/)
- [Agent Plugins: MCP servers](https://agent-plugins.org/plugin-authors/mcp-servers)
- [Connect to the CockroachDB Cloud MCP Server](https://www.cockroachlabs.com/docs/cockroachcloud/connect-to-the-cockroachdb-cloud-mcp-server)
- [CockroachDB and AI](https://www.cockroachlabs.com/docs/stable/cockroachdb-and-ai)
- [cockroachlabs/cockroachdb-skills](https://github.com/cockroachlabs/cockroachdb-skills)
- Examples: [Neon power](https://github.com/kirodotdev/powers/tree/main/neon), [MongoDB power](https://github.com/mongodb-partners/mongodb-kiro-power)

## License

Apache-2.0 (matching upstream cockroachdb-skills).
