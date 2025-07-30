def pbFishing(hasencounter,rodtype=1)
  basebitechance=50
  bitechance=basebitechance+(15*rodtype)   # 65, 80, 95
  if $Trainer.party.length>0 && !$Trainer.party[0].isEgg?
    bitechance*=2 if ($Trainer.party[0].ability == :STICKYHOLD)
    bitechance*=2 if ($Trainer.party[0].ability == :SUCTIONCUPS)
  end
  hookchance=100
  oldpattern=$game_player.fullPattern
  pbFishingBegin
  msgwindow=Kernel.pbCreateMessageWindow
  loop do
    time=2+rand(10)
    message=""
    time.times do 
      message+=".  "
    end
    if pbWaitMessage(msgwindow,time)
      pbFishingEnd
      $game_player.setDefaultCharName(nil,oldpattern)
      Kernel.pbMessageDisplay(msgwindow,_INTL("Not even a nibble..."))
      Kernel.pbDisposeMessageWindow(msgwindow)
      return false
    end
    if rand(100)<bitechance && hasencounter
      frames=rand(21)+25
      
      # --- MODIFICATION START ---
      # Display the "bite" message without waiting for input.
      #Kernel.pbMessageDisplay(msgwindow,message+_INTL("\r\nOh!  A bite!"),false)
      (frames/2).times do
        Graphics.update
        Input.update
      end
      
      # Since the goal is to always auto-hook, we skip the failure checks
      # and proceed directly to the success outcome.
      Kernel.pbMessageDisplay(msgwindow,_INTL("Landed a Pokémon!"))
      Kernel.pbDisposeMessageWindow(msgwindow)
      pbFishingEnd
      $game_player.setDefaultCharName(nil,oldpattern)
      return true
      # --- MODIFICATION END ---
      
    else
      pbFishingEnd
      $game_player.setDefaultCharName(nil,oldpattern)
      Kernel.pbMessageDisplay(msgwindow,_INTL("Not even a nibble..."))
      Kernel.pbDisposeMessageWindow(msgwindow)
      return false
    end
  end
  Kernel.pbDisposeMessageWindow(msgwindow)
  return false
end