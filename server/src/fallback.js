/**
 * Two providers, one interface: try the primary, use the backup when it fails.
 *
 * The case this exists for is concrete. `gemini-2.5-flash-lite` scored 140/140
 * against the tutor prompt at roughly a third the price of the 3.1 the app
 * ships — but Google has closed it to new API keys, so it is reachable only
 * through OpenRouter, and only for as long as OpenRouter's own access lasts.
 * Running it without a net would mean the day Google finishes retiring it, the
 * app's AI stops. With a net, that day is a line in a log.
 *
 * What it does not do is judge quality. A backup can only react to a request
 * that *failed*; a primary that answers badly still answers, and no wrapper can
 * tell. That is what `tools/eval` is for, and why re-running it against the
 * shipped model matters more than this file does.
 */

/**
 * Which primary failures are worth trying the backup for: all of them.
 *
 * This started out clever — pass through 4xx on the grounds that a malformed
 * request would fail identically on the backup, and retrying only doubles the
 * latency to reach the same error. Pointing the primary at a retired model to
 * test it showed why that was wrong: OpenRouter answers an unknown model with
 * **400** and the message "is not a valid model ID", not 404. The one scenario
 * this class exists for was landing in the "do not retry" branch.
 *
 * So the rule is now the simple one, and the asymmetry justifies it. The
 * primary is an optimisation; the backup is the contract. Retrying a genuinely
 * malformed request costs one wasted call before the same error surfaces, and
 * `stats.failed` still counts it. Not retrying a recoverable one costs an
 * outage. There is no primary error where returning it beats trying the backup.
 */

export class FallbackProvider {
  /**
   * @param {{primary: object, backup: object, primaryModel?: string,
   *   backupModel: string, logger?: object}} opts
   *   `backupModel` is required and is usually a *different* model id, not just
   *   the same one on another route — the whole scenario is the primary's model
   *   ceasing to exist. `primaryModel` overrides whatever the caller asked for,
   *   which is what lets the app keep requesting the model it was built with
   *   while the deployment quietly serves a cheaper one.
   */
  constructor({ primary, backup, primaryModel = null, backupModel, logger = console } = {}) {
    if (!primary) throw new Error('a primary provider is required');
    if (!backup) throw new Error('a backup provider is required');
    if (!backupModel) throw new Error('backupModel is required');
    this.primary = primary;
    this.backup = backup;
    this.primaryModel = primaryModel;
    this.backupModel = backupModel;
    this.logger = logger;

    /**
     * Counters, surfaced on `/healthz`.
     *
     * The reason to run the primary at all is that it is cheaper. If it starts
     * failing permanently and every request silently lands on the backup, the
     * app keeps working perfectly while the bill triples — and nothing would
     * say so. These numbers are how that becomes visible.
     */
    this.stats = { primary: 0, fallback: 0, failed: 0, lastFallbackAt: null };
  }

  async generate(req) {
    try {
      const reply = await this.primary.generate({
        ...req,
        model: this.primaryModel ?? req.model,
      });
      this.stats.primary += 1;
      return reply;
    } catch (err) {
      this.stats.fallback += 1;
      this.stats.lastFallbackAt = new Date().toISOString();
      // The message, never the body: an upstream error can quote the prompt.
      this.logger.warn?.(
        `ai-proxy: primary failed (${err.message}); serving ${this.backupModel}`,
      );

      try {
        return await this.backup.generate({ ...req, model: this.backupModel });
      } catch (backupErr) {
        this.stats.failed += 1;
        throw backupErr;
      }
    }
  }

  /** Shape for `/healthz`. */
  snapshot() {
    const served = this.stats.primary + this.stats.fallback;
    return {
      ...this.stats,
      backupModel: this.backupModel,
      fallbackRate: served ? Number((this.stats.fallback / served).toFixed(4)) : 0,
    };
  }
}
