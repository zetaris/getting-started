# Upload a PDF and read its text

Upload a PDF to Zetaris, register it as a file table, then read its text using SQL. You need permission to upload files and create a Lightning database and table.

## 1. Upload the PDF

Open **NDP File System → file-store** and upload your PDF. For this example, put it directly in `file-store` and note its filename.

## 2. Register the file

Open **Workbench → SQL Workspace → New Query**. Run each statement separately. Replace `your_file.pdf` with your uploaded filename.

Create a Lightning database:

```sql
CREATE LIGHTNING DATABASE pdf_demo
```

Register the PDF:

```sql
CREATE LIGHTNING FILESTORE TABLE documents
FROM pdf_demo
FORMAT PDF
OPTIONS (
  path "dffs://your_file.pdf",
  preview_len "100000"
)
```

Use a different database or table name if these already exist, and update the queries below to match. If the file is inside a folder, use its matching File Store path rather than just the filename. `dffs://` refers to Zetaris File Store, not a path on your laptop.

## 3. Read the text preview

```sql
SELECT *
FROM pdf_demo.documents
```

The `preview` column contains extracted text. To select just that column:

```sql
SELECT preview
FROM pdf_demo.documents
```

The default preview length is **1,000 characters**. Setting `preview_len` to `"100000"` allows up to **100,000 characters** in the preview. Longer documents may be cut off.

## 4. Extract text from the PDF bytes

The content table, `pdf_demo.documents.content`, exposes the underlying PDF bytes in `bincontent`. Pass those bytes to `pdfToText`:

```sql
SELECT pdfToText(bincontent) AS text
FROM pdf_demo.documents.content
```

Use the same table name throughout. For example, a table named `questions` would use `pdf_demo.questions.content` instead.

## Common questions

| Question | What to do |
|---|---|
| Why do I see bytes instead of text? | Use the `preview` column, or call `pdfToText(bincontent)` on the content table. |
| Why is the text cut off? | Increase `preview_len` when registering the PDF, or extract text from its bytes as shown above. The preview is length-limited. |
| Why can't Zetaris find the file? | Check the uploaded filename, folder and `dffs://` path. Uploading the file and registering a SQL table are separate steps. |
| Why is the text empty? | Check whether you can select text in the original PDF. For scanned documents, check your build's OCR support. |
| What if the columns or function differ? | Inspect `SELECT *` and check your Zetaris build's PDF support. This example uses the `preview`, `bincontent` and `pdfToText` names from the supplied support workflow. |

For general File Store registration syntax, see [CREATE LIGHTNING FILESTORE TABLE](zetaris-lightning-sql-commands.md#53-create-lightning-filestore-table).
