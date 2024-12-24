# MM2-AutoFarm
MM2 Summer Update AutoFarm (openSource)

--updated 4:40 am August 2, 2024
you can use : <br/> loadstring(game:HttpGet("https://raw.githubusercontent.com/Zyn-ic/MM2-AutoFarm/main/FreeScript.lua", true))()

# Potential Updates:
* Implement it in a Full MM2 Hub
* implement crushfire's [scheduler class module](https://youtu.be/jGIomP26RRQ?si=0ba7S9dpC5fKFPfl) to see if that would reduce the coroutine usage [not the best with coroutine]


# Pros:
* My script is very lightweight and should run on anything above 50% [U.N.C TEST](https://raw.githubusercontent.com/unified-naming-convention/NamingStandard/main/UNCCheckEnv.lua)
* My script uses Octree for fast computation on the closest coin
* My script has dynamic speed adjust with radius and walkspeed
* My script has a functional tweenPosition that is smooth (invalid position safe 80%)
* Memory and Connection Management
* [this way the variable allocation is removed and the code doesn't keep running while/after/during you die]


# Cons:
* This does not autoexecute with the rounds you must manually run it when you have a weapon or the start timer is finished
<img src="https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcSLxnk3Xm9ageDalMb07ci_yvGz4OnuXz9DeQ&s" alt="Screenshot of the round" width="500"/>

* I have fixed some of the "fake coin positions" but for anyone wanting to take a step further the problem is removing already touched/removing coins
  best way to do this is using Octree:FindFirstNode()
<img src="https://raw.githubusercontent.com/Zyn-ic/MM2-AutoFarm/main/Pic/fake%20coin%20spot.png" alt="fake coin spot" width="500"/>

* Lastly the BodyPosition is not the best for keeping the player still
* [if you ever fling or get killed just run infiniteyield and goto a player and run the script again]

