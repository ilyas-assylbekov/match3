--[[
    GD50
    Match-3 Remake

    -- Board Class --

    Author: Colton Ogden
    cogden@cs50.harvard.edu

    The Board is our arrangement of Tiles with which we must try to find matching
    sets of three horizontally or vertically.
]]

Board = Class{}

function Board:init(x, y, level)
    self.x = x
    self.y = y
    self.matches = {}

    self.level = level

    self:initializeTiles()
end

function Board:initializeTiles()
    self.tiles = {}

    for tileY = 1, 8 do
        
        -- empty table that will serve as a new row
        table.insert(self.tiles, {})

        for tileX = 1, 8 do
            
            -- create a new tile at X,Y with a random color and variety
            table.insert(self.tiles[tileY], Tile(tileX, tileY, math.random(18), math.random( math.min( 6, self.level ) )))
        end
    end

    for i = 1, math.random(8) do
        local j = math.random(8)
        self.tiles[i][j].shiny = true
    end

    while self:calculateMatches() do
        
        -- recursively initialize if matches were returned so we always have
        -- a matchless board on start
        self:initializeTiles()
    end
end

--[[
    Goes left to right, top to bottom in the board, calculating matches by counting consecutive
    tiles of the same color. Doesn't need to check the last tile in every row or column if the 
    last two haven't been a match.
]]
function Board:calculateMatches()
    local matches = {}

    -- how many of the same color blocks in a row we've found
    local matchNum = 1

    -- horizontal matches first
    for y = 1, 8 do
        local colorToMatch = self.tiles[y][1].color

        matchNum = 1
        
        -- every horizontal tile
        for x = 2, 8 do
            
            -- if this is the same color as the one we're trying to match...
            if self.tiles[y][x].color == colorToMatch then
                matchNum = matchNum + 1
            else
                
                -- set this as the new color we want to watch for
                colorToMatch = self.tiles[y][x].color

                -- if we have a match of 3 or more up to now, add it to our matches table
                if matchNum >= 3 then
                    local match = {}

                    -- go backwards from here by matchNum
                    for x2 = x - 1, x - matchNum, -1 do                        
                        -- add each tile to the match that's in that match
                        table.insert(match, self.tiles[y][x2])

                        if self.tiles[y][x2].shiny then
                            match = {}
                            for i = 1, 8 do
                                table.insert( match, self.tiles[y][i] )
                            end
                        end
                    end

                    -- add this match to our total matches table
                    table.insert(matches, match)
                end

                matchNum = 1

                -- don't need to check last two if they won't be in a match
                if x >= 7 then
                    break
                end
            end
        end

        -- account for the last row ending with a match
        if matchNum >= 3 then
            local match = {}
            
            -- go backwards from end of last row by matchNum
            for x = 8, 8 - matchNum + 1, -1 do
                table.insert(match, self.tiles[y][x])

                if self.tiles[y][x].shiny then
                    match = {}
                    for i = 1, 8 do
                        table.insert( match, self.tiles[y][i] )
                    end
                end

            end

            table.insert(matches, match)
        end
    end

    -- vertical matches
    for x = 1, 8 do
        local colorToMatch = self.tiles[1][x].color

        matchNum = 1

        -- every vertical tile
        for y = 2, 8 do
            if self.tiles[y][x].color == colorToMatch then
                matchNum = matchNum + 1
            else
                colorToMatch = self.tiles[y][x].color

                if matchNum >= 3 then
                    local match = {}

                    for y2 = y - 1, y - matchNum, -1 do
                        table.insert(match, self.tiles[y2][x])

                        if self.tiles[y2][x].shiny then
                            match = {}
                            for i = 1, 8 do
                                table.insert( match, self.tiles[i][x] )
                            end
                        end
                    end

                    table.insert(matches, match)
                end

                matchNum = 1

                -- don't need to check last two if they won't be in a match
                if y >= 7 then
                    break
                end
            end
        end

        -- account for the last column ending with a match
        if matchNum >= 3 then
            local match = {}
            
            -- go backwards from end of last row by matchNum
            for y = 8, 8 - matchNum + 1, -1 do
                table.insert(match, self.tiles[y][x])

                if self.tiles[y][x].shiny then
                    match = {}
                    for i = 1, 8 do
                        table.insert( match, self.tiles[i][x] )
                    end
                end
            end

            table.insert(matches, match)
        end
    end

    -- store matches for later reference
    self.matches = matches

    -- return matches table if > 0, else just return false
    return #self.matches > 0 and self.matches or false
end

