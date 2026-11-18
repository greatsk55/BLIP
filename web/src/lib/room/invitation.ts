/** URLSearchParams decodes exactly once, preserving literal percent characters. */
export function readInvitation(url: string) {
  const parsed = new URL(url);
  let values = new URLSearchParams(parsed.hash.slice(1));
  if (!values.get('p') && !values.get('k')) values = parsed.searchParams;
  return { creator: values.get('p') || undefined, password: values.get('k') || undefined,
    admin: values.get('a') || undefined };
}
