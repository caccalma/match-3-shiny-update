PlayState = Class{__includes = BaseState}

function PlayState:init()

    self.transitionAlpha = 1

    self.boardHighlightX = 0
    self.boardHighlightY = 0

    self.rectHighlighted = false

    self.canInput = true

    self.highlightedTile = nil

    self.score = 0
    self.timer = 60

    Timer.every(0.5, function()
        self.rectHighlighted = not self.rectHighlighted
    end)

    Timer.every(1, function()
        self.timer = self.timer - 1

        if self.timer <= 5 then
            gSounds['clock']:play()
        end
    end)

    self.seconds = 0
    self.secondsY = 168
    self.secondsOpacity = 1
end

function PlayState:enter(params)

    self.level = params.level

    self.board = params.board or Board(VIRTUAL_WIDTH - 272, 16)

    self.score = params.score or 0

    self.scoreGoal = self.level * 1.25 * 1000

end

function PlayState:update(dt)
    if love.keyboard.wasPressed('escape') then
        love.event.quit()
    end

    if self.timer <= 0 then
        Timer.clear()
        
        gSounds['game-over']:play()

        gStateMachine:change('game-over', {
            score = self.score
        })
    end

    if self.score >= self.scoreGoal then

        Timer.clear()

        gSounds['next-level']:play()

        gStateMachine:change('begin-game', {
            level = self.level + 1,
            score = self.score
        })
    end

    if self.canInput then

        if love.keyboard.wasPressed('up') then
            self.boardHighlightY = math.max(0, self.boardHighlightY - 1)
            gSounds['select']:play()
        elseif love.keyboard.wasPressed('down') then
            self.boardHighlightY = math.min(7, self.boardHighlightY + 1)
            gSounds['select']:play()
        elseif love.keyboard.wasPressed('left') then
            self.boardHighlightX = math.max(0, self.boardHighlightX - 1)
            gSounds['select']:play()
        elseif love.keyboard.wasPressed('right') then
            self.boardHighlightX = math.min(7, self.boardHighlightX + 1)
            gSounds['select']:play()

        elseif not self.isKeyboard then

            local mouseCursorX, mouseCursorY = push:toGame(love.mouse.getPosition())
            local mouseCursorX = mouseCursorX - (VIRTUAL_WIDTH - 272)
            local mouseCursorY = mouseCursorY - 16
            
            if mouseCursorX >= 0 and mouseCursorX <= 255
            and mouseCursorY >= 0 and mouseCursorY <= 255 then
      
                local mouseCursorGridX = math.floor(mouseCursorX / 32)
                local mouseCursorGridY = math.floor(mouseCursorY / 32)

             self.boardHighlightX = mouseCursorGridX
             self.boardHighlightY = mouseCursorGridY
            end
        end    

        if love.keyboard.wasPressed('enter') or love.keyboard.wasPressed('return')
        or love.keyboard.wasPressed('space') or love.mouse.wasPressed(1) then
            local x = self.boardHighlightX + 1
            local y = self.boardHighlightY + 1
            
            if not self.highlightedTile then
                self.highlightedTile = self.board.tiles[y][x]

            elseif self.highlightedTile == self.board.tiles[y][x] then
                self.highlightedTile = nil

            elseif math.abs(self.highlightedTile.gridX - x) + math.abs(self.highlightedTile.gridY - y) > 1 then
                gSounds['error']:play()
                self.highlightedTile = nil
            else
                self.canInput = false
                local tempX = self.highlightedTile.gridX
                local tempY = self.highlightedTile.gridY

                local newTile = self.board.tiles[y][x]

                self.highlightedTile.gridX = newTile.gridX
                self.highlightedTile.gridY = newTile.gridY
                newTile.gridX = tempX
                newTile.gridY = tempY

                self.board.tiles[self.highlightedTile.gridY][self.highlightedTile.gridX] =
                    self.highlightedTile

                self.board.tiles[newTile.gridY][newTile.gridX] = newTile

                Timer.tween(0.1, {
                    [self.highlightedTile] = {x = newTile.x, y = newTile.y},
                    [newTile] = {x = self.highlightedTile.x, y = self.highlightedTile.y}
                })
                :finish(
                    function()
                        local highlightedTile = self.highlightedTile

                        if not self:calculateMatches() then
                            gSounds['error']:play()
                            self.highlightedTile = nil
                            Timer.after(0.25, function() 

                                local tempX = highlightedTile.gridX
                                local tempY = highlightedTile.gridY
    
                                highlightedTile.gridX = newTile.gridX
                                highlightedTile.gridY = newTile.gridY
                                newTile.gridX = tempX
                                newTile.gridY = tempY
    
                                self.board.tiles[highlightedTile.gridY][highlightedTile.gridX] =
                                highlightedTile
    
                                self.board.tiles[newTile.gridY][newTile.gridX] = newTile
    
                                Timer.tween(0.1, {
                                    [highlightedTile] = {x = newTile.x, y = newTile.y},
                                    [newTile] = {x = highlightedTile.x, y = highlightedTile.y}
                                })
                        end)
                    end
                    self.board:check()
                    self.canInput = true
                end)
            end
        end
    end

    Timer.update(dt)
