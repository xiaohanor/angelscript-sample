class USummitKnightSettings : UHazeComposableSettings
{
	UPROPERTY(Category = "Intro")
	float IntroDuration = 1.0;

	UPROPERTY(Category = "Progression")
	float HealthThresholdStarts0 = 0.95;

	UPROPERTY(Category = "Progression")
	float HealthThresholdStartToSwoop = 0.95;

	UPROPERTY(Category = "Progression")
	float HealthThresholdStartSlam = 0.85;

	UPROPERTY(Category = "Progression")
	float HealthThresholdMainSlam = 0.55;

	UPROPERTY(Category = "Progression")
	float HealthThresholdStartToCircling = 0.8;

	UPROPERTY(Category = "Progression")
	float HealthThresholdMainToEndCircling = 0.2;


	UPROPERTY(Category = "Circling")
	float CirclingIntroDuration = 0.0; // 0.0 means we use animation duration

	UPROPERTY(Category = "Circling")
	float CirclingIntroSpeed = 4000.0;

	UPROPERTY(Category = "Circling")
	float CirclingOutsideDistance = 3000.0;

	UPROPERTY(Category = "Circling")
	float CirclingSpeed = 5000.0;


	UPROPERTY(Category = "SwoopAcrossArena")
	float SwoopTelegraphDuration = 0.0; // 0.0 means we use animation duration 

	UPROPERTY(Category = "SwoopAcrossArena")
	float SwoopTraversalDuration = 0.0; // 0.0 means we use animation duration 

	UPROPERTY(Category = "SwoopAcrossArena")
	float SwoopRecoveryDuration = 0.0; // 0.0 means we use animation duration 

	UPROPERTY(Category = "SwoopAcrossArena")
	float SwoopHitPlayerRadius = 1000.0; 

	UPROPERTY(Category = "SwoopAcrossArena")
	float SwoopAccidentalTargetForVOStartRadius = 1500.0; 

	UPROPERTY(Category = "SwoopAcrossArena")
	float SwoopAccidentalTargetForVOEndRadius = 3000.0; 

	UPROPERTY(Category = "SwoopAcrossArena")
	float SwoopHitPlayerDamage = 0.01;  

	UPROPERTY(Category = "SwoopAcrossArena")
	float SwoopHitPlayerStumbleDistance = 2000.0;  

	UPROPERTY(Category = "SwoopAcrossArena")
	int SwoopNumObstacles = 4;  

	UPROPERTY(Category = "SwoopAcrossArena")
	float SwoopObstacleMinRange = 1500.0;  

	UPROPERTY(Category = "SwoopAcrossArena")
	float SwoopObstacleMaxRange = 3000.0;  

	UPROPERTY(Category = "SwoopAcrossArena")
	float SwoopObstacleArenaEdgeClearance = 1000.0;  


	// Play this much of hurt reaction before launching into slam if appropriate
	UPROPERTY(Category = "SlamAttack")
	float SlamInitialHurtDuration = 1.1; 

	UPROPERTY(Category = "SlamAttack")
	float SlamEnterTelegraphDuration = 0.0; // 0.0 means we use animation duration 

	UPROPERTY(Category = "SlamAttack")
	float SlamEnterAnticipationDuration = 0.0; // 0.0 means we use animation duration 

	UPROPERTY(Category = "SlamAttack")
	float SlamEnterActionDuration = 0.0; // 0.0 means we use animation duration 

	UPROPERTY(Category = "SlamAttack")
	float SlamEnterRecoveryDuration = 0.0; // 0.0 means we use animation duration 

	UPROPERTY(Category = "SlamAttack")
	float SlamMhDuration = 0.1;

	UPROPERTY(Category = "SlamAttack")
	float SlamExitDuration = 0.0; // 0.0 means we use animation duration 

	UPROPERTY(Category = "SlamAttack")
	float SlamEnterHeight = 3000.0;

	UPROPERTY(Category = "SlamAttack")
	float SlamStunDuration = 0.0; // 0.0 means we use animation duration 

	UPROPERTY(Category = "SlamAttack")
	float SlamExitStunDuration = 0.0; // 0.0 means we use animation duration 

	UPROPERTY(Category = "SlamAttack")
	float SlamShockwaveStartRadius = 100.0;

	UPROPERTY(Category = "SlamAttack")
	float SlamShockwaveEndRadius = 5000.0;

	UPROPERTY(Category = "SlamAttack")
	float SlamShockwaveExpansionSpeed = 2400.0;

	UPROPERTY(Category = "SlamAttack")
	float SlamShockwaveDamage = 0.8;

	UPROPERTY(Category = "SlamAttack")
	float SlamShockwaveDamageHeight = 100.0;

	UPROPERTY(Category = "SlamAttack")
	float SlamShockwaveDamageWidth = 200.0;

	UPROPERTY(Category = "SlamAttack")
	float SlamShockwaveStumbleForce = 2000.0;

	// Delay after shockwave start until obstacles start spawning
	UPROPERTY(Category = "SlamAttack")
	float SlamSummonObstaclesDelay = 0.8; 

	// Duration during which obstacles spawn
	UPROPERTY(Category = "SlamAttack")
	float SlamSummonObstaclesDuration = 0.1; 

	UPROPERTY(Category = "SwoopAcrossArena")
	int SlamNumObstacles = 12;  

	UPROPERTY(Category = "SwoopAcrossArena")
	int MainSlamNumObstacles = 36;  

	UPROPERTY(Category = "SwoopAcrossArena")
	int EndSlamNumObstacles = 12;  

	UPROPERTY(Category = "SlamAttack")
	float SlamCooldown = 60.0;


	UPROPERTY(Category = "SmashGround")
	float SmashGroundTelegraphDuration = 0.0; // 0.0 means we use animation duration 

	UPROPERTY(Category = "SmashGround")
	float SmashGroundAnticipationDuration = 0.0; // 0.0 means we use animation duration 

	UPROPERTY(Category = "SmashGround")
	float SmashGroundActionDuration = 0.0; // 0.0 means we use animation duration 

	UPROPERTY(Category = "SmashGround")
	float SmashGroundRecoveryDuration = 0.0; // 0.0 means we use animation duration 

	UPROPERTY(Category = "SmashGround")
	float SmashGroundTurnDuration = 2.0;

	UPROPERTY(Category = "SmashGround")
	float SmashGroundReachToTarget = 4000.0;

	UPROPERTY(Category = "SmashGround")
	float SmashGroundTipRadius = 200.0;

	UPROPERTY(Category = "SmashGround")
	float SmashGroundBaseRadius = 600.0;

	UPROPERTY(Category = "SmashGround")
	float SmashGroundHitOuterBuffer = 500.0;

	UPROPERTY(Category = "SmashGround")
	float SmashGroundDamage = 1.0;

	UPROPERTY(Category = "TakeDamage")
	float SmashGroundStumbleDistance = 2000.0;


	UPROPERTY(Category = "TakeDamage")
	float HurtReactionDuration = 0.9;

	UPROPERTY(Category = "TakeDamage")
	float TailDragonHitCamSettingsBlendInTime = 2.0;

	UPROPERTY(Category = "TakeDamage")
	float TailDragonHitCamSettingsDuration = 0.2;

	UPROPERTY(Category = "TakeDamage")
	float TailDragonHitCamSettingsBlendOutTime = -1.0; // -1.0 uses default blend time

	UPROPERTY(Category = "TakeDamage")
	float SmashCrystalStunnedDuration = 1.1;

	UPROPERTY(Category = "TakeDamage")
	float SmashCrystalPushedDistance = 1500.0;

	UPROPERTY(Category = "TakeDamage")
	float SmashCrystalPushedForce = 5000.0;

	UPROPERTY(Category = "TakeDamage")
	float SmashCrystalPlayerStumbleDistance = 3000.0;

	UPROPERTY(Category = "TakeDamage")
	float SmashCrystalPlayerStumbleDuration = 1.0;

	UPROPERTY(Category = "TakeDamage")
	float SmashCrystalDamage = 0.047;

	UPROPERTY(Category = "TakeDamage")
	float AcidDamageFactor = 0.006;


	UPROPERTY(Category = "AlmostDead")
	float AlmostDeadIntroSpeed = 4000.0;
	
	UPROPERTY(Category = "AlmostDead")
	float AlmostDeadIntroDurationAdjustment = -1.0;


	UPROPERTY(Category = "Obstacles")
	USummitMeltSettings MetalObstacleMeltSettings = KnightMetalObstacleMeltSettings;


	UPROPERTY(Category = "CircleDodge")
	int CircleDodgeAfterNumSwoops = 2;

	UPROPERTY(Category = "CircleDodge")
	float CircleDodgeAfterSwoopTime = 6.0;

	UPROPERTY(Category = "CircleDodge")
	float CircleDodgeRange = 3000.0;

	UPROPERTY(Category = "CircleDodge")
	float CircleDodgeDuration = 2.0;

	UPROPERTY(Category = "CircleDodge")
	float CircleDodgeCooldown = 4.0;

	UPROPERTY(Category = "CircleDodge")
	float CircleDodgeSpeed = 5000.0;

	UPROPERTY(Category = "CircleDodge")
	float CircleDodgeInsideRadius = 800.0;


	UPROPERTY(Category = "SummonObstacles")
	float SummonObstaclesTelegraphDuration = 0.0; // 0.0 means we use animation duration

	UPROPERTY(Category = "SummonObstacles")
	float SummonObstaclesAnticipationDuration = 0.0; // 0.0 means we use animation duration

	UPROPERTY(Category = "SummonObstacles")
	float SummonObstaclesActionDuration = 0.0; // 0.0 means we use animation duration

	UPROPERTY(Category = "SummonObstacles")
	float SummonObstaclesRecoverDuration = 0.0; // 0.0 means we use animation duration

	UPROPERTY(Category = "SummonObstacles")
	int SummonObstaclesNumber = 24;


	UPROPERTY(Category = "LargeAreaStrike")
	float LargeAreaStrikeTelegraphDuration = 0.0; // 0.0 means we use animation duration

	UPROPERTY(Category = "LargeAreaStrike")
	float LargeAreaStrikeAnticipationDuration = 0.0; // 0.0 means we use animation duration

	UPROPERTY(Category = "LargeAreaStrike")
	float LargeAreaStrikeActionDuration = 0.0; // 0.0 means we use animation duration

	UPROPERTY(Category = "LargeAreaStrike")
	float LargeAreaStrikeRecoverDuration = 0.0; // 0.0 means we use animation duration


	UPROPERTY(Category = "MeteorShower")
	int MeteorShowerNumber = 24;

	UPROPERTY(Category = "MeteorShower")
	float MeteorShowerTelegraphDuration = 0.0; // 0.0 means we use animation duration

	UPROPERTY(Category = "MeteorShower")
	float MeteorShowerAnticipationDuration = 0.0; // 0.0 means we use animation duration

	UPROPERTY(Category = "MeteorShower")
	float MeteorShowerAttackDuration = 0.0; // 0.0 means we use animation duration

	UPROPERTY(Category = "MeteorShower")
	float MeteorShowerRecoverDuration = 0.0; // 0.0 means we use animation duration

	UPROPERTY(Category = "MeteorShower")
	float MeteorShowerFlightDuration = 1.5;

	UPROPERTY(Category = "MeteorShower")
	float MeteorShowerSteepness = 3000.0;

	UPROPERTY(Category = "MeteorShower")
	float MeteorShowerIgnitionDuration = 1.0;

	UPROPERTY(Category = "MeteorShower")
	float MeteorShowerCooldownDuration = 10.0;

	UPROPERTY(Category = "MeteorShower")
	bool MeteorShowerTurnTowardsNextTargetLocation = false;

	UPROPERTY(Category = "MeteorShower")
	float MeteorShowerLandDamageRadius = 600.0;

	UPROPERTY(Category = "MeteorShower")
	float MeteorShowerLandDamage = 0.2;

	UPROPERTY(Category = "MeteorShower")
	float MeteorShowerLandStumbleDistance = 800.0;

	UPROPERTY(Category = "MeteorShower")
	float MeteorShowerDamagePerSecond = 1.0;


	UPROPERTY(Category = "HomingFireballs")
	float HomingFireballsTelegraphDuration = 0.0; // 0.0 means we use animation duration

	UPROPERTY(Category = "HomingFireballs")
	float HomingFireballsAnticipationDuration = 0.0; // 0.0 means we use animation duration

	UPROPERTY(Category = "HomingFireballs")
	float HomingFireballsAttackDuration = 0.0; // 0.0 means we use animation duration

	UPROPERTY(Category = "HomingFireballs")
	float HomingFireballsRecoverDuration = 0.0; // 0.0 means we use animation duration

	UPROPERTY(Category = "HomingFireballs")
	float HomingFireballsLaunchInterval = 0.075;

	UPROPERTY(Category = "HomingFireballs")
	float HomingFireballsFlightDuration = 0.7;

	UPROPERTY(Category = "HomingFireballs")
	float HomingFireballsSteepness = 5000.0;

	UPROPERTY(Category = "HomingFireballs")
	float HomingFireballsDamage = 0.9;

	UPROPERTY(Category = "HomingFireballs")
	float HomingFireballsDamageRadius = 200.0;

	UPROPERTY(Category = "HomingFireballs")
	float HomingFireballsDamageDuration = 0.8;

	UPROPERTY(Category = "HomingFireballs")
	float HomingFireballsStumbleDistance = 1500.0;


	UPROPERTY(Category = "RotatingCrystal")
	float RotatingCrystalTelegraphDuration = 0.0; // 0.0 means we use animation duration

	UPROPERTY(Category = "RotatingCrystal")
	float RotatingCrystalAnticipationDuration = 0.0; // 0.0 means we use animation duration

	UPROPERTY(Category = "RotatingCrystal")
	float RotatingCrystalAttackDuration = 0.0; // 0.0 means we use animation duration

	UPROPERTY(Category = "RotatingCrystal")
	float RotatingCrystalRecoverDuration = 0.0; // 0.0 means we use animation duration

	UPROPERTY(Category = "RotatingCrystal")
	bool bRotatingCrystalWaitForExpiration = false;

	UPROPERTY(Category = "RotatingCrystal")
	int RotatingCrystalNumber = 1;

	UPROPERTY(Category = "RotatingCrystal")
	float RotatingCrystalLaunchSpreadDegrees = 120.0;

	UPROPERTY(Category = "RotatingCrystal")
	float RotatingCrystalStrikeDuration = 4.0;

	UPROPERTY(Category = "RotatingCrystal")
	float RotatingCrystalPlayerDamage = 0.6;

	UPROPERTY(Category = "RotatingCrystal")
	float RotatingLaunchSteepness = 2000.0;

	UPROPERTY(Category = "RotatingCrystal")
	float RotatingStrikeSteepness = 400.0;

	UPROPERTY(Category = "RotatingCrystal")
	float RotatingStrikeLength = 4000.0;


	UPROPERTY(Category = "CrystalTrail")
	float CrystalTrailTelegraphDuration = 0.0; // 0.0 means we use animation duration

	UPROPERTY(Category = "CrystalTrail")
	float CrystalTrailAnticipationDuration = 0.0; // 0.0 means we use animation duration

	UPROPERTY(Category = "CrystalTrail")
	float CrystalTrailActionDuration = 0.0; // 0.0 means we use animation duration

	UPROPERTY(Category = "CrystalTrail")
	float CrystalTrailRecoverDuration = 0.0; // 0.0 means we use animation duration

	UPROPERTY(Category = "CrystalTrail")
	bool bCrystalTrailCanSmash = false;

	UPROPERTY(Category = "CrystalTrail")
	int CrystalTrailNumber = 4;

	UPROPERTY(Category = "RotatingCrystal")
	float CrystalTrailSpreadDegrees = 10.0;

	UPROPERTY(Category = "CrystalTrail")
	float CrystalTrailReleaseSpeed = 4000.0;

	UPROPERTY(Category = "CrystalTrail")
	float CrystalTrailReleaseSteepness = 400.0;

	UPROPERTY(Category = "CrystalTrail")
	float CrystalTrailFlightDuration = 0.0;

	UPROPERTY(Category = "CrystalTrail")
	float CrystalTrailMaxGroundDuration = 8.0;

	UPROPERTY(Category = "CrystalTrail")
	float CrystalTrailLandSteepness = 4000.0;

	UPROPERTY(Category = "CrystalTrail")
	float CrystalTrailLandDistance = 3500.0;

	UPROPERTY(Category = "CrystalTrail")
	float CrystalTrailLandPause = 1.0;

	UPROPERTY(Category = "CrystalTrail")
	float CrystalTrailMoveSpeedMax = 1800.0;

	UPROPERTY(Category = "CrystalTrail")
	float CrystalTrailHomingRange = 6000.0;

	UPROPERTY(Category = "CrystalTrail")
	float CrystalTrailHomingEndRange = 1000.0;

	UPROPERTY(Category = "CrystalTrail")
	float CrystalTrailHomingMaxNearDuration = 1.0;

	UPROPERTY(Category = "CrystalTrail")
	float CrystalTrailHomingNearRange = 1000.0;

	UPROPERTY(Category = "CrystalTrail")
	int CrystalTrailAccelerationDuration = 3.0;

	UPROPERTY(Category = "CrystalTrail")
	int CrystalTrailSegmentsNumber = 0; // 20

	UPROPERTY(Category = "CrystalTrail")
	float CrystalTrailSegmentGrowTime = 0.2;

	UPROPERTY(Category = "CrystalTrail")
	float CrystalTrailSegmentShrinkTime = 1.5;

	UPROPERTY(Category = "CrystalTrail")
	int CrystalTrailSmashSegmentWidth = 2;

	UPROPERTY(Category = "CrystalTrail")
	float CrystalTrailHitRadius = 300.0;

	UPROPERTY(Category = "CrystalTrail")
	float CrystalTrailHitDamage = 0.9;

	UPROPERTY(Category = "CrystalTrail")
	float CrystalTrailStumbleDistance = 1000.0;


	UPROPERTY(Category = "CrystalDivider")
	int CrystalDividerMoveSpeed = 10000;

	UPROPERTY(Category = "CrystalDivider")
	int CrystalDividerAccelerationDuration = 1.0;

	UPROPERTY(Category = "CrystalDivider")
	float CrystalDividerSegmentGrowTime = 0.5;


	UPROPERTY(Category = "CrystalDivider")
	int CrystalDividerSmashSegmentWidth = 2;

	UPROPERTY(Category = "CrystalDivider")
	float CrystalDividerHitRadius = 200.0;

	UPROPERTY(Category = "CrystalDivider")
	float CrystalDividerStumbleDistance = 2400.0;

	UPROPERTY(Category = "CrystalDivider")
	float CrystalDividerExpirationDuration = 2.0;

	UPROPERTY(Category = "CrystalDivider")
	int CrystalDividerMaxSegments = 60;




	UPROPERTY(Category = "AreaDenialFireball")
	float AreaDenialFireballTelegraphDuration = 0.0; // 0.0 means we use animation duration

	UPROPERTY(Category = "AreaDenialFireball")
	float AreaDenialFireballAnticipationDuration = 0.0; // 0.0 means we use animation duration

	UPROPERTY(Category = "AreaDenialFireball")
	float AreaDenialFireballAttackDuration = 0.0; // 0.0 means we use animation duration

	UPROPERTY(Category = "AreaDenialFireball")
	float AreaDenialFireballRecoverDuration = 0.0; // 0.0 means we use animation duration

	UPROPERTY(Category = "AreaDenialFireball")
	float AreaDenialFireballFlightDuration = 1.5;

	UPROPERTY(Category = "AreaDenialFireball")
	float AreaDenialFireballSteepness = 3000.0;

	// Time from last ball landing until the whole mess explodes
	UPROPERTY(Category = "AreaDenialFireball")
	float AreaDenialFireballIgnitionDuration = 1.0;

	UPROPERTY(Category = "AreaDenialFireball")
	float AreaDenialFireballCooldownDuration = 10.0;

	UPROPERTY(Category = "AreaDenialFireball")
	bool AreaDenialFireballTurnTowardsNextTargetLocation = false;

	UPROPERTY(Category = "AreaDenialFireball")
	float AreaDenialFireballLandDamageRadius = 1000.0;

	UPROPERTY(Category = "AreaDenialFireball")
	float AreaDenialFireballLandDamage = 0.5;

	UPROPERTY(Category = "AreaDenialFireball")
	float AreaDenialFireballLandStumbleDistance = 400.0;

	UPROPERTY(Category = "AreaDenialFireball")
	float AreaDenialFireballDamagePerSecond = 1.0;


	UPROPERTY(Category = "CrystalCage")
	float CrystalCageTelegraphDuration = 0.0; // 0.0 means we use animation duration

	UPROPERTY(Category = "CrystalCage")
	float CrystalCageAnticipationDuration = 0.0; // 0.0 means we use animation duration

	UPROPERTY(Category = "CrystalCage")
	float CrystalCageActionDuration = 0.0; // 0.0 means we use animation duration

	UPROPERTY(Category = "CrystalCage")
	float CrystalCageRecoverDuration = 0.0; // 0.0 means we use animation duration

	UPROPERTY(Category = "CrystalCage")
	float CrystalCageRadius= 1500.0;

	UPROPERTY(Category = "CrystalCage")
	float CrystalCageSpreadDuration = 1.0;

	UPROPERTY(Category = "CrystalCage")
	float CrystalCageSegmentGrowthDuration = 0.5;

	UPROPERTY(Category = "CrystalCage")
	int CrystalCageSmashSegmentsHalfWidth = 3;

	UPROPERTY(Category = "CrystalCage")
	int CrystalCageSmashedExpirationDuration = 5.0;

	UPROPERTY(Category = "CrystalCage")
	int CrystalCageExpirationDuration = 30.0;


	UPROPERTY(Category = "CrystalWall")
	float CrystalWallTelegraphDuration = 0.0; // 0.0 means we use animation duration

	UPROPERTY(Category = "CrystalWall")
	float CrystalWallAnticipationDuration = 0.0; // 0.0 means we use animation duration

	UPROPERTY(Category = "CrystalWall")
	float CrystalWallAttackDuration = 0.0; // 0.0 means we use animation duration

	UPROPERTY(Category = "CrystalWall")
	float CrystalWallRecoverDuration = 0.0; // 0.0 means we use animation duration

	UPROPERTY(Category = "CrystalWall")
	int CrystalWallSegmentsHalfWidth = 6;

	UPROPERTY(Category = "CrystalWall")
	bool bCrystalWallWaitForExpiration = false;

	UPROPERTY(Category = "CrystalWall")
	float CrystalWallMoveSpeedTarget = 2500.0;

	UPROPERTY(Category = "CrystalWall")
	float CrystalWallMoveSpeedStart = 0.0;

	UPROPERTY(Category = "CrystalWall")
	float CrystalWallSpeedUpDuration = 5.0;

	UPROPERTY(Category = "CrystalWall")
	int CrystalWallSmashSegmentWidth = 3;

	UPROPERTY(Category = "CrystalWall")
	float CrystalWallSegmentSpreadDuration = 2.0;

	UPROPERTY(Category = "CrystalWall")
	float CrystalWallCurvature = 890.0;

	UPROPERTY(Category = "CrystalWall")
	float CrystalWallDragonStumbleDistance = 4000.0;

	UPROPERTY(Category = "CrystalWall")
	float CrystalWallPlayerDamage = 0.9;


	UPROPERTY(Category = "MetalWall")
	float MetalWallTelegraphDuration = 0.0; // 0.0 means we use animation duration

	UPROPERTY(Category = "MetalWall")
	float MetalWallAnticipationDuration = 0.0; // 0.0 means we use animation duration

	UPROPERTY(Category = "MetalWall")
	float MetalWallAttackDuration = 0.0; // 0.0 means we use animation duration

	UPROPERTY(Category = "MetalWall")
	float MetalWallRecoverDuration = 0.0; // 0.0 means we use animation duration

	UPROPERTY(Category = "MetalWall")
	bool bMetalWallWaitForExpiration = false;

	UPROPERTY(Category = "MetalWall")
	float MetalWallMoveSpeedTarget = 2500.0;

	UPROPERTY(Category = "MetalWall")
	float MetalWallDeployProbeRadius = 3000.0;

	UPROPERTY(Category = "MetalWall")
	float MetalWallMoveSpeedStart = 0.0;

	UPROPERTY(Category = "MetalWall")
	float MetalWallSpeedUpDuration = 5.0;

	UPROPERTY(Category = "MetalWall")
	int MetalWallSegmentWidthNumber = 10;

	UPROPERTY(Category = "MetalWall")
	float MetalWallDepthAtEdges = -200.0;

	UPROPERTY(Category = "MetalWall")
	float MetalWallSegmentDeployDuration = 0.8;

	UPROPERTY(Category = "MetalWall")
	float MetalWallSegmentSpreadDuration = 1.2;

	UPROPERTY(Category = "MetalWall")
	float MetalWallDragonStumbleDistance = 3000.0;

	UPROPERTY(Category = "MetalWall")
	float MetalWallPlayerDamage = 0.9;
	

	UPROPERTY(Category = "PathEndSmash")
	float PathEndSmashTelegraphDuration = 3.0; // 0.0 means we use animation duration

	UPROPERTY(Category = "PathEndSmash")
	float PathEndSmashAnticipationDuration = 0.0; // 0.0 means we use animation duration

	UPROPERTY(Category = "PathEndSmash")
	float PathEndSmashActionDuration = 0.0; // 0.0 means we use animation duration

	UPROPERTY(Category = "PathEndSmash")
	float PathEndSmashRecoverDuration = 0.0; // 0.0 means we use animation duration

	UPROPERTY(Category = "PathEndSmash")
	float PathEndSmashHitRadius = 500.0; 

	UPROPERTY(Category = "PathEndSmash")
	FVector PathEndSmashSlideForwardOffset = FVector(5000.0, 0.0, 0.0);

	
	UPROPERTY(Category = "Shockwave")
	float ShockwaveTelegraphDuration = 0.0; // 0.0 means we use animation duration

	UPROPERTY(Category = "Shockwave")
	float ShockwaveAnticipationDuration = 0.0; // 0.0 means we use animation duration

	UPROPERTY(Category = "Shockwave")
	float ShockwaveActionDuration = 0.0; // 0.0 means we use animation duration

	UPROPERTY(Category = "Shockwave")
	float ShockwaveRecoverDuration = 0.0; // 0.0 means we use animation duration

	UPROPERTY(Category = "Shockwave")
	float ShockwaveAnimTimeScale = 0.6;

	UPROPERTY(Category = "Shockwave")
	float ShockwaveWidth = 1350.0;

	UPROPERTY(Category = "Shockwave")
	float ShockwaveMoveSpeed = 4000.0;

	UPROPERTY(Category = "Shockwave")
	float ShockwaveExpireRange = 12000.0;

	UPROPERTY(Category = "Shockwave")
	float ShockwaveDamage = 0.9;

	UPROPERTY(Category = "Shockwave")
	float ShockwaveStumbleDistance = 3000.0;


	UPROPERTY(Category = "FlailSmash")
	float FlailSmashTelegraphDuration = 0.0; // 0.0 means we use animation duration

	UPROPERTY(Category = "FlailSmash")
	float FlailSmashAnticipationDuration = 0.0; // 0.0 means we use animation duration

	UPROPERTY(Category = "FlailSmash")
	float FlailSmashActionDuration = 0.0; // 0.0 means we use animation duration

	UPROPERTY(Category = "FlailSmash")
	float FlailSmashRecoverDuration = 0.0; // 0.0 means we use animation duration

	UPROPERTY(Category = "FlailSmash")
	float FlailSmashExplosionDuration = 3.0;

	UPROPERTY(Category = "FlailSmash")
	float FlailSmashExplosionRadius = 1000.0;


	UPROPERTY(Category = "SpinningSlash")
	float SpinningSlashStartDuration = 0.7; // 0.0 means we use animation duration

	UPROPERTY(Category = "SpinningSlash")
	float SpinningSlashLoopDuration = 2.0; // 0.0 means we use animation duration 

	// Note that number of shockwaves is this + 1 as we launch a new shockwave at the start of each loop
	UPROPERTY(Category = "SpinningSlash")
	int SpinningSlashLoopNumber = 2;

	UPROPERTY(Category = "SpinningSlash")
	float SpinningSlashRecoverDuration = 0.0; // 0.0 means we use animation duration

	UPROPERTY(Category = "SpinningSlash")
	float SpinningSlashSlideForwardDistance = 0.0;

	UPROPERTY(Category = "SpinningSlash")
	float SpinningSlashShockwaveMoveSpeed = 5000;

	UPROPERTY(Category = "SpinningSlash")
	float SpinningSlashShockwaveHeight = 200.0;

	UPROPERTY(Category = "SpinningSlash")
	float SpinningSlashShockwaveDamage = 0.6;

	UPROPERTY(Category = "SpinningSlash")
	float SpinningSlashShockwaveStumbleHeight = 1500.0;


	UPROPERTY(Category = "SummonCritters")
	float SummonCrittersTelegraphDuration = 0.0; // 0.0 means we use animation duration

	UPROPERTY(Category = "SummonCritters")
	float SummonCrittersAnticipationDuration = 0.0; // 0.0 means we use animation duration

	UPROPERTY(Category = "SummonCritters")
	float SummonCrittersActionDuration = 0.0; // 0.0 means we use animation duration

	UPROPERTY(Category = "SummonCritters")
	float SummonCrittersRecoverDuration = 0.0; // 0.0 means we use animation duration

	UPROPERTY(Category = "SummonCritters")
	int SummonCrittersNumber = 4; 

	UPROPERTY(Category = "SummonCritters")
	float SummonCrittersSpacing = 1500.0;


	UPROPERTY(Category = "SingleSlash")
	float SingleSlashTelegraphDuration = 0.0; // 0.0 means we use animation duration

	UPROPERTY(Category = "SingleSlash")
	float SingleSlashAnticipationDuration = 0.0; // 0.0 means we use animation duration

	UPROPERTY(Category = "SingleSlash")
	float SingleSlashActionDuration = 0.0; // 0.0 means we use animation duration

	UPROPERTY(Category = "SingleSlash")
	float SingleSlashRecoverDuration = 0.0; // 0.0 means we use animation duration

	UPROPERTY(Category = "DualSlash")
	float SingleSlashTurnDuration = 2.0;


	UPROPERTY(Category = "DualSlash")
	float DualSlashTurnDuration = 2.0;


	UPROPERTY(Category = "GenericAttackShockwave")
	float GenericAttackShockwaveMoveSpeed = 4000; 

	UPROPERTY(Category = "GenericAttackShockwave")
	float GenericAttackBladeImpactKillWidth = 300.0;

	UPROPERTY(Category = "GenericAttackShockwave")
	float GenericAttackBladeImpactKnockbackWidth = 600.0;

	UPROPERTY(Category = "GenericAttackShockwave")
	float GenericAttackShockwaveWidth = 500.0;

	UPROPERTY(Category = "GenericAttackShockwave")
	float GenericAttackShockwaveDamage = 0.9;

	UPROPERTY(Category = "GenericAttackShockwave")
	float GenericAttackShockwaveStumbleDistance = 2000.0;


	UPROPERTY(Category = "FinalSmash")
	float FinalSmashTelegraphDuration = 0.0; // 0.0 means we use animation duration

	UPROPERTY(Category = "FinalSmash")
	float FinalSmashAnticipationDuration = 0.0; // 0.0 means we use animation duration

	UPROPERTY(Category = "FinalSmash")
	float FinalSmashActionDuration = 0.0; // 0.0 means we use animation duration

	UPROPERTY(Category = "FinalSmash")
	float FinalSmashRemainingDuration = 0.0; // 0.0 means we use animation duration

	UPROPERTY(Category = "FinalSmash")
	float FinalSmashStuckDuration = 5.0; // Mh, so no default duration

	UPROPERTY(Category = "FinalSmash")
	float FinalSmashRecoverDuration = 0.0; // 0.0 means we use animation duration

	UPROPERTY(Category = "FinalSmash")
	float FinalSmashSlideForwardDistance = 1000.0;

	UPROPERTY(Category = "FinalSmash")
	float FinalSmashHitRadius = 500.0;

	UPROPERTY(Category = "FinalSmash")
	float FinalSmashDamage = 0.8;

	UPROPERTY(Category = "FinalSmash")
	float FinalSmashPlayerJumpToHeadSpeed = 5000.0;

	UPROPERTY(Category = "FinalSmash")
	float FinalSmashStumbleDistance = 3000.0;


	UPROPERTY(Category = "FinalRailSmash")
	float FinalRailSmashTelegraphDuration = 0.0; // 0.0 means we use animation duration

	UPROPERTY(Category = "FinalRailSmash")
	float FinalRailSmashAnticipationDuration = 0.0; // 0.0 means we use animation duration

	UPROPERTY(Category = "FinalRailSmash")
	float FinalRailSmashActionDuration = 0.0; // 0.0 means we use animation duration

	UPROPERTY(Category = "FinalRailSmash")
	float FinalRailSmashRemainingDuration = 0.0; // 0.0 means we use animation duration

	UPROPERTY(Category = "FinalRailSmash")
	float FinalRailSmashStuckDuration = 5.0; // Mh, so no default duration

	UPROPERTY(Category = "FinalRailSmash")
	float FinalRailSmashRecoverDuration = 0.0; // 0.0 means we use animation duration

	UPROPERTY(Category = "FinalRailSmash")
	float FinalRailSmashSlideForwardDistance = 0.0;

	UPROPERTY(Category = "FinalRailSmash")
	float FinalRailSmashHitHeadRange = 500.0;

	UPROPERTY(Category = "FinalRailSmash")
	float FinalRailSmashHitRadius = 500.0;

	UPROPERTY(Category = "FinalRailSmash")
	float FinalRailSmashDamage = 0.8;

	UPROPERTY(Category = "FinalRailSmash")
	float FinalRailSmashStumbleDistance = 3000.0;

	UPROPERTY(Category = "FinalRailSmash")
	float FinalRailSmashRollUpSwordRadius = 500.0;


	UPROPERTY(Category = "DamageCrystal")
	float DamageCrystalDuration = 0.0; // 0.0 means we use animation duration

	UPROPERTY(Category = "DamageCrystal")
	float DamageCrystalPushSpeed = 4000.0;

	UPROPERTY(Category = "DamageCrystal")
	float DamageCrystalImmediatePushOutsideOuterWallDistance = 1000.0;

	UPROPERTY(Category = "DamageCrystal")
	float DamageCrystalAngryPushOutsideOuterWallDistance = 4000.0;


	UPROPERTY(Category = "DestroyCrystal")
	float DestroyCrystalDuration = 0.0; // 0.0 means we use animation duration

	UPROPERTY(Category = "DestroyCrystal")
	uint DestroyCrystalCoreHits = 1;

	// How knight moves in preparation for second phase. XY is in local space of original position, Z is height above arena floor.
	UPROPERTY(Category = "DestroyCrystal")
	FVector DestroyCrystalSecondPhaseMove = FVector(-5000.0, 0.0, 0.0);

	UPROPERTY(Category = "Helmet")
	float MeltHelmetFractionPerHit = 1.0;

	UPROPERTY(Category = "Helmet")
	float MeltHelmetRegenerationRate = 0.75;

	UPROPERTY(Category = "Helmet")
	float MeltHelmetRegenerationCooldown = 5.0;

	UPROPERTY(Category = "Helmet")
	float MeltHelmetMeltingSpeed = 0.75;

	UPROPERTY(Category = "Helmet")
	float MeltHelmetUnmeltSpeed = 0.4;

	UPROPERTY(Category = "Helmet")
	float MeltHelmetDissolvingSpeed = 1.2;

	UPROPERTY(Category = "Helmet")
	float MeltHelmetUndissolvingSpeed = 0.45;

	// If > 0, helmet stop protecting head when it's integrity falls below this fraction (i.e. higher value earlier loss of protection)
	UPROPERTY(Category = "Helmet")
	float MeltHelmetIntactCollisionThreshold = 0.99; 

	// If MeltHelmetIntactCollisionThreshold is 0, helmet stops protecting head when it's dissolved by this much (higher value, later loss of protection)
	UPROPERTY(Category = "Helmet")
	float MeltHelmetDissolvedCollisionThreshold = 0.0;


	UPROPERTY(Category = "DamageHead")
	float DamageHeadDuration = 0.0; // 0.0 means we use animation duration


	UPROPERTY(Category = "DestroyHead")
	float DestroyHeadDuration = 0.0; // 0.0 means we use animation duration

	UPROPERTY(Category = "DestroyHead")
	uint8 DestroyHeadHits = 2;

	UPROPERTY(Category = "Shieldwall")
	float ShieldwallLowerWhenInsideBuffer = 1000.0;

	UPROPERTY(Category = "Shieldwall")
	bool ShieldWallOnlyRaiseNearTailDragon = false;

	UPROPERTY(Category = "Shieldwall")
	float ShieldWallLurkingDetectionRadius = 3200.0;

	UPROPERTY(Category = "Shieldwall")
	float ShieldWallPushAfterLurkingDuration = 3.0;

	UPROPERTY(Category = "Shieldwall")
	float ShieldWallPushAfterLurkingCooldown = 8.0;


	UPROPERTY(Category = "Movement")
	float RotationDuration = 3.0;

	UPROPERTY(Category = "Movement")
	float Friction = 4.0;
};
