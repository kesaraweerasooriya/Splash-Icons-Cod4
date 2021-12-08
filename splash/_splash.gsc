/*

TODO :- thread Like This

 if (isDefined(attacker) && isplayer(attacker)) //Original
 {   
	attacker thread maps\mp\gametypes\_splash::killedPlayer(self, sWeapon, sMeansOfDeath, iDamage);   
 }
 
*/ 
#include maps\mp\_utility;
#include maps\mp\gametypes\_hud_util;
init() 
{
	precacheShader("gradient_top");
	precacheShader("gradient_bottom");
	precacheShader("line_horizontal");
	
	level.numKills = 0;
	precacheShader("rank_prestige10");

	level thread onPlayerConnect();
}
onPlayerConnect() 
{
	for (;;) 
	{
		level waittill("connected", player);
		player thread onPlayerSpawned();
		player.lastKilledBy = undefined;
		if (!isdefined(player.pers["cur_kill_streak"]))
			player.pers["cur_kill_streak"] = 0;
		if (!isdefined(player.pers["cur_death_streak"]))
			player.pers["cur_death_streak"] = 0;
		player.lastwallbang = undefined;
		player.recentKillCount = 0;
		player.lastKillTime = 0;

	}

}
onPlayerSpawned() {
	self endon("disconnect");
	level endon("game_ended");
	for (;;) {
		self waittill("spawned");
		self thread countDeathStreak();
		self thread countKillStreak();
		self.firstTimeDamaged = [];
		self.damaged = undefined;

	}

}
countDeathStreak() {
	self endon("disconnect");
	self endon("joined_spectators");
	if (!isdefined(self.pers["cur_death_streak"]))
		self.pers["cur_death_streak"] = 0;
	before = self.deaths;
	for (;;) {
		current = self.deaths;
		while (current == self.deaths)
			wait 0.05;
		self.pers["cur_death_streak"] = self.deaths - before;

	}

}
countKillStreak() {
	self endon("disconnect");
	self endon("joined_spectators");
	if (!isdefined(self.pers["cur_kill_streak"]))
		self.pers["cur_kill_streak"] = 0;
	before = self.kills;
	for (;;) {
		current = self.kills;
		while (current == self.kills)
			wait 0.05;
		self.pers["cur_kill_streak"] = self.kills - before;

	}

}
killedPlayer(victim, weapon, meansOfDeath, damage) 
{

	/*if (victim.team == self.team)
		return;
	victimGuid = victim.guid;
	myGuid = self.guid;
	curTime = getTime();
	*/
	
	attacker=self;
	if( attacker == victim || !isPlayer( attacker ) )
		return;
	
	victimGuid = victim.guid;
	myGuid = self.guid;
	curTime = getTime();
	
	self thread updateRecentKills();
	self.lastKillTime = getTime();
	self.lastKilledPlayer = victim;

	self.modifiers = [];

	level.numKills++;

	if (weapon == "none")
		return false;

	if (isdefined(self.lastwallbang) && self.lastwallbang == getTime())
		self wallbang();

	if (isDefined(victim.damaged) && victim.damaged == getTime()) {
		//	weaponClass = getWeaponClass( weapon );

		if (meansOfDeath != "MOD_MELEE" && meansOfDeath != "MOD_HEAD_SHOT" && (meansOfDeath == "MOD_RIFLE_BULLET" || meansOfDeath == "MOD_PISTOL_BULLET") && (damage > 200))
			//self thread splashNotifyDelayed( "one_shot_kill" );
			self oneshotkill();
	}
	if (level.numKills == 1)
		self firstBlood();

	if (self.pers["cur_death_streak"] > 3)
		self comeBack();

	if (meansOfDeath == "MOD_HEAD_SHOT")
		self headShot();

	if (!isAlive(self) && self.deathtime + 800 < getTime())
		self postDeathKill();

	if (isAlive(self) && self.health < 10)
		self neardeathkill();

	if (level.teamBased && curTime - victim.lastKillTime < 500) {
		if (victim.lastkilledplayer != self)
			self avengedPlayer();
	}

	if (isDefined(victim.attackerPosition))
		attackerPosition = victim.attackerPosition;
	else
		attackerPosition = self.origin;

	if (isAlive(self) && (meansOfDeath == "MOD_RIFLE_BULLET" || meansOfDeath == "MOD_PISTOL_BULLET" || meansOfDeath == "MOD_HEAD_SHOT") && distance(attackerPosition, victim.origin) > 1536 && !isDefined(self.assistedSuicide))
		self longshot();

	if (isDefined(victim.pers["cur_kill_streak"]) && victim.pers["cur_kill_streak"] >= max(3, int(level.aliveCount[level.otherTeam[victim.team]] / 2)))
		self buzzKill();

	if (isDefined(self.pers["cur_kill_streak"]) && self.pers["cur_kill_streak"] == 3)
		self kingslayer();
	if (isDefined(self.pers["cur_kill_streak"]) && self.pers["cur_kill_streak"] == 5)
		self bloodthirsty();

	if (isdefined(self.lastKilledBy) && self.lastKilledBy == victim && level.players.size > 6)
		self revenge();

	victim.lastKilledBy = self;
}

