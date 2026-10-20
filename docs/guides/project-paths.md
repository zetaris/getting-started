# Choose what to build

Choose a question you want to answer. Use [Cookbooks](recipe-readiness.md) to find a sample source and its limits. The ideas below can start with any source that fits; PokéAPI is one optional starter.

## Hackathon tracks

The [event page](https://hackathon.genai.works/event/open-agent-hackathon-2026) lists the current tracks, rules and judging. Choose a track that fits the work your agent will demonstrate.

## Analyse some data

Start with a small sample from a Cookbook, or use the [PokéAPI starter](first-dataset.md). Then:

1. Write your question.
2. Check what each row and field means.
3. Query the data and compare a few results with the source.
4. Save the SQL and explain what you found, including any gaps.

## Combine sources

Choose a second source. Check the join key and what each row represents. Look for duplicates and missing matches; company names alone often are not enough to join records.

Try these guides:

- [VDM and USL](zetaris-lightning-sql-companion.md) compares the SQL and model options, with their tested limits.
- [EDGAR and SIC](../../open_data/usl/HOWTO.md) walks through a USL model, relationships and data-quality checks. The foreign-key check found one invalid record; materialisation remains unverified.
- [EDGAR, PUDL and NOAA](create-edgar-pudl-noaa-usl.md) is an advanced walkthrough. PUDL is blocked, its weather period is partial, and its data-quality result is unverified.

Use your own local or AWS Zetaris instance. Choose database, container, namespace and model names for your project and use them consistently.

Save the joined result and explain any duplicates, missing matches or date gaps.

## Build an app or chart

Show real query results in the interface and make errors visible. Keep platform credentials on the server, out of browser code. A deployed app needs its own access and authentication setup.

The [PUDL chart example](../../examples/pudl-chart/README.md) uses Python and a local HTML chart. Its sample data can check the layout, but a real query is needed to show the connection works. The example is available once PUDL works on your instance.

PUDL's energy-source codes describe fuel categories, not generation. For generation analysis, register and check the generator table first.

## Prepare your demo

Use the [demo template](demo-template.md) to record your setup, query and result, including anything you have not checked. Follow the [official event rules](https://hackathon.genai.works/event/open-agent-hackathon-2026) for submission details.
