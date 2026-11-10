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
      <span>Your name (optional)</span>
      <input
        type="text"
        maxLength={100}
        autocomplete="off"
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
