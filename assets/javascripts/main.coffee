@App = Ember.Application.create()

Config.iframes = [
  "//www.facebook.com/plugins/like.php?href=http%3A%2F%2F#{escape(Config.host)}&amp;width=107&amp;height=20&amp;colorscheme=light&amp;layout=button_count&amp;action=like&amp;show_faces=true&amp;send=false",
  "http://platform.twitter.com/widgets/tweet_button.1378258117.html#_=1378492153846&amp;count=horizontal&amp;id=twitter-widget-0&amp;lang=en&amp;size=m&amp;text=#{escape(Config.caption)}&amp;url=http%3A%2F%2F#{escape(Config.host)}%2F",
  "http://ghbtns.com/github-btn.html?user=krasnoukhov&repo=langgame&type=watch&count=true"
]

App.Router.map ->
  this.route("game")
  this.route("stats")

App.IndexRoute = Ember.Route.extend()
App.GameRoute = Ember.Route.extend(
  setupController: (controller) ->
    controller.load()
    
  renderTemplate: ->
    this.render("game")
)
App.StatsRoute = Ember.Route.extend(
  model: ->
    Ember.$.getJSON "/stats"
  
  renderTemplate: ->
    this.render("stats")
)

App.ApplicationController = Ember.Controller.extend(
  routeChanged: (->
    return unless ga
    
    self = this
    Em.run.next ->
      ga("send", "pageview", "/#{self.get("currentPath")}")
    
  ).observes("currentPath")
)

App.IndexController = Ember.ObjectController.extend($.extend(
  isLoading: false
  
  actions:
    play: ->
      self = this
      
      # Create game
      self.set("isLoading", true)
      $.post("/game").always(->
        self.set("isLoading", false)
      ).done((data) ->
        controller = self.controllerFor("game")
        controller.set("response", data)
        self.transitionToRoute("game")
      )
      
, Config))

App.GameController = Ember.ObjectController.extend($.extend(
  isLoading: false
  response: null
  waitResponse: null
  
  hasSurvived: (->
    return false unless this.get("response")
    this.get("response").status == "survived"
  ).property("response")
  
  highlightedSnippet: (->
    return "" unless this.get("response")
    snippet = this.get("response").variant.snippet
    hljs.highlightAuto(snippet).value
  ).property("response")
  
  load: ->
    self = this
    
    # Load game
    self.set("isLoading", true)
    $.get("/game").always(->
      self.set("isLoading", false)
    ).done((data) ->
      if data.error
        self.transitionToRoute("index")
      else
        self.set("response", data)
    )
  
  result: (data) ->
    ga("send", "pageview", "/game")
    
    if data.correct
      response = $.extend({}, data)
      response.variant = data.correct
      response.variant.live = data.game.lives > 0
      this.set("response", response)
      
      this.set("waitResponse", data)
    else
      this.set("response", data)
    
  actions:
    choose: (option) ->
      self = this
      
      self.set("isLoading", true)
      $.ajax(url: "/game", type: "PUT", data: {
        option: option
      }).always(->
        self.set("isLoading", false)
      ).done((data) ->
        if data.error
          alert(data.error)
        else
          self.result(data)
      )
    
    next: ->
      this.set("response", this.get("waitResponse"))
      this.set("waitResponse", null)
    
, Config))

App.StatsController = Ember.ObjectController.extend(Config)
