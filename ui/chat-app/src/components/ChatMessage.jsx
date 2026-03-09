import ReactMarkdown from "react-markdown"
import remarkGfm from "remark-gfm"
import CodeBlock from "./CodeBlock"

export default function ChatMessage({message}){

  const isUser = message.role==="user"

  return(

    <div className={isUser ? "" : "bg-[#444654]"}>

        <div className="max-w-3xl mx-auto px-6 py-6 flex gap-4">

            <div className="w-8 h-8 rounded bg-gray-600 flex items-center justify-center text-xs">

                {isUser ? "U" : "AI"}

            </div>

            <div className="flex-1 text-[15px] leading-7">

                <ReactMarkdown
                  remarkPlugins={[remarkGfm]}
                  components={{

                    code({inline,className,children}){

                      const match=/language-(\w+)/.exec(className||"")

                      if(!inline && match){

                        return(
                          <CodeBlock
                            language={match[1]}
                            children={String(children)}
                          />
                        )

                      }

                      return <code>{children}</code>

                    }

                  }}
                >

                  {message.content}

                </ReactMarkdown>

            </div>

        </div>

    </div>

  )
}