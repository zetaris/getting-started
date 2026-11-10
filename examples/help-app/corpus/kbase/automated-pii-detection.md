---
source: kbase
url: https://kbase.zetaris.com/knowledge/automated-pii-detection
title: "Automated PII Classification"
kind: other
lastmod: 2026-01-19
retrieved: 2026-11-10
sha256: b62dadbec2d3902ccd67ca8eb12b44d9bd7494f068f6159eabca355142cea0f2
---
# Automated PII Classification

[What is PII?](#what_is_pii)

[What is PII classification?](#pii_classification)

[What happens after classifying PII?](#pii_outcomes)

[Detailed Process of Detection and Anonymization](#pii_process)

### What is PII?

PII, an acronym for Personally Identifiable Information, is the cornerstone of an individual's digital identity. Leaks or mishandling of PII can unleash a storm of problems, from privacy breaches to identity theft. Global regulations, including GDPR (General Data Protection Regulation) and HIPAA(Health Insurance Portability and Accountability Act of 1996), underscore the significance of PII by laying out strict measures for its protection.

### What is PII Classification?

PII Classification is a task in which text token are being identified as PII. In particular, techniques used for Named Entity Recognition (NER) tasks. It is a type of sequence labeling task.

### ![](https://kbase.zetaris.com/hs-fs/hubfs/image-png-Jul-23-2025-01-29-49-0319-AM.png)

The label (Input Sequence) indicates if a token (like a word) corresponds to a named entity (Output Sequence). Using the default settings, Zetaris will pick on 18 different named entities, including:

<table style="width: 100%; border-collapse: collapse; table-layout: fixed; border: 1px solid #99acc2; height: 630px; border-color: #CCCCCC;"><tbody><tr style="height: 35px;"><td style="width: 27.802%; padding: 4px; height: 35px; border-style: solid; vertical-align: middle;">PERSON</td><td style="width: 72.198%; padding: 4px; height: 35px; border-style: solid; vertical-align: middle;">People, including fictional</td></tr><tr style="height: 35px;"><td style="width: 27.802%; padding: 4px; height: 35px; border-style: solid; vertical-align: middle;">NORP</td><td style="width: 72.198%; padding: 4px; height: 35px; border-style: solid; vertical-align: middle;">Nationalities or religious or political groups</td></tr><tr style="height: 35px;"><td style="width: 27.802%; padding: 4px; height: 35px; border-style: solid; vertical-align: middle;">FACILITY</td><td style="width: 72.198%; padding: 4px; height: 35px; border-style: solid; vertical-align: middle;">Buildings, airports, highways, bridges, etc.</td></tr><tr style="height: 35px;"><td style="width: 27.802%; padding: 4px; height: 35px; border-style: solid; vertical-align: middle;">ORGANIZATION</td><td style="width: 72.198%; padding: 4px; height: 35px; border-style: solid; vertical-align: middle;">Companies, agencies, institutions, etc.</td></tr><tr style="height: 35px;"><td style="width: 27.802%; padding: 4px; height: 35px; border-style: solid; vertical-align: middle;">GPE</td><td style="width: 72.198%; padding: 4px; height: 35px; border-style: solid; vertical-align: middle;">Countries, cities, states</td></tr><tr style="height: 35px;"><td style="width: 27.802%; padding: 4px; height: 35px; border-style: solid; vertical-align: middle;">LOCATION</td><td style="width: 72.198%; padding: 4px; height: 35px; border-style: solid; vertical-align: middle;">Non-GPE locations, mountain ranges, bodies of water</td></tr><tr style="height: 35px;"><td style="width: 27.802%; padding: 4px; height: 35px; border-style: solid; vertical-align: middle;">PRODUCT</td><td style="width: 72.198%; padding: 4px; height: 35px; border-style: solid; vertical-align: middle;">Vehicles, weapons, foods, etc. (Not services)</td></tr><tr style="height: 35px;"><td style="width: 27.802%; padding: 4px; height: 35px; border-style: solid; vertical-align: middle;">EVENT</td><td style="width: 72.198%; padding: 4px; height: 35px; border-style: solid; vertical-align: middle;">Named hurricanes, battles, wars, sports events, etc.</td></tr><tr style="height: 35px;"><td style="width: 27.802%; padding: 4px; height: 35px; border-style: solid; vertical-align: middle;">WORK OF ART</td><td style="width: 72.198%; padding: 4px; height: 35px; border-style: solid; vertical-align: middle;">Titles of books, songs, etc.</td></tr><tr style="height: 35px;"><td style="width: 27.802%; padding: 4px; height: 35px; border-style: solid; vertical-align: middle;">LAW</td><td style="width: 72.198%; padding: 4px; height: 35px; border-style: solid; vertical-align: middle;">Named documents made into laws.</td></tr><tr style="height: 35px;"><td style="width: 27.802%; padding: 4px; height: 35px; border-style: solid; vertical-align: middle;">LANGUAGE</td><td style="width: 72.198%; padding: 4px; height: 35px; border-style: solid; vertical-align: middle;">Any named language</td></tr><tr style="height: 35px;"><td style="width: 27.802%; padding: 4px; height: 35px; border-style: solid; vertical-align: middle;">DATE</td><td style="width: 72.198%; padding: 4px; height: 35px; border-style: solid; vertical-align: middle;">Absolute or relative dates or periods</td></tr><tr style="height: 35px;"><td style="width: 27.802%; padding: 4px; height: 35px; border-style: solid; vertical-align: middle;">TIME</td><td style="width: 72.198%; padding: 4px; height: 35px; border-style: solid; vertical-align: middle;">Times smaller than a day</td></tr><tr style="height: 35px;"><td style="width: 27.802%; padding: 4px; height: 35px; border-style: solid; vertical-align: middle;">PERCENT</td><td style="width: 72.198%; padding: 4px; height: 35px; border-style: solid; vertical-align: middle;">Percentage (including “%”)</td></tr><tr style="height: 35px;"><td style="width: 27.802%; padding: 4px; height: 35px; border-style: solid; vertical-align: middle;">MONEY</td><td style="width: 72.198%; padding: 4px; height: 35px; border-style: solid; vertical-align: middle;">Monetary values, including unit</td></tr><tr style="height: 35px;"><td style="width: 27.802%; padding: 4px; height: 35px; border-style: solid; vertical-align: middle;">QUANTITY</td><td style="width: 72.198%; padding: 4px; height: 35px; border-style: solid; vertical-align: middle;">Measurements, as of weight or distance</td></tr><tr style="height: 35px;"><td style="width: 27.802%; padding: 4px; height: 35px; border-style: solid; vertical-align: middle;">ORDINAL</td><td style="width: 72.198%; padding: 4px; height: 35px; border-style: solid; vertical-align: middle;">“first”, “second”</td></tr><tr style="height: 35px;"><td style="width: 27.802%; padding: 4px; height: 35px; border-style: solid; vertical-align: middle;">CARDINAL</td><td style="width: 72.198%; padding: 4px; height: 35px; border-style: solid; vertical-align: middle;">Numerals that do not fall under another type</td></tr></tbody></table>

Note: The the default setting on named entities can be configured for specific elements

### What happens after classifying PII?

#### Tagging

For structured and unstructured data sets, once PII has been identified it will be assigned a tag of "PII". 

![](https://kbase.zetaris.com/hs-fs/hubfs/image-png-Jul-23-2025-01-06-24-4907-AM.png)

These tags can also then be used to generate _**automated security policies**_ whereby obfuscating that data to unprivileged users.

#### Describing

The automated classifier will also attempt to describe the data as best as possible, leverage both the metadata and field level values.

![](https://kbase.zetaris.com/hs-fs/hubfs/image-png-Jul-23-2025-01-06-41-2022-AM.png)

#### Data Anonymization

Another approach is to replace the identifier with a dummy value. For example, if a person’s name or phone number is recognized in a sentence like “_My name is Amy and my number is 85562333_”, then the anonymized text can be “_My name is <PERSON\_NAME> and my number is <PHONE\_NUMBER>_”. It is simple and straightforward but there is some disadvantage to this method. We lose important information when using one value for all the same entity types. In this example, we would not know what is the gender of the person. Depending on the use of the anonymized text, it can be desirable to keep such information. Or when it comes to addresses, one would like to preserve the geographical distribution to a certain level.

Another method is to replace the detected entity with a surrogate value. It can be either randomly sampled from a pre-determined list for each entity type, or according to some rule.

### Detailed Process of Detection and Anonymization

The process of detections and anonymization goes through two phases. Firstly, the text runs through the Analyzer and locates where PII exists. Secondly, the Anonymizer obfuscates the data according to rules configured for PII detection.

![](https://kbase.zetaris.com/hs-fs/hubfs/image-png-Jul-23-2025-04-42-47-7961-AM.png)
