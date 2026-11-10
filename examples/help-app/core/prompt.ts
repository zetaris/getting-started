// Prompt rules for Answer mode, and whole-file context for code questions.

/** The instruction sent to the LLM node with the question. */
export function answerPrompt(question: string): string {
  return `${question}\n\nAnswer only from the supplied passages. ` +
    `Cite the FILE (and section) of every passage you use. ` +
    `Each passage says whether it comes from the repo docs (REPO: repo) or the Zetaris ` +
    `Knowledge base (REPO: kbase); say which one a fact came from, and if they disagree show ` +
    `both. If the passages do not contain the answer, say "not covered in these docs" and do ` +
    `not invent syntax.`;
}

const CODE_WORDS =
  /\b(sql|query|queries|select|example|syntax|statement|command|create|script|show me|write)\b/i;

/** Questions that ask for SQL or an example get whole files, not just chunks. */
export function isCodeQuestion(q: string): boolean {
  return CODE_WORDS.test(q);
}

/** Remove the leading block of `--` comment lines from a SQL file's text. */
export function stripSqlHeader(sql: string): string {
  const lines = sql.split("\n");
  let i = 0;
  while (
    i < lines.length && (lines[i].startsWith("--") || lines[i].trim() === "")
  ) i++;
  return lines.slice(i).join("\n");
}

export const MAX_FILE_CHARS = 7000;

/** Whole-file context for the top files: each file's text up to MAX_FILE_CHARS, headed by its path. */
export async function wholeFileContext(
  files: string[],
  read: (file: string) => Promise<string | null>,
  limit = 4,
  keepHeader = false,
): Promise<{ header: string; text: string }[]> {
  const out: { header: string; text: string }[] = [];
  for (const f of files.slice(0, limit)) {
    const raw = await read(f);
    if (raw === null) continue;
    const body = f.endsWith(".sql") && !keepHeader ? stripSqlHeader(raw) : raw;
    out.push({
      header: `FILE: ${f}\nWHOLE FILE: yes`,
      text: body.slice(0, MAX_FILE_CHARS),
    });
  }
  return out;
}

/** For code questions: the two best SQL scripts and the two best other files, so the model sees
 * real statements as well as the prose around them. Input is ordered best first. */
export function pickCodeFiles(files: string[]): string[] {
  const sql = files.filter((f) => f.endsWith(".sql")).slice(0, 2);
  const other = files.filter((f) => !f.endsWith(".sql")).slice(0, 2);
  return [...sql, ...other];
}
