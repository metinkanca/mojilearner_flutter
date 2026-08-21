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

export class MemorySessionStore {
  constructor({ ttlMs = DEFAULT_TTL_MS, maxSessions = DEFAULT_MAX_SESSIONS } = {}) {
    this.ttlMs = ttlMs;
    this.maxSessions = maxSessions;
    /** @type {Map<string, {systemInstruction: string, history: Array<{role: string, text: string}>, model: string, touchedAt: number}>} */
    this.sessions = new Map();
  }

  /** Drops everything idle for longer than the TTL. */
  sweep(now = Date.now()) {
    for (const [id, s] of this.sessions) {
      if (now - s.touchedAt > this.ttlMs) this.sessions.delete(id);
    }
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
      history: [...history],
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

  append(id, message) {
    const s = this.get(id);
    if (!s) return false;
    s.history.push(message);
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
