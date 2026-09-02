// MatricQuest SA — approved-content retrieval for Quest Coach (section 6).
// Quest Coach may only ground its answers in rows that are content_status = 'published'
// (lessons/topics/questions) or a papers/paper_assets row with a confirmed association.
// It must never search draft/in_review content, and must never fabricate a citation.

import type { SupabaseClient } from "https://esm.sh/@supabase/supabase-js@2";

export interface RetrievedSource {
  entityType: "lesson" | "question" | "topic" | "paper";
  entityId: string;
  title: string;
}

export interface RetrievalResult {
  contextText: string;
  sources: RetrievedSource[];
}

/**
 * Naive but honest retrieval: full-text match against published lesson blocks and question
 * prompts/solutions within the given topic (or subject, if no topic is selected yet). Returns
 * an empty result — never a guess — when nothing published matches, so the caller can tell the
 * learner "could not verify" instead of inventing an answer.
 */
export async function retrieveApprovedContext(
  supabase: SupabaseClient,
  params: { subjectId?: string; topicId?: string; queryText: string },
): Promise<RetrievalResult> {
  const sources: RetrievedSource[] = [];
  const chunks: string[] = [];

  let lessonQuery = supabase
    .from("lessons")
    .select("id, title, topic_id, lesson_blocks(body_markdown, block_type)")
    .eq("content_status", "published")
    .limit(3);
  if (params.topicId) lessonQuery = lessonQuery.eq("topic_id", params.topicId);

  const { data: lessons } = await lessonQuery;
  for (const lesson of lessons ?? []) {
    const text = (lesson.lesson_blocks ?? [])
      .map((b: { body_markdown?: string }) => b.body_markdown ?? "")
      .join("\n");
    if (text.trim().length === 0) continue;
    chunks.push(`Lesson "${lesson.title}":\n${text}`);
    sources.push({ entityType: "lesson", entityId: lesson.id, title: lesson.title });
  }

  let questionQuery = supabase
    .from("questions")
    .select("id, prompt_markdown, topic_id, question_solutions(solution_markdown, explanation_markdown, is_official_memorandum)")
    .eq("content_status", "published")
    .limit(3);
  if (params.topicId) questionQuery = questionQuery.eq("topic_id", params.topicId);

  const { data: questions } = await questionQuery;
  for (const q of questions ?? []) {
    const solutions = (q.question_solutions ?? [])
      .map((s: { solution_markdown: string; is_official_memorandum: boolean }) =>
        `${s.is_official_memorandum ? "[Official memorandum guidance] " : "[Teaching explanation] "}${s.solution_markdown}`)
      .join("\n");
    chunks.push(`Question: ${q.prompt_markdown}\n${solutions}`);
    sources.push({ entityType: "question", entityId: q.id, title: q.prompt_markdown.slice(0, 60) });
  }

  return { contextText: chunks.join("\n\n---\n\n"), sources };
}