wallbang() {
	self thread splashNotifyDelayed("puncture");
	self thread maps\mp\gametypes\_rank::giveRankXP("wallbang");
	wait.01;
}

longshot() {
	self thread splashNotifyDelayed("longshot");
	self thread maps\mp\gametypes\_rank::giveRankXP("longshot");
	wait.01;
}

execution() {
	self thread splashNotifyDelayed("execution");
	self thread maps\mp\gametypes\_rank::giveRankXP("execution");
	wait.01;
}

headShot() {
	self thread splashNotifyDelayed("headshot_splash");
	self playlocalsound("headshot");
	self thread maps\mp\gametypes\_rank::giveRankXP("headshot_splash");
	wait.01;
}

avengedPlayer() {
	self thread splashNotifyDelayed("avenger");
	self thread maps\mp\gametypes\_rank::giveRankXP("avenger");
	wait.01;
}

assistedSuicide() {
	self thread splashNotifyDelayed("assistedsuicide");
	self thread maps\mp\gametypes\_rank::giveRankXP("assistedsuicide");
	wait.01;
}

defendedPlayer() {
	self thread splashNotifyDelayed("defender");
	self thread maps\mp\gametypes\_rank::giveRankXP("defender");
	wait.01;
}

postDeathKill() {
	self thread splashNotifyDelayed("posthumous");
	self thread maps\mp\gametypes\_rank::giveRankXP("posthumous");
	wait.01;
}

revenge() {
	self thread splashNotifyDelayed("revenge");
	self thread maps\mp\gametypes\_rank::giveRankXP("revenge");
	wait.01;
}

oneshotkill() {
	self thread splashNotifyDelayed("one_shot_kill");
	self thread maps\mp\gametypes\_rank::giveRankXP("one_shot_kill");
	wait.01;
}

neardeathkill() {
	self thread splashNotifyDelayed("neardeath");
	self thread maps\mp\gametypes\_rank::giveRankXP("neardeath");
	wait.01;
}

kingslayer() {
	self thread splashNotifyDelayed("king_slayer");
	self thread maps\mp\gametypes\_rank::giveRankXP("king_slayer");
	wait.01;
}

bloodthirsty() {
	self thread splashNotifyDelayed("bloodthirsty");
	self thread maps\mp\gametypes\_rank::giveRankXP("bloodthirsty");
	wait.01;
}
multiKill(killCount) 
{
	assert(killCount > 1);

	if (killCount == 2) 
	{
		self thread splashNotifyDelayed("doublekill");
		self playlocalsound("doublekill");
	} else if (killCount == 3) {
		self thread splashNotifyDelayed("triplekill");
		thread teamPlayerCardSplash("callout_3xkill", self);
		self stoplocalsound("doublekill");
		self playlocalsound("triplekill");
	} else {
		self thread splashNotifyDelayed("multikill");
		thread teamPlayerCardSplash("callout_3xpluskill", self);
		self stoplocalsound("triplekill");
		self playlocalsound("holyshit");
	}
}

firstBlood() {
	self thread splashNotifyDelayed("firstblood");
	//thread playSoundOnPlayers("firstblood");
	self thread maps\mp\gametypes\_rank::giveRankXP("firstblood");
	thread teamPlayerCardSplash("callout_firstblood", self);
}

