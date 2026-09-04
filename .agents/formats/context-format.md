# CONTEXT.md format

The glossary of one bounded context: the words the domain uses, what each means, and how the
concepts relate. Written in English.

## Structure

```md
# {Context name}

{One or two sentences: what this context is and why it exists.}

## Language

**Order**:
A customer's request for goods, tracked from placement to fulfilment.
_Avoid_: purchase, transaction

**Invoice**:
A request for payment sent to a customer after delivery.
_Avoid_: bill, payment request

**Customer**:
A person or organisation that places orders.
_Avoid_: client, buyer, account

## Relationships

- An **Order** produces one or more **Invoices**
- An **Invoice** belongs to exactly one **Customer**

## Example dialogue

> **Dev:** "When a **Customer** places an **Order**, do we create the **Invoice** immediately?"
> **Domain expert:** "No. An **Invoice** is only generated once a **Fulfilment** is confirmed."

## Flagged ambiguities

- "account" was used to mean both **Customer** and **User**. Resolved: they are distinct concepts.
```

## Rules

- **Be opinionated.** When several words exist for one concept, pick the best and list the others
  under _Avoid_.
- **Flag conflicts explicitly.** A term used in two senses goes under "Flagged ambiguities" with its
  resolution.
- **Keep definitions tight.** One sentence. Define what the thing is, not what it does.
- **Show relationships** with bold term names and cardinality where it is obvious.
- **Only terms specific to this context.** General programming concepts (timeouts, error types,
  utility patterns) do not belong, however often the project uses them. Before adding a term, ask:
  is this a concept unique to this context, or a general programming concept? Only the former
  belongs.
- **Group terms under subheadings** when natural clusters emerge. A flat list is fine when every
  term belongs to one cohesive area.
- **Write an example dialogue** between a developer and a domain expert that shows how the terms
  interact and where the boundaries between related concepts lie.
- **No em-dashes** in the prose.

## Single context or several

Most repositories have one context: a single `CONTEXT.md` at the root.

A repository with several contexts has a `CONTEXT-MAP.md` at the root listing the contexts, where
each lives and how they relate:

```md
# Context map

## Contexts

- [Ordering](./src/ordering/CONTEXT.md): receives and tracks customer orders
- [Billing](./src/billing/CONTEXT.md): generates invoices and processes payments
- [Fulfilment](./src/fulfilment/CONTEXT.md): manages warehouse picking and shipping

## Relationships

- Ordering to Fulfilment: Ordering emits `OrderPlaced`; Fulfilment consumes it to start picking
- Fulfilment to Billing: Fulfilment emits `ShipmentDispatched`; Billing consumes it to generate invoices
- Ordering and Billing share the types `CustomerId` and `Money`
```

Which structure applies is inferred, never asked first:

| Found at the root | Structure |
|---|---|
| `CONTEXT-MAP.md` | several contexts; read the map to find them and pick the one the plan touches, asking only when it is unclear |
| `CONTEXT.md` only | one context |
| neither | one context; the root `CONTEXT.md` is created when the first term is resolved |

The map itself is never created or edited by the session.
