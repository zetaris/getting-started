// One in-flight LLM request per browser session: a call can occupy the model for 45 s on the
// user's own hardware. In memory, so it resets on restart and is per server process.
export class InFlight {
  #busy = new Set<string>();

  /** Returns a release function, or null when this session already has a request running. */
  tryStart(id: string): (() => void) | null {
    if (this.#busy.has(id)) return null;
    this.#busy.add(id);
    return () => void this.#busy.delete(id);
  }

  get size(): number {
    return this.#busy.size;
  }
}
