'use client';
import { useSyncExternalStore, type ReactNode } from 'react';
const subscribe = () => () => {};
export function useClientReady() {
  return useSyncExternalStore(subscribe, () => true, () => false);
}
export default function ClientOnly({ children }: { children: ReactNode }) {
  return useClientReady() ? children : null;
}
