import { application } from "./application"
import HelloController from "./hello_controller"
import TiptapController from "./tiptap_controller"

application.register("hello", HelloController)
application.register("tiptap", TiptapController)
