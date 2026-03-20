import client from './client'

export const getUsers = () =>
  client.get('/chat/users').then((r) => r.data)

export const getHistory = (otherUsername) =>
  client.get(`/chat/history/${otherUsername}`).then((r) => r.data)

export const sendMessage = (recipientUsername, content) =>
  client.post('/chat/send', { recipientUsername, content })
