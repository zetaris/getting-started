import { useSignal } from "@preact/signals";
import { useEffect } from "preact/hooks";
import { getName, setName } from "./prefs.ts";

/** There is no login: this free-text name is stored in this browser and sent with pins and likes. */
export default function NameField() {
  const name = useSignal("");
  useEffect(() => {
    name.value = getName();
  }, []);
  return (
    <label class="namefield">
      <span class="sr-only">Your name (optional)</span>
      <input
        type="text"
        maxLength={100}
        autocomplete="off"
        placeholder="Your name"
        title="Optional. Shown on pins, likes and saved examples. There is no login."
        data-testid="name"
        value={name.value}
        onInput={(e) => {
          name.value = (e.target as HTMLInputElement).value;
          setName(name.value);
        }}
      />
    </label>
  );
}
