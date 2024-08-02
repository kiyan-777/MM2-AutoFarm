# MM2-AutoFarm
MM2 Summer Update AutoFarm (openSource)

--updated 4:40 am August 2, 2024
you can use : <br/> loadstring(game:HttpGet("https://raw.githubusercontent.com/Zyn-ic/MM2-AutoFarm/main/FreeScript.lua", true))()

# Potential Updates:
* add a list of the fake coin positions [it's 3am i've been making this since 2:30pm thats why i dont want to log them]
* if i dont add the list then add a simple gui so you can log and add in the positions yourself
* implement crushfire's [scheduler class module](https://youtu.be/jGIomP26RRQ?si=0ba7S9dpC5fKFPfl) to see if that would reduce the coroutine usage [not the best with coroutine]


# Pros:
* My script is very lightweight and should run on anything above 50% [U.N.C TEST](https://raw.githubusercontent.com/unified-naming-convention/NamingStandard/main/UNCCheckEnv.lua)
* My script uses Octree for fast computation on the closest beach ball
* My script has dynamic speed adjust with radius and walkspeed
* My script has a functional tweenPosition that is smooth (invalid position safe 80%)
* Memory and Connection Management
* [this way the variable allocation is removed and the code doesn't keep running while/after/during you die]


# Cons:
* This does not autoexecute with the rounds you must manually run it when you have a weapon or the start timer is finished
<img src="https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcSLxnk3Xm9ageDalMb07ci_yvGz4OnuXz9DeQ&s" alt="Screenshot of the round" width="500"/>
* This program does not account for the fake coin Positions in the air bove each map
<img src="https://raw.githubusercontent.com/Zyn-ic/MM2-AutoFarm/main/Pic/fake%20coin%20spot.png" alt="fake coin spot" width="500"/>
* [sadly you will have to make your own gui script to log those positions]
* Lastly the BodyPosition is not the best for keeping the player still
* [if you ever fling or get killed just run infiniteyield and goto a player and run the script again]
* My script has dynamic speed adjust warning
* [so it will take longer to reach a part too far from the character if you make the radius too big]
* [example lets say the radius is 200 studs away and the distance is 189 studs away which is within a 200 stud radius <br/> then your speed will be (189/26) = 7.26923077 studs per sec]
* ! WOULD NOT RECOMMEND GOING OVER 80 RADIUS AND KEEP 26 WALKSPEED MAX 28
