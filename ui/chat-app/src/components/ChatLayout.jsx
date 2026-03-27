import { useState, useEffect, useRef } from "react"
import ChatMessage from "./ChatMessage"
import ChatInput from "./ChatInput"

function getWebSocketUrl(){
  if(import.meta.env.VITE_WS_URL){
    return import.meta.env.VITE_WS_URL
  }

  const protocol = window.location.protocol === "https:" ? "wss:" : "ws:"
  return protocol + "//" + window.location.hostname + ":8000/chat"
}

export default function ChatLayout({ chat, updateMessages, newChat }){

  const [socket,setSocket] = useState(null)
  const [connectionError,setConnectionError] = useState("")

  const bottomRef = useRef(null)
  const chatRef = useRef(chat)
  const pendingChatIdRef = useRef(null)
  const messages = chat?.messages ?? []

  useEffect(()=>{
    chatRef.current = chat
  },[chat])

  useEffect(()=>{

    const ws = new WebSocket(getWebSocketUrl())

    ws.onopen = () => {
      setConnectionError("")
    }

    ws.onmessage = (event)=>{

      const token = event.data

      if(token.startsWith("[error] ")){
        setConnectionError(token.replace("[error] ", ""))
        pendingChatIdRef.current = null
        return
      }

      const activeChat = chatRef.current
      const targetChatId = pendingChatIdRef.current ?? activeChat?.id

      if(targetChatId === null || targetChatId === undefined){
        return
      }

      const baseMessages = activeChat?.id === targetChatId
        ? (activeChat.messages ?? [])
        : []
      const nextMessages = [...baseMessages]
      const lastMessage = nextMessages[nextMessages.length - 1]
      const appendToAssistant = lastMessage?.role === "assistant"

      if(nextMessages.length === 0 || appendToAssistant === false){
        nextMessages.push({role:"assistant",content:token})
      } else {
        nextMessages[nextMessages.length-1] = {
          ...nextMessages[nextMessages.length-1],
          content: nextMessages[nextMessages.length-1].content + token,
        }
      }

      updateMessages(nextMessages, targetChatId)
    }

    ws.onerror = () => {
      setConnectionError("Unable to connect to the backend WebSocket server.")
      pendingChatIdRef.current = null
    }

    ws.onclose = () => {
      pendingChatIdRef.current = null
    }

    setSocket(ws)

    return () => ws.close()

  },[])

  useEffect(()=>{
    bottomRef.current?.scrollIntoView({behavior:"smooth"})
  },[messages])

  function send(text){

    const socketOpen = socket === null ? false : socket.readyState === WebSocket.OPEN

    if(socketOpen === false) return

    const activeChat = chat ?? newChat()
    const targetChatId = activeChat.id
    const existingMessages = activeChat.messages ?? []
    const nextMessages = [
      ...existingMessages,
      {role:"user",content:text}
    ]

    pendingChatIdRef.current = targetChatId
    updateMessages(nextMessages, targetChatId)
    setConnectionError("")

    socket.send(JSON.stringify({
      message: text
    }))

  }

  return(

    <div className="flex flex-col flex-1">

        <div className="flex-1 overflow-y-auto">

            {connectionError ? (
              <div className="m-4 rounded-lg border border-red-500/40 bg-red-500/10 p-3 text-sm text-red-100">
                {connectionError}
              </div>
            ) : null}

            {chat === null || chat === undefined ? (
              <div className="m-4 rounded-lg border border-gray-700 bg-[#2a2b32] p-4 text-sm text-gray-300">
                Start a new chat to begin.
              </div>
            ) : null}

            {messages.map((m,i)=>(
                <ChatMessage key={i} message={m}/>
            ))}

            <div ref={bottomRef}></div>

        </div>

        <ChatInput send={send}/>

    </div>

  )

}
