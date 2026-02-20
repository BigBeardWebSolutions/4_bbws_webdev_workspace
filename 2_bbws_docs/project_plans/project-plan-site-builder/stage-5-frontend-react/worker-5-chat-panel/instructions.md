# Worker Instructions: Chat Panel Component

**Worker ID**: worker-5-chat-panel
**Stage**: Stage 5 - Frontend React Development
**Project**: project-plan-site-builder

---

## Task

Create the Chat Panel component for conversational AI interaction with Server-Sent Events (SSE) streaming support. This is the primary interface for users to interact with the AI to generate and refine landing pages.

---

## Inputs

**Reference Documents**:
- `/Users/tebogotseka/Documents/agentic_work/2_bbws_docs/LLDs/3.1.1_LLD_Site_Builder_Frontend.md` (Section 4, 11)
- `/Users/tebogotseka/Documents/agentic_work/2_bbws_docs/UX/Site_Builder_Wireframes_v1.md`

**Dependencies**:
- App Shell from worker-1
- Generation API endpoint

---

## Deliverables

Create the following files:

### 1. ChatPanel.tsx

```typescript
// src/components/chat/ChatPanel.tsx
import { useState, useRef, useEffect } from 'react';
import { ChatMessage } from './ChatMessage';
import { ChatInput } from './ChatInput';
import { StreamingMessage } from './StreamingMessage';
import { SuggestionChips } from './SuggestionChips';
import { useChat } from '@/hooks/useChat';

interface ChatPanelProps {
  projectId: string;
  onGenerationComplete: (html: string, css: string) => void;
}

export function ChatPanel({ projectId, onGenerationComplete }: ChatPanelProps) {
  const {
    messages,
    isStreaming,
    sendMessage,
    abortGeneration
  } = useChat(projectId);

  const messagesEndRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' });
  }, [messages]);

  const suggestions = [
    'Create a product launch page',
    'Summer sale landing page',
    'Newsletter signup page'
  ];

  return (
    <div className="flex flex-col h-full bg-white">
      {/* Chat Header */}
      <div className="p-4 border-b">
        <h2 className="text-lg font-semibold">AI Assistant</h2>
      </div>

      {/* Messages Area */}
      <div className="flex-1 overflow-y-auto p-4 space-y-4">
        {messages.length === 0 && (
          <div className="text-center text-gray-500 py-8">
            <p className="mb-4">Hi! I'll help you create your landing page.</p>
            <p className="text-sm">What would you like to build today?</p>
          </div>
        )}

        {messages.map((message) => (
          message.isStreaming ? (
            <StreamingMessage
              key={message.id}
              content={message.content}
            />
          ) : (
            <ChatMessage
              key={message.id}
              message={message}
            />
          )
        ))}

        <div ref={messagesEndRef} />
      </div>

      {/* Suggestions */}
      {messages.length === 0 && (
        <SuggestionChips
          suggestions={suggestions}
          onSelect={sendMessage}
        />
      )}

      {/* Input Area */}
      <ChatInput
        onSend={sendMessage}
        onAbort={abortGeneration}
        isStreaming={isStreaming}
        disabled={isStreaming}
      />
    </div>
  );
}
```

### 2. ChatMessage.tsx

```typescript
// src/components/chat/ChatMessage.tsx
import { User, Bot } from 'lucide-react';
import ReactMarkdown from 'react-markdown';
import type { ChatMessage as ChatMessageType } from '@/types';

interface ChatMessageProps {
  message: ChatMessageType;
}

export function ChatMessage({ message }: ChatMessageProps) {
  const isUser = message.role === 'user';

  return (
    <div className={`flex gap-3 ${isUser ? 'flex-row-reverse' : ''}`}>
      {/* Avatar */}
      <div className={`
        w-8 h-8 rounded-full flex items-center justify-center flex-shrink-0
        ${isUser ? 'bg-blue-500' : 'bg-purple-500'}
      `}>
        {isUser ? (
          <User className="w-5 h-5 text-white" />
        ) : (
          <Bot className="w-5 h-5 text-white" />
        )}
      </div>

      {/* Content */}
      <div className={`
        max-w-[80%] rounded-lg p-3
        ${isUser ? 'bg-blue-500 text-white' : 'bg-gray-100 text-gray-900'}
      `}>
        <ReactMarkdown className="prose prose-sm">
          {message.content}
        </ReactMarkdown>

        {/* Timestamp */}
        <div className={`
          text-xs mt-1
          ${isUser ? 'text-blue-200' : 'text-gray-500'}
        `}>
          {new Date(message.timestamp).toLocaleTimeString()}
        </div>
      </div>
    </div>
  );
}
```

