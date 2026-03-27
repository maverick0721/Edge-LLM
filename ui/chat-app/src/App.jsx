import { useState, useEffect } from "react"
import Sidebar from "./components/Sidebar"
import ChatLayout from "./components/ChatLayout"

export default function App(){

  const [chats,setChats] = useState([])
  const [currentChat,setCurrentChat] = useState(null)

  useEffect(()=>{

    const saved = localStorage.getItem("edge_chats")

    if(saved){
      const parsed = JSON.parse(saved)
      setChats(parsed)

      if(parsed.length > 0){
        setCurrentChat(parsed[0].id)
      }
    }

  },[])

  useEffect(()=>{
    localStorage.setItem("edge_chats",JSON.stringify(chats))
  },[chats])

  useEffect(()=>{
    if(chats.length === 0){
      setCurrentChat(null)
      return
    }

    const exists = chats.some(chat => chat.id === currentChat)

    if(exists === false){
      setCurrentChat(chats[0].id)
    }
  },[chats,currentChat])

  function newChat(){

    const chat = {
      id: Date.now(),
      title: "New Chat",
      messages: []
    }

    setChats(prev => [chat,...prev])
    setCurrentChat(chat.id)

    return chat
  }

  function updateMessages(messages, targetChatId = currentChat){
    if(targetChatId === null){
      return
    }

    setChats(prev =>
      prev.map(chat => {

        if(chat.id === targetChatId){
          let title = chat.title

          if(messages.length > 0 && chat.title === "New Chat"){
            title = messages[0].content.slice(0,30)
          }

          return {
            ...chat,
            messages,
            title
          }
        }

        return chat
      })
    )

  }

  const current = chats.find(chat => chat.id === currentChat)

  return(

    <div className="flex h-screen text-white">

      <Sidebar
        chats={chats}
        currentChat={currentChat}
        setCurrentChat={setCurrentChat}
        newChat={newChat}
        setChats={setChats}
      />

      <ChatLayout
        chat={current}
        updateMessages={updateMessages}
        newChat={newChat}
      />

    </div>

  )

}
