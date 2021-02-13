GameOverState = Class{__includes = BaseState}

function GameOverState:init()

end

function GameOverState:enter(params)
    self.score = params.score 
end

function GameOverState:update(dt)
    if love.keyboard.wasPressed('enter') or love.keyboard.wasPressed('return') then
        gStateMachine:change('start')
    end
end

function GameOverState:render()
    
    love.graphics.setFont(gFonts['large'])
    love.graphics.setColor(255/255, 204/255, 128/255, 230/255)
    love.graphics.rectangle('fill', VIRTUAL_WIDTH / 2 - 64, 64, 128, 136, 4)
    
    love.graphics.setColor(51/255, 31/255, 0, 1)
    
    love.graphics.printf('GAME OVER', VIRTUAL_WIDTH / 2 - 64, 75, 128, 'center')
    
    love.graphics.setFont(gFonts['medium'])
    love.graphics.printf('SCORE: ' .. tostring(self.score), VIRTUAL_WIDTH / 2 - 64, 145, 128, 'center')
    love.graphics.printf('Press Enter', VIRTUAL_WIDTH / 2 - 64, 180, 128, 'center')
end