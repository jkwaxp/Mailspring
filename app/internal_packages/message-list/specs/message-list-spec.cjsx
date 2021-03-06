_ = require "underscore"
moment = require "moment"
proxyquire = require("proxyquire").noPreserveCache()

React = require "react"
ReactDOM = require "react-dom"
ReactTestUtils = require 'react-dom/test-utils'

{Thread,
 Contact,
 Actions,
 Folder,
 Message,
 Account,
 DraftStore,
 MessageStore,
 AccountStore,
 MailspringTestUtils,
 ComponentRegistry} = require "mailspring-exports"

MessageParticipants = require("../lib/message-participants").default
MessageItemContainer = require("../lib/message-item-container").default
MessageList = require('../lib/message-list').default

# User_1 needs to be "me" so that when we calculate who we should reply
# to, it properly matches the AccountStore
user_1 = new Contact
  accountId: TEST_ACCOUNT_ID
  name: TEST_ACCOUNT_NAME
  email: TEST_ACCOUNT_EMAIL
user_2 = new Contact
  accountId: TEST_ACCOUNT_ID
  name: "User Two"
  email: "user2@nylas.com"
user_3 = new Contact
  accountId: TEST_ACCOUNT_ID
  name: "User Three"
  email: "user3@nylas.com"
user_4 = new Contact
  accountId: TEST_ACCOUNT_ID
  name: "User Four"
  email: "user4@nylas.com"
user_5 = new Contact
  accountId: TEST_ACCOUNT_ID
  name: "User Five"
  email: "user5@nylas.com"

m1 = new Message({
  "id"   : "111",
  "from" : [ user_1 ],
  "to"   : [ user_2 ],
  "cc"   : [ user_3, user_4 ],
  "bcc"  : null,
  "body"      : "Body One",
  "date"      : new Date(1415814587),
  "draft"     : false
  "files"     : [],
  "unread"    : false,
  "snippet"   : "snippet one...",
  "subject"   : "Subject One",
  "threadId" : "thread_12345",
  "accountId" : TEST_ACCOUNT_ID,
  folder: new Folder({role: 'all', name: 'All Mail'}),
})
m2 = new Message({
  "id"   : "222",
  "from" : [ user_2 ],
  "to"   : [ user_1 ],
  "cc"   : [ user_3, user_4 ],
  "bcc"  : null,
  "body"      : "Body Two",
  "date"      : new Date(1415814587),
  "draft"     : false
  "files"     : [],
  "unread"    : false,
  "snippet"   : "snippet Two...",
  "subject"   : "Subject Two",
  "threadId" : "thread_12345",
  "accountId" : TEST_ACCOUNT_ID,
  folder: new Folder({role: 'all', name: 'All Mail'}),
})
m3 = new Message({
  "id"   : "333",
  "from" : [ user_3 ],
  "to"   : [ user_1 ],
  "cc"   : [ user_2, user_4 ],
  "bcc"  : [],
  "body"      : "Body Three",
  "date"      : new Date(1415814587),
  "draft"     : false
  "files"     : [],
  "unread"    : false,
  "snippet"   : "snippet Three...",
  "subject"   : "Subject Three",
  "threadId" : "thread_12345",
  "accountId" : TEST_ACCOUNT_ID,
  folder: new Folder({role: 'all', name: 'All Mail'}),
})
m4 = new Message({
  "id"   : "444",
  "from" : [ user_4 ],
  "to"   : [ user_1 ],
  "cc"   : [],
  "bcc"  : [ user_5 ],
  "body"      : "Body Four",
  "date"      : new Date(1415814587),
  "draft"     : false
  "files"     : [],
  "unread"    : false,
  "snippet"   : "snippet Four...",
  "subject"   : "Subject Four",
  "threadId" : "thread_12345",
  "accountId" : TEST_ACCOUNT_ID,
  folder: new Folder({role: 'all', name: 'All Mail'}),
})
m5 = new Message({
  "id"   : "555",
  "from" : [ user_1 ],
  "to"   : [ user_4 ],
  "cc"   : [],
  "bcc"  : [],
  "body"      : "Body Five",
  "date"      : new Date(1415814587),
  "draft"     : false
  "files"     : [],
  "unread"    : false,
  "snippet"   : "snippet Five...",
  "subject"   : "Subject Five",
  "threadId" : "thread_12345",
  "accountId" : TEST_ACCOUNT_ID,
  folder: new Folder({role: 'all', name: 'All Mail'}),
})
testMessages = [m1, m2, m3, m4, m5]
draftMessages = [
  new Message({
    "id"   : "666",
    "headerMessageId": "asdasd-asd@mbbp.local",
    "from" : [ user_1 ],
    "to"   : [ ],
    "cc"   : [ ],
    "bcc"  : null,
    "body"      : "Body One",
    "date"      : new Date(1415814587),
    "draft"     : true
    "files"     : [],
    "unread"    : false,
    "snippet"   : "draft snippet one...",
    "subject"   : "Draft One",
    "threadId" : "thread_12345",
    "accountId" : TEST_ACCOUNT_ID,
    folder: new Folder({role: 'all', name: 'All Mail'}),
  }),
]

