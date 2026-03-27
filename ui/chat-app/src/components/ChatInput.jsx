import { useState } from "react"

export default function ChatInput({ send }){

  const [text,setText] = useState("")

  function submit(){

    if(!text.trim()) return

    send(text)

    setText("")
  }

  return(


    <div className="border-t border-gray-700 p-4">
        <div className="max-w-3xl mx-auto flex">
            <input
              className="flex-1 bg-[#40414f] p-3 rounded-l-lg outline-none"
              placeholder="Send a message..."
              value={text}
              onChange={(e)=>setText(e.target.value)}
              onKeyDown={(e)=>{
                if(e.key==="Enter"){
                  submit()
                }
              }}
            />
            <button
              onClick={submit}
              className="bg-green-600 px-4 rounded-r-lg"
            >
              Send
            </button>
        </div>
    </div>

  )
}