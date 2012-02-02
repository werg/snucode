# todo: set the template

class exports.LoginDia extends Backbone.View
	# color chooser
	# username
	initialize: ->
		@render()
		
	render: =>
		@el = $(@template())
		$('body').append @el
		@el.modal {backdrop: true, keyboard: true, show: true}
		@delegateEvents @events

	events:
		"click .login-button":    "login"
	
	switchPills: =>
		@$('#register-pill').toggleClass 'active'
		@$('#login-pill').toggleClass 'active'
		@$('#auth-ok-button').toggleClass 'register-button'
		@$('#auth-ok-button').toggleClass 'login-button'
		
	
	switchRegister: =>
		@switchPills()
		@$('.register-fields').show 'fast'
		@$('#auth-ok-button').text('Register')
		#@$('#auth-ok-button').addClass 'register-button'
		#@$('#auth-ok-button').removeClass 'login-button'
		
	
	switchLogin: =>
		@switchPills()
		@$('.register-fields').hide 'fast'
		@$('#auth-ok-button').text('Login')
		#@$('#auth-ok-button').removeClass 'register-button'
		#@$('#auth-ok-button').addClass 'login-button'
		
	
	login: =>
		credentials =
			username: @$('#username').val()
			password: @$('#login-pwd').val()
			register: false
			valid: true
		@hide()
		@options.callback credentials
		
		# todo find out how to authenticate and insert @options.callback :)
	
	register: =>
		credentials =
			username: @$('#username').val()
			password: @$('#login-pwd').val()
			email:    @$('#register-email').val()
			register: true
			valid: true
		@hide()
		@options.callback credentials
	
	hide: =>
		@el.modal 'hide'
		@el.remove()
		
	cancel: =>
		@hide()
		@options.callback {valid: false}
		
	