testThread = new Thread({
  "id": "12345"
  "id" : "thread_12345"
  "subject" : "Subject 12345",
  "accountId" : TEST_ACCOUNT_ID
})

describe "MessageList", ->
  beforeEach ->
    MessageStore._items = []
    MessageStore._threadId = null
    spyOn(MessageStore, "itemsLoading").andCallFake ->
      false

    @messageList = ReactTestUtils.renderIntoDocument(<MessageList />)
    @messageList_node = ReactDOM.findDOMNode(@messageList)

  it "renders into the document", ->
    expect(ReactTestUtils.isCompositeComponentWithType(@messageList,
           MessageList)).toBe true

  it "by default has zero children", ->
    items = ReactTestUtils.scryRenderedComponentsWithType(@messageList,
            MessageItemContainer)

    expect(items.length).toBe 0

  describe "Populated Message list", ->
    beforeEach ->
      MessageStore._items = testMessages
      MessageStore._expandItemsToDefault()
      MessageStore.trigger(MessageStore)
      @messageList.setState(currentThread: testThread)
      MailspringTestUtils.loadKeymap("keymaps/base")

    it "renders all the correct number of messages", ->
      items = ReactTestUtils.scryRenderedComponentsWithType(@messageList,
              MessageItemContainer)
      expect(items.length).toBe 5

    it "renders the correct number of expanded messages", ->
      msgs = ReactTestUtils.scryRenderedDOMComponentsWithClass(@messageList, "collapsed message-item-wrap")
      expect(msgs.length).toBe 4

    it "displays lists of participants on the page", ->
      items = ReactTestUtils.scryRenderedComponentsWithType(@messageList,
              MessageParticipants)
      expect(items.length).toBe 2

    it "includes drafts as message item containers", ->
      msgs = @messageList.state.messages
      @messageList.setState
        messages: msgs.concat(draftMessages)
      items = ReactTestUtils.scryRenderedComponentsWithType(@messageList,
              MessageItemContainer)
      expect(items.length).toBe 6

  describe "reply type", ->
    it "prompts for a reply when there's only one participant", ->
      MessageStore._items = [m3, m5]
      MessageStore._thread = testThread
      MessageStore.trigger()
      expect(@messageList._replyType()).toBe "reply"
      cs = ReactTestUtils.scryRenderedDOMComponentsWithClass(@messageList, "footer-reply-area")
      expect(cs.length).toBe 1

    it "prompts for a reply-all when there's more than one participant and the default is reply-all", ->
      spyOn(AppEnv.config, "get").andReturn "reply-all"
      MessageStore._items = [m5, m3]
      MessageStore._thread = testThread
      MessageStore.trigger()
      expect(@messageList._replyType()).toBe "reply-all"
      cs = ReactTestUtils.scryRenderedDOMComponentsWithClass(@messageList, "footer-reply-area")
      expect(cs.length).toBe 1

    it "prompts for a reply-all when there's more than one participant and the default is reply", ->
      spyOn(AppEnv.config, "get").andReturn "reply"
      MessageStore._items = [m5, m3]
      MessageStore._thread = testThread
      MessageStore.trigger()
      expect(@messageList._replyType()).toBe "reply"
      cs = ReactTestUtils.scryRenderedDOMComponentsWithClass(@messageList, "footer-reply-area")
      expect(cs.length).toBe 1

    it "hides the reply type if the last message is a draft", ->
      MessageStore._items = [m5, m3, draftMessages[0]]
      MessageStore._thread = testThread
      MessageStore.trigger()
      cs = ReactTestUtils.scryRenderedDOMComponentsWithClass(@messageList, "footer-reply-area")
      expect(cs.length).toBe 0

  describe "Message minification", ->
    beforeEach ->
      @messageList.MINIFY_THRESHOLD = 3
      @messageList.setState minified: true
      @messages = [
        {id: 'a'}, {id: 'b'}, {id: 'c'}, {id: 'd'}, {id: 'e'}, {id: 'f'}, {id: 'g'}
      ]

    it "ignores the first message if it's collapsed", ->
      @messageList.setState messagesExpandedState:
        a: false, b: false, c: false, d: false, e: false, f: false, g: "default"

      out = @messageList._messagesWithMinification(@messages)
      expect(out).toEqual [
        {id: 'a'},
        {
          type: "minifiedBundle"
          messages: [{id: 'b'}, {id: 'c'}, {id: 'd'}, {id: 'e'}]
        },
        {id: 'f'},
        {id: 'g'}
      ]

    it "ignores the first message if it's expanded", ->
      @messageList.setState messagesExpandedState:
        a: "default", b: false, c: false, d: false, e: false, f: false, g: "default"

      out = @messageList._messagesWithMinification(@messages)
      expect(out).toEqual [
        {id: 'a'},
        {
          type: "minifiedBundle"
          messages: [{id: 'b'}, {id: 'c'}, {id: 'd'}, {id: 'e'}]
        },
        {id: 'f'},
        {id: 'g'}
      ]

    it "doesn't minify the last collapsed message", ->
      @messageList.setState messagesExpandedState:
        a: false, b: false, c: false, d: false, e: false, f: "default", g: "default"

      out = @messageList._messagesWithMinification(@messages)
      expect(out).toEqual [
        {id: 'a'},
        {
          type: "minifiedBundle"
          messages: [{id: 'b'}, {id: 'c'}, {id: 'd'}]
        },
        {id: 'e'},
        {id: 'f'},
        {id: 'g'}
      ]

    it "allows explicitly expanded messages", ->
      @messageList.setState messagesExpandedState:
        a: false, b: false, c: false, d: false, e: false, f: "explicit", g: "default"

      out = @messageList._messagesWithMinification(@messages)
      expect(out).toEqual [
        {id: 'a'},
        {
          type: "minifiedBundle"
          messages: [{id: 'b'}, {id: 'c'}, {id: 'd'}, {id: 'e'}]
        },
        {id: 'f'},
        {id: 'g'}
      ]

    it "doesn't minify if the threshold isn't reached", ->
      @messageList.setState messagesExpandedState:
        a: false, b: "default", c: false, d: "default", e: false, f: "default", g: "default"

      out = @messageList._messagesWithMinification(@messages)
      expect(out).toEqual [
        {id: 'a'},
        {id: 'b'},
        {id: 'c'},
        {id: 'd'},
        {id: 'e'},
        {id: 'f'},
        {id: 'g'}
      ]

    it "doesn't minify if the threshold isn't reached due to the rule about not minifying the last collapsed messages", ->
      @messageList.setState messagesExpandedState:
        a: false, b: false, c: false, d: false, e: "default", f: "default", g: "default"

      out = @messageList._messagesWithMinification(@messages)
      expect(out).toEqual [
        {id: 'a'},
        {id: 'b'},
        {id: 'c'},
        {id: 'd'},
        {id: 'e'},
        {id: 'f'},
        {id: 'g'}
      ]

    it "minifies at the threshold if the message is explicitly expanded", ->
      @messageList.setState messagesExpandedState:
        a: false, b: false, c: false, d: false, e: "explicit", f: "default", g: "default"

      out = @messageList._messagesWithMinification(@messages)
      expect(out).toEqual [
        {id: 'a'},
        {
          type: "minifiedBundle"
          messages: [{id: 'b'}, {id: 'c'}, {id: 'd'}]
        },
        {id: 'e'},
        {id: 'f'},
        {id: 'g'}
      ]

    it "can have multiple minification blocks", ->
      messages = [
        {id: 'a'}, {id: 'b'}, {id: 'c'}, {id: 'd'}, {id: 'e'}, {id: 'f'},
        {id: 'g'}, {id: 'h'}, {id: 'i'}, {id: 'j'}, {id: 'k'}, {id: 'l'}
      ]

      @messageList.setState messagesExpandedState:
        a: false, b: false, c: false, d: false, e: false, f: "default",
        g: false, h: false, i: false, j: false, k: false, l: "default"

      out = @messageList._messagesWithMinification(messages)
      expect(out).toEqual [
        {id: 'a'},
        {
          type: "minifiedBundle"
          messages: [{id: 'b'}, {id: 'c'}, {id: 'd'}]
        },
        {id: 'e'},
        {id: 'f'},
        {
          type: "minifiedBundle"
          messages: [{id: 'g'}, {id: 'h'}, {id: 'i'}, {id: 'j'}]
        },
        {id: 'k'},
        {id: 'l'}
      ]

    it "can have multiple minification blocks next to explicitly expanded messages", ->
      messages = [
        {id: 'a'}, {id: 'b'}, {id: 'c'}, {id: 'd'}, {id: 'e'}, {id: 'f'},
        {id: 'g'}, {id: 'h'}, {id: 'i'}, {id: 'j'}, {id: 'k'}, {id: 'l'}
      ]

      @messageList.setState messagesExpandedState:
        a: false, b: false, c: false, d: false, e: "explicit", f: "default",
        g: false, h: false, i: false, j: false, k: "explicit", l: "default"

      out = @messageList._messagesWithMinification(messages)
      expect(out).toEqual [
        {id: 'a'},
        {
          type: "minifiedBundle"
          messages: [{id: 'b'}, {id: 'c'}, {id: 'd'}]
        },
        {id: 'e'},
        {id: 'f'},
        {
          type: "minifiedBundle"
          messages: [{id: 'g'}, {id: 'h'}, {id: 'i'}, {id: 'j'}]
        },
        {id: 'k'},
        {id: 'l'}
      ]