end


function PlayState:calculateMatches()
    self.highlightedTile = nil

    local matches = self.board:calculateMatches()
    
    if matches then

        gSounds['match']:stop()
        gSounds['match']:play()

        for k, match in pairs(matches) do
            
            for i, tile in pairs(match) do
                self.score = self.score + 50 * tile.variety
            end

            self.timer = self.timer + #match
            self.seconds = self.seconds + #match
        end

        Timer.after(0.25, function() 
            Timer.tween(0.5, {
                [self] = { secondsY = 145, secondsOpacity = 0},
            })
            :finish(function()
                self.seconds = 0
                self.secondsY = 168
                self.secondsOpacity = 1
            end)
        end)
            
        self.board:removeMatches()

        local tilesToFall = self.board:getFallingTiles()

        Timer.tween(0.25, tilesToFall):finish(function()
            local newTiles = self.board:getNewTiles()
            
            Timer.tween(0.25, newTiles):finish(function()

                self:calculateMatches()
            end)
        end)
        return true
    else
        return false
    end
end

function PlayState:render()
    self.board:render()

    if self.highlightedTile then
        love.graphics.setBlendMode("add")

        love.graphics.setColor(255/255, 255/255, 255/255, 100 / 255)
        love.graphics.rectangle(
            "fill",
            (self.highlightedTile.gridX - 1) * 32 + (VIRTUAL_WIDTH - 272),
            (self.highlightedTile.gridY - 1) * 32 + 16, 32, 32, 4 )

        love.graphics.setBlendMode("alpha")
    end

    if self.rectHighlighted then
        love.graphics.setColor(252 / 255, 213 / 255, 121 / 255, 255 / 255)
    else
        love.graphics.setColor(224 / 255, 158 / 255, 4/ 255, 255 / 255)
    end

    love.graphics.setLineWidth(4)
    love.graphics.rectangle(
        "line",
        self.boardHighlightX * 32 + (VIRTUAL_WIDTH - 272),
        self.boardHighlightY * 32 + 16, 32,32,4
    )

    love.graphics.setColor(255/255, 204/255, 128/255, 200/255)
    love.graphics.rectangle("fill", 20, 85, 180, 118, 4)

    love.graphics.setColor(51/255, 31/255, 0, 1)
    love.graphics.setFont(gFonts["medium"])
    love.graphics.printf("LEVEL: " .. tostring(self.level), 24, 100, 182, "center")
    love.graphics.printf("SCORE: " .. tostring(self.score), 24, 125, 182, "center")
    love.graphics.printf("GOAL: " .. tostring(self.scoreGoal), 24, 150, 182, "center")
    love.graphics.printf("TIMER: " .. tostring(self.timer), 24, 175, 182, "center")

 if self.seconds > 0 then
        love.graphics.setColor(51/255, 31/255, 0, self.secondsOpacity)
        love.graphics.printf('+ ' .. tostring(self.seconds) .. ' s', 92, self.secondsY, 182, 'center')
        love.graphics.setColor(51/255, 31/255, 0, 1)
    end
end