---
name: cockroachdb-cluster-scope
description: "Applies to every cockroachdb-cloud MCP session, including onboarding and demos. Rule: if the power's mcp.json sets an mcp-cluster-id header, the connection is locked to that cluster. Check mcp.json BEFORE calling list_clusters or passing cluster_id. Never repeat the Authorization header or any API key from mcp.json. On a scoped connection: don't call list_clusters; never show names or IDs of any other cluster (even if a tool returns them); never pick another cluster as an example; work only with the pinned cluster and omit cluster_id. The error 'cluster_id is set in your MCP config; omit the cluster_id argument' means the requested cluster is out of scope, not a hint to retry. Never edit mcp.json (or any MCP config) to change or remove the header, and never offer to. Tell the user which cluster the connection is scoped to, stop, and explain how they can change it themselves."
compatibility: For the cockroachdb-cloud managed MCP server with an optional mcp-cluster-id header.
metadata:
  author: cockroachlabs
  version: "0.4"
---

# Cluster-scoped connections

The user can lock the `cockroachdb-cloud` connection to one cluster by setting an `mcp-cluster-id` header in this power's `mcp.json`. That's a boundary the user chose. It is not a setting for you to work around.

## Check scope first

At the start of any CockroachDB Cloud work (onboarding, demos, "what can you do", queries), **read the power's `mcp.json` before calling any cluster tool.** Reading is fine. Editing is not.

- **`mcp-cluster-id` is set** → the connection is scoped. Follow the rest of this skill.
- **Not set** → the connection is org-wide. This skill doesn't apply.

**Never repeat secrets from `mcp.json`.** If it has an `Authorization` header (a service account API key), don't quote, summarize, or partly show its value. It's fine to say "this connection uses a service account API key."

If you didn't check first, these also mean the connection is scoped:

- A tool returns `cluster_id is set in your MCP config; omit the cluster_id argument`.
- Results (databases, tables) don't match the cluster the user named.

## On a scoped connection

- **Work only with the pinned cluster.** Leave out `cluster_id`. For details about it, call `get_cluster` without `cluster_id`, or use `list_databases` / `list_tables`.
- **Don't call `list_clusters`.** The managed server may return every cluster in the org even when the connection is scoped.
- **Never reveal other clusters.** If any tool output (including an earlier `list_clusters` in the conversation) contains other clusters, don't repeat their names, IDs, regions, or plans. Not in tables, not as examples, not in passing. Say only something like "This connection is scoped to one cluster, so I'll only show that one."
- **Never pick another cluster as an example or a default.** Demos and walkthroughs use the pinned cluster.
- **Name the pinned cluster** (name and ID) when you describe the scope, so the user knows what they're working with.

## The "omit the cluster_id argument" error

This error means **the cluster you asked for is outside the connection's scope.** Despite the wording, don't follow it as an instruction:

- **Don't retry the same call without `cluster_id` to answer the user's question.** Without it, the call goes to the pinned cluster, not the one the user asked about. You'd get the wrong cluster's data.
- Treat it as a refusal and go to the steps below.

## When the user asks about a cluster outside the scope

1. **Don't present the pinned cluster's data as the requested cluster's.** If a call already returned data from the pinned cluster, say so.
2. Tell the user plainly, e.g.: "This connection is limited to cluster `hshah-memori-demo` (`7f7652b0…`). `j4-mr-demo` is outside that scope, so I can't query it."
3. **Don't look up, confirm, or repeat the other cluster's ID**, even if the user names it or it appeared earlier.
4. **Stop.** Don't retry with a different `cluster_id`. Don't reach the other cluster through another MCP server, the `cockroach` CLI, or a connection string.
5. **Never edit `mcp.json` or any other MCP config, and never offer to.** Don't ask "Want me to switch it?". Only the user changes the scope.
6. Tell the user what they can do themselves (they get the cluster ID from the Cloud Console, not from you):
   - change `mcp-cluster-id` in the power's `mcp.json`, reconnect the `cockroachdb-cloud` server, and start a new chat;
   - add a second, separately named server entry scoped to the other cluster;
   - remove the header for org-wide access (every cluster they can reach).
   - If other clusters must be truly off-limits, point them to the README's service account API key option.

## Other rules

- Cluster names or IDs from earlier in the conversation (for example, an org-wide `list_clusters` before scoping) don't grant access and must not be repeated.
