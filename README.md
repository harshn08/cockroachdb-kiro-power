# CockroachDB Power for Kiro

> **Status: WIP / pre-release.** Personal staging repo; intended to move to a Cockroach Labs org before public listing.

Give your Kiro agent CockroachDB expertise on demand. When you mention CockroachDB (or related terms like `crdb`, `multi-region`, `molt`), Kiro activates this power and loads:

- **CockroachDB Cloud managed MCP server** (`https://cockroachlabs.cloud/mcp`) — list databases/tables, inspect schemas and indexes, run read-only SQL and `EXPLAIN`, and (with explicit write consent) create databases/tables and insert rows. OAuth login, no API keys to paste.
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
    └── <vendored skills>/             # From cockroachlabs/cockroachdb-skills
```

### Skills

| Skill | Source |
|---|---|
| `cockroachdb-getting-started` | this repo |
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

## Install locally (for testing)

1. `git clone` this repo and run `./scripts/sync-skills.sh`.
2. In Kiro: **Powers panel → Add Custom Power → Import power from a folder** → select this directory → **Install**.
3. Ask Kiro something like *"Connect to my CockroachDB cluster and list the tables in defaultdb"*.
4. Authenticate the `cockroachdb-cloud` MCP server when prompted (browser OAuth; choose read and/or write scope).

Tip: start read-only against a staging cluster.

### Optional: scope to a single cluster

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

- **Put the header in this power's `mcp.json`.** A `cockroachdb-cloud` entry in your Kiro user or workspace config is a *separate* server. Kiro may keep calling the power's unscoped server instead, and your scope is silently ignored. Keep one server entry.
- **The agent won't change the scope.** If you ask about a cluster outside the scope, the `cockroachdb-getting-started` skill tells Kiro to say which cluster the connection is limited to and stop. It won't retry with a different `cluster_id`, look for another way in, or edit `mcp.json`. Only you change the scope.
- **To work with a different cluster**, pick one:
  1. Change `mcp-cluster-id` yourself, reconnect the server, and start a new chat.
  2. Add a second, separately named server entry scoped to the other cluster.
  3. Remove the header for org-wide access.
- The header only limits which cluster the connection can use. It doesn't grant permissions. For service-account API keys, also limit the account's role to that cluster.

## Known limitations (managed MCP server)

- `explain_query`: `SELECT` / `INSERT` / `CREATE TABLE` only; no `EXPLAIN ANALYZE`.
- `show_statement`: introspective `SHOW` only, max 100 rows.
- No access to `crdb_internal`, `system`, `pg_catalog`, `information_schema`, `pg_extension` — skills that need these fall back to `cockroach sql --url $DATABASE_URL`.
- **Unclear out-of-scope error.** On a cluster-scoped connection, a request for another cluster returns `cluster_id is set in your MCP config; omit the cluster_id argument`. That reads like a workaround hint rather than a hard limit, and agents may respond by offering to edit `mcp.json`. The getting-started skill guards against this. Upstream feedback for the MCP team: word it as a limit, e.g. *"This connection is limited to cluster `<name>`. Requests for other clusters aren't allowed."*

## Roadmap

- [x] Run `sync-skills.sh` and commit vendored skills
- [x] Fix `mcp.json` schema compliance (Agent Plugins 1.0.0)
- [x] Add cluster-scope guardrail to `cockroachdb-getting-started` (report and stop; never edit `mcp.json`)
- [ ] Share out-of-scope error wording feedback with the MCP team (#mcp-cross-team-collab)
- [ ] Confirm whether `list_clusters` respects `mcp-cluster-id`
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
- [Agent Plugins: MCP servers](https://agent-plugins.org/plugin-authors/mcp-servers)
- [Connect to the CockroachDB Cloud MCP Server](https://www.cockroachlabs.com/docs/cockroachcloud/connect-to-the-cockroachdb-cloud-mcp-server)
- [CockroachDB and AI](https://www.cockroachlabs.com/docs/stable/cockroachdb-and-ai)
- [cockroachlabs/cockroachdb-skills](https://github.com/cockroachlabs/cockroachdb-skills)
- Examples: [Neon power](https://github.com/kirodotdev/powers/tree/main/neon), [MongoDB power](https://github.com/mongodb-partners/mongodb-kiro-power)

## License

Apache-2.0 (matching upstream cockroachdb-skills).
