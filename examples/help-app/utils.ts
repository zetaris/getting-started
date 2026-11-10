import { createDefine } from "fresh";

// Per-request state. There is no login in v1, so it is only the browser session id the
// one-LLM-request-at-a-time limit keys on.
export interface State {
  sessionId: string;
}

export const define = createDefine<State>();
