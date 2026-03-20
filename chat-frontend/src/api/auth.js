import client from './client'

export const login = (username, password) =>
  client.post('/auth/login', { username, password }).then((r) => r.data)

export const signup = (username, email, password) =>
  client.post('/auth/signup', { username, email, password }).then((r) => r.data)
