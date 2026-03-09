import {Prism as SyntaxHighlighter}
from "react-syntax-highlighter"

import {vscDarkPlus}
from "react-syntax-highlighter/dist/esm/styles/prism"

import {Copy} from "lucide-react"

export default function CodeBlock({language,children}){

  function copy(){

    navigator.clipboard.writeText(children)

  }

  return(

    <div className="relative">

        <button
          onClick={copy}
          className="absolute top-2 right-2 text-gray-300 hover:text-white"
        >
          <Copy size={16}/>
        </button>

        <SyntaxHighlighter
          language={language}
          style={vscDarkPlus}
        >

          {children}

        </SyntaxHighlighter>

    </div>

  )
}