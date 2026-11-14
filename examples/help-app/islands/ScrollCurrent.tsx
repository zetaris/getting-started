import { useEffect } from "preact/hooks";

/** Bring the current page's sidebar link into view once the drawer is open. */
export default function ScrollCurrent() {
  useEffect(() => {
    document.querySelector('aside.side a[aria-current="page"]')
      ?.scrollIntoView({ block: "nearest" });
  }, []);
  return null;
}
