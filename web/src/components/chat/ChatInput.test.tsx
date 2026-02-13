import { describe, it, expect, vi } from 'vitest';
import { render, screen, fireEvent } from '@testing-library/react';
import ChatInput from './ChatInput';

describe('ChatInput', () => {
  it('Enter 키로 메시지를 전송한다', () => {
    const onSend = vi.fn();
    render(<ChatInput onSend={onSend} />);
    const textarea = screen.getByPlaceholderText('TYPE_MESSAGE...');

    fireEvent.change(textarea, { target: { value: 'hello' } });
    fireEvent.keyDown(textarea, { key: 'Enter', shiftKey: false });

    expect(onSend).toHaveBeenCalledWith('hello');
  });

  it('전송 후 입력값이 초기화된다', () => {
    const onSend = vi.fn();
    render(<ChatInput onSend={onSend} />);
    const textarea = screen.getByPlaceholderText('TYPE_MESSAGE...');

    fireEvent.change(textarea, { target: { value: 'hello' } });
    fireEvent.keyDown(textarea, { key: 'Enter', shiftKey: false });

    expect(textarea).toHaveValue('');
  });

  it('Shift+Enter는 전송하지 않는다 (줄바꿈)', () => {
    const onSend = vi.fn();
    render(<ChatInput onSend={onSend} />);
    const textarea = screen.getByPlaceholderText('TYPE_MESSAGE...');

    fireEvent.change(textarea, { target: { value: 'hello' } });
    fireEvent.keyDown(textarea, { key: 'Enter', shiftKey: true });

    expect(onSend).not.toHaveBeenCalled();
  });

  it('빈 메시지는 전송할 수 없다', () => {
    const onSend = vi.fn();
    render(<ChatInput onSend={onSend} />);
    const textarea = screen.getByPlaceholderText('TYPE_MESSAGE...');

    fireEvent.keyDown(textarea, { key: 'Enter', shiftKey: false });
    expect(onSend).not.toHaveBeenCalled();

    // 공백만 있는 경우도
    fireEvent.change(textarea, { target: { value: '   ' } });
    fireEvent.keyDown(textarea, { key: 'Enter', shiftKey: false });
    expect(onSend).not.toHaveBeenCalled();
  });

  it('disabled 상태에서는 입력이 비활성화된다', () => {
    render(<ChatInput onSend={vi.fn()} disabled />);
    const textarea = screen.getByPlaceholderText('TYPE_MESSAGE...');

    expect(textarea).toBeDisabled();
  });

  it('disabled 상태에서 전송 버튼도 비활성화된다', () => {
    render(<ChatInput onSend={vi.fn()} disabled />);
    const button = screen.getByRole('button', { name: 'Send message' });

    expect(button).toBeDisabled();
  });

  it('Send 버튼 클릭으로 메시지를 전송한다', () => {
    const onSend = vi.fn();
    render(<ChatInput onSend={onSend} />);
    const textarea = screen.getByPlaceholderText('TYPE_MESSAGE...');
    const button = screen.getByRole('button', { name: 'Send message' });

    fireEvent.change(textarea, { target: { value: 'click send' } });
    fireEvent.click(button);

    expect(onSend).toHaveBeenCalledWith('click send');
  });
});
