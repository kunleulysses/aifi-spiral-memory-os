# Finance Isolation Contract

AI-Fi Spiral Memory OS is a hackathon-safe memory-agent slice. It must not interfere with the finance sector or trading cluster.

## Hard Rules

- Use only `AIFI_CREATURE_*` environment variables.
- Use only creature-owned persistence namespaces such as `creature_*`.
- Do not import broker execution, portfolio, reconciliation, scorecard, Alpaca, MetaTrader, or trading services.
- Do not restart, inspect, or modify finance systemd services from game code.
- Do not write to finance ledgers, broker-truth tables, validation portfolio records, or trading runtime state.
- Do not include finance credentials in app bundles, fixtures, tests, or generated modules.

## Allowed Reuse

The game may reuse architecture patterns:

- Capability manifests
- Spiral memory
- Sigil/DNA identity
- Holographic future generation
- Regret memory
- Mutation safety
- Canary rollout
- SLO checks
- Attribution ledgers

When reused, these must be copied, adapted, or wrapped into `Creature*` services with creature-only permissions.

## Safe Product Namespaces

- App/service prefix: `aifi-creature`
- DB schema/table prefix: `creature_`
- Env var prefix: `AIFI_CREATURE_`
- Generated module permission prefix: `creature.`
