#lang pyret

import "src/lang/pyret-lib/experimental/check.arr" as Check

var todo1: {
  due: "25 January 2012",
  task: "Write mixin examples",
  done: false,
  complete(self): self.{ done: true }
}

fun sealable(obj):
  obj.{
    seal(self, names-to-expose):
      names-to-expose.foldr(\name, self-sealed: (
        self-sealed.{ [name]: self.[name] }
      ), {})
    end
  }
end

var todo2: sealable(todo1)
var todo3: todo2.seal(["done", "complete"])
Check.equal(todo3.done, false, "done is present after seal")
Check.equal(todo3.complete().done, true, "complete is present after seal")
todo3.task # should error
