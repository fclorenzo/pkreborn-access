# Add "Accessible Summary" to the Pokémon Screen Menu
class PokemonScreen
  # Create a copy of the original pbPokemonScreen method to modify
  alias_method :accessibility_mod_original_pbPokemonScreen, :pbPokemonScreen

def pbPokemonScreen
    @scene.pbStartScene(@party, @party.length > 1 ? _INTL("Choose a Pokémon.") : _INTL("Choose Pokémon or cancel."), nil)
    loop do
      @scene.pbSetHelpText(@party.length > 1 ? _INTL("Choose a Pokémon.") : _INTL("Choose Pokémon or cancel."))
      pkmnid = @scene.pbChoosePokemon(false, true, shortcut_keys: true)
      if pkmnid.is_a?(Array) && pkmnid[0] == 1 # Switch
        @scene.pbSetHelpText(_INTL("Move to where?"))
        oldpkmnid = pkmnid[1]
        pkmnid = @scene.pbChoosePokemon(true, true, 1)
        if pkmnid >= 0 && pkmnid != oldpkmnid
          pbSwitch(oldpkmnid, pkmnid)
        end
        next
      end
      if pkmnid.is_a?(Array) && pkmnid[0] == 2 # Item
        pkmn = @party[pkmnid[1]]
        itemMenu(pkmnid[1], pkmn)
        next
      end
      if pkmnid.is_a?(Array) && pkmnid[0] == 3 # Summary
        @scene.pbSummary(pkmnid[1])
        next
      end
      if pkmnid < 0
        break
      end

      pkmn = @party[pkmnid]
      commands = []
      cmdSummary = -1
      cmdRelearn = -1
      cmdSwitch = -1
      cmdItem = -1
      cmdDebug = -1
      cmdMail = -1
      cmdRename = -1
      # --- INJECT OUR NEW COMMAND VARIABLE ---
      cmdAccessibleSummary = -1
      # --- END OF INJECTION ---

      # Build the commands
      commands[cmdSummary = commands.length] = _INTL("Summary")
      
      # --- INJECT OUR NEW COMMAND ---
      commands[cmdAccessibleSummary = commands.length] = _INTL("Accessible Summary")
      # --- END OF INJECTION ---

      pkmn.relearner = [pkmn.relearner, 0] if !pkmn.relearner.is_a?(Array)
      commands[cmdRelearn = commands.length] = _INTL("Relearn") if pkmn.relearner[0] == true
      if $DEBUG || (Reborn && $game_switches[:MiniDebug_Pass])
        # Commands for debug mode only
        commands[cmdDebug = commands.length] = _INTL("Debug")
      end
      if $game_switches[:EasyHMs_Password]
        acmdTMX = -1
        commands[acmdTMX = commands.length] = _INTL("Use TMX")
      end
      cmdMoves = [-1, -1, -1, -1]
      for i in 0...pkmn.moves.length
        move = pkmn.moves[i]
        # Check for hidden moves and add any that were found
        if !pkmn.isEgg? && (
           move.move == :MILKDRINK ||
           move.move == :SOFTBOILED ||
           HiddenMoveHandlers.hasHandler(move.move)
         )
          commands[cmdMoves[i] = commands.length] = getMoveName(move.move)
        end
      end
      commands[cmdSwitch = commands.length] = _INTL("Switch") if @party.length > 1
      if !pkmn.isEgg?
        if pkmn.mail
          commands[cmdMail = commands.length] = _INTL("Mail")
        else
          commands[cmdItem = commands.length] = _INTL("Item")
        end
        commands[cmdRename = commands.length] = _INTL("Rename")
      end
      commands[commands.length] = _INTL("Cancel")
      command = @scene.pbShowCommands(_INTL("Do what with {1}?", pkmn.name), commands)
      havecommand = false
      for i in 0...4
        if cmdMoves[i] >= 0 && command == cmdMoves[i]
          havecommand = true
          if pkmn.moves[i].move == :SOFTBOILED || pkmn.moves[i].move == :MILKDRINK
            if pkmn.hp <= (pkmn.totalhp / 5.0).floor
              pbDisplay(_INTL("Not enough HP..."))
              break
            end
            @scene.pbSetHelpText(_INTL("Use on which Pokémon?"))
            oldpkmnid = pkmnid
            loop do
              @scene.pbPreSelect(oldpkmnid)
              pkmnid = @scene.pbChoosePokemon(true)
              break if pkmnid < 0

              newpkmn = @party[pkmnid]
              if newpkmn.isEgg? || newpkmn.hp == 0 || newpkmn.hp == newpkmn.totalhp || pkmnid == oldpkmnid
                pbDisplay(_INTL("This item can't be used on that Pokémon."))
              else
                pkmn.hp -= (pkmn.totalhp / 5.0).floor
                hpgain = pbItemRestoreHP(newpkmn, (pkmn.totalhp / 5.0).floor)
                @scene.pbDisplay(_INTL("{1}'s HP was restored by {2} points.", newpkmn.name, hpgain))
                pbRefresh
              end
            end
            break
          elsif Kernel.pbCanUseHiddenMove?(pkmn, pkmn.moves[i].move)
            @scene.pbEndScene
            if pkmn.moves[i].move == :FLY
              if $cache.mapdata[$game_map.map_id].MapPosition.is_a?(Hash)
                region = pbUnpackMapHash[0]
              else
                region = $cache.mapdata[$game_map.map_id].MapPosition[0]
              end

              if $game_switches[:Blindstep]
                ret = Blindstep.flyMenu
              else
                scene = PokemonRegionMapScene.new(region, false)
                screen = PokemonRegionMap.new(scene)
                ret = screen.pbStartFlyScreen
              end

              if ret
                $PokemonTemp.flydata = ret
                $game_system.bgs_stop
                $game_screen.weather(0, 0, 0)
                return [pkmn, pkmn.moves[i].move]
              end
              @scene.pbStartScene(@party, @party.length > 1 ? _INTL("Choose a Pokémon.") : _INTL("Choose Pokémon or cancel."))
              break
            end
            return [pkmn, pkmn.moves[i].move]
          else
            break
          end
        end
      end
      if $game_switches[:EasyHMs_Password] && !pkmn.isEgg?
        if acmdTMX >= 0 && command == acmdTMX
          aRetArr = passwordUseTMX(pkmn)
          if aRetArr.length > 0
            havecommand = true
            return aRetArr
          end
        end
      end
      next if havecommand

      if cmdSummary >= 0 && command == cmdSummary
        @scene.pbSummary(pkmnid)
      # --- INJECT OUR NEW COMMAND LOGIC ---
      elsif cmdAccessibleSummary >= 0 && command == cmdAccessibleSummary
        # This opens our new sub-menu
        loop do
          # Use the scene's showCommands method to display our sub-menu
          sub_command = @scene.pbShowCommands(_INTL("Accessible Summary"), [
            _INTL("Display BST"),
            _INTL("Pokemon Details"),
            _INTL("Cancel")
          ])

          case sub_command
          when 0 # Display BST
            # Call the helper function we added earlier
            pbDisplayBSTData(pkmn)
          when 1 # Pokemon Details
            # Call the helper function we added earlier
            torDisplayPokemonDetails(pkmn)
          when -1, 2 # Cancel
            break
          end
        end
      # --- END OF INJECTION ---
      elsif cmdRelearn >= 0 && command == cmdRelearn
        pbRelearnMoveScreen(pkmn)
      elsif cmdSwitch >= 0 && command == cmdSwitch
        @scene.pbSetHelpText(_INTL("Move to where?"))
        oldpkmnid = pkmnid
        pkmnid = @scene.pbChoosePokemon(true)
        if pkmnid >= 0 && pkmnid != oldpkmnid
          pbSwitch(oldpkmnid, pkmnid)
        end
      elsif cmdDebug >= 0 && command == cmdDebug
        pbPokemonDebug(self, pkmn, pkmnid)
      elsif cmdMail >= 0 && command == cmdMail
        command = @scene.pbShowCommands(_INTL("Do what with the mail?"), [_INTL("Read"), _INTL("Take"), _INTL("Cancel")])
        case command
          when 0 # Read
            pbFadeOutIn(99999) {
              pbDisplayMail(pkmn.mail, pkmn)
            }
          when 1 # Take
            pbTakeItem(pkmn)
            pbRefreshSingle(pkmnid)
        end
      elsif cmdItem >= 0 && command == cmdItem
        itemMenu(pkmnid, pkmn)
      elsif cmdRename >= 0 && command == cmdRename
        species = getMonName(pkmn.species, pkmn.form)
        $game_variables[5] = Kernel.pbMessageFreeText("#{species}'s nickname?", _INTL(""), false, 12)
        if pbGet(5) == ""
          pkmn.name = getMonName(pkmn.species, pkmn.form)
          pbSet(5, pkmn.name)
        end
        if pbGet(5) != pkmn.name
          pkmn.name = pbGet(5)
          pbDisplay(_INTL("{1} was renamed to {2}.", species, pkmn.name))
        end
      end
    end
    @scene.pbEndScene
    return nil
  end
