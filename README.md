# rose
A fun visualization tool for Penrose tilings

How to Use Rose:

Some terminology:

A World has a current Stage, and can have a Store of alternate Stages

A Stage has a number of dimensions that it projects, and some number of Panes, which represents each dimension

A Pane has a color, a degree of rotation, and some amount of shift on the x and y coordinate. Panes are drawn as sets of parallel lines. 

-----------------------------------------------------------------------------
There are two ways to initialize a visualizer:

   -- With a fresh stage, with any number of projected dimensions.
      For n dimensions, use (main n)
   -- With a saved stage and store of stages.
      To use the stage s and store store, use (start-from s store)


-----------------------------------------------------------------------------
Commands

There are two categories of commands in rose:

    -- Commands that operate on a single Pane
    -- Commands that operate on the current Stage and/or the Store


--------
Commands that operate on a single Pane:

To operate on a single pane, you first press the number of that pane (unfortunately, currently this means that you can only operate on Panes 0-9. To change properties of higher-dimension Panes, quit a session, and manually modify the properties on the return value of that session)

Once you have pressed the number representing the pane you want to change, these are the commands at your disposal:

    -- r to change the color of the pane to red
    -- o to change the color of the pane to orange
    -- y to change the color of the pane to yellow
    -- g to change the color of the pane to green
    -- b to change the color of the pane to blue
    -- p to change the color of the pane to purple
    -- . to change the color of the pane to white
    -- w to shift the pane up
    -- s to shift the pane down
    -- a to shift the pane left
    -- d to shift the pane right

    -- ` to rotate the pane counter-clockwise
    -- , to rotate the pane clockwise

    
--------
Commands that operate on an entire Stage:


    -- [ to zoom the Stage in
    -- ] to zoom the Stage out

    -- m to increase the number of lines on all panes (more)
    -- l to decrease the number of lines on all panes (less)

    -- up to shift the entire Stage up
    -- down to shift the entire Stage down
    -- left to shift the entire Stage left
    -- right to shift the entire Stage right
    (arrow keys)

    -- r to re-set the zoom and number of lines per pane to the starting value


---------
Commands that operate on the Store

To add a new, fresh Stage to the Store, with order `n`, press `n` and then `f` (fresh)

    -- - to scroll through the Store
    -- = to add a copy of the current stage to the Store
    -- q to clean out the store (the Stage currently shown will be saved)