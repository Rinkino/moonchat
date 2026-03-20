import { useState, useEffect, useRef, useCallback } from 'react'
import { useNavigate } from 'react-router-dom'
import { getUsers, getHistory, sendMessage } from '../api/chat'
import { useWebSocket } from '../hooks/useWebSocket'

function formatTime(sentAt) {
  if (!sentAt) return ''
  const d = new Date(sentAt)
  return d.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })
}

function avatarLetter(name) {
  return name ? name[0].toUpperCase() : '?'
}

export default function Chat() {
  const [users, setUsers] = useState([])
  const [activeUser, setActiveUser] = useState(null)
  const [conversations, setConversations] = useState({})
  const [input, setInput] = useState('')
  const [sending, setSending] = useState(false)
  const messagesEndRef = useRef(null)
  const navigate = useNavigate()
  const currentUser = localStorage.getItem('username')

  // Ref-wrapped handler so the WS callback always has fresh state
  const onMessageRef = useRef(null)
  onMessageRef.current = useCallback((msg) => {
    const otherUser = msg.sender
    setConversations((prev) => ({
      ...prev,
      [otherUser]: [...(prev[otherUser] || []), msg],
    }))
  }, [])

  useWebSocket(onMessageRef)

  useEffect(() => {
    getUsers().then(setUsers).catch(() => {})
  }, [])

  useEffect(() => {
    messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' })
  }, [conversations, activeUser])

  const selectUser = async (username) => {
    setActiveUser(username)
    if (!conversations[username]) {
      try {
        const history = await getHistory(username)
        setConversations((prev) => ({ ...prev, [username]: history }))
      } catch {
        setConversations((prev) => ({ ...prev, [username]: [] }))
      }
    }
  }

  const handleSend = async () => {
    const content = input.trim()
    if (!content || !activeUser || sending) return

    setInput('')
    setSending(true)

    // Optimistic add — server only pushes WS to the recipient, not the sender
    const optimistic = {
      id: `tmp-${Date.now()}`,
      message: content,
      sender: currentUser,
      receiver: activeUser,
      sentAt: new Date().toISOString(),
    }
    setConversations((prev) => ({
      ...prev,
      [activeUser]: [...(prev[activeUser] || []), optimistic],
    }))

    try {
      await sendMessage(activeUser, content)
    } catch {
      // Remove the optimistic message on failure
      setConversations((prev) => ({
        ...prev,
        [activeUser]: (prev[activeUser] || []).filter((m) => m.id !== optimistic.id),
      }))
    } finally {
      setSending(false)
    }
  }

  const handleKeyDown = (e) => {
    if (e.key === 'Enter' && !e.shiftKey) {
      e.preventDefault()
      handleSend()
    }
  }

  const logout = () => {
    localStorage.clear()
    navigate('/login')
  }

  const messages = activeUser ? conversations[activeUser] || [] : []

  return (
    <div className="chat-layout">
      {/* Header */}
      <header className="chat-header">
        <span className="logo">MoonChat</span>
        <div className="header-right">
          <span className="current-user">{currentUser}</span>
          <button className="btn-logout" onClick={logout}>Sign out</button>
        </div>
      </header>

      {/* Sidebar */}
      <aside className="chat-sidebar">
        <p className="sidebar-heading">Contacts</p>
        <ul className="user-list">
          {users.map((u) => (
            <li
              key={u}
              className={`user-item ${activeUser === u ? 'active' : ''}`}
              onClick={() => selectUser(u)}
            >
              <div className="avatar">{avatarLetter(u)}</div>
              <span className="username">{u}</span>
            </li>
          ))}
        </ul>
      </aside>

      {/* Main area */}
      <main className="chat-main">
        {!activeUser ? (
          <div className="chat-empty">
            <div className="icon">💬</div>
            <p>Select a contact to start chatting</p>
          </div>
        ) : (
          <>
            <div className="chat-thread-header">
              <div className="avatar">{avatarLetter(activeUser)}</div>
              <span className="thread-name">{activeUser}</span>
            </div>

            <div className="message-list">
              {messages.map((msg) => {
                const isSent = msg.sender === currentUser
                return (
                  <div key={msg.id} className={`message-row ${isSent ? 'sent' : 'received'}`}>
                    <div className="bubble">
                      {msg.message}
                      <div className="time">{formatTime(msg.sentAt)}</div>
                    </div>
                  </div>
                )
              })}
              <div ref={messagesEndRef} />
            </div>

            <div className="message-input-area">
              <input
                type="text"
                placeholder={`Message ${activeUser}...`}
                value={input}
                onChange={(e) => setInput(e.target.value)}
                onKeyDown={handleKeyDown}
                autoFocus
              />
              <button
                className="btn-send"
                onClick={handleSend}
                disabled={!input.trim() || sending}
                aria-label="Send"
              >
                <svg viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
                  <path d="M2 21l21-9L2 3v7l15 2-15 2z" />
                </svg>
              </button>
            </div>
          </>
        )}
      </main>
    </div>
  )
}