--[[
    Remove the matches from the Board by just setting the Tile slots within
    them to nil, then setting self.matches to nil.
]]
function Board:removeMatches()
    for k, match in pairs(self.matches) do
        for k, tile in pairs(match) do
            self.tiles[tile.gridY][tile.gridX] = nil
        end
    end

    self.matches = nil
end

--[[
    Shifts down all of the tiles that now have spaces below them, then returns a table that
    contains tweening information for these new tiles.
]]
function Board:getFallingTiles()
    -- tween table, with tiles as keys and their x and y as the to values
    local tweens = {}

    -- for each column, go up tile by tile till we hit a space
    for x = 1, 8 do
        local space = false
        local spaceY = 0

        local y = 8
        while y >= 1 do
            
            -- if our last tile was a space...
            local tile = self.tiles[y][x]
            
            if space then
                
                -- if the current tile is *not* a space, bring this down to the lowest space
                if tile then
                    
                    -- put the tile in the correct spot in the board and fix its grid positions
                    self.tiles[spaceY][x] = tile
                    tile.gridY = spaceY

                    -- set its prior position to nil
                    self.tiles[y][x] = nil

                    -- tween the Y position to 32 x its grid position
                    tweens[tile] = {
                        y = (tile.gridY - 1) * 32
                    }

                    -- set Y to spaceY so we start back from here again
                    space = false
                    y = spaceY

                    -- set this back to 0 so we know we don't have an active space
                    spaceY = 0
                end
            elseif tile == nil then
                space = true
                
                -- if we haven't assigned a space yet, set this to it
                if spaceY == 0 then
                    spaceY = y
                end
            end

            y = y - 1
        end
    end

    -- create replacement tiles at the top of the screen
    for x = 1, 8 do
        for y = 8, 1, -1 do
            local tile = self.tiles[y][x]

            -- if the tile is nil, we need to add a new one
            if not tile then

                -- new tile with random color and variety
                local tile = Tile(x, y, math.random(18), math.random( math.min( 6, self.level ) ), math.random(0,1) == 1 and true or false )
                tile.y = -32
                self.tiles[y][x] = tile

                -- create a new tween to return for this tile to fall down
                tweens[tile] = {
                    y = (tile.gridY - 1) * 32
                }
            end
        end
    end

    return tweens
end

function Board:render()
    for y = 1, #self.tiles do
        for x = 1, #self.tiles[1] do
            self.tiles[y][x]:render(self.x, self.y)
        end
    end
end


function Board:checkMatches()
    -- Copy board
    local boardCopy = Board( self.x, self.y, self.level )
    boardCopy:copyTiles( self.tiles )
    -- Check every tile for every move
    for y = 1, 8 do
        for x = 1, 8 do
            -- Check swap with right tile
            local swapY = y
            local swapX = math.min( 8, x + 1 )
            if boardCopy:checkSwap( y, x, swapY, swapX ) then
                return true
            end
            -- Check swap with down tile
            swapY = math.min( 8, y + 1 )
            swapX = x
            if boardCopy:checkSwap( y, x, swapY, swapX ) then
                return true
            end
            -- Check swap with right tile
            swapY = y
            swapX = math.max( 1, x - 1 )
            if boardCopy:checkSwap( y, x, swapY, swapX ) then
                return true
            end
            -- Check swap with up tile
            swapY = math.max( 1, y - 1 )
            swapX = x
            if boardCopy:checkSwap( y, x, swapY, swapX ) then
                return true
            end

        end
    end

    return false

end

function Board:copyTiles( tiles )
    self.tiles = {}
    for y = 1, 8 do
        table.insert( self.tiles, {} )
        for x = 1, 8 do
            local newTile = Tile( x, y, tiles[y][x].color, tiles[y][x].variety, tiles[y][x].shiny )
            table.insert( self.tiles[y], newTile )
        end
    end
end

function Board:checkSwap( y, x, swapY, swapX )
    local currentTile = self.tiles[y][x]
    local swapTile = self.tiles[swapY][swapX]

    self:swap( currentTile, swapTile )

    local matches = self:calculateMatches()

    currentTile = self.tiles[y][x]
    swapTile = self.tiles[swapY][swapX]

    self:swap( currentTile, swapTile )

    return matches

end

function Board:swap( tile1, tile2 )
    local tempX = tile2.gridX
    local tempY = tile2.gridY

    tile2.gridX = tile1.gridX
    tile2.gridY = tile1.gridY

    tile1.gridX = tempX
    tile1.gridY = tempY

    -- swap tiles in the tiles table
    self.tiles[tempY][tempX] = tile1
    self.tiles[tile2.gridY][tile2.gridX] = tile2
end