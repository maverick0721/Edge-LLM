import { useState, useEffect, useRef } from "react"
import ChatMessage from "./ChatMessage"
import ChatInput from "./ChatInput"

export default function ChatLayout(){

  const [messages,setMessages] = useState([])
  const [socket,setSocket] = useState(null)

  const bottomRef = useRef(null)

  useEffect(()=>{

    const ws = new WebSocket("ws://127.0.0.1:8000/chat")

    ws.onopen = () => {
      console.log("WebSocket connected")
    }

    ws.onmessage = (event)=>{

      const token = event.data

      setMessages(prev => {

        if(prev.length === 0 || prev[prev.length-1].role !== "assistant"){

          return [
            ...prev,
            {role:"assistant",content:token}
          ]

        }

        const updated = [...prev]

        updated[updated.length-1].content += token

        return updated

      })

    }

    setSocket(ws)

    return () => ws.close()

  },[])

  useEffect(()=>{
    bottomRef.current?.scrollIntoView({behavior:"smooth"})
  },[messages])

  function send(text){

    if(!text.trim()) return

    socket.send(text)

    setMessages(prev => [
      ...prev,
      {role:"user",content:text}
    ])

  }

  return(

    <div className="flex flex-col flex-1">

        <div className="flex-1 overflow-y-auto">

            {messages.map((m,i)=>(
                <ChatMessage key={i} message={m}/>
            ))}

            <div ref={bottomRef}></div>

        </div>

        <ChatInput send={send}/>

    </div>

  )

}