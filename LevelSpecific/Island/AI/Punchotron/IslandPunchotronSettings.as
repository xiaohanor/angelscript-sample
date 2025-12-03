class UIslandPunchotronSettings : UHazeComposableSettings
{	

	// Attack Damage

	UPROPERTY(Category = "AttackDamage")
	float HaywireAttackDamage = 0.5;

	UPROPERTY(Category = "AttackDamage")
	float SpinningAttackDamage = 0.5;

	UPROPERTY(Category = "AttackDamage")
	float BackhandAttackDamage = 0.7;

	UPROPERTY(Category = "AttackDamage")
	float JumpAttackDamage = 0.9;

	UPROPERTY(Category = "AttackDamage")
	float KickAttackDamage = 0.6;

	UPROPERTY(Category = "AttackDamage")
	float ProximityAttackDamage = 0.5;

	UPROPERTY(Category = "AttackDamage")
	float WheelchairKickAttackDamage = 0.5;

	UPROPERTY(Category = "AttackDamage")
	float CobraStrikeAttackDamage = 0.5;


	// Global Cooldown

	// Cooldown between any attack
	UPROPERTY(Category = "Attack")
	float GlobalAttackCooldown = 0.5;
	
	// Deviation range (+/-) from GlobalAttackCooldown.
	UPROPERTY(Category = "Attack")
	float GlobalAttackCooldownDeviationRange = 0.1;


	// Jump Attack

	UPROPERTY(Category = "Attack|JumpAttack")
	float JumpAttackMinRange = 2000.0;

	UPROPERTY(Category = "Attack|JumpAttack")
	float JumpAttackMaxRange = 3500.0;
	
	UPROPERTY(Category = "Attack|JumpAttack")
	float JumpAttackDuration = 3.67;
	
	UPROPERTY(Category = "Attack|JumpAttack")
	float JumpAttackCooldown = 5.0;

	UPROPERTY(Category = "Attack|JumpAttack")
	float JumpAttackHitFraction = 0.5;

	UPROPERTY(Category = "Attack|JumpAttack")
	float JumpAttackHitEndFraction = 0.9;
	
	UPROPERTY(Category = "Attack|JumpAttack")
	float JumpAttackTargetOffset = 0.0;

	UPROPERTY(Category = "Attack|JumpAttack")
	float JumpAttackHitOffset = 60.0;
	
	UPROPERTY(Category = "Attack|JumpAttack")
	float JumpAttackHitRadius = 120.0;
	
	UPROPERTY(Category = "Attack|JumpAttack")
	float JumpAttackHeight = 400.0;
	
	UPROPERTY(Category = "Attack|JumpAttack")
	bool bIsJumpAttackEnabled = true;


	// Haywire Attack

	UPROPERTY(Category = "Attack|HaywireAttack")
	float HaywireAttackCooldown = 3.0;

	// Deviation range (+/-) from HaywireAttackCooldown
	UPROPERTY(Category = "Attack|HaywireAttack")
	float HaywireAttackCooldownDeviationRange = 0.2;

	UPROPERTY(Category = "Attack|HaywireAttack")
	float HaywireMinAttackRange = 100.0;
	
	UPROPERTY(Category = "Sidescroller|Attack|HaywireAttack")
	float SidescrollerHaywireMinAttackRange = 0.0;

	UPROPERTY(Category = "Attack|HaywireAttack")
	float HaywireMaxAttackRange = 400.0;
	
	UPROPERTY(Category = "Sidescroller|Attack|HaywireAttack")
	float SidescrollerHaywireMaxAttackRange = 350.0;

	UPROPERTY(Category = "Attack|HaywireAttack")
	float HaywireAttackDuration = 2.8;
	
	UPROPERTY(Category = "Attack|HaywireAttack")
	float HaywireAttackHitFraction = 0.20;

	UPROPERTY(Category = "Attack|HaywireAttack")
	float HaywireAttackHitEndFraction = 0.9;

	UPROPERTY(Category = "Attack|HaywireAttack")
	float HaywireAttackTargetOffset = 150.0;

	UPROPERTY(Category = "Attack|HaywireAttack")
	float HaywireAttackHitOffset = 150.0;
	
	UPROPERTY(Category = "Sidescroller|Attack|HaywireAttack")
	float SidescrollerHaywireAttackHitOffset = 160.0;

	UPROPERTY(Category = "Attack|HaywireAttack")
	float HaywireAttackHitRadius = 150.0;
	
	UPROPERTY(Category = "Sidescroller|Attack|HaywireAttack")
	float SidescrollerHaywireAttackHitRadius = 140.0;

	UPROPERTY(Category = "Attack|HaywireAttack")
	float HaywireAttackMoveSpeed = 500.0;

	UPROPERTY(Category = "Sidescroller|Attack|HaywireAttack")
	float SidescrollerHaywireAttackMoveSpeed = 250.0;


	// Spinning Attack

	UPROPERTY(Category = "Attack|SpinningAttack")
	float SpinningAttackCooldown = 4.0;

	// Deviation range (+/-) from SpinningAttackCooldown
	UPROPERTY(Category = "Attack|SpinningAttack")
	float SpinningAttackCooldownDeviationRange = 0.2;

	UPROPERTY(Category = "Attack|SpinningAttack")
	float SpinningAttackMinRange = 300.0;

	UPROPERTY(Category = "Attack|SpinningAttack")
	float SpinningAttackMaxRange = 1200.0;
	
	UPROPERTY(Category = "Attack|SpinningAttack")
	float SpinningAttackTelegraphDuration = 2.25;
	
	UPROPERTY(Category = "Attack|SpinningAttack")
	float SpinningAttackDuration = 2.2;
		
	UPROPERTY(Category = "Attack|SpinningAttack")
	float SpinningAttackTargetOffset = 500.0;

	UPROPERTY(Category = "Attack|SpinningAttack")
	float SpinningAttackHitOffset = 0.0;

	UPROPERTY(Category = "Attack|SpinningAttack")
	float SpinningAttackHitRadius = 200.0;

	UPROPERTY(Category = "Sidescroller|Attack|SpinningAttack")
	float SidescrollerSpinningAttackHitRadius = 170.0;
	
	UPROPERTY(Category = "Attack|SpinningAttack")
	float SpinningAttackMoveSpeed = 1000.0;


	// Kick Attack

	UPROPERTY(Category = "Attack|KickAttack")
	float KickAttackCooldown = 0.5;

	// Deviation range (+/-) from KickAttackCooldown
	UPROPERTY(Category = "Attack|KickAttack")
	float KickAttackCooldownDeviationRange = 0.1;

	UPROPERTY(Category = "Attack|KickAttack")
	float KickAttackRange = 200.0;
	
	UPROPERTY(Category = "Attack|KickAttack")
	float KickAttackDuration = 2;
	
	UPROPERTY(Category = "Attack|KickAttack")
	float KickAttackHitFraction = 0.40;

	UPROPERTY(Category = "Attack|KickAttack")
	float KickAttackHitEndFraction = 0.50;

	UPROPERTY(Category = "Attack|KickAttack")
	float KickAttackTargetOffset = 500.0;

	UPROPERTY(Category = "Attack|KickAttack")
	float KickAttackHitOffset = 120.0;

	UPROPERTY(Category = "Attack|KickAttack")
	float KickAttackHitRadius = 40.0;

	
	// Backhand Attack
	
	UPROPERTY(Category = "Attack|BackhandAttack")
	float BackhandAttackCooldown = 2.5;

	UPROPERTY(Category = "Attack|BackhandAttack")
	float BackhandAttackRange = 700.0;
	
	UPROPERTY(Category = "Attack|BackhandAttack")
	float BackhandAttackDuration = 2.66;
	
	UPROPERTY(Category = "Attack|BackhandAttack")
	float BackhandAttackHitFraction = 0.40;

	UPROPERTY(Category = "Attack|BackhandAttack")
	float BackhandAttackHitEndFraction = 0.875;

	UPROPERTY(Category = "Attack|BackhandAttack")
	float BackhandAttackTargetOffset = 500.0;

	UPROPERTY(Category = "Attack|BackhandAttack")
	float BackhandAttackHitOffset = 0.0;

	UPROPERTY(Category = "Attack|BackhandAttack")
	float BackhandAttackHitRadius = 220.0;


	// Proximity Attack
	
	UPROPERTY(Category = "Attack|ProximityAttack")
	float ProximityAttackMaxRange = 350.0;

	UPROPERTY(Category = "Attack|ProximityAttack")
	float ProximityAttackTelegraphDuration = 0.5;
	
	UPROPERTY(Category = "Attack|ProximityAttack")
	float ProximityAttackAnticipationDuration = 0.6;
	
	UPROPERTY(Category = "Attack|ProximityAttack")
	float ProximityAttackActionDuration = 0.3;

	UPROPERTY(Category = "Attack|ProximityAttack")
	float ProximityAttackDuration = 2.0;
	
	UPROPERTY(Category = "Attack|ProximityAttack")
	float ProximityAttackCooldown = 1.0;

	UPROPERTY(Category = "Attack|ProximityAttack")
	float ProximityAttackHitRadius = 80.0;

	// Handles case when player is within reach but trying to dodge by stepping into Punchotron
	UPROPERTY(Category = "Attack|ProximityAttack")
	float ProximityAttackCloseRangeHitRadius = 250.0;


	// Set a max speed for when it is permitted to switch target to closest target on a panel. Prevents swinging in midair.
	UPROPERTY(Category = "Attack|ProximityAttack")
	float ProximityAttackPanelChangeTargetMaxSpeed = 200.0;

	// Wheelchair Kick Attack

	UPROPERTY(Category = "Attack|WheelchairKickAttack")
	float WheelchairKickAttackCooldown = 4.0;

	// Deviation range (+/-) from WheelchairKickAttack
	UPROPERTY(Category = "Attack|WheelchairKickAttack")
	float WheelchairKickAttackCooldownDeviationRange = 0.2;

	UPROPERTY(Category = "Attack|WheelchairKickAttack")
	float WheelchairKickAttackMinRange = 300.0;

	UPROPERTY(Category = "Attack|WheelchairKickAttack")
	float WheelchairKickAttackMaxRange = 1200.0;
	
	UPROPERTY(Category = "Attack|WheelchairKickAttack")
	float WheelchairKickAttackTelegraphDuration = 1.0;
	
	// Time window for attack action and damage dealing
	UPROPERTY(Category = "Attack|WheelchairKickAttack")
	float WheelchairKickAttackActionDuration = 2.2;

	UPROPERTY(Category = "Attack|WheelchairKickAttack")
	float WheelchairKickAttackDuration = 4.2;
		
	UPROPERTY(Category = "Attack|WheelchairKickAttack")
	float WheelchairKickAttackTargetOffset = 200.0;

	UPROPERTY(Category = "Attack|WheelchairKickAttack")
	float WheelchairKickAttackHitOffset = 0.0;

	UPROPERTY(Category = "Attack|WheelchairKickAttack")
	float WheelchairKickAttackHitRadius = 200.0;
	
	UPROPERTY(Category = "Attack|WheelchairKickAttack")
	float WheelchairKickAttackMoveSpeed = 2500.0;


	// CobraStrike Attack

	UPROPERTY(Category = "Attack|CobraStrikeAttack")
	float CobraStrikeAttackCooldown = 3.0;

	// Deviation range (+/-) from CobraStrikeAttack
	UPROPERTY(Category = "Attack|CobraStrikeAttack")
	float CobraStrikeAttackCooldownDeviationRange = 0.2;

	UPROPERTY(Category = "Attack|CobraStrikeAttack")
	float CobraStrikeAttackMinRange = 300.0;

	UPROPERTY(Category = "Attack|CobraStrikeAttack")
	float CobraStrikeAttackMaxRange = 3000.0;
	
	UPROPERTY(Category = "Attack|CobraStrikeAttack")
	float CobraStrikeAttackTelegraphDuration = 1.0;
	
	UPROPERTY(Category = "Attack|CobraStrikeAttack")
	float CobraStrikeAttackAnticipationDuration = 1.0;
	
	// Time window for attack action and damage dealing
	UPROPERTY(Category = "Attack|CobraStrikeAttack")
	float CobraStrikeAttackActionDuration = 1.0;

	UPROPERTY(Category = "Attack|CobraStrikeAttack")
	float CobraStrikeRecoveryDuration = 1.0;

	UPROPERTY(Category = "Attack|CobraStrikeAttack")
	float CobraStrikeAttackDuration = 4.0;

	UPROPERTY(Category = "Attack|CobraStrikeAttack")
	float CobraStrikeAttackTargetOffset = 500.0;

	UPROPERTY(Category = "Attack|CobraStrikeAttack")
	float CobraStrikeAttackHitOffset = 100.0;

	UPROPERTY(Category = "Attack|CobraStrikeAttack")
	float CobraStrikeAttackHitRadius = 200.0;
	
	UPROPERTY(Category = "Attack|CobraStrikeAttack")
	float CobraStrikeAttackMoveSpeed = 10000.0;

	UPROPERTY(Category = "Attack|CobraStrikeAttack")
	float CobraStrikeTelegraphingMoveSpeed = 50.0;

	UPROPERTY(Category = "Sidescroller|Attack|CobraStrikeAttack")
	float SidescrollerCobraStrikeAttackMoveSpeed = 1500.0;

	// Gentleman

	UPROPERTY(Category = "Attack")
	EGentlemanCost AttackGentlemanCost = EGentlemanCost::Large;

	UPROPERTY(Category = "Attack")
	float AttackTokenCooldown = 1.0;


	// Knockdown
	
	UPROPERTY(Category = "Attack")
	float KnockdownDistance = 300.0;

	UPROPERTY(Category = "Attack")
	float KnockdownDuration = 1.5;


	// Damage to Punchotron

	UPROPERTY(Category = "Damage")
	float DefaultDamage = 0.007;

	UPROPERTY(Category = "Damage")
	float SidescrollerBulletDamage = 0.010;

	UPROPERTY(Category = "Damage")
	float HurtReactionDuration = 0.8;

	UPROPERTY(Category = "Damage")
	float StunnedDuration = 5.0;
	
	UPROPERTY(Category = "Sidescroller|Damage")
	float SidescrollerStunnedDuration = 3.0;

	UPROPERTY(Category = "Damage")
	float ForceFieldDepletedDamage = 0.02;
	
	UPROPERTY(Category = "Damage")
	float ForceFieldDepletedCooldown = 5.0;
	
	UPROPERTY(Category = "Sidescroller|Damage")	
	float SidescrollerForceFieldDepletedCooldown = 2.0;

	UPROPERTY(Category = "Damage")
	float TauntDuration = 3.0;

	// Cooldown behaviour duration
	UPROPERTY(Category = "Damage")
	float CooldownDuration = 0.0;

	UPROPERTY(Category = "Damage")
	float DeathDuration = 1.15;

	// Boss Punchotron will activate his shield after health has decreased to this level.
	UPROPERTY(Category = "Boss|Damage")
	float BossActivateForcefieldHealthLimit = 0.75;

	// After camera cuts to Punchotron, this is the time it takes for forcefield to enable
	UPROPERTY(Category = "Boss|ActivateForcefieldCutscene")
	float BossEnableForcefieldInCutsceneTimer = 0.5;
	
	// After forcefield enables in cutscene, this is the time it takes for input and movement to unblock.
	UPROPERTY(Category = "Boss|ActivateForcefieldCutscene")
	float BossEnableMovementInCutsceneTimer = 2.0;

	UPROPERTY(Category = "Boss|ActivateForcefieldCutscene")
	bool bIsBossForcefieldCutsceneEnabled = true;

	// Crowd Avoidance

	// When there are others within this range we will move away from them
	UPROPERTY(Category = "Combat|CrowdAvoidance")
	float CrowdAvoidanceMaxRange = 700.0;

	// Avoid getting this close to anybody as much as possible
	UPROPERTY(Category = "Combat|CrowdAvoidance")
	float CrowdAvoidanceMinRange = 400.0;

	// Max acceleration away from others
	UPROPERTY(Category = "Combat|CrowdAvoidance")
	float CrowdAvoidanceForce = 1000.0;


	// Sideways Movement

	UPROPERTY(Category = "Combat|SidewaysMovement")
	float SidewaysMoveSpeed = 300.0;

	// Stop performing sideways movement when this close to target
	UPROPERTY(Category = "Combat|SidewaysMovement")
	float SidewaysMinRange = 100.0;
	
	// Range for which the sideways target location (waypoint) is considered reached
	UPROPERTY(Category = "Combat|SidewaysMovement")
	float SidewaysTargetLocationRadius = 100.0;
	
	// Minimum time between each sideways movement activation
	UPROPERTY(Category = "Combat|SidewaysMovement")
	float SidewaysMinCooldown = 1.0;

	// Maximum time between each sideways movement activation
	UPROPERTY(Category = "Combat|SidewaysMovement")
	float SidewaysMaxCooldown = 2.0;
	
	// Maximum time spent in sideways movement behaviour
	UPROPERTY(Category = "Combat|SidewaysMovement")
	float SidewaysMaxActiveDuration = 1.0;


	// Chase

	// Stop chase when this close to target
	UPROPERTY(Category = "Combat|Chase")
	float ChaseMinRange = 50.0;
	
	// Will stop the chase for this duration after the min range has been reached
	UPROPERTY(Category = "Combat|Chase")
	float ChaseMinRangeCooldown = 0.5;

	UPROPERTY(Category = "Combat|Chase")
	float ChaseScaleDownMoveSpeedRange = 400.0;

	// Speed when in chase behaviour
	UPROPERTY(Category = "Combat|Chase")
	float ChaseMoveSpeed = 1200.0;
	
	// Speed when in eleavtor chase behaviour
	UPROPERTY(Category = "Combat|ElevatorChase")
	float ElevatorChaseMoveSpeed = 500.0;
	

	// Chase speed is multiplied with this factor when on a panel in punchotron arena.
	UPROPERTY(Category = "Combat|Chase")
	float OnPanelSlowdownFactor = 1.0;

	
	// Engage general settings

	UPROPERTY(Category = "Combat|Engage")
	float  HaywireEngageTelegraphDuration = 1.0;

	UPROPERTY(Category = "Combat|Engage")
	float  HaywireEngageAnticipationDuration = 1.0;

	// Stop when this close to target
	UPROPERTY(Category = "Combat|Engage")
	float HaywireEngageMinRange = 500.0;
	
	// Activate Engage within this range
	UPROPERTY(Category = "Combat|Engage")
	float HaywireEngageMaxRange = 1500.0;

	// Will stop for this duration after the min range has been reached
	UPROPERTY(Category = "Combat|Engage")
	float HaywireEngageMinRangeCooldown = 8.0;

	// Speed when in engage behaviour
	UPROPERTY(Category = "Combat|Engage")
	float HaywireTelegraphingMoveSpeed = 200.0;

	// Speed when in engage behaviour
	UPROPERTY(Category = "Combat|Engage")
	float HaywireEngageMoveSpeed = 4000.0;

	
	// Engage Spinning Attack
	
	// Stop when this close to target
	UPROPERTY(Category = "Combat|Engage|SpinningAttack")
	float SpinningAttackEngageMinRange = 1000.0;


	// Spline follow
	
	UPROPERTY(Category = "Combat|Engage")
	float FollowSplineSpeed = 2000.0;

	// Start following spline when this far away from player
	UPROPERTY(Category = "Combat|Engage")
	float FollowSplineStartMinDistToPlayer = 1500.0;

	// Stop following spline when this close to player
	UPROPERTY(Category = "Combat|Engage")
	float FollowSplineStopMinDistToPlayer = 500.0;

	
	
    UPROPERTY(Category = "Movement")
	float GroundFriction = 1.0;
    
	UPROPERTY(Category = "Sidescroller|Movement")
	float SidescrollerGroundFriction = 2.0;

	// Ground friction is set to this amount when punchotron is on a panel in the punchotron arena.
	UPROPERTY(Category = "Combat|Chase")
	float OnPanelGroundFriction = 2.00;

	
    UPROPERTY(Category = "Movement")
	float AirFriction = 0.5;
	
    UPROPERTY(Category = "Movement")
	float SplineGroundFriction = 1.2;

	// Distance at which we consider ourselves at a spline when following it
    UPROPERTY(Category = "Movement")
	float SplineFollowCaptureDistance = 100.0;

	// Additional spline-orthogonal friction when sliding onto spline
    UPROPERTY(Category = "Movement")
	float SplineCaptureBrakeFriction = 1.0;

	// How fast we change facing
    UPROPERTY(Category = "Movement")
	float TurnDuration = 1.5;

	// How fast we stop turning when we no longer have a focus (higher values is faster stop)
    UPROPERTY(Category = "Movement")
	float StopTurningDamping = 5.0;


	// Contact damage

	// Cooldown time until next contact damage may be dealt to player.
	UPROPERTY(Category = "ContactDamage")
	float ContactDamagePlayerCooldown = 1.0;

	// Damage dealt to player on contact
	UPROPERTY(Category = "ContactDamage")
	float ContactDamageAmount = 0.9;

	// Knockdown duration
	UPROPERTY(Category = "ContactDamage")
	float ContactDamageKnockdownDuration = 1.25;
	
	// Knockdown distance
	UPROPERTY(Category = "ContactDamage")
	float ContactDamageKnockdownDistance = 800.0;
}
