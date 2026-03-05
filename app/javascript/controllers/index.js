import { application } from "./application"
import HelloController from "./hello_controller"
import ProsemirrorController from "./prosemirror_controller"

application.register("hello", HelloController)
application.register("prosemirror", ProsemirrorController)
