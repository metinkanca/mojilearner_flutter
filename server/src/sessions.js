/**
 * Chat sessions, held server-side.
 *
 * The client contract forces this: `/v1/ai/chat/send` sends only a sessionId
 * and one message, so the conversation history has to live here. That is the
 * single fact that decides how this service can be hosted — it cannot be a
 * stateless function without an external store.
 *
 * The default store is an in-memory Map, which is correct for one long-lived
 * process and wrong for more than one. Anything that scales past a single
 * instance needs a shared implementation of this interface instead; the
 * endpoints only ever use the four methods below.
 */

/** Idle time after which a session is dropped. */
const DEFAULT_TTL_MS = 30 * 60 * 1000;

/**
 * Hard cap on concurrent sessions.
 *
 * Without it a bored caller can hold the process's whole heap in abandoned
 * conversations. On overflow the least recently used session goes, which is
 * the one most likely to have been abandoned already.
 */
const DEFAULT_MAX_SESSIONS = 500;

/**
 * Messages kept in a conversation, oldest dropped first.
 *
 * The cost control that matters most, because the provider is stateless: every
 * turn re-sends the whole history at the input rate, so an untrimmed chat costs
 * O(n^2) in tokens over n turns. A 20-turn session bills roughly 76k input
 * tokens to carry 6k tokens of actual conversation.
 *
 * Safe to trim here precisely because it is not where the conversation's rules
 * live. The persona, the output format, the scenario briefing and the SRS queue
 * are all in `systemInstruction`, which is stored separately and re-sent whole
 * on every turn. What ageing out costs the learner is the far end of a long
 * chat, which the model would have been weighting lightly anyway.
 *
 * 16 is eight exchanges. Long enough that a scenario holds together, short
 * enough that the quadratic never gets going.
 */
const DEFAULT_MAX_HISTORY = 16;

export class MemorySessionStore {
  constructor({
    ttlMs = DEFAULT_TTL_MS,
    maxSessions = DEFAULT_MAX_SESSIONS,
    maxHistory = DEFAULT_MAX_HISTORY,
  } = {}) {
    this.ttlMs = ttlMs;
    this.maxSessions = maxSessions;
    this.maxHistory = maxHistory;
    /** @type {Map<string, {systemInstruction: string, history: Array<{role: string, text: string}>, model: string, touchedAt: number}>} */
    this.sessions = new Map();
  }

  /** Drops everything idle for longer than the TTL. */
  sweep(now = Date.now()) {
    for (const [id, s] of this.sessions) {
      if (now - s.touchedAt > this.ttlMs) this.sessions.delete(id);
    }
  }

  /**
   * The most recent [maxHistory] messages, with a leading model turn dropped.
   *
   * That last part is not cosmetic: Gemini rejects a `contents` array whose
   * first entry is a model turn, and slicing a window out of an alternating
   * conversation lands on one half the time.
   */
  trim(history) {
    if (!(this.maxHistory > 0) || history.length <= this.maxHistory) return history;
    const window = history.slice(-this.maxHistory);
    return window[0]?.role === 'model' ? window.slice(1) : window;
  }

  create(id, { systemInstruction, history, model }) {
    this.sweep();
    if (this.sessions.size >= this.maxSessions) {
      // Map preserves insertion order and `get` reinserts, so the first key is
      // the least recently used.
      const oldest = this.sessions.keys().next().value;
      if (oldest !== undefined) this.sessions.delete(oldest);
    }
    this.sessions.set(id, {
      systemInstruction,
      history: this.trim([...history]),
      model,
      touchedAt: Date.now(),
    });
  }

  /** Returns the session, or null when it is unknown or has expired. */
  get(id) {
    const s = this.sessions.get(id);
    if (!s) return null;
    if (Date.now() - s.touchedAt > this.ttlMs) {
      this.sessions.delete(id);
      return null;
    }
    // Reinsert so recency ordering stays true for the LRU eviction above.
    this.sessions.delete(id);
    s.touchedAt = Date.now();
    this.sessions.set(id, s);
    return s;
  }

  /**
   * Adds one message and re-applies the window.
   *
   * Mutates the stored array in place rather than replacing it, so a caller
   * holding the session object from `get` still sees the trim — and so the
   * rollback in `/v1/ai/chat/send`, which pops the user turn it just added,
   * keeps popping the right element.
   */
  append(id, message) {
    const s = this.get(id);
    if (!s) return false;
    s.history.push(message);
    const trimmed = this.trim(s.history);
    if (trimmed.length !== s.history.length) {
      s.history.splice(0, s.history.length - trimmed.length);
    }
    return true;
  }

  get size() {
    return this.sessions.size;
  }
}

/** Opaque, unguessable session id. */
export function newSessionId(randomBytes) {
  return `s_${Date.now().toString(36)}_${randomBytes(12).toString('hex')}`;
}
