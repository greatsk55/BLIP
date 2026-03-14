'use client';

import { use } from 'react';
import EmbedRoomClient from './EmbedRoomClient';

interface PageProps {
  params: Promise<{ roomId: string }>;
}

export default function EmbedRoomPage({ params }: PageProps) {
  const { roomId } = use(params);
  return <EmbedRoomClient roomId={roomId} />;
}
