# CockroachDB Power for Kiro

> **Status: WIP / pre-release.** Personal staging repo; intended to move to a Cockroach Labs org before public listing.

Give your Kiro agent CockroachDB expertise on demand. When you mention CockroachDB (or related terms like `crdb`, `multi-region`, `molt`), Kiro activates this power and loads:

- **CockroachDB Cloud managed MCP server** (`https://cockroachlabs.cloud/mcp`) — list databases/tables, inspect schemas and indexes, run read-only SQL and `EXPLAIN`, and (with explicit write consent) create databases/tables and insert rows. OAuth login, no API keys to paste.
- **CockroachDB Agent Skills** — schema & SQL best practices, transaction/retry design, multi-region patterns, local cluster setup, MOLT migrations, statement profiling, and cluster health reviews.

## Layout

This power uses Kiro's recommended [Agent Plugins format](https://kiro.dev/docs/powers/create/).

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
  "mcpServers": {
    "cockroachdb-cloud": {
      "url": "https://cockroachlabs.cloud/mcp",
      "headers": { "mcp-cluster-id": "<your-cluster-id>" }
    }
  }
}
```

## Known limitations (managed MCP server)

- `explain_query`: `SELECT` / `INSERT` / `CREATE TABLE` only; no `EXPLAIN ANALYZE`.
- `show_statement`: introspective `SHOW` only, max 100 rows.
- No access to `crdb_internal`, `system`, `pg_catalog`, `information_schema`, `pg_extension` — skills that need these fall back to `cockroach sql --url $DATABASE_URL`.

## Roadmap

- [ ] Run `sync-skills.sh` and commit vendored skills
- [ ] Verify full managed-MCP tool list against a live staging cluster; update skill references
- [ ] Add `cockroach sql` fallback notes to observability skills that query `crdb_internal`
- [ ] Add CockroachDB Docs MCP server to `mcp.json` (confirm endpoint)
- [ ] Add verified `ccloud` CLI examples to `cockroachdb-getting-started`
- [ ] Test keyword activation doesn't collide with Neon / Supabase / Aurora powers
- [ ] Move to Cockroach Labs org, make public, add "Add to Kiro" button
- [ ] Pursue curated listing on [kiro.dev/powers](https://kiro.dev/powers/)

## References

- [Kiro: Create powers](https://kiro.dev/docs/powers/create/)
- [Connect to the CockroachDB Cloud MCP Server](https://www.cockroachlabs.com/docs/cockroachcloud/connect-to-the-cockroachdb-cloud-mcp-server)
- [CockroachDB and AI](https://www.cockroachlabs.com/docs/stable/cockroachdb-and-ai)
- [cockroachlabs/cockroachdb-skills](https://github.com/cockroachlabs/cockroachdb-skills)
- Examples: [Neon power](https://github.com/kirodotdev/powers/tree/main/neon), [MongoDB power](https://github.com/mongodb-partners/mongodb-kiro-power)

## License

Apache-2.0 (matching upstream cockroachdb-skills).
