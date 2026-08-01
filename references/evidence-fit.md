# Evidence Fit By Task Type

Apply only the rows triggered by the accepted task and changed behavior.

| Task type | Minimum useful proof |
| --- | --- |
| Markdown/docs | Readback, format, and relevant link/path check |
| Pure logic | Relevant unit tests including material edge cases |
| CLI | Command output showing changed behavior |
| API/server action | Request/response, validation/error behavior, shared contract alignment |
| UI/frontend state | Browser/state check covering material new states |
| RAG/retrieval | Sample query, retrieved material, citations, groundedness check |
| Auth/data isolation | Authorized case plus two-user or equivalent negative isolation test |
| Payment/product state | Authoritative payment result plus resulting state at the architecture-declared source of truth |
| Migration/schema | Migration artifact, data-risk note, rollback/backfill where relevant; backup/PITR before production execution |
| AI endpoint | Auth, limits/cost, retry, logging, failure path, output validation |
| Tool action | Permission, approval where needed, audit trail, result validation, failure/retry behavior |
| Provider/webhook | Contract/authenticity, relevant test or replay, idempotency/ordering behavior |
| Version-sensitive behavior | Installed version plus current primary source and matching implementation |
| Triggered observability | Named operational question plus observable test event/error/request or explicit cannot-verify |
