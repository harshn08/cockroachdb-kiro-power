---
name: cockroachdb-getting-started
description: Use when setting up CockroachDB for a project, connecting Kiro to a CockroachDB Cloud cluster, starting a local CockroachDB cluster, or wiring a CockroachDB connection string into an application. Also use when the cockroachdb-cloud MCP server fails to connect or authenticate.
compatibility: Works with the cockroachdb-cloud managed MCP server (CockroachDB Cloud), or without it using the cockroach CLI against a local or self-hosted cluster.
metadata:
  author: cockroachlabs
  version: "0.3"
---

# Getting started with CockroachDB

This skill onboards a user to CockroachDB inside Kiro: pick a target cluster, connect, wire the app, and hand off to the right specialist skill.

## 1. Pick the target

Ask the user which applies:

- **Existing CockroachDB Cloud cluster** → go to 2a
- **New CockroachDB Cloud cluster** → go to 2b
- **Local development cluster** → go to 2c

## 2a. CockroachDB Cloud (existing cluster)

1. Verify the MCP connection by calling `list_databases` on the `cockroachdb-cloud` server.
2. If the call fails with an auth error, tell the user to authenticate the `cockroachdb-cloud` server from Kiro's MCP panel. They will:
   - log in to CockroachDB Cloud in the browser,
   - select an organization (if they belong to more than one),
   - grant **read** and optionally **write** scopes on the Authorize MCP Access screen.
3. Recommend starting **read-only** and against a **staging** cluster before granting access to production data.
4. By default a connection can reach every cluster the user can access. To prevent the agent from switching clusters, suggest scoping the connection to one cluster by adding an `mcp-cluster-id` header (Cluster ID is in the Cloud Console URL: `https://cockroachlabs.cloud/cluster/{cluster_id}/overview`). The header must go on **this power's** `mcp.json` server entry; a separate server entry in the user or workspace config is a different server and does not scope the power's connection. The user makes this change themselves. Once a connection is scoped, follow the `cockroachdb-cluster-scope` skill.
5. Custom/enterprise MCP clients may need their OAuth redirect URL allowlisted by an Org Admin under **Governance > OAuth apps**.

## 2b. New CockroachDB Cloud cluster

- Create the cluster in the Cloud Console, or with the `ccloud` CLI (run `ccloud --help`; commands support structured JSON output, which is ideal for agents).
- Create a SQL user and retrieve the connection string.
- Then continue with 2a to connect the MCP server.

<!-- TODO: add verified ccloud command examples once CLI syntax is confirmed against the current release. -->

## 2c. Local cluster

Hand off to the `setting-up-local-cluster` skill for full guidance.

Quick path for a throwaway dev node:

```bash
cockroach start-single-node --insecure --listen-addr=localhost:26257 --http-addr=localhost:8080
# connection string:
# postgresql://root@localhost:26257/defaultdb?sslmode=disable
```

Never use `--insecure` outside local development.

## 3. Wire up the application

- Store the connection string in `.env` as `DATABASE_URL` and ensure `.env` is in `.gitignore`. Never hardcode credentials.
- CockroachDB Cloud requires TLS: use `sslmode=verify-full`.
- CockroachDB speaks the PostgreSQL wire protocol — use a standard Postgres driver (node-postgres, psycopg, pgx, JDBC, etc.).
- **Always implement client-side transaction retry** for SQLSTATE `40001` (serialization conflicts). CockroachDB runs at SERIALIZABLE isolation by default. See `designing-application-transactions`.
- Default primary keys to `UUID PRIMARY KEY DEFAULT gen_random_uuid()`. Avoid `SERIAL`/sequential keys, which create write hotspots.

## 4. Hand off to specialist skills

| User intent | Skill |
|---|---|
| Write / optimize SQL, design schema | `cockroachdb-sql` |
| Transaction design, retries, contention | `designing-application-transactions` |
| Multi-region, survival goals, REGIONAL BY ROW | `designing-multi-region-applications` |
| Local cluster setup | `setting-up-local-cluster` |
| Migrate from PostgreSQL / MySQL / Aurora / RDS | `molt-fetch`, then `molt-verify` |
| Slow queries, statement profiling | `profiling-statement-fingerprints` |
| Cluster health check | `reviewing-cluster-health` |
| Connection scoped to one cluster; request for another cluster | `cockroachdb-cluster-scope` |

## Guardrails: managed MCP server limits

The `cockroachdb-cloud` managed MCP server is intentionally constrained. Plan around these:

- `explain_query` supports only `SELECT`, `INSERT`, and `CREATE TABLE`. `EXPLAIN ANALYZE` is not supported.
- `show_statement` supports only introspective `SHOW` statements (e.g. `SHOW SCHEMAS`, `SHOW INDEXES`, `SHOW CONSTRAINTS`, `SHOW REGIONS`) and returns at most 100 rows.
- MCP tools **cannot** access `system`, `crdb_internal`, `pg_catalog`, `information_schema`, or `pg_extension`. When a workflow needs these (common in observability skills), fall back to:
  ```bash
  cockroach sql --url "$DATABASE_URL" -e "<SQL>"
  ```
- Write tools are only available if the user granted the write scope.
- **Never** run writes or DDL against a production cluster without explicit user confirmation.
- **Cluster-scoped connections:** never edit `mcp.json` to change or remove `mcp-cluster-id`, and never offer to. See `cockroachdb-cluster-scope`.