### 3. StreamingMessage.tsx

```typescript
// src/components/chat/StreamingMessage.tsx
import { Bot } from 'lucide-react';
import ReactMarkdown from 'react-markdown';

interface StreamingMessageProps {
  content: string;
}

export function StreamingMessage({ content }: StreamingMessageProps) {
  return (
    <div className="flex gap-3">
      <div className="w-8 h-8 rounded-full bg-purple-500 flex items-center justify-center flex-shrink-0">
        <Bot className="w-5 h-5 text-white" />
      </div>

      <div className="max-w-[80%] rounded-lg p-3 bg-gray-100">
        <ReactMarkdown className="prose prose-sm">
          {content}
        </ReactMarkdown>

        {/* Typing indicator */}
        <span className="inline-block w-2 h-4 bg-purple-500 animate-pulse ml-1" />
      </div>
    </div>
  );
}
```

### 4. ChatInput.tsx

```typescript
// src/components/chat/ChatInput.tsx
import { useState, useRef, KeyboardEvent } from 'react';
import { Send, StopCircle } from 'lucide-react';

interface ChatInputProps {
  onSend: (message: string) => void;
  onAbort: () => void;
  isStreaming: boolean;
  disabled: boolean;
}

export function ChatInput({
  onSend,
  onAbort,
  isStreaming,
  disabled
}: ChatInputProps) {
  const [input, setInput] = useState('');
  const textareaRef = useRef<HTMLTextAreaElement>(null);

  const handleSend = () => {
    if (input.trim() && !disabled) {
      onSend(input.trim());
      setInput('');
    }
  };

  const handleKeyDown = (e: KeyboardEvent<HTMLTextAreaElement>) => {
    if (e.key === 'Enter' && !e.shiftKey) {
      e.preventDefault();
      handleSend();
    }
  };

  return (
    <div className="p-4 border-t bg-white">
      <div className="flex items-end gap-2">
        <textarea
          ref={textareaRef}
          value={input}
          onChange={(e) => setInput(e.target.value)}
          onKeyDown={handleKeyDown}
          placeholder="Describe the page you want to create..."
          rows={1}
          className="
            flex-1 resize-none rounded-lg border border-gray-300
            p-3 focus:outline-none focus:ring-2 focus:ring-blue-500
            disabled:bg-gray-100
          "
          disabled={disabled}
        />

        {isStreaming ? (
          <button
            onClick={onAbort}
            className="
              p-3 rounded-lg bg-red-500 text-white
              hover:bg-red-600 transition-colors
            "
            aria-label="Stop generation"
          >
            <StopCircle className="w-5 h-5" />
          </button>
        ) : (
          <button
            onClick={handleSend}
            disabled={!input.trim() || disabled}
            className="
              p-3 rounded-lg bg-blue-500 text-white
              hover:bg-blue-600 transition-colors
              disabled:bg-gray-300 disabled:cursor-not-allowed
            "
            aria-label="Send message"
          >
            <Send className="w-5 h-5" />
          </button>
        )}
      </div>
    </div>
  );
}
```

### 5. SuggestionChips.tsx

```typescript
// src/components/chat/SuggestionChips.tsx
import { Sparkles } from 'lucide-react';

interface SuggestionChipsProps {
  suggestions: string[];
  onSelect: (suggestion: string) => void;
}

export function SuggestionChips({ suggestions, onSelect }: SuggestionChipsProps) {
  return (
    <div className="px-4 pb-2">
      <div className="flex items-center gap-2 text-sm text-gray-500 mb-2">
        <Sparkles className="w-4 h-4" />
        <span>Suggestions</span>
      </div>
      <div className="flex flex-wrap gap-2">
        {suggestions.map((suggestion) => (
          <button
            key={suggestion}
            onClick={() => onSelect(suggestion)}
            className="
              px-3 py-1.5 rounded-full text-sm
              bg-gray-100 hover:bg-gray-200
              transition-colors
            "
          >
            {suggestion}
          </button>
        ))}
      </div>
    </div>
  );
}
```

### 6. useChat.ts (Hook)

