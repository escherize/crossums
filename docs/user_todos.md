# User Todos
A couple bits of feedback that the user noticed, "issues":
Don't implement these until asked.

# Issues

## Add 0 (negatives?) as possible cell values

## Operator Ideas

AutoAim: When there is 1 red row target, and 1 red column target, then their intersection usually (always? check this) is the solution. So this operator automatically clicks it for you, saving some time.

if 2 targets turn green from the same move you get a bonus

Bonus for not deleting any cells

Bonus for not circling any cells

Circlicious: +2 dollar for each circled cell, -1 dollar for each deleted cell
Elite Delete: -1 dollar for each circled cell, +2 dollar for each deleted cell

CoinFlip: 50% chance if you misstep you don't lose a heart

Xray: for targets with a row/col that has a selected cell: adds a small number in the top right corner of each target field, which is the sum of circled cells (helps do the math automatically)

SquarePeg: bonus for squares where all are deleted or circled: size 2x2 is good, 3x3 is crazy good

## Functions

Auto-Circle a random critical cell

Auto-Delete a random non-critical cell

Add a life

Give a +1,-1 wiggle room for a target cell


## Animations x tests 

How will our test runner fit in with animations? will we need to wait in between? maybe a "reduce motion" mode where we do our logic testing?

## Solving: What the hell just happened, why did I win/lose?

(Like balatro), We eventually need a game mode that iteratively adds up players' scores, and shows how the final score came to be.

As it is now it's quite tough to actually see what happened and why
