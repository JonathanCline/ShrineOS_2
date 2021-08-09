---
--- This file is for documentation purposes and may be removed as needed
---
error("cannot open documentation file")

---
--- ShrineOS thread object documentation
---
--- @class shrine.thread.obj.doc

--- @type shrine.thread.obj.doc
local thread_obj_doc = {}

---
--- Thread ID
---
--- @type shrine.uuid
thread_obj_doc.id = require("uuid").next()

---
--- Thread Coroutine ID
---
--- @type thread
thread_obj_doc.coid = coroutine.create()

---
--- Child thread list
---
--- @type table
thread_obj_doc.children = {}

---
--- Thread local variables
---
--- @type table
thread_obj_doc.locals = {}

---
--- When the thread is allowed to be resumed up again, nil means thread can be resumed whenever
---
--- @type seconds|nil
thread_obj_doc.wake_after = 0

---
--- Tells if the thread is allowed to be forcefully woken or not
---
--- @type boolean
thread_obj_doc.sleeping = false

---
--- Thread signal queue for sending messages between threads
---
--- @type table
thread_obj_doc.signals = {}



---
--- ShrineOS thread type documentation
---
--- @class shrine.thread.doc

--- @type shrine.thread.doc
local thread_doc = {}

---
--- Thread ID
---
thread_doc.id = require("uuid").next()

---
--- Thread local variable table
---
--- @type table
thread_doc.locals = {}
