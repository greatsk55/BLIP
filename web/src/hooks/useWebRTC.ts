'use client';

import { useState, useCallback, useRef, useEffect } from 'react';
import { encryptMessage, decryptMessage, encryptFileChunk, decryptFileChunk } from '@/lib/crypto';
import { splitIntoChunks, reassembleChunks, computeChecksum, verifyChecksum, CHUNK_SIZE } from '@/lib/media/chunk';
import { compressImage } from '@/lib/media/compress';
import { createVideoThumbnail, getMediaType, validateFileSize } from '@/lib/media/thumbnail';
import type { FileTransferHeader, DecryptedMessage, MediaMetadata } from '@/types/chat';
import type { WebRTCSignalingHandlers } from '@/hooks/useChat';

// DataChannel 바이너리 프로토콜 타입
const PACKET_HEADER = 0x01;
const PACKET_CHUNK = 0x02;
const PACKET_DONE = 0x03;
const PACKET_CANCEL = 0x05;

// 바이너리 프로토콜 상수
// UUID = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx" (36자)
// 기존 32바이트 → transferId 잘림 → HEADER의 전체 UUID와 Map key 불일치
const TRANSFER_ID_SIZE = 36;

// 흐름 제어
const WINDOW_SIZE = 16;
const BUFFERED_AMOUNT_LOW = CHUNK_SIZE * 4;

const log = (...args: unknown[]) => console.log('[WebRTC]', ...args);
const logError = (...args: unknown[]) => console.error('[WebRTC]', ...args);

export type WebRTCState = 'idle' | 'connecting' | 'connected' | 'failed' | 'closed';

interface UseWebRTCOptions {
  enabled: boolean;
  channel: any; // Supabase RealtimeChannel (send 전용)
  sharedSecret: Uint8Array | null;
  isInitiator: boolean;
  myId: string;
  onMediaReceived: (message: Omit<DecryptedMessage, 'isMine'>) => void;
  onTransferProgress: (transferId: string, progress: number) => void;
  /** useChat이 subscribe 전에 등록한 시그널링 핸들러 setter */
  setWebrtcHandlers: (handlers: WebRTCSignalingHandlers | null) => void;
}

interface UseWebRTCReturn {
  sendFile: (file: File, transferId: string) => Promise<string | null>;
  webrtcState: WebRTCState;
  cleanup: () => void;
}

