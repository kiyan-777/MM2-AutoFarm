# MM2-Zynic-Hub
MM2 Winter Update Hub (openSource)

![Screenshot 2025-01-13 213032](https://github.com/user-attachments/assets/f71ac57d-37ff-4762-9ae3-f7cf4f88dc48)

--updated 7:54 am January 13, 2025
you can use : <br/> loadstring(game:HttpGet("https://raw.githubusercontent.com/Zyn-ic/MM2-AutoFarm/main/FreeScript.lua", true))()

<details>
  <summary>Preview of the HUB</summary>
  <img src="https://github.com/user-attachments/assets/d3150b7c-975e-44be-a758-b4f64bd0ae28" alt="image-description"/>
  <img src="https://github.com/user-attachments/assets/e184cbba-da04-4089-a8ac-d38a48e6f558" alt="image-description"/>
  <img src="https://github.com/user-attachments/assets/b4c145b6-38d0-4225-8120-4d6ead646e01" alt="image-description"/>
  <img src="https://github.com/user-attachments/assets/3d00068c-e99d-414c-ac07-0504bab9e6fd" alt="image-description"/>
  <img src="https://github.com/user-attachments/assets/8c68b38d-ec3e-43e3-8fa3-ef0720eeed1e" alt="image-description"/>
  <img src="https://github.com/user-attachments/assets/628f61b7-313f-4927-a547-93176897aacc" alt="image-description"/>
</details>

# Disclaimer
I noticed my script has be forked and used in a lot of the newer mm2 autofarm scripts to find the closet coin and I'm kinda honored cause before I uploaded the free script back in summer 2024 autofarms were just collecting any random coin that spawned into the map and I did the same thing until I watched some youtube and found crushfire's video on Octree and from there the script was born. Sadly I had a lot to do in college so I couldn't update the script to be better but on my winter break in a mere two days I made an updated version which wouldn't have you go to coins outside the map or "false positions" as I used to call it. Then in I think 4 or 5 days I created the [Free Script](/FreeScript.lua) which is a mm2 hub. I WILL NOT BE UPDATING the hub and will focus on better techniques/functions to [collect coins](/Zynic-Auto-Farm/source.lua);
- [x] faster
- [x] safer
- [x] smarter
- [x] and accout for all werid possibilities (like a murderer killing you while you're tweening to a coin)

## Basic Features

* Increase/Decrease walkspeed
* TP to player
* Refresh Roles [^1]
* Rejoin
* Server Hop
* Destroy gui

## Advance Features
* Autofarm
* Murderer/Sheriff Info [^2]
* Get Gun [^3]
* Fling Murderer
* Waypoints
* Hitbox Size
* ESP
* TP to alive player


[^1]: used to refresh roles manually
[^2]: will refresh role automatically but is as acurate as I need it to be
[^3]: safe gun is a setting feature for get gun. It's purpose is to make sure you're not too far from the gun when getting it.


# Potential Updates:
* implement crushfire's [scheduler class module](https://youtu.be/jGIomP26RRQ?si=0ba7S9dpC5fKFPfl) to see if that would reduce the coroutine usage[^4]
[^4]: I'm not the best with coroutines