end

# Accessible Summary Screen Functions
def pbDisplayBSTData(pkmn,defaultMoveID=0)
  cmdwin=pbListWindow([],200)
  commands=[]
  moveDefault=0
  dexentity=$cache.pkmn[pkmn.species]
  name = dexentity.forms[pkmn.form]
  singleformoverride=false
  if !name
    name="Base Form"
    singleformoverride=true
  end

  commands.push("Species : #{dexentity.pokemonData[dexentity.forms[0]].name}")
  commands.push("Dex n° : #{dexentity.pokemonData[dexentity.forms[0]].dexnum}")
  commands.push("Form : #{name}")

  if pkmn.form==0 || singleformoverride
    typing=""
    typing+="#{torDeCapsTypings(dexentity.pokemonData[dexentity.forms[0]].Type1)}"
    
    if dexentity.pokemonData[dexentity.forms[0]].Type2!=dexentity.pokemonData[dexentity.forms[0]].Type1 && !(dexentity.pokemonData[dexentity.forms[0]].Type2.nil?)
      typing+=" / #{torDeCapsTypings(dexentity.pokemonData[dexentity.forms[0]].Type2)}"
    end
  else
    type1changed=true
    type2changed=true
    typing=""
    if !dexentity.pokemonData[dexentity.forms[pkmn.form]].Type1.nil?
      typing+="#{torDeCapsTypings(dexentity.pokemonData[dexentity.forms[pkmn.form]].Type1)}"
    end
    if typing==""
      type1changed=false
    end
    
    if dexentity.pokemonData[dexentity.forms[pkmn.form]].Type2!=dexentity.pokemonData[dexentity.forms[pkmn.form]].Type1 && !(dexentity.pokemonData[dexentity.forms[pkmn.form]].Type2.nil?)
      typing+=" / #{torDeCapsTypings(dexentity.pokemonData[dexentity.forms[pkmn.form]].Type2)}"
    end
    if typing==""
      type2changed=false
    end
    if !type1changed && !type2changed
      typing=""
      typing+="#{torDeCapsTypings(dexentity.pokemonData[dexentity.forms[0]].Type1)}"
      if dexentity.pokemonData[dexentity.forms[0]].Type2!=dexentity.pokemonData[dexentity.forms[0]].Type1 && !(dexentity.pokemonData[dexentity.forms[0]].Type2.nil?)
        typing+=" / #{torDeCapsTypings(dexentity.pokemonData[dexentity.forms[0]].Type2)}"
      end
    end
    if !type1changed && type2changed
      typing=""
      typing+="#{torDeCapsTypings(dexentity.pokemonData[dexentity.forms[0]].Type1)}"
      if dexentity.pokemonData[dexentity.forms[pkmn.form]].Type2!=dexentity.pokemonData[dexentity.forms[pkmn.form]].Type1 && !(dexentity.pokemonData[dexentity.forms[pkmn.form]].Type2.nil?)
        typing+=" / #{torDeCapsTypings(dexentity.pokemonData[dexentity.forms[pkmn.form]].Type2)}"
      end
    end
    if dexentity.pokemonData[dexentity.forms[0]].name=="Arceus" || dexentity.pokemonData[dexentity.forms[0]].name=="Silvally"
      typing=""
      typing+="#{dexentity.forms[pkmn.form]}"
      if dexentity.pokemonData[dexentity.forms[0]].name=="Arceus"
        typing+=" Plate"
      end
      if dexentity.pokemonData[dexentity.forms[0]].name=="Silvally"
        typing+=" Memory"
      end
    end
  end
  
  commands.push("#{typing}")
  commands.push(" ")
  bst=0
  bsstat=[]
  if pkmn.form==0 || singleformoverride
    bsstat=dexentity.pokemonData[dexentity.forms[0]].BaseStats
  else
    bsstat=dexentity.pokemonData[dexentity.forms[pkmn.form]].BaseStats
    if bsstat.nil?
      bsstat=dexentity.pokemonData[dexentity.forms[0]].BaseStats
    end
  end

  for i in 0..5
    bst=bst+bsstat[i]
  end
  commands.push("HP : #{bsstat[0]}")
  commands.push("Atk : #{bsstat[1]}")
  commands.push("Def : #{bsstat[2]}")
  commands.push("SpA : #{bsstat[3]}")
  commands.push("SpD : #{bsstat[4]}")
  commands.push("Spe : #{bsstat[5]}")	
  commands.push("BST : #{bst}")	
  
  ablist=pkmn.getAbilityList
  abilities="#{getAbilityName(ablist[0])}"
  abcount=0
  for ab in ablist
    if abcount>0
      abilities+=" / #{getAbilityName(ablist[abcount])}"
    end
    abcount=abcount+1
  end
  commands.push(" ")
  commands.push("Abilities : #{abilities}")	

  realcommands=[]
  for command in commands
    realcommands.push(_ISPRINTF("{1:s}",command))
  end
  pbCommands2(cmdwin,realcommands,-1,0,false) 
  cmdwin.dispose
  return 0
