export interface Room {
  id: string;
  authKeyHash: string;
  createdAt: string;
  expiresAt: string;
  status: 'waiting' | 'active' | 'destroyed';
  participantCount: number;
}

export interface Message {
  id: string;
  senderId: string;
  senderName: string;
  ciphertext: string;
  nonce: string;
  timestamp: number;
}

export type MessageType = 'text' | 'image' | 'video';

export interface MediaMetadata {
  fileName: string;
  mimeType: string;
  size: number;
  width?: number;
  height?: number;
  duration?: number;
}

export interface DecryptedMessage {
  id: string;
  senderId: string;
  senderName: string;
  content: string;
  timestamp: number;
  isMine: boolean;
  type: MessageType;
  mediaUrl?: string;
  mediaThumbnail?: string;
  mediaMetadata?: MediaMetadata;
  transferProgress?: number;
}

export interface FileTransferHeader {
  transferId: string;
  fileName: string;
  mimeType: string;
  totalSize: number;
  totalChunks: number;
  checksum: string;
}

export interface EncryptedFileChunk {
  ciphertext: Uint8Array;
  nonce: Uint8Array;
}

export interface Participant {
  id: string;
  username: string;
  publicKey: string;
  joinedAt: number;
}

export type ChatStatus =
  | 'loading'
  | 'password_required'
  | 'created'
  | 'connecting'
  | 'chatting'
  | 'destroyed'
  | 'expired'
  | 'room_full'
  | 'error';

export interface EncryptedPayload {
  ciphertext: string;
  nonce: string;
}

export interface KeyPair {
  publicKey: Uint8Array;
  secretKey: Uint8Array;
}
