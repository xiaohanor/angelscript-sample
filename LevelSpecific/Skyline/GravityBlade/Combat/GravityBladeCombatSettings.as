namespace GravityBladeCombat
{
	const FConsoleVariable CVar_DebugBladeTraces("Haze.Skyline.DebugBladeTraces", 0);

	const FName TargetableCategory =n"GravityBladeCombat";
	const FName Feature = n"GravityBladeCombat";
	const FName GloryKillFeature = n"GloryKill";

	const bool bShowCrosshair = true;
	
	// Input
	const float InputBufferTime = 0.2;

	// How far our reach is when attacking.
	const float HitRange = 200.0;
	const float TargetRange = 300.0;
	// What distance from an active target we want to be when attacking.
	const float SuctionDistance = HitRange * 0.5;
	// If we're closer than this distance to the target, move away again
	const float SuctionMinimumDistance = 50.0;
	// Disregards angle check if within this range.
	const float HitSafeRange = 40.0;
	// Maximum angle in degrees at which we can hit an object.
	const float MaxHitAngle = 120.0;
	// Maximum distance before we can rush towards them when attacking
	const float MaxRushDistance = 1000.0;
	// Default maximum rush distance for enemies
	const float DefaultMaxRushDistanceEnemies = 250.0;
	// Default maximum rush distance while dashing
	const float DefaultMaxRushDistanceDashing = 250.0;
	// Default maximum rush distance while airborne
	const float DefaultMaxRushDistanceAirborne = 250.0;
	// Maximum distance of an enemy will be targeted from.
	const float MaxVisibleDistance = 3000.0;
	// Maximum distance of an enemy for Zoes visualization
	const float MaxVisibleDistanceZoe = MaxRushDistance;
	// Weighing of distance vs. angle when searching for suction target, < .5 favors angle, > .5 favors distance.
	const float SuctionDistanceAngleWeight = 0.5;
	// Remaps delta movement applied by root movement towards movement input depending on input size.
	const FVector2D RootMovementInputScale = FVector2D(1.0, 1.0);
	// Default recoil duration used whenever a recoil is requested with no specific duration.
	const float DefaultRecoilDuration = 0.8;
	// Minimum amount of knockback any hit will cause, _is_ affected by hit window multiplier
	const float MinimumKnockbackLength = 200;

	// ** Combat Grapple
	// Whether to enable grappling to enemies during combat
	const bool bEnableCombatGrapple = true;
	// Default maximum distance we can grapple to enemies with the grapple move
	const float DefaultMaxCombatGrappleDistance = 2000.0;
	// Default maximum distance we can grapple to enemies with the grapple move
	const float DefaultMinCombatGrappleDistance = 400.0;
	// Default maximum auto-aim angle we can grapple to enemies with the grapple move
	const float DefaultMaxCombatGrappleAngle = 30.0;

	// If degrees between player forward and direction from player to target is within this threshold, don't rotate CW/CCW based on which foot is forward in the animation, just rotate closest.
	const float PickRotationDirectionDegreeThreshold = 120.0;

	const float CombatCameraEndDelay = 0.5;

	// Rush
	const float RushSpeed = 3000;
	const float RushMinTimeToReachTarget = 0.3;
	const float RushMaxTimeToReachTarget = 0.4;
	const float RushVerticalAdjustTime = 0.2;
	const float RushDistanceThreshold = 250;
	const float AirRushMaxHeight = 400;
	const float RushCharacterRotationSpeed = 720.0;

	// Dash
	const float DashGraceTime = 0.1;

	// Air Slam
	const float AirSlamMinimumHeightDifference = -30.0;
	const float AirSlamMaximumDistance = 200.0;
	const float AirSlamDownwardSpeed = 2500.0;
	const float AirSlamAnticipationDuration = 0.3;

	// Camera
	const float CombatCameraBlendInTime = 0.5;
	const float CombatCameraBlendOutTime = 2.0;

	// Follow Camera
	// const float CombatCameraFollowAgainDelay = 0.5;
	// const FRotator OffsetDesiredRotationInLeap = FRotator(0.0, 0.0, 0.0);
	// const float LeapingFollowCameraInterpSpeed = 3.0;

	// Rush camera
	const float RushCameraRotationSpeed = 100.0;
	const float RushCameraRotationSpeedWhenInAnticipationDelay = 30.0;
	const float RushCameraSidewaysAngle = 45.0;

	// Glory kill can only trigger when attacking eenmies with health lower than this
	const float GloryKillDamage = 0.4;

	// If enforcers are further away from the player than this distance they are treated as "not dangerous", if no dangerous enforcers are found except the target, the glory kill will be executed.
	const float GloryKillEnforcerDangerMaxRange = 750.0;
	
	// Chance of triggering glory kill even when there are others left that may be dangerous
	const float GloryKillWhileInDangerChance = 0.8;

	// Should we only allow glory kills when grounded or also when in air or dashing?
	const bool bAllowOnlyGroundedGloryKills = false;

	const bool bAllowCancellingGloryKills = true;

	// If attacking a target within this time of completing another Glory Kill, a glory kill will be inited immediately
	const float GloryKillChainedDuration = 0.75;

	// Opportunity Attack
	const float OpportunityAttackCameraImpulseMultiplier = 0.1;
	
	// DEBUG
	const bool DEBUG_RequestOverrideWithAttackState = false;
	const bool DEBUG_WaitOneFrameBeforeStartingStrafe = true;
	const bool DEBUG_DrawEnforcerDangerMaxRange = false;
}

namespace GravityBladeCombatTags
{
	const FName GravityBladeCombat = n"GravityBladeCombat";

	const FName GravityBladeAttackActivation = n"GravityBladeAttackActivation";

	const FName GravityBladeRush = n"GravityBladeRush";
	const FName GravityBladeDashRush = n"GravityBladeDashRush";

	const FName GravityBladeAttack = n"GravityBladeAttack";
	const FName GravityBladeAirAttack = n"GravityBladeAirAttack";
	const FName GravityBladeDashAttack = n"GravityBladeDashAttack";
	const FName GravityBladeCombatDashCheck = n"GravityBladeCombatDashCheck";
	const FName GravityBladeGroundAttack = n"GravityBladeGroundAttack";
	const FName GravityBladeJumpAttack = n"GravityBladeJumpAttack";
	const FName GravityBladeSprintAttack = n"GravityBladeSprintAttack";

	const FName GravityBladeGloryKill = n"GravityBladeGloryKill";

	const FName GravityBladeAttackRecoil = n"GravityBladeAttackRecoil";
	const FName GravityBladeCombatAim = n"GravityBladeCombatAim";
	const FName GravityBladeCombatAnimation = n"GravityBladeCombatAnimation";
	const FName GravityBladeCombatCamera = n"GravityBladeCombatCamera";
	const FName GravityBladeCombatPrimaryInput = n"GravityBladeCombatPrimaryInput";
}

enum EGravityBladeRequestAnimationDebug
{
	DontRequestAnimation,
	RequestLocomotionWithMovement,
	RequestOverrideWithMovement
}