end

def torDisplayPokemonDetails(pkmn,defaultMoveID=0)
  cmdwin=pbListWindow([],500)
  commands=[]
  dexentity=$cache.pkmn[pkmn.species]
  name = dexentity.forms[pkmn.form]
  singleformoverride=false
  if !name
    name="Base Form"
    singleformoverride=true
  end

  if pkmn.form==0 || singleformoverride
    typing=""
    typing+="#{torDeCapsTypings(dexentity.pokemonData[dexentity.forms[0]].Type1)}"
    
    if dexentity.pokemonData[dexentity.forms[0]].Type2!=dexentity.pokemonData[dexentity.forms[0]].Type1 && !(dexentity.pokemonData[dexentity.forms[0]].Type2.nil?)
      typing+=" / #{torDeCapsTypings(dexentity.pokemonData[dexentity.forms[0]].Type2)}"
    end
  else
    type1changed=true
    type2changed=true
    typing=""
    if !dexentity.pokemonData[dexentity.forms[pkmn.form]].Type1.nil?
      typing+="#{torDeCapsTypings(dexentity.pokemonData[dexentity.forms[pkmn.form]].Type1)}"
    end
    if typing==""
      type1changed=false
    end
    
    if dexentity.pokemonData[dexentity.forms[pkmn.form]].Type2!=dexentity.pokemonData[dexentity.forms[pkmn.form]].Type1 && !(dexentity.pokemonData[dexentity.forms[pkmn.form]].Type2.nil?)
      typing+=" / #{torDeCapsTypings(dexentity.pokemonData[dexentity.forms[pkmn.form]].Type2)}"
    end
    if typing==""
      type2changed=false
    end
    if !type1changed && !type2changed
      typing=""
      typing+="#{torDeCapsTypings(dexentity.pokemonData[dexentity.forms[0]].Type1)}"
      if dexentity.pokemonData[dexentity.forms[0]].Type2!=dexentity.pokemonData[dexentity.forms[0]].Type1 && !(dexentity.pokemonData[dexentity.forms[0]].Type2.nil?)
        typing+=" / #{torDeCapsTypings(dexentity.pokemonData[dexentity.forms[0]].Type2)}"
      end
    end
    if !type1changed && type2changed
      typing=""
      typing+="#{torDeCapsTypings(dexentity.pokemonData[dexentity.forms[0]].Type1)}"
      if dexentity.pokemonData[dexentity.forms[pkmn.form]].Type2!=dexentity.pokemonData[dexentity.forms[pkmn.form]].Type1 && !(dexentity.pokemonData[dexentity.forms[pkmn.form]].Type2.nil?)
        typing+=" / #{torDeCapsTypings(dexentity.pokemonData[dexentity.forms[pkmn.form]].Type2)}"
      end
    end
    if dexentity.pokemonData[dexentity.forms[0]].name=="Arceus" || dexentity.pokemonData[dexentity.forms[0]].name=="Silvally"
      typing=""
      typing+="#{dexentity.forms[pkmn.form]}"
      if dexentity.pokemonData[dexentity.forms[0]].name=="Arceus"
        typing+=" Plate"
      end
      if dexentity.pokemonData[dexentity.forms[0]].name=="Silvally"
        typing+=" Memory"
      end
    end
  end
  
  commands.push("#{dexentity.pokemonData[dexentity.forms[0]].name} - #{typing}")
  remexp=PBExp.startExperience(pkmn.level+1,pkmn.growthrate)-pkmn.exp
  commands.push("Level #{pkmn.level} - #{remexp} experience to next level")
  itemname="No Held Item"
  if pkmn.item
    itemname="Held item : #{$cache.items[pkmn.item].name}"
  end  
  commands.push("#{itemname}")  
  commands.push("Ability : #{getAbilityName(pkmn.ability)} - Nature : #{torDeCapsNature(pkmn.nature)}")	
  commands.push("HP : #{pkmn.iv[0]} IV - #{pkmn.ev[0]} EV - #{pkmn.totalhp} total")
  commands.push("Attack : #{pkmn.iv[1]} IV - #{pkmn.ev[1]} EV - #{pkmn.attack} total")
  commands.push("Defense : #{pkmn.iv[2]} IV - #{pkmn.ev[2]} EV - #{pkmn.defense} total")
  commands.push("Special Attack : #{pkmn.iv[3]} IV - #{pkmn.ev[3]} EV - #{pkmn.spatk} total")
  commands.push("Special Defense : #{pkmn.iv[4]} IV - #{pkmn.ev[4]} EV - #{pkmn.spdef} total")
  commands.push("Speed : #{pkmn.iv[5]} IV - #{pkmn.ev[5]} EV - #{pkmn.speed} total")	
  
  movecounter=1
  for move in pkmn.moves
    if move
      commands.push("Move #{movecounter} - #{$cache.moves[move.move].name}")	
      movecounter=movecounter+1
    end
  end

  realcommands=[]
  for command in commands
    realcommands.push(_ISPRINTF("{1:s}",command))
  end
  pbCommands2(cmdwin,realcommands,-1,0,true) 
  cmdwin.dispose
  return 0
