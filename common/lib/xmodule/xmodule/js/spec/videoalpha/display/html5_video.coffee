describe 'VideoAlpha HTML5Video', ->

  playbackRates = [0.75, 1.0, 1.25, 1.5]

  STATUS =
    UNSTARTED: -1,
    ENDED: 0,
    PLAYING: 1,
    PAUSED: 2,
    BUFFERING: 3,
    CUED: 5

  beforeEach ->
    loadFixtures 'videoalpha_html5.html'
    @el = $('#example').find('.video')
    @playerVars =
      controls: 0
      wmode: 'transparent'
      rel: 0
      showinfo: 0
      enablejsapi: 1
      modestbranding: 1
      html5: 1
      end: 5
    @html5Sources =
      mp4: 'http://www.808.dk/pics/video/gizmo.mp4'
      webm: 'http://www.808.dk/pics/video/gizmo.webm'
      ogg: 'http://www.808.dk/pics/video/gizmo.ogv'
      # mp4: 'test.mp4'
      # webm: 'test.webm'
      # ogg: 'test.ogv'
    @onReady = jasmine.createSpy 'onReady'
    @onStateChange = jasmine.createSpy 'onStateChange'

    @player = new window.HTML5Video.Player @el,
      playerVars: @playerVars,
      videoSources: @html5Sources,
      events:
        onReady: @onReady
        onStateChange: @onStateChange

    @videoEl = @el.find('.video-player video').get(0)

  it 'PlayerState', ->
    expect(HTML5Video.PlayerState).toEqual STATUS

  describe 'constructor', ->
    it 'create an html5 video element', ->
      expect(@el.find('.video-player div')).toContain 'video'

    it 'check if sources are created in correct way', ->
      sources = $(@videoEl).find('source')
      videoTypes = ['mp4', 'webm', 'ogg']
      videoSources = [
        'http://www.808.dk/pics/video/gizmo.mp4',
        'http://www.808.dk/pics/video/gizmo.webm',
        'http://www.808.dk/pics/video/gizmo.ogv'
      ]
      $.each sources, (index, source) ->
        s = $(source)
        expect($.inArray(s.attr('src'), videoSources)).not.toEqual -1
        expect($.inArray(s.attr('type').replace('video/', ''), videoTypes))
          .not.toEqual -1

    it 'check if click event is handled on the player', ->
        expect(@videoEl).toHandle 'click'

  describe 'events:', ->

    beforeEach ->
      spyOn(@player, 'callStateChangeCallback').andCallThrough()

    describe 'click', ->

      describe 'when player is paused', ->

        beforeEach ->
          spyOn(@videoEl, 'play').andCallThrough()
          @player.playerState = STATUS.PAUSED
          $(@videoEl).trigger('click')

        it 'native play event was called', ->
          expect(@videoEl.play).toHaveBeenCalled()

        it 'player state was changed', ->
          expect(@player.playerState).toBe STATUS.PLAYING

        it 'callback was called', ->
          expect(@player.callStateChangeCallback).toHaveBeenCalled()


      describe 'when player is played', ->

        beforeEach ->
          spyOn(@videoEl, 'pause').andCallThrough()
          @player.playerState = STATUS.PLAYING
          $(@videoEl).trigger('click')

        it 'native pause event was called', ->
          expect(@videoEl.pause).toHaveBeenCalled()

        it 'player state was changed', ->
          expect(@player.playerState).toBe STATUS.PAUSED

        it 'callback was called', ->
          expect(@player.callStateChangeCallback).toHaveBeenCalled()

    describe 'play', ->

      beforeEach ->
        spyOn(@videoEl, 'play').andCallThrough()
        @player.playerState = STATUS.PAUSED
        @videoEl.play()

      it 'native event was called', ->
        expect(@videoEl.play).toHaveBeenCalled()

      it 'player state was changed', ->
        waitsFor ( ->
          @player.playerState != HTML5Video.PlayerState.PAUSED
        ), 'Player state should be changed', 200

        runs ->
          expect(@player.playerState).toBe STATUS.PLAYING

      it 'callback was called', ->
        waitsFor ( ->
          @player.playerState != HTML5Video.PlayerState.PAUSED
        ), 'Player state should be changed', 200

        runs ->
          expect(@player.callStateChangeCallback).toHaveBeenCalled()

    describe 'pause', ->

      beforeEach ->
        spyOn(@videoEl, 'pause').andCallThrough()
        @videoEl.play()
        @videoEl.pause()

      it 'native event was called', ->
        expect(@videoEl.pause).toHaveBeenCalled()

      it 'player state was changed', ->
        waitsFor ( ->
          @player.playerState != HTML5Video.PlayerState.UNSTARTED
        ), 'Player state should be changed', 400

        runs ->
          expect(@player.playerState).toBe STATUS.PAUSED

      it 'callback was called', ->
        waitsFor ( ->
          @player.playerState != HTML5Video.PlayerState.UNSTARTED
        ), 'Player state should be changed', 400

        runs ->
          expect(@player.callStateChangeCallback).toHaveBeenCalled()

    describe 'canplay', ->

      beforeEach ->
        waitsFor ( ->
          @player.playerState != STATUS.UNSTARTED
        ), 'Video cannot be played', 200

      it 'player state was changed', ->
        runs ->
          expect(@player.playerState).toBe STATUS.PAUSED

      it 'end property was defined', ->
        expect(@player.end).not.toBeNull()

      it 'start position was defined', ->
        expect(@videoEl.currentTime).toBe(@player.start)

      it 'callback was called', ->
        runs ->
          expect(@player.config.events.onReady).toHaveBeenCalled()

    xdescribe 'ended', ->
      beforeEach ->
        waitsFor ( ->
          @seek = @videoEl.currentTime
          @player.playerState != STATUS.UNSTARTED
        ), 'Video cannot be played', 200

      it 'player state was changed', ->
        runs ->
          @videoEl.currentTime = @videoEl.duration
          @videoEl.play()

          waitsFor ( ->
            @player.playerState != STATUS.PLAYING
          ), 'aaa', 200

          runs ->
            expect(@player.playerState).toBe STATUS.ENDED

      it 'callback was called', ->
        runs ->
          expect(@player.callStateChangeCallback).toHaveBeenCalled()

    xdescribe 'timeupdate', ->

      beforeEach ->
        spyOn(@videoEl, 'pause').andCallThrough()
        waitsFor ( ->
          @player.playerState != STATUS.UNSTARTED
        ), 'Video cannot be played', 200


      it 'player state was changed', ->
        runs ->
          @videoEl.currentTime = 7
          @videoEl.play()

          waitsFor ( ->
            @player.playerState != STATUS.PLAYING
          ), 'aaa', 200

          runs ->
            expect(@videoEl.pause).toHaveBeenCalled()
            # expect(@player.playerState).toBe STATUS.PAUSED

      xit 'player state was changed', ->
        flag = undefined
        @videoEl.addEventListener 'timeupdate', ((data) ->
          flag = true
        ), false

        # waitsFor ( ->
        #   @seek = @videoEl.currentTime
        #   flag == true
        # ), 'We cannot play the video', 200
        waitsFor ( ->
          @seek = @videoEl.currentTime
          @player.playerState != STATUS.UNSTARTED
        ), 'Video cannot be played', 200

        runs ->
          expect(@videoEl.pause).toHaveBeenCalled()

  describe 'methods:', ->

    beforeEach ->
      waitsFor ( ->
        @volume = @videoEl.volume
        @seek = @videoEl.currentTime
        @player.playerState == STATUS.PAUSED
      ), 'Video cannot be played', 200


    it 'pauseVideo', ->
      spyOn(@videoEl, 'pause').andCallThrough()
      @player.pauseVideo()
      expect(@videoEl.pause).toHaveBeenCalled()

    describe 'seekTo', ->

      it 'set new correct value', ->
        runs ->
          @player.seekTo(2)
          expect(@videoEl.currentTime).toBe 2

      it 'set new inccorrect values', ->
        runs ->
          @player.seekTo(-50)
          expect(@videoEl.currentTime).toBe @seek
          @player.seekTo('5')
          expect(@videoEl.currentTime).toBe @seek
          @player.seekTo(500000)
          expect(@videoEl.currentTime).toBe @seek

    describe 'setVolume', ->

      it 'set new correct value', ->
        runs ->
          @player.setVolume(50)
          expect(@videoEl.volume).toBe 50*0.01

      it 'set new inccorrect values', ->
        runs ->
          @player.setVolume(-50)
          expect(@videoEl.volume).toBe @volume
          @player.setVolume('5')
          expect(@videoEl.volume).toBe @volume
          @player.setVolume(500000)
          expect(@videoEl.volume).toBe @volume

    it 'getCurrentTime', ->
      runs ->
        @videoEl.currentTime = 3
        expect(@player.getCurrentTime()).toBe 3

    it 'playVideo', ->
      runs ->
        spyOn(@videoEl, 'play').andCallThrough()
        @player.playVideo()
        expect(@videoEl.play).toHaveBeenCalled()

    it 'getPlayerState', ->
      runs ->
        @player.playerState = STATUS.PLAYING
        expect(@player.getPlayerState()).toBe STATUS.PLAYING

    it 'getVolume', ->
      runs ->
        @volume = @videoEl.volume = 0.5
        expect(@player.getVolume()).toBe @volume

    it 'getDuration', ->
      runs ->
        @duration = @videoEl.duration
        expect(@player.getDuration()).toBe @duration

    describe 'setPlaybackRate', ->
      it 'set a correct value', ->
        @playbackRate = 1.5
        @player.setPlaybackRate @playbackRate
        expect(@videoEl.playbackRate).toBe @playbackRate

      it 'set NaN value', ->
        @playbackRate = NaN
        @player.setPlaybackRate @playbackRate
        expect(@videoEl.playbackRate).toBe 1.0

    it 'getAvailablePlaybackRates', ->
      expect(@player.getAvailablePlaybackRates()).toEqual playbackRates
