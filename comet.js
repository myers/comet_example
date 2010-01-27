Comet = Class.create({
  initialize: function(url, nick) {
    this.url = url;
    this.nick = nick;
    this.requests = [];
    this.emptyOutgoing();
  },
  
  emptyOutgoing: function() {
    this.outgoing = [this.nick];
  },
  
  start: function() {
    this.makeIdleRequestIfNeeded();
  },

  onMessage: function(message) {
  },
  
  send: function(value) {
    this.outgoing.push(value)
    this.makeRequest();
  },

  makeIdleRequestIfNeeded: function() {
    if (this.requests.length != 0) {
      return;
    }
    this.makeRequest();
  },
    
  makeRequest: function() {
    var request = new Ajax.Request('/comet/', {
      contentType: 'application/json',
      method: 'post',
      postBody: Object.toJSON(this.outgoing),
      onSuccess: function(response) {
        this.onMessage(response.responseJSON);
        this.requests = this.requests.without(response.request);
        this.makeIdleRequestIfNeeded();
      }.bind(this)
    });
    this.requests.push(request);
    this.emptyOutgoing();
  }
});


