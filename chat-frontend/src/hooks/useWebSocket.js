import { useEffect, useRef, useCallback } from 'react'
import { Client } from '@stomp/stompjs'
import SockJS from 'sockjs-client'

// onMessageRef — a React ref whose .current holds the message handler.
// Using a ref avoids recreating the STOMP connection on every render.
export function useWebSocket(onMessageRef) {
  const clientRef = useRef(null)

  useEffect(() => {
    const token = localStorage.getItem('token')
    if (!token) return

    const stompClient = new Client({
      webSocketFactory: () => new SockJS(`/ws?token=${token}`),
      connectHeaders: { Authorization: `Bearer ${token}` },
      reconnectDelay: 5000,
      onConnect: () => {
        stompClient.subscribe('/user/queue/messages', (frame) => {
          const msg = JSON.parse(frame.body)
          onMessageRef.current?.(msg)
        })
      },
    })

    stompClient.activate()
    clientRef.current = stompClient

    return () => stompClient.deactivate()
  }, [])

  const send = useCallback((recipientUsername, content) => {
    if (clientRef.current?.connected) {
      clientRef.current.publish({
        destination: '/app/chat',
        body: JSON.stringify({ recipientUsername, content }),
      })
    }
  }, [])

  return send
}