buzzKill() {
	self thread splashNotifyDelayed("buzzkill");
	self thread maps\mp\gametypes\_rank::giveRankXP("buzzkill");
}

comeBack() {
	self thread splashNotifyDelayed("comeback");
	self thread maps\mp\gametypes\_rank::giveRankXP("comeback");
}
updateRecentKills() {
	self endon("disconnect");
	level endon("game_ended");
	self notify("updateRecentKills");
	self endon("updateRecentKills");
	self.recentKillCount++;
	wait(1.0);
	if (self.recentKillCount > 1)
		self multiKill(self.recentKillCount);
	self.recentKillCount = 0;

}
isWallBang(attacker, victim) {
	return bulletTracePassed(attacker getEye(), victim getEye(), true, attacker);

}
/* -----------------UTILITIES-----------*/

splashNotifyDelayed(splash) {
	actionData = spawnStruct();

	actionData.name = splash;
	actionData.sound = getSplashSound(splash);
	actionData.duration = getSplashDuration(splash);

	//	self thread underScorePopup(getSplashTitle(splash), (1,1,.2));
	self thread splashNotify(actionData);
}

getSplashTitle(splash) {
	return tableLookupIString("mp/splashTable.csv", 1, splash, 2);

}
getSplashDescription(splash) {
	return tableLookupIString("mp/splashTable.csv", 1, splash, 3);

}
getSplashMaterial(splash) {
	return tableLookup("mp/splashTable.csv", 1, splash, 4);

}
getSplashColorRGBA(splash, i) {
	return stringToFloat(tableLookup("mp/splashTable.csv", 1, splash, i));

}
getSplashDuration(splash) {
	return stringToFloat(tableLookup("mp/splashTable.csv", 1, splash, 5));

}
getSplashSound(splash) {
	return tableLookup("mp/splashTable.csv", 1, splash, 10);

}
teamPlayerCardSplash(splash, owner, team) {
	actionData = spawnStruct();
	actionData.name = splash;
	actionData.sound = getSplashSound(splash);
	actionData.duration = getSplashDuration(splash);
	for (i = 0;i < level.players.size;i++) {
		if (isDefined(team) && level.players[i].team != team)
			continue;
		level.players[i]thread playerCardSplashNotify(actionData, owner);

	}

}
splashNotify(splash) {
	self endon("disconnect");

	wait 0.05;
	if (level.gameEnded)
		return;

	if (tableLookup("mp/splashTable.csv", 1, splash.name, 0) != "") {
		if (isDefined(self.splashinprogress) && self.splashinprogress) {
			if (!isdefined(self.splashwaitcount))
				self.splashwaitcount = .4;
			else
				self.splashwaitcount += .4;
			wait self.splashwaitcount;
			self notify("splashwaitting");
			self.splashwaitcount -= .4;
		}

		self.splashinprogress = true;

		//self destroySplash(splashNotify);

		if (isDefined(splash.sound))
			self playLocalSound(splash.sound);

		splashNotify[0] = addTextHud(self, 0, -90, 0, "center", "middle", 1.4);//-110
		splashNotify[0].font = "default";
		splashNotify[0].horzAlign = "center";
		splashNotify[0].vertAlign = "middle";
		splashNotify[0]setText(getTitleText(splash.name));
		splashNotify[0].glowcolor = (0.3, 0.3, 2.0);
		splashNotify[0].glowalpha = 0;//getSplashColorRGBA(splash.name,8);
		splashNotify[0].sort = 1001;
		//splashNotify[0] maps\mp\gametypes\_hud::fontPulseInit();
		splashNotify[0].hideWhenInMenu = true;
		splashNotify[0].archived = false;

		splashNotify[1] = addTextHud(self, 0, -130, 0, "center", "middle", 1.4);//-90
		splashNotify[1].horzAlign = "center";
		splashNotify[1].vertAlign = "middle";
		splashNotify[1]setshader(getSplashMaterial(splash.name), 120, 120);//getSplashDescription(splash.name)
		splashNotify[1].sort = 1002;
		//splashNotify[1] maps\mp\gametypes\_hud::fontPulseInit();
		splashNotify[1].hideWhenInMenu = true;
		splashNotify[1].archived = false;

		splashNotify[0]thread moveasidetext(self);
		splashNotify[1]thread moveasideshader(self);

		for (i = 0;i < splashNotify.size;i++) {
			splashNotify[i]fadeOverTime(0.15);
			splashNotify[i].alpha = 1.0;
		}
		//	splashNotify[0] thread maps\mp\gametypes\_hud::fontPulse( self );
		//	splashNotify[1] thread maps\mp\gametypes\_hud::fontPulse( self );
		splashNotify[1]scaleovertime(.1, 70, 70);

		wait(splash.duration - 0.05);

		for (i = 0;i < splashNotify.size;i++) {
			splashNotify[i]fadeOverTime(0.15);
			splashNotify[i].alpha = 0;
		}

		splashNotify[0]scaleOverTime(0.15, 480, 480);

		wait 0.1;
		self destroySplash(splashNotify);
		wait 0.05;
		self.splashinprogress = false;
	}
}
destroySplash(splashNotify) {
	if (!isDefined(splashNotify) || !splashNotify.size)
		return;
	for (i = 0;i < splashNotify.size;i++)
		splashNotify[i]destroy();
	splashNotify = [];

}
playerCardSplashNotify(splash, owner) {
	self endon("disconnect");
	if (level.gameEnded)
		return;
	if (!isDefined(owner))
		return;
	wait 0.05;
	while (isDefined(self.leftnotifyinprogress) && self.leftnotifyinprogress)
		wait 0.05;
	self.leftnotifyinprogress = true;
	self destroyPlayerCard();
	self.leftnotify = [];
	self.leftnotify[0] = newClientHudElem(self);
	self.leftnotify[0].x = -150;
	self.leftnotify[0].y = 125;
	self.leftnotify[0].alignX = "left";
	self.leftnotify[0].horzAlign = "left";
	self.leftnotify[0].alignY = "top";
	self.leftnotify[0]setShader("gradient_top", 150, 25);
	self.leftnotify[0].alpha = 0.5;
	self.leftnotify[0].sort = 900;
	self.leftnotify[0].hideWhenInMenu = true;
	self.leftnotify[0].archived = false;
	self.leftnotify[1] = newClientHudElem(self);
	self.leftnotify[1].x = -150;
	self.leftnotify[1].y = 155;
	self.leftnotify[1].alignX = "left";
	self.leftnotify[1].horzAlign = "left";
	self.leftnotify[1].alignY = "top";
	self.leftnotify[1]setShader("gradient_bottom", 150, 25);
	self.leftnotify[1].alpha = 0.2;
	self.leftnotify[1].sort = 901;
	self.leftnotify[1].hideWhenInMenu = true;
	self.leftnotify[1].archived = false;
	self.leftnotify[2] = newClientHudElem(self);
	self.leftnotify[2].x = -150;
	self.leftnotify[2].y = 130;
	self.leftnotify[2].alignX = "left";
	self.leftnotify[2].horzAlign = "left";
	self.leftnotify[2].alignY = "top";
	self.leftnotify[2].alpha = 1;
	//self.leftnotify[2]setShader("rank_prestige10", 40, 40);
	self.leftnotify[2].sort = 902;
	self.leftnotify[2].hideWhenInMenu = true;
	self.leftnotify[2].archived = false;
	self.leftnotify[3] = addTextHud(self, -100, 130, 1, "left", "top", 1.4);
	self.leftnotify[3].horzAlign = "left";
	self.leftnotify[3]setText(owner.name);
	self.leftnotify[3].sort = 903;
	self.leftnotify[3].color = self getColorByTeam(owner);
	self.leftnotify[3].hideWhenInMenu = true;
	self.leftnotify[3].archived = false;
	self.leftnotify[4] = addTextHud(self, -100, 145, 1, "left", "top", 1.4);
	self.leftnotify[4].horzAlign = "left";
	self.leftnotify[4]setText(getSplashTitle(splash.name));
	self.leftnotify[4].sort = 904;
	self.leftnotify[4].hideWhenInMenu = true;
	self.leftnotify[4].archived = false;
	self.leftnotify[5] = newClientHudElem(self);
	self.leftnotify[5].x = -150;
	self.leftnotify[5].y = 125;
	self.leftnotify[5].alignX = "left";
	self.leftnotify[5].horzAlign = "left";
	self.leftnotify[5].alignY = "top";
	self.leftnotify[5]setShader("line_horizontal", 150, 1);
	self.leftnotify[5].alpha = 0.3;
	self.leftnotify[5].sort = 905;
	self.leftnotify[5].hideWhenInMenu = true;
	self.leftnotify[5].archived = false;
	self.leftnotify[6] = newClientHudElem(self);
	self.leftnotify[6].x = -150;
	self.leftnotify[6].y = 174;
	self.leftnotify[6].alignX = "left";
	self.leftnotify[6].horzAlign = "left";
	self.leftnotify[6].alignY = "top";
	self.leftnotify[6]setShader("line_horizontal", 150, 1);
	self.leftnotify[6].alpha = 0.3;
	self.leftnotify[6].sort = 906;
	self.leftnotify[6].hideWhenInMenu = true;
	self.leftnotify[6].archived = false;
	for (i = 0;i < self.leftnotify.size && isDefined(self.leftnotify[i]);i++)
		self.leftnotify[i]moveOverTime(0.15);
	self.leftnotify[0].x = 5;
	self.leftnotify[1].x = 5;
	self.leftnotify[2].x = 5;
	self.leftnotify[3].x = 55;
	self.leftnotify[4].x = 55;
	self.leftnotify[5].x = 5;
	self.leftnotify[6].x = 5;
	wait 0.15;
	wait(splash.duration - 0.05);
	for (i = 0;i < self.leftnotify.size;i++)
		self.leftnotify[i]moveOverTime(0.15);
	self.leftnotify[0].x = -150;
	self.leftnotify[1].x = -150;
	self.leftnotify[2].x = -150;
	self.leftnotify[3].x = -100;
	self.leftnotify[4].x = -100;
	self.leftnotify[5].x = -150;
	self.leftnotify[6].x = -150;
	wait 5;
	self destroyPlayerCard();
	self.leftnotifyinprogress = false;
	wait 0.05;

}
getColorByTeam(owner) {
	if (owner.team == self.team)
		return (0, 0.54, 1);
	return (1, 0.55, 0);

}
destroyPlayerCard() {
	if (!isDefined(self.leftnotify) || !self.leftnotify.size)
		return;
	for (i = 0;i < self.leftnotify.size;i++)
		self.leftnotify[i]destroy();
	self.leftnotify = [];

}
stringToFloat(stringVal) {
	if (isDefined(stringVal)) {
		floatElements = strtok(stringVal, ".");
		floatVal = int(floatElements[0]);
		if (isDefined(floatElements[1])) {
			modifier = 1;
			for (i = 0;i < floatElements[1].size;i++)
				modifier *= 0.1;
			floatVal += int(floatElements[1]) * modifier;

		}
		return floatVal;

	}
	return 1.5;

}
fontPulse(player) {
	self notify("fontPulse");
	self endon("fontPulse");
	player endon("disconnect");
	player endon("joined_team");
	player endon("joined_spectators");
	scaleRange = self.maxFontScale - self.baseFontScale;
	while (self.fontScale < self.maxFontScale) {
		self.fontScale = min(self.maxFontScale, self.fontScale + (scaleRange / self.inFrames));
		wait 0.05;

	}
	while (self.fontScale > self.baseFontScale) {
		self.fontScale = max(self.baseFontScale, self.fontScale - (scaleRange / self.outFrames));
		wait 0.05;

	}

}
addTextHud(who, x, y, alpha, alignX, alignY, fontScale) {
	if (isPlayer(who))
		hud = newClientHudElem(who);
	else
		hud = newHudElem();
	hud.x = x;
	hud.y = y;
	hud.alpha = alpha;
	hud.alignX = alignX;
	hud.alignY = alignY;
	hud.fontScale = fontScale;
	return hud;

}
waittill_notify_ent_or_timeout(ent, msg, timer) {
	if (isDefined(ent) && isDefined(msg))
		ent endon(msg);
	wait(timer);

}

