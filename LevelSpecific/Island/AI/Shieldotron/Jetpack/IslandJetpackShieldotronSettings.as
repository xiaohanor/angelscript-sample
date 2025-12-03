class UIslandJetpackShieldotronSettings : UHazeComposableSettings
{

	// Default damage to JetpackShieldotron from player bullet
	UPROPERTY(Category = "Damage")
	float DefaultDamage = 0.027;

	// General attack settings

	UPROPERTY(Category = "Combat|GeneralAttackSettings")
	float GeneralAttackMinCooldown = 0.0;

	UPROPERTY(Category = "Combat|GeneralAttackSettings")
	float GeneralAttackMaxCooldown = 0.2;

	// Rocket Attack

	UPROPERTY(Category = "Combat|RocketAttack")
	float RocketAttackMinRange = 100.0;		

	UPROPERTY(Category = "Combat|RocketAttack")
	float RocketAttackMaxRange = 7000.0;

	UPROPERTY(Category = "Rocket Attack")
	int RocketAttackBurstNumber = 3;

	// Orb Attack

	UPROPERTY(Category = "Combat|OrbAttack")
	float OrbAttackMinRange = 100.0;		

	UPROPERTY(Category = "Combat|OrbAttack")
	float OrbAttackMaxRange = 7000.0;

	UPROPERTY(Category = "Combat|OrbAttack")
	int OrbAttackBurstNumber = 1;

	UPROPERTY(Category = "Combat|OrbAttack")
	float OrbProjectileExpirationTime = 6.0;
	
	// When past target remaining expiration time will be truncated to this value
	UPROPERTY(Category = "Combat|OrbAttack")
	float OrbProjectileReducedExpirationTime = 0.5;

	UPROPERTY(Category = "Combat|OrbAttack")
	float OrbProjectileLaunchSpeed = 1500.0;
	
	UPROPERTY(Category = "Combat|OrbAttack")
	float OrbProjectileSpeed = 1000.0;

	// Homing steering force
	UPROPERTY(Category = "Combat|OrbAttack")
	float OrbHomingStrength = 40.0;

	// Homing max steering speed (prevents oscillation)
	UPROPERTY(Category = "Combat|OrbAttack")
	float OrbProjectileMaxPlanarHomingSpeed = 2000.0;

	UPROPERTY(Category = "Combat|OrbAttack")
	float OrbScaleTime = 0.1;

	// Lemon Attack
	
	// Tell 'em to suck a lemon!
	UPROPERTY(Category = "Combat|LemonAttack")
	float LemonAttackDamage = 0.5;

	UPROPERTY(Category = "Combat|LemonAttack")
	float LemonAttackMinRange = 100.0;

	UPROPERTY(Category = "Combat|LemonAttack")
	float LemonAttackMaxRange = 5000.0;

	UPROPERTY(Category = "Combat|LemonAttack")
	float LemonAttackDuration = 2.0;

	UPROPERTY(Category = "Combat|LemonAttack")
	int LemonAttackBurstNumber = 40;

	UPROPERTY(Category = "Combat|LemonAttack")
	float LemonAttackCooldown = 0.2;
	
	UPROPERTY(Category = "Combat|LemonAttack")
	float LemonAttackProjectileSpeed = 2500;

	UPROPERTY(Category = "Combat|LemonAttack")
	EGentlemanCost LemonAttackGentlemanCost = EGentlemanCost::Small;


	// Moon Attack

	UPROPERTY(Category = "Combat|MoonAttack")
	float MoonAttackMinRange = 100.0;

	UPROPERTY(Category = "Combat|MoonAttack")
	float MoonAttackMaxRange = 7000.0;

	UPROPERTY(Category = "Combat|MoonAttack")
	float MoonAttackDuration = 1.0;

	UPROPERTY(Category = "Combat|MoonAttack")
	int MoonAttackBurstNumber = 10;

	UPROPERTY(Category = "Combat|MoonAttack")
	float MoonAttackCooldown = 6.0;
	
	UPROPERTY(Category = "Combat|MoonAttack")
	float MoonAttackProjectileSpeed = 1500;

	UPROPERTY(Category = "Combat|MoonAttack")
	EGentlemanCost MoonAttackGentlemanCost = EGentlemanCost::Small;


	// Jetpack Scenepoint Entry

	UPROPERTY(Category = "ScenepointEntry")
	float ScenepointEntryMoveSpeed = 500.0;
	
	// Jetpack

	UPROPERTY(Category = "Health")
	bool bHasDestroyableJetpack = false;
	
	UPROPERTY(Category = "Health")
	int JetpackHealthNumHits = 20;
	
	
	UPROPERTY(Category = "HoldWaypoint")
	float HoldWaypointMoveSpeed = 1000;

	// If target is out of range, try to find another waypoint immediately.
	UPROPERTY(Category = "HoldWaypoint")
	float HoldWaypointMaxRange = 3000;

	UPROPERTY(Category = "EngageAttackPosition")
	float EngageAttackPositionCooldownMin = 0.25;

	UPROPERTY(Category = "EngageAttackPosition")
	float EngageAttackPositionCooldownMax = 0.75;


 	UPROPERTY(Category = "Chase")
	float HoverChaseMinRange = 1000;

	UPROPERTY(Category = "Chase")
	float HoverChaseMoveSpeed = 2000;

	UPROPERTY(Category = "Chase")
	float HoverChaseHeight = 500;


	UPROPERTY(Category = "Drift")
	float HoverDriftMoveSpeed = 400;

	UPROPERTY(Category = "Drift")
	float HoverDriftCooldownMin = 0.1;

	UPROPERTY(Category = "Drift")
	float HoverDriftCooldownMax = 0.5;

	UPROPERTY(Category = "Drift")
	float HoverDriftMaxHeight = 1200;


	UPROPERTY(Category = "Drift")
	float HoverAvoidWallsDistance = 200;

	UPROPERTY(Category = "Drift")
	float HoverAvoidWallsMoveSpeed = 500;

	UPROPERTY(Category = "Drift")
	float HoverAvoidWallsDuration = 1.0;


	UPROPERTY(Category = "HoverAtScenepoint")
	float HoverAtScenepointMoveSpeed = 500;

	UPROPERTY(Category = "HoverAtScenepoint")
	float HoverAtScenepointCooldown = 1.0;


	UPROPERTY(Category = "Bobbing")
	float BobbingAmplitude = 50;

	UPROPERTY(Category = "Bobbing")
	float BobbingMinInterval = 1.5;

	UPROPERTY(Category = "Bobbing")
	float BobbingMaxInterval = 2.5;

}
