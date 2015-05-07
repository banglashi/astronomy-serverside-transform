# Collections
@Chats = new Mongo.Collection 'chats'

@Chat = Astronomy.Class
    name: 'Chat'
    collection: Chats
    transform: true
    fields: 
        title:
            type: 'string'
        lastMessage:
            type: 'object'
        members:
            type: 'array'
            default: []

@Messages = new Mongo.Collection 'messages'

@Message = Astronomy.Class
    name: 'Message'
    collection: Messages
    transform: true
    fields: 
        chatId:
            type: 'string'
        message:
            type: 'string'
    behaviors: ['timestamp']

# FlowRouter routes
FlowRouter.route '/',
    subscriptions: (params, queryParams) ->
        @register('chats', Meteor.subscribe('chats'))
    action: (params) ->
        FlowLayout.render('MasterLayout', { main:'Test'})

# Client helper
if Meteor.isClient
    Template.Test.helpers
        chats: () ->
            Chats.find()

# Server
if Meteor.isServer

    # transform doc server side breaks astronomy
    Meteor.publish "chats", () ->
        self = this
        transform = (doc) ->
            obj = doc.get()
            lastMessage = Messages.findOne({chatId: obj._id}, {sort: {createdAt: -1}, transform: null})
            obj.lastMessage = lastMessage
            obj
        observer = Chats.find().observe(
            added: (document) ->
                self.added 'chats', document._id, transform(document)
                return
            changed: (newDocument, oldDocument) ->
                self.changed 'chats', oldDocument._id, transform(newDocument)
                return
            removed: (oldDocument) ->
                self.removed 'chats', oldDocument._id
                return
        )
        self.onStop ->
            observer.stop()
            return
        self.ready()
        return
    
    # Working publication
    # Meteor.publish 'chats', () ->
    #     Chats.find({})

    # startup data
    Meteor.startup () ->
        if Chats.find().count() == 0
            chat1Id = Chats.insert
                title: "first chat"
            chat2Id = Chats.insert
                title: "second chat"
            
            Messages.insert
                chatId: chat1Id
                message: "message in chat 1"
            Messages.insert
                chatId: chat2Id
                message: "message in chat 2"