```typescript
// src/hooks/useChat.ts
import { useState, useCallback, useRef } from 'react';
import type { ChatMessage } from '@/types';

export function useChat(projectId: string) {
  const [messages, setMessages] = useState<ChatMessage[]>([]);
  const [isStreaming, setIsStreaming] = useState(false);
  const abortControllerRef = useRef<AbortController | null>(null);

  const sendMessage = useCallback(async (content: string) => {
    // Add user message
    const userMessage: ChatMessage = {
      id: crypto.randomUUID(),
      role: 'user',
      content,
      timestamp: new Date().toISOString(),
    };

    setMessages(prev => [...prev, userMessage]);
    setIsStreaming(true);

    // Create assistant message placeholder
    const assistantMessage: ChatMessage = {
      id: crypto.randomUUID(),
      role: 'assistant',
      content: '',
      timestamp: new Date().toISOString(),
      isStreaming: true,
    };

    setMessages(prev => [...prev, assistantMessage]);

    try {
      abortControllerRef.current = new AbortController();

      const response = await fetch(
        `${import.meta.env.VITE_API_URL}/v1/sites/${projectId}/generation`,
        {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            'Authorization': `Bearer ${getToken()}`,
          },
          body: JSON.stringify({ prompt: content }),
          signal: abortControllerRef.current.signal,
        }
      );

      const reader = response.body?.getReader();
      const decoder = new TextDecoder();

      while (reader) {
        const { done, value } = await reader.read();
        if (done) break;

        const chunk = decoder.decode(value);
        setMessages(prev => {
          const updated = [...prev];
          const last = updated[updated.length - 1];
          last.content += chunk;
          return updated;
        });
      }
    } catch (error) {
      if (error.name !== 'AbortError') {
        console.error('Generation failed:', error);
      }
    } finally {
      setIsStreaming(false);
      setMessages(prev => {
        const updated = [...prev];
        const last = updated[updated.length - 1];
        last.isStreaming = false;
        return updated;
      });
    }
  }, [projectId]);

  const abortGeneration = useCallback(() => {
    abortControllerRef.current?.abort();
    setIsStreaming(false);
  }, []);

  return {
    messages,
    isStreaming,
    sendMessage,
    abortGeneration,
  };
}
```

### 7. Tests (ChatPanel.test.tsx)

```typescript
// tests/components/ChatPanel.test.tsx
import { render, screen, fireEvent, waitFor } from '@testing-library/react';
import { vi, describe, it, expect } from 'vitest';
import { ChatPanel } from '@/components/chat/ChatPanel';

describe('ChatPanel', () => {
  it('renders empty state with suggestions', () => {
    render(
      <ChatPanel
        projectId="test-123"
        onGenerationComplete={vi.fn()}
      />
    );

    expect(screen.getByText(/Hi! I'll help you/i)).toBeInTheDocument();
    expect(screen.getByText('Suggestions')).toBeInTheDocument();
  });

  it('sends message on Enter key', async () => {
    render(
      <ChatPanel
        projectId="test-123"
        onGenerationComplete={vi.fn()}
      />
    );

    const input = screen.getByPlaceholderText(/describe the page/i);
    fireEvent.change(input, { target: { value: 'Create a landing page' } });
    fireEvent.keyDown(input, { key: 'Enter' });

    await waitFor(() => {
      expect(screen.getByText('Create a landing page')).toBeInTheDocument();
    });
  });

  it('shows streaming indicator during generation', async () => {
    // Test streaming state
  });

  it('can abort generation', async () => {
    // Test abort functionality
  });
});
```

---

## Expected Output

```
output/
├── src/
│   ├── components/
│   │   └── chat/
│   │       ├── ChatPanel.tsx
│   │       ├── ChatMessage.tsx
│   │       ├── StreamingMessage.tsx
│   │       ├── ChatInput.tsx
│   │       └── SuggestionChips.tsx
│   └── hooks/
│       └── useChat.ts
├── tests/
│   └── components/
│       └── ChatPanel.test.tsx
└── README.md
```

---

## Success Criteria

- [ ] ChatPanel renders correctly
- [ ] Messages display with correct styling
- [ ] SSE streaming works with abort capability
- [ ] Enter key sends messages
- [ ] Shift+Enter creates new line
- [ ] Suggestions clickable
- [ ] Typing indicator shows during streaming
- [ ] Accessible (keyboard nav, ARIA labels)
- [ ] Tests pass with >80% coverage
- [ ] Responsive design works

---

## Execution Steps

1. Read Frontend LLD Section 4, 11
2. Create ChatPanel component
3. Create ChatMessage component
4. Create StreamingMessage component
5. Create ChatInput component
6. Create SuggestionChips component
7. Implement useChat hook with SSE
8. Write unit tests
9. Test with mock API
10. Update work.state to COMPLETE

---

**Status**: PENDING
**Created**: 2026-01-16
