---
name: cockroachdb-cluster-scope
description: "Applies whenever a request names a specific CockroachDB cluster, a cockroachdb-cloud tool call would pass cluster_id, or a tool returns 'cluster_id is set in your MCP config; omit the cluster_id argument'. Rule: if the power's mcp.json sets an mcp-cluster-id header, the connection is locked to that cluster. That error means the requested cluster is out of scope. It is not a hint to retry. Don't retry without cluster_id to answer the question (that queries the pinned cluster instead). Never edit mcp.json (or any MCP config) to change or remove the header, and never offer to. Tell the user which cluster the connection is scoped to, stop, and explain how they can change it themselves."
compatibility: For the cockroachdb-cloud managed MCP server with an optional mcp-cluster-id header.
metadata:
  author: cockroachlabs
  version: "0.2"
---

# Cluster-scoped connections

The user can lock the `cockroachdb-cloud` connection to one cluster by setting an `mcp-cluster-id` header in this power's `mcp.json`. That's a safety boundary the user chose. It is not a setting for you to work around.

## How to tell the connection is scoped

- A tool returns `cluster_id is set in your MCP config; omit the cluster_id argument`.
- Results (databases, tables) don't match the cluster the user named.
- You can **read** `mcp.json` to confirm and to get the pinned cluster ID for your answer. Reading is fine. Editing is not.

## The "omit the cluster_id argument" error

This error means **the cluster you asked for is outside the connection's scope.** Despite the wording, don't follow it as an instruction:

- **Don't retry the same call without `cluster_id` to answer the user's question.** Without it, the call goes to the pinned cluster, not the one the user asked about. You'd get the wrong cluster's data.
- Treat it as a refusal and go to the steps below.

## When the user asks about a cluster outside the scope

1. **Don't present the pinned cluster's data as the requested cluster's.** If a call already returned data from the pinned cluster, say so.
2. Tell the user plainly, e.g.: "This connection is limited to cluster `hshah-memori-demo` (`7f7652b0…`). `j4-mr-demo` is outside that scope, so I can't query it."
3. **Stop.** Don't retry with a different `cluster_id`. Don't reach the other cluster through another MCP server, the `cockroach` CLI, or a connection string.
4. **Never edit `mcp.json` or any other MCP config, and never offer to.** Don't ask "Want me to switch it?". Only the user changes the scope.
5. Tell the user what they can do themselves:
   - change `mcp-cluster-id` in the power's `mcp.json`, reconnect the `cockroachdb-cloud` server, and start a new chat;
   - add a second, separately named server entry scoped to the other cluster;
   - remove the header for org-wide access (every cluster they can reach).

## Other rules

- On a scoped connection, leave out the `cluster_id` argument **only when the user is asking about the pinned cluster**.
- Cluster names or IDs from earlier in the conversation (for example, an org-wide `list_clusters` before scoping) don't grant access.
