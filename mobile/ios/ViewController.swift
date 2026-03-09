import UIKit

class ViewController: UIViewController {

    func sendPrompt(text:String){

        let url = URL(string:"http://localhost:8000/generate")!

        var req = URLRequest(url:url)

        req.httpMethod = "POST"

        req.httpBody = "{\"text\":\"\(text)\"}".data(using:.utf8)

        URLSession.shared.dataTask(with:req){data,res,error in

            if let d = data{
                let result = String(data:d,encoding:.utf8)
                print(result!)
            }

        }.resume()
    }
}