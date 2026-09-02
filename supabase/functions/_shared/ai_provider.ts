// MatricQuest SA — provider-independent AI service layer (section 3/6).
// Nothing above this module knows which LLM vendor is in use. Swapping providers means writing a
// new class here and changing one line in the factory — no changes anywhere else in the codebase.
// API keys live only in Supabase Edge Function secrets (`supabase secrets set ...`), never in the
// mobile app bundle and never in this repo.

export interface AiMessage {
  role: "system" | "user" | "assistant";
  content: string;
}

export interface AiCompletionRequest {
  messages: AiMessage[];
  maxOutputTokens?: number;
  temperature?: number;
}

export interface AiCompletionResult {
  text: string;
  inputTokens: number;
  outputTokens: number;
  estimatedCostCents: number;
}

export interface AiProvider {
  readonly name: string;
  complete(req: AiCompletionRequest): Promise<AiCompletionResult>;
}

/** Anthropic Claude implementation. Reads its key from the ANTHROPIC_API_KEY secret. */
class AnthropicProvider implements AiProvider {
  readonly name = "anthropic";
  private readonly apiKey: string;
  private readonly model: string;

  constructor(apiKey: string, model = "claude-sonnet-5") {
    this.apiKey = apiKey;
    this.model = model;
  }

  async complete(req: AiCompletionRequest): Promise<AiCompletionResult> {
    const system = req.messages.find((m) => m.role === "system")?.content;
    const turns = req.messages.filter((m) => m.role !== "system");

    const res = await fetch("https://api.anthropic.com/v1/messages", {
      method: "POST",
      headers: {
        "content-type": "application/json",
        "x-api-key": this.apiKey,
        "anthropic-version": "2023-06-01",
      },
      body: JSON.stringify({
        model: this.model,
        system,
        messages: turns.map((m) => ({ role: m.role, content: m.content })),
        max_tokens: req.maxOutputTokens ?? 800,
        temperature: req.temperature ?? 0.2,
      }),
    });

    if (!res.ok) {
      throw new Error(`AnthropicProvider: upstream error ${res.status}: ${await res.text()}`);
    }

    const data = await res.json();
    const text = (data.content ?? []).map((b: { text?: string }) => b.text ?? "").join("");
    const inputTokens = data.usage?.input_tokens ?? 0;
    const outputTokens = data.usage?.output_tokens ?? 0;

    // Rough cost estimate for Sonnet-class pricing; used only for the per-learner daily cost cap,
    // not for billing. Keep in one place so it's easy to correct when pricing changes.
    const estimatedCostCents = Math.round((inputTokens / 1_000_000) * 300 + (outputTokens / 1_000_000) * 1500);

    return { text, inputTokens, outputTokens, estimatedCostCents };
  }
}

/** No-network stub used by local dev / CI when no provider key is configured (section 3). */
class LocalStubProvider implements AiProvider {
  readonly name = "local_stub";

  async complete(req: AiCompletionRequest): Promise<AiCompletionResult> {
    const lastUser = [...req.messages].reverse().find((m) => m.role === "user")?.content ?? "";
    return {
      text:
        "[local dev mode — no AI provider configured] I can't reach a real model right now, so I " +
        "can't verify an answer to: \"" + lastUser.slice(0, 160) + "\". Configure ANTHROPIC_API_KEY " +
        "to enable Quest Coach.",
      inputTokens: 0,
      outputTokens: 0,
      estimatedCostCents: 0,
    };
  }
}

export function createAiProvider(env: Record<string, string | undefined>): AiProvider {
  const key = env.ANTHROPIC_API_KEY;
  if (!key) return new LocalStubProvider();
  return new AnthropicProvider(key, env.ANTHROPIC_MODEL ?? "claude-sonnet-5");
}