moveasidetext(player) {
	player endon("disconnect");
	while (isdefined(self)) {
		if (!isdefined(player))
			return;

		player waittill("splashwaitting");
		if (isdefined(self)) {
			self moveovertime(.2);
			self.x = self.x + 75;
			if (self.x > 300) {
				self fadeovertime(.2);
				self.alpha = 0;
			}

			//self fontscaleovertime(.1,1.4);  //bugged
		}
	}
}

moveasideshader(player) {
	player endon("disconnect");
	while (isdefined(self)) {
		if (!isdefined(player))
			return;

		player waittill("splashwaitting");
		if (isdefined(self)) {
			self moveovertime(.2);
			self.x = self.x + 75;
			self scaleovertime(.2, 50, 50);
			if (self.x > 300) {
				self fadeovertime(.2);
				self.alpha = 0;
			}

		}
	}
}

fontscaleovertime(time, value) {
	if (!isdefined(time) || !isdefined(value) || value > 2.4 || value < 1.4)
		return;

	if (value > self.fontscale) {
		diff = value - self.fontscale;
		increment = diff / time * 100;
		while (self.fontscale < value) {
			self.fontscale += increment;
			wait.01;
		}
	}

	if (value < self.fontscale) {
		diff = self.fontscale - value;
		increment = diff / time * 100;
		while (self.fontscale > value) {
			self.fontscale -= increment;
			wait.01;
		}
	}
}

