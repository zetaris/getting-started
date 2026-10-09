# Choose what to build

Once [your first dataset](first-dataset.md) works, choose a question you want to answer. These are ideas to help you start. Check [available recipes](recipe-readiness.md) before adding another source.

## Hackathon tracks

The [Open Agent Hackathon 2026](https://hackathon.genai.works/event/open-agent-hackathon-2026) lists these tracks:

| Track | Focus |
|---|---|
| Solving Fragmented Intelligence | Discover and work across fragmented data sources. |
| The Agent That Can Explain Why | Investigate questions across sources and produce evidence-backed answers. |
| Reasoning Architecture | Turn data, knowledge, memory and reasoning into reliable decisions and actions. |
| Wildcard [Tinkerer] | Extend an existing project with Zetaris and Meterless; judging scores the new work. |

Check the event page's rules before choosing your track. The options below help you get started with data; your hackathon entry should demonstrate the agent's useful work.

## Analyse some data

Start with Pikachu's hidden abilities, or try a query from a recipe's `_select.sql` file after setting up its required tables.

1. Write your question.
2. Check what each row and field means.
3. Write a query and compare a few results with the source.
4. Save the SQL and explain what you found, including any gaps.

## Combine sources

Choose a second source. Check the join key and what each row represents. Look for duplicates and missing matches. Company names alone often aren't enough to join records.

Try these guides:

- [VDM and USL](zetaris-lightning-sql-companion.md) explains the options and limits. VDM creation uses the GUI.
- [EDGAR and SIC](../../open_data/usl/HOWTO.md) walks through a USL model, relationships and data-quality checks. It records a foreign-key check failure and open questions about materialisation.
- [EDGAR, PUDL and NOAA](create-edgar-pudl-noaa-usl.md) is an advanced walkthrough. PUDL is currently blocked, its weather period is partial, and its data-quality result hasn't been verified. Resolve those before relying on its results.

On the shared instance, replace all sample database, container, namespace and model names with your assigned names. Use shared sources only with read permission, and leave other teams' objects alone.

Save the joined result and explain any duplicates, missing matches or gaps in the dates.

## Build an app or chart

Use a query result in a simple interface. Show the real data and make errors visible. Keep platform credentials on the server, out of browser code. A deployed app also needs its own access and authentication setup.

The [PUDL chart example](../../examples/pudl-chart/README.md) uses Python and a local HTML chart. It's available once PUDL works on your instance. Its sample data can help check the chart layout, but you still need a real query to show the connection works.

PUDL's energy-source codes describe fuel categories. They don't measure generation. For generation analysis, register and check the generator table first.

## Prepare your demo

Use the [demo template](demo-template.md). Save the setup, query and result, and note anything you haven't checked. Check the [event page](https://hackathon.genai.works/event/open-agent-hackathon-2026) for submission details.
