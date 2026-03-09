import { useState, useEffect } from "react"
import Sidebar from "./components/Sidebar"
import ChatLayout from "./components/ChatLayout"

export default function App(){

  const [chats,setChats] = useState([])
  const [currentChat,setCurrentChat] = useState(null)

  // load chats from browser
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

  // save chats
  useEffect(()=>{
    localStorage.setItem("edge_chats",JSON.stringify(chats))
  },[chats])

  function newChat(){

    const chat = {
      id: Date.now(),
      title: "New Chat",
      messages: []
    }

    // ADD chat instead of replacing
    setChats(prev => [chat,...prev])

    setCurrentChat(chat.id)

  }

  function updateMessages(messages){

    setChats(prev =>
      prev.map(chat => {

        if(chat.id !== currentChat) return chat

        let title = chat.title

        // auto title
        if(messages.length > 0 && chat.title === "New Chat"){
          title = messages[0].content.slice(0,30)
        }

        return {
          ...chat,
          messages,
          title
        }

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
      />

    </div>

  )

}