end

def torDeCapsTypings(entrytype)
  decapshash = {:NORMAL => "Normal", :FIRE => "Fire", :WATER => "Water", :GRASS  => "Grass", :ELECTRIC  => "Electric", :ICE  => "Ice", :FIGHTING  => "Fighting", :POISON  => "Poison",
  :GROUND  => "Ground", :FLYING  => "Flying", :PSYCHIC  => "Psychic", :BUG  => "Bug", :ROCK => "Rock", :GHOST  => "Ghost", :DRAGON  => "Dragon", :DARK  => "Dark", :STEEL  => "Steel",
  :FAIRY  => "Fairy"}
  if entrytype.nil?
    return nil
  else
    return decapshash[entrytype]
  end
end

def torDeCapsNature(entrynat)
  decapshash = {:HARDY => "Hardy", :LONELY => "Lonely", :ADAMANT => "Adamant", :NAUGHTY  => "Naughty", :BRAVE  => "Brave",
  :BOLD  => "Bold", :DOCILE  => "Docile", :IMPISH  => "Impish", :LAX  => "Lax", :RELAXED  => "Relaxed",
  :MODEST  => "Modest", :MILD  => "Mild", :BASHFUL => "Bashful", :RASH  => "Rash", :QUIET  => "Quiet",
  :CALM  => "Calm", :GENTLE  => "Gentle", :CAREFUL => "Careful", :QUIRKY  => "Quirky", :SASSY  => "Sassy",
  :TIMID  => "Timid", :HASTY  => "Hasty", :JOLLY => "Jolly", :NAIVE  => "Naive", :SERIOUS  => "Serious",
  }
  if entrynat.nil?
    return nil
  else
    return decapshash[entrynat]
  end
end