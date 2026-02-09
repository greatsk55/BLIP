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

export interface DecryptedMessage {
  id: string;
  senderId: string;
  senderName: string;
  content: string;
  timestamp: number;
  isMine: boolean;
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
