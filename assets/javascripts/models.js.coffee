App.User = DS.Model.extend
  name: DS.attr("string")
  email:  DS.attr("string")
  role:   DS.attr("string")
  password: DS.attr("string")
  color: DS.attr("string")
  authToken: DS.attr("string")

  isAdmin: (->
    @get("role") == "admin"
  ).property("role")


  borderStyle: (->
    "border-left: 0.2em solid #{@get("color")};"
  ).property("color")

  fontColor: (->
    "color: #{@get("color")};"
  ).property("color")


DS.ArrayTransform = DS.Transform.extend
  deserialize: (serialized)-> []
  serialize: (deserialized)-> []

App.register("transform:array", DS.ArrayTransform)

App.Room = DS.Model.extend
  name: DS.attr("string")
  roomUserState: DS.belongsTo("room_user_state")
  messages: DS.attr("array")
  users: DS.attr("array")
  isHistoryAvailable: DS.attr("boolean")


App.RoomUserState = DS.Model.extend Em.Evented,
  user: DS.belongsTo("user")
  joined:  DS.attr("boolean")
  room:  DS.belongsTo("room")
  lastPingedAt: DS.attr("date")
  beforeMessageId: DS.attr("number")
  afterMessageId: DS.attr("number")

  addMessages: (data)->
    messages = data.messages
    before = data.before

    if before
      addAction = "unshiftObject"
    else
      addAction = "pushObject"

    for messageAttrs in messages
      if @store.recordIsLoaded("message", messageAttrs.id)
        message = @store.getById("message", messageAttrs.id)
        if !@get("room.messages").contains(message)
          @get("room.messages")[addAction](message)
        return

      message = @store.push("message", {
        id: messageAttrs.id,
        type: messageAttrs.type,
        body: messageAttrs.body,
        createdAt: messageAttrs.created_at
      })
      message.set("room", @get("room"))

      if @store.recordIsLoaded("user", messageAttrs.user.id)
        user = @store.getById("user", messageAttrs.user.id)
      else
        userParams =
          id: messageAttrs.user.id
          name: messageAttrs.user.name
          role: messageAttrs.user.role
          color: App.paintBox.getColor()
        user = @store.push("user", userParams)

      message.set("user", user)
      @get("room.messages")[addAction](message)

      console.log @get("user.name"), message.get("body").match(@get("user.name"))

      if message.get("body").match(@get("user.name")) && addAction == "pushObject" && @get("afterMessageId")
        console.log "play audio"
        $audio = $("audio")[0]
        $audio.load()
        $audio.play()

      if @get("room.messages.length") == (MogoChat.config.messagesPerLoad + 1) && addAction == "pushObject"
        @get("room.messages").shiftObject()

    if messages.length > 0 && !before
      @set("afterMessageId", messages[messages.length - 1].id)


App.Message = DS.Model.extend
  body: DS.attr("string")
  type: DS.attr("string")
  createdAt: DS.attr("string")
  errorPosting: DS.attr("boolean", defaultValue: false)
  user: DS.belongsTo("user")
  room: DS.belongsTo("room")

  condensedBody: (->
    splitMsg = @get("body").split("\n")
    if splitMsg.length > 5
      newMsg = splitMsg.slice(0, 4)
      newMsg.push("...")
      newMsg.join("\n")
    else
      splitMsg.join("\n")
  ).property("body")

  link: (->
    "/rooms/#{@get("room.id")}/messages/#{@get("id")}"
  ).property(["id", "roomId"])