export function useWebRTC({
  enabled,
  channel,
  sharedSecret,
  isInitiator,
  myId,
  onMediaReceived,
  onTransferProgress,
  setWebrtcHandlers,
}: UseWebRTCOptions): UseWebRTCReturn {
  const [webrtcState, setWebrtcState] = useState<WebRTCState>('idle');

  const pcRef = useRef<RTCPeerConnection | null>(null);
  const dcRef = useRef<RTCDataChannel | null>(null);

  // 수신 중인 파일 전송 상태
  const receivingRef = useRef<Map<string, {
    header: FileTransferHeader;
    chunks: Map<number, Uint8Array>;
    receivedCount: number;
  }>>(new Map());

  const sharedSecretRef = useRef(sharedSecret);
  sharedSecretRef.current = sharedSecret;

  const channelRef = useRef(channel);
  channelRef.current = channel;

  const onMediaReceivedRef = useRef(onMediaReceived);
  onMediaReceivedRef.current = onMediaReceived;

  const onTransferProgressRef = useRef(onTransferProgress);
  onTransferProgressRef.current = onTransferProgress;

  // DataChannel 메시지 수신 처리
  const setupDataChannel = useCallback((dc: RTCDataChannel) => {
    dc.binaryType = 'arraybuffer';
    dcRef.current = dc;

    dc.onopen = () => {
      log('DataChannel opened');
      setWebrtcState('connected');
    };

    dc.onclose = () => {
      log('DataChannel closed');
      setWebrtcState('closed');
    };

    dc.onerror = (e) => {
      logError('DataChannel error:', e);
    };

    dc.onmessage = async (event) => {
      if (!sharedSecretRef.current) return;

      const data = new Uint8Array(event.data as ArrayBuffer);
      const packetType = data[0];
      const payload = data.slice(1);

      switch (packetType) {
        case PACKET_HEADER: {
          const decrypted = decryptMessage(
            JSON.parse(new TextDecoder().decode(payload)),
            sharedSecretRef.current
          );
          if (!decrypted) return;

          const header: FileTransferHeader = JSON.parse(decrypted);
          log('Receiving file:', header.fileName, `(${header.totalChunks} chunks)`);
          receivingRef.current.set(header.transferId, {
            header,
            chunks: new Map(),
            receivedCount: 0,
          });
          break;
        }

        case PACKET_CHUNK: {
          const transferIdBytes = payload.slice(0, TRANSFER_ID_SIZE);
          const transferId = new TextDecoder().decode(transferIdBytes).replace(/\0/g, '');
          const view = new DataView(payload.buffer, payload.byteOffset + TRANSFER_ID_SIZE, 4);
          const chunkIndex = view.getUint32(0);
          const nonce = payload.slice(TRANSFER_ID_SIZE + 4, TRANSFER_ID_SIZE + 4 + 24);
          const ciphertext = payload.slice(TRANSFER_ID_SIZE + 4 + 24);

          const transfer = receivingRef.current.get(transferId);
          if (!transfer) {
            logError('Chunk for unknown transfer:', transferId);
            return;
          }

          const decrypted = decryptFileChunk(ciphertext, nonce, sharedSecretRef.current);
          if (!decrypted) {
            logError('Chunk decrypt failed — index:', chunkIndex);
            return;
          }

          transfer.chunks.set(chunkIndex, decrypted);
          transfer.receivedCount++;
          log('Chunk', chunkIndex, 'received', `(${transfer.receivedCount}/${transfer.header.totalChunks})`);

          const progress = transfer.receivedCount / transfer.header.totalChunks;
          onTransferProgressRef.current(transferId, progress);
          break;
        }

        case PACKET_DONE: {
          const transferId = new TextDecoder().decode(payload.slice(0, TRANSFER_ID_SIZE)).replace(/\0/g, '');
          const expectedChecksum = new TextDecoder().decode(payload.slice(TRANSFER_ID_SIZE));

          const transfer = receivingRef.current.get(transferId);
          if (!transfer) return;

          try {
            log('Reassembling', transfer.header.totalChunks, 'chunks...');
            const assembled = reassembleChunks(transfer.chunks, transfer.header.totalChunks);
            const valid = await verifyChecksum(assembled, expectedChecksum);
            if (!valid) {
              logError('File checksum mismatch');
              return;
            }

            const blob = new Blob([assembled.buffer as ArrayBuffer], { type: transfer.header.mimeType });
            const mediaUrl = URL.createObjectURL(blob);

            const mediaType = getMediaType(transfer.header.mimeType);
            if (!mediaType) {
              logError('Unknown media type:', transfer.header.mimeType);
              return;
            }

            log('File received:', transfer.header.fileName, `(${assembled.length} bytes)`);
            onMediaReceivedRef.current({
              id: transfer.header.transferId,
              senderId: 'peer',
              senderName: '',
              content: '',
              timestamp: Date.now(),
              type: mediaType,
              mediaUrl,
              mediaMetadata: {
                fileName: transfer.header.fileName,
                mimeType: transfer.header.mimeType,
                size: transfer.header.totalSize,
              },
            });
          } catch (e) {
            logError('DONE processing error:', e);
          } finally {
            receivingRef.current.delete(transferId);
          }
          break;
        }

        case PACKET_CANCEL: {
          const transferId = new TextDecoder().decode(payload.slice(0, TRANSFER_ID_SIZE)).replace(/\0/g, '');
          receivingRef.current.delete(transferId);
          log('Transfer cancelled:', transferId);
          break;
        }
      }
    };
  }, []);

  // WebRTC 연결 초기화
  useEffect(() => {
    if (!enabled || !channel || !sharedSecret) {
      return;
    }

    log('Init start — initiator:', isInitiator);
    let isMounted = true;

    // 시그널링 큐: TURN fetch 완료 전 도착한 메시지 보관
    const pendingSignals: { type: string; payload: any }[] = [];
    let pcReady = false;

    // Supabase broadcast payload 추출 — 중첩 깊이에 상관없이 ciphertext를 찾음
    // self: false 설정으로 자기 자신의 브로드캐스트는 수신하지 않으므로 senderId 체크 불필요
    function extractCrypto(raw: any): { ciphertext: string; nonce: string } | null {
      // ciphertext가 나올 때까지 .payload 를 최대 3단계 unwrap
      let obj = raw;
      for (let i = 0; i < 3; i++) {
        if (obj?.ciphertext && obj?.nonce) return obj;
        if (obj?.payload !== undefined) obj = obj.payload;
        else break;
      }
      if (obj?.ciphertext && obj?.nonce) return obj;
      return null;
    }

    // --- 시그널링 핸들러 ---
    async function processOffer(payload: any) {
      if (!sharedSecretRef.current || !pcRef.current) {
        log('processOffer SKIPPED — no pc or no secret');
        return;
      }
      const crypto = extractCrypto(payload);
      if (!crypto) {
        logError('processOffer — failed to extract ciphertext/nonce from payload');
        return;
      }

      try {
        const decrypted = decryptMessage(crypto, sharedSecretRef.current);
        if (!decrypted) {
          logError('processOffer — decryption failed');
          return;
        }

        const offer = JSON.parse(decrypted);
        log('Received offer, setting remote description');
        await pcRef.current.setRemoteDescription(offer);

        const answer = await pcRef.current.createAnswer();
        await pcRef.current.setLocalDescription(answer);

        const encrypted = encryptMessage(
          JSON.stringify(answer),
          sharedSecretRef.current
        );
        channelRef.current?.send({
          type: 'broadcast',
          event: 'webrtc_answer',
          payload: {
            ciphertext: encrypted.ciphertext,
            nonce: encrypted.nonce,
          },
        });
        log('Sent answer');
      } catch (e) {
        logError('processOffer error:', e);
      }
    }

    async function processAnswer(payload: any) {
      if (!sharedSecretRef.current || !pcRef.current) {
        log('processAnswer SKIPPED — no pc or no secret');
        return;
      }
      const crypto = extractCrypto(payload);
      if (!crypto) {
        logError('processAnswer — failed to extract ciphertext/nonce');
        return;
      }

      try {
        const decrypted = decryptMessage(crypto, sharedSecretRef.current);
        if (!decrypted) {
          logError('processAnswer — decryption failed');
          return;
        }

        log('Received answer, setting remote description');
        await pcRef.current.setRemoteDescription(JSON.parse(decrypted));
      } catch (e) {
        logError('processAnswer error:', e);
      }
    }

    async function processIce(payload: any) {
      if (!sharedSecretRef.current || !pcRef.current) return;
      const crypto = extractCrypto(payload);
      if (!crypto) return;

      try {
        const decrypted = decryptMessage(crypto, sharedSecretRef.current);
        if (!decrypted) return;

        await pcRef.current.addIceCandidate(new RTCIceCandidate(JSON.parse(decrypted)));
      } catch (e) {
        logError('processIce error:', e);
      }
    }

    // 시그널 도착 시: PC 준비됐으면 바로 처리, 아니면 큐에 보관
    function handleOffer(payload: any) {
      if (pcReady) processOffer(payload);
      else pendingSignals.push({ type: 'offer', payload });
    }
    function handleAnswer(payload: any) {
      if (pcReady) processAnswer(payload);
      else pendingSignals.push({ type: 'answer', payload });
    }
    function handleIce(payload: any) {
      if (pcReady) processIce(payload);
      else pendingSignals.push({ type: 'ice', payload });
    }

    // ★ useChat이 subscribe 전에 등록한 시그널링 핸들러에 콜백 연결
    setWebrtcHandlers({
      onOffer: handleOffer,
      onAnswer: handleAnswer,
      onIce: handleIce,
    });
    log('Signaling handlers registered via useChat forwarding');

    async function initWebRTC() {
      // 1. TURN 크레덴셜 가져오기
      let iceServers: RTCIceServer[];
      try {
        const res = await fetch('/api/turn-credentials');
        if (!res.ok) throw new Error(`TURN API ${res.status}`);
        const data = await res.json();
        iceServers = data.iceServers;
        log('TURN credentials fetched:', iceServers.length, 'servers');
      } catch (e) {
        logError('TURN fetch failed, falling back to STUN:', e);
        iceServers = [{ urls: 'stun:stun.cloudflare.com:3478' }];
      }
      if (!isMounted) return;

      // 2. PeerConnection 생성
      const pc = new RTCPeerConnection({
        iceServers,
        iceTransportPolicy: 'relay',
      });
      pcRef.current = pc;
      setWebrtcState('connecting');

      pc.oniceconnectionstatechange = () => {
        const state = pc.iceConnectionState;
        log('ICE state:', state);
        if (state === 'failed' || state === 'disconnected') {
          setWebrtcState('failed');
        } else if (state === 'closed') {
          setWebrtcState('closed');
        }
      };

      pc.onicecandidate = (event) => {
        if (event.candidate && sharedSecretRef.current && channelRef.current) {
          const encrypted = encryptMessage(
            JSON.stringify(event.candidate.toJSON()),
            sharedSecretRef.current
          );
          channelRef.current.send({
            type: 'broadcast',
            event: 'webrtc_ice',
            payload: {
              ciphertext: encrypted.ciphertext,
              nonce: encrypted.nonce,
            },
          });
        }
      };

      pc.onicegatheringstatechange = () => {
        log('ICE gathering state:', pc.iceGatheringState);
      };

      // 3. Responder: DataChannel 수신 대기
      if (!isInitiator) {
        pc.ondatachannel = (event) => {
          log('DataChannel received from initiator');
          setupDataChannel(event.channel);
        };
      }

      // 4. PC 준비 완료 → 큐에 쌓인 시그널 처리
      pcReady = true;
      for (const signal of pendingSignals) {
        if (signal.type === 'offer') await processOffer(signal.payload);
        else if (signal.type === 'answer') await processAnswer(signal.payload);
        else if (signal.type === 'ice') await processIce(signal.payload);
      }
      pendingSignals.length = 0;

      // 5. Initiator: DataChannel 생성 + Offer 전송
      if (isInitiator) {
        const dc = pc.createDataChannel('media', {
          ordered: true,
          maxRetransmits: 30,
        });
        setupDataChannel(dc);

        const offer = await pc.createOffer();
        await pc.setLocalDescription(offer);

        if (!sharedSecretRef.current) return;
        const encrypted = encryptMessage(
          JSON.stringify(offer),
          sharedSecretRef.current
        );
        channel.send({
          type: 'broadcast',
          event: 'webrtc_offer',
          payload: {
            ciphertext: encrypted.ciphertext,
            nonce: encrypted.nonce,
          },
        });
        log('Sent offer');
      }
    }

    initWebRTC();

    return () => {
      isMounted = false;
      // 시그널링 핸들러 해제
      setWebrtcHandlers(null);
      // PeerConnection 정리
      if (dcRef.current) {
        dcRef.current.close();
        dcRef.current = null;
      }
      if (pcRef.current) {
        pcRef.current.close();
        pcRef.current = null;
      }
    };
  }, [enabled, channel, sharedSecret, isInitiator, myId, setupDataChannel, setWebrtcHandlers]);

  // 파일 전송
  const sendFile = useCallback(async (file: File, transferId: string): Promise<string | null> => {
    const dc = dcRef.current;
    const secret = sharedSecretRef.current;

    if (!dc || dc.readyState !== 'open' || !secret) {
      logError('sendFile blocked — dc:', dc?.readyState, 'secret:', !!secret);
      return null;
    }

    // 파일 크기 검증
    const sizeCheck = validateFileSize(file);
    if (!sizeCheck.valid) {
      logError('File too large:', file.size);
      return null;
    }
    const mediaType = getMediaType(file.type);
    if (!mediaType) {
      logError('Unsupported media type:', file.type);
      return null;
    }

    try {
      let fileData: Uint8Array;
      let metadata: Partial<MediaMetadata> = {
        fileName: file.name,
        mimeType: file.type,
        size: file.size,
      };

      // 이미지 압축
      if (mediaType === 'image') {
        const compressed = await compressImage(file);
        fileData = new Uint8Array(await compressed.blob.arrayBuffer());
        metadata.width = compressed.width;
        metadata.height = compressed.height;
        metadata.mimeType = compressed.blob.type;
        metadata.size = compressed.blob.size;
      } else {
        // 동영상: 원본 전송
        fileData = new Uint8Array(await file.arrayBuffer());
        try {
          const { metadata: videoMeta } = await createVideoThumbnail(file);
          metadata.width = videoMeta.width;
          metadata.height = videoMeta.height;
          metadata.duration = videoMeta.duration;
        } catch {
          // 섬네일 실패해도 전송 계속
        }
      }

      log('Sending file:', file.name, `(${fileData.length} bytes)`);

      const checksum = await computeChecksum(fileData);
      const chunks = splitIntoChunks(fileData);

      // 1. 헤더 전송
      const header: FileTransferHeader = {
        transferId,
        fileName: metadata.fileName!,
        mimeType: metadata.mimeType!,
        totalSize: metadata.size!,
        totalChunks: chunks.length,
        checksum,
      };

      const encryptedHeader = encryptMessage(JSON.stringify(header), secret);
      const headerJson = new TextEncoder().encode(
        JSON.stringify({ ciphertext: encryptedHeader.ciphertext, nonce: encryptedHeader.nonce })
      );
      const headerPacket = new Uint8Array(1 + headerJson.length);
      headerPacket[0] = PACKET_HEADER;
      headerPacket.set(headerJson, 1);
      dc.send(headerPacket);

      // 2. 청크 전송 (흐름 제어)
      const transferIdBytes = new TextEncoder().encode(
        transferId.padEnd(TRANSFER_ID_SIZE, '\0').slice(0, TRANSFER_ID_SIZE)
      );

      for (let i = 0; i < chunks.length; i++) {
        // 백프레셔: 버퍼가 가득 차면 대기
        while (dc.bufferedAmount > CHUNK_SIZE * WINDOW_SIZE) {
          await waitForBufferDrain(dc);
        }

        const encrypted = encryptFileChunk(chunks[i], secret);

        // [1byte type][36byte transferId][4byte index][24byte nonce][ciphertext]
        const packet = new Uint8Array(1 + TRANSFER_ID_SIZE + 4 + 24 + encrypted.ciphertext.length);
        packet[0] = PACKET_CHUNK;
        packet.set(transferIdBytes, 1);
        const indexView = new DataView(packet.buffer, 1 + TRANSFER_ID_SIZE, 4);
        indexView.setUint32(0, i);
        packet.set(encrypted.nonce, 1 + TRANSFER_ID_SIZE + 4);
        packet.set(encrypted.ciphertext, 1 + TRANSFER_ID_SIZE + 4 + 24);

        dc.send(packet);
        onTransferProgressRef.current(transferId, (i + 1) / chunks.length);
      }

      // 3. 완료 신호
      const checksumBytes = new TextEncoder().encode(checksum);
      const donePacket = new Uint8Array(1 + TRANSFER_ID_SIZE + checksumBytes.length);
      donePacket[0] = PACKET_DONE;
      donePacket.set(transferIdBytes, 1);
      donePacket.set(checksumBytes, 1 + TRANSFER_ID_SIZE);
      dc.send(donePacket);

      log('File sent:', file.name, `(${chunks.length} chunks)`);
      return transferId;
    } catch (e) {
      logError('sendFile error:', e);
      return null;
    }
  }, []);

  // WebRTC 정리
  const cleanup = useCallback(() => {
    if (dcRef.current) {
      dcRef.current.close();
      dcRef.current = null;
    }
    if (pcRef.current) {
      pcRef.current.close();
      pcRef.current = null;
    }
    receivingRef.current.clear();
    setWebrtcState('closed');
  }, []);

  return { sendFile, webrtcState, cleanup };
}

function waitForBufferDrain(dc: RTCDataChannel): Promise<void> {
  return new Promise((resolve) => {
    dc.bufferedAmountLowThreshold = BUFFERED_AMOUNT_LOW;
    dc.onbufferedamountlow = () => {
      dc.onbufferedamountlow = null;
      resolve();
    };
  });
}