getTitleText(type) {
	switch (type) {
	case "headshot_splash":
		return "Headshot!";

	case "assistedsuicide":
		return "Assisted Suicide!";

	case "longshot":
		return "Longshot!";

	case "avenger":
		return "Avenger!";

	case "defender":
		return "Rescuer!";

	case "posthumous":
		return "Afterlife!";

	case "revenge":
		return "Payback!";

	case "doublekill":
		return "Double-Kill!";

	case "triplekill":
		return "Triple-Kill!";

	case "multikill":
		return "Multi-Kill!";

	case "firstblood":
		return "First Blood!";

	case "buzzkill":
		return "Buzzkill!";

	case "comeback":
		return "Comeback!";

	case "knifethrow":
		return "Knife Throw!";

	case "callout_3xkill":
		return "Triple-Kill!";

	case "callout_3xpluskill":
		return "Multi-Kill!";

	case "callout_firstblood":
		return "First Blood!";

	case "one_shot_kill":
		return "One Shot Kill!";

	case "king_slayer":
		return "King Slayer!";

	case "puncture":
		return "Puncture!";

	case "bloodthirsty":
		return "Bloodthirsty!";

	case "neardeath":
		return "NearDeath kill";

	case "pointblank":
		return "Point Blank";

	case "merciless":
		return "Merciless Kill";

	default:
		return "";
	}
}
/*----------Crazy utility ----------*/
underScorePopup(string, hudColor, glowAlpha) {
	self endon("disconnect");
	self endon("joined_team");
	self endon("joined_spectators");
	while (isDefined(self.underScoreInProgress) && self.underScoreInProgress)
		wait 0.05;
	self.underScoreInProgress = true;
	if (!isDefined(hudColor))
		hudColor = (1, 1, 1);
	if (!isDefined(glowAlpha))
		glowAlpha = 0;
	if (!isDefined(self._scorePopup)) {
		self._scorePopup = newClientHudElem(self);
		self._scorePopup.horzAlign = "center";
		self._scorePopup.vertAlign = "middle";
		self._scorePopup.alignX = "left";
		self._scorePopup.alignY = "middle";
		self._scorePopup.y = -30;
		self._scorePopup.font = "objective";
		self._scorePopup.fontscale = 1.4;
		self._scorePopup.archived = false;
		self._scorePopup.hideWhenInMenu = true;
		self._scorePopup.sort = 9999;

	}
	self._scorePopup.x = -50;
	self._scorePopup.alpha = 0;
	self._scorePopup.color = hudColor;
	self._scorePopup.glowColor = hudColor;
	self._scorePopup.glowAlpha = glowAlpha;
	self._scorePopup setText(string);
	self._scorePopup fadeOverTime(0.5);
	self._scorePopup.alpha = 1;
	self._scorePopup moveOverTime(0.75);
	self._scorePopup.x = 35;
	wait 1.5;
	self._scorePopup fadeOverTime(0.75);
	self._scorePopup.alpha = 0;
	wait 0.2;
	self.underScoreInProgress = false;

}
getWeaponClass(weapon) {
	tokens = strTok(weapon, "_")[0];
	weaponClass = tableLookUp("mp/statsTable.csv", 4, tokens, 2);
	return weaponClass;

}
