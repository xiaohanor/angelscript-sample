class UIslandWalkerSettings : UHazeComposableSettings
{
	UPROPERTY(Category = "Movement")
	float TurnDuration = 10.0;

	UPROPERTY(Category = "TrackTarget")
	float TrackTargetSwivelSpeed = 60.0;

	UPROPERTY(Category = "TrackTarget")
	float TrackTargetTurnThresholdDegrees = 30.0;

	UPROPERTY(Category = "TrackTarget")
	float TrackTargetTurnCooldown = 8.0;

	UPROPERTY(Category = "TrackTarget")
	float TrackTargetTurnDuration = 0.0; // O.0 is anim default duration


	UPROPERTY(Category = "Laser")
	float LaserRange = 6000.0;

	UPROPERTY(Category = "Laser")
	float LaserPlayerDamagePerSweep = 0.9;

	UPROPERTY(Category = "Laser")
	float LaserValidAngle = 45.0;

	UPROPERTY(Category = "Laser")
	float ExposedLaserValidAngle = 35;

	UPROPERTY(Category = "Laser")
	float LaserFollowSpeed = 1600;

	UPROPERTY(Category = "Laser")
	float LaserFollowDamping = 0.1;

	UPROPERTY(Category = "Laser")
	float LaserLagBehindTargetTime = 0.2;

	UPROPERTY(Category = "Laser")
	float LaserTelegraphDuration = 0.0; // O.0 is anim default duration

	UPROPERTY(Category = "Laser")
	float LaserDuration = 6.0; // Stay in mh for this long

	UPROPERTY(Category = "Laser")
	float LaserRecoverDuration = 0.0; // O.0 is anim default duration 

	UPROPERTY(Category = "Laser")
	float LaserBeamWidth = 150.0;

	UPROPERTY(Category = "Laser")
	float LaserCooldown = 10.0;

	UPROPERTY(Category = "Laser")
	float GatlingCasingsPerSecond = 15.0;

	UPROPERTY(Category = "Laser")
	float GatlingCasingsLifeTime = 2;

	UPROPERTY(Category = "Laser")
	FVector GatlingCasingsEjectSpeed = FVector(0.0, -320.0, 320.0);

	UPROPERTY(Category = "Laser")
	float GatlingCasingsEjectScatterYaw = 4.0;

	UPROPERTY(Category = "Laser")
	float GatlingCasingsEjectScatterPitch = 3.0;

	UPROPERTY(Category = "Laser")
	float GatlingCasingsDamageInterval = 0.2;

	UPROPERTY(Category = "Laser")
	float GatlingCasingsDamagePerSecond = 1.0;

	UPROPERTY(Category = "Laser")
	float GatlingCasingsDamageRadius = 100.0;


	UPROPERTY(Category = "SpinningLaser")
	float SpinningLaserTelegraphDuration = 0.0; // O.0 is anim default duration

	UPROPERTY(Category = "SpinningLaser")
	float SpinningLaserSpinUpDuration = 5.0;

	UPROPERTY(Category = "SpinningLaser")
	float SpinningLaserSpinDuration = 4.0;

	UPROPERTY(Category = "SpinningLaser")
	float SpinningLaserSpinDownDuration = 3.0;

	UPROPERTY(Category = "SpinningLaser")
	float SpinningLaserRecoveryDuration = 0.0; // O.0 is anim default duration;

	UPROPERTY(Category = "SpinningLaser")
	float SpinningLaserDegreesPerSecond = 120.0;

	UPROPERTY(Category = "SpinningLaser")
	float SpinningLaserTrackingDuration = 1.0;

	UPROPERTY(Category = "SpinningLaser")
	float SpinningLaserMinRange = 500.0;

	UPROPERTY(Category = "SpinningLaser")
	float SpinningLaserCooldown = 15.0;

	
	UPROPERTY(Category = "Spawning")
	int RespawnMaxActiveMinions = 2;

	// Maximum this amount of spawned minions at one time
	UPROPERTY(Category = "Spawning")
	int SpawningMaxSpawnCount = 5;

	// Add this amount to maximum of spawned minions at one time (used in later phases)
	UPROPERTY(Category = "Spawning")
	int SpawningAdditionalMaxSpawnCount = 5;

	// Wait this long before we spawn new minions after first buzzer was killed
	UPROPERTY(Category = "Spawning")
	float SpawningCooldown = 22.0;

	UPROPERTY(Category = "Spawning")
	float SpawningLaunchSpeed = 3000.0;

	UPROPERTY(Category = "Spawning")
	float PostSpawnNerfedTargetingDuration = 5.0;

	UPROPERTY(Category = "Spawning")
	float PostSpawnNerfedTargetingRange = 1000.0;


	UPROPERTY(Category = "DefensiveSpawning")
	float DefensiveSpawnTelegraphDuration = 0.0; // 0.0 is anim duration

	UPROPERTY(Category = "DefensiveSpawning")
	float DefensiveSpawnDuration = 7.0;

	UPROPERTY(Category = "DefensiveSpawning")
	float DefensiveSpawnRecoveryDuration = 0.0; // 0.0 is anim duration


	UPROPERTY(Category = "StandingSpawning")
	float StandingSpawnTelegraphDuration = 0.0; // 0.0 is anim duration

	UPROPERTY(Category = "StandingSpawning")
	float StandingSpawnAnticipationDuration = 0.0; // 0.0 is anim duration

	UPROPERTY(Category = "StandingSpawning")
	float StandingSpawnActionDuration = 0.0; // 0.0 is anim duration

	UPROPERTY(Category = "StandingSpawning")
	float StandingSpawnRecoveryDuration = 0.0; // 0.0 is anim duration


	UPROPERTY(Category = "SuspendedSpawning")
	int SuspendedMaxSpawnCount = 4;

	UPROPERTY(Category = "SuspendedSpawning")
	float SuspendedSpawnCooldown = 20.0;

	// Only allow spawning after this many times spraying 
	UPROPERTY(Category = "SuspendedSpawning")
	int SuspendedSpawnSprayGasCount = 2;

	UPROPERTY(Category = "SuspendedSpawning")
	float SuspendedSpawnTelegraphDuration = 0.0; // 0.0 is anim duration

	UPROPERTY(Category = "SuspendedSpawning")
	float SuspendedSpawnAnticipationDuration = 0.0; // 0.0 is anim duration

	UPROPERTY(Category = "SuspendedSpawning")
	float SuspendedSpawnActionDuration = 0.0; // 0.0 is anim duration

	UPROPERTY(Category = "SuspendedSpawning")
	float SuspendedSpawnRecoveryDuration = 0.0; // 0.0 is anim duration

	UPROPERTY(Category = "SuspendedSpawning")
	float SuspendedSpawnPostPauseDuration = 5.0; 

	UPROPERTY(Category = "SuspendedSpawning")
	float SuspendedSpawnPrePauseDuration = 2.0; 


	UPROPERTY(Category = "FireBurst")
	float FireBurstMaxAngle = 60.0;

	UPROPERTY(Category = "FireBurst")
	float FireBurstTelegraphDuration = 0.0; // 0.0 is anim duration

	UPROPERTY(Category = "FireBurst")
	float FireBurstAnticipationDuration = 0.0; // 0.0 is anim duration

	UPROPERTY(Category = "FireBurst")
	float FireBurstActionDuration = 0.0; // 0.0 is anim duration

	UPROPERTY(Category = "FireBurst")
	float FireBurstRecoverDuration = 0.0; // 0.0 is anim duration

	UPROPERTY(Category = "FireBurst")
	float FireBurstTargetPredictionTime = 0.0;

	UPROPERTY(Category = "FireBurst")
	float FireBurstCooldown = 12.0;

	UPROPERTY(Category = "FireBurst")
	float FireBurstSlamDamage = 1.0;

	UPROPERTY(Category = "FireBurst")
	float FireBurstDamageAreaHeight = 1000.0;

	UPROPERTY(Category = "FireBurst")
	float FireBurstDamageAreaRadius = 600.0;

	UPROPERTY(Category = "FireBurst")
	FVector FireBurstDamageAreaOffset = FVector(800.0, 0.0, 0.0);

	UPROPERTY(Category = "FireBurst")
	float FireBurstSpraySpeed = 2500.0;

	UPROPERTY(Category = "FireBurst")
	float FireBurstDamagePerSecond = 1.0;


	// Trigger side slam when we've not been able to attack for this long
	UPROPERTY(Category = "SideSlam")
	float SideSlamFrustrationTime = 5.0;

	UPROPERTY(Category = "SideSlam")
	float SideSlamTelegraphDuration = 0.7;

	UPROPERTY(Category = "SideSlam")
	float SideSlamAnticipationDuration = 0.5;

	UPROPERTY(Category = "SideSlam")
	float SideSlamActionDuration = 0.5;

	UPROPERTY(Category = "SideSlam")
	float SideSlamRecoverDuration = 3.0;

	UPROPERTY(Category = "SideSlam")
	float SideSlamCooldown = 6.0;

	UPROPERTY(Category = "SideSlam")
	float SideSlamTurnDuration = 5.0;

	UPROPERTY(Category = "SideSlam")
	float SideSlamTargetPredictionTime = 1.0;

	UPROPERTY(Category = "SideSlam")
	FVector SideSlamDamageAreaOffset = FVector(0.0, 200.0, 0.0);

	UPROPERTY(Category = "SideSlam")
	float SideSlamDamage = 1.0;

	UPROPERTY(Category = "SideSlam")
	float SideSlamDamageAreaHeight = 1000.0;

	UPROPERTY(Category = "SideSlam")
	float SideSlamDamageAreaRadius = 1200.0;


	UPROPERTY(Category = "JumpAttack")
	float JumpAttackTelegraph = 0.0; // 0.0 is anim duration

	UPROPERTY(Category = "JumpAttack")
	float JumpAttackAnticipation = 0.0; // 0.0 is anim duration

	UPROPERTY(Category = "JumpAttack")
	float JumpAttackDuration = 0.0; // 0.0 is anim duration

	UPROPERTY(Category = "JumpAttack")
	float JumpAttackRecovery = 0.0; // 0.0 is anim duration

	UPROPERTY(Category = "JumpAttack")
	float JumpAttackRadius = 1250;

	UPROPERTY(Category = "JumpAttack")
	float JumpAttackShockwaveSpeed = 1500.0;

	UPROPERTY(Category = "JumpAttack")
	float JumpAttackShockwaveWidth = 100.0;

	UPROPERTY(Category = "JumpAttack")
	float JumpAttackShockwaveHeight = 150.0;

	UPROPERTY(Category = "JumpAttack")
	float JumpAttackShockwaveStopRadius = 5000.0;

	UPROPERTY(Category = "JumpAttack")
	float JumpAttackShockwaveDamage = 0.9;

	UPROPERTY(Category = "JumpAttack")
	float JumpAttackShockwaveKnockbackForce = 1000.0;

	UPROPERTY(Category = "JumpAttack")
	float JumpAttackShockwaveKnockbackDuration = 1.5;


	UPROPERTY(Category = "Reposition")
	float RepositionCooldown = 14.0;

	UPROPERTY(Category = "Reposition")
	float RepositionMoveLength = 800.0;


	UPROPERTY(Category = "Damage")
	float LegDestroyedHurtDuration = 0.0; // 0.0 means we use animation duration

	UPROPERTY(Category = "Damage")
	FIslandRedBlueImpactOverchargeResponseComponentSettings CoverPanelOverchargeSettings;
	default CoverPanelOverchargeSettings.ChargeAmountPerImpact = 0.04;
	default CoverPanelOverchargeSettings.StartDischargingDelay = 60.0;
	default CoverPanelOverchargeSettings.DischargeSpeed = 0.25;

	UPROPERTY(Category = "Damage")
	FIslandRedBlueImpactOverchargeResponseComponentSettings LegPanelOverchargeSettings;
	default LegPanelOverchargeSettings.ChargeAmountPerImpact = 0.04;
	default LegPanelOverchargeSettings.StartDischargingDelay = 1.5;
	default LegPanelOverchargeSettings.DischargeSpeed = 0.5;

	UPROPERTY(Category = "Damage")
	float CablePanelDamagePerImpactFirstJump = 0.025;

	UPROPERTY(Category = "Damage")
	float CablePanelDamagePerImpactLaterJumps = 0.07;

	UPROPERTY(Category = "Damage")
	FIslandRedBlueImpactOverchargeResponseComponentSettings HeadPanelOverchargeSettings;
	default HeadPanelOverchargeSettings.ChargeAmountPerImpact = 0.05;  
	default HeadPanelOverchargeSettings.StartDischargingDelay = 0.5;
	default HeadPanelOverchargeSettings.DischargeSpeed = 0.5;

	UPROPERTY(Category = "Damage")
	float HeadDamageInitialDuration = 9.0;

	UPROPERTY(Category = "Damage")
	float HeadDamagePerImpactInitial = 0.0007;

	UPROPERTY(Category = "Damage")
	float HeadDamagePerImpact = 0.0015;

	UPROPERTY(Category = "Damage")
	float HeadDamagePerImpactSwim = 0.0012;

	UPROPERTY(Category = "Damage")
	float HeadDamagePerImpactHatchInitial = 0.001;

	UPROPERTY(Category = "Damage")
	float HeadDamagePerImpactHatchPostSwim = 0.005;

	UPROPERTY(Category = "Damage")
	bool bHeadStumpUseHealthBar = true;

	UPROPERTY(Category = "Damage")
	FVector HeadStumpHealthBarOffset = FVector(-500.0, 0.0, 0.0);

	UPROPERTY(Category = "Damage")
	FVector2D HeadStumpHealthBarScale = FVector2D(1.6, 3.0);


	UPROPERTY(Category = "ForceField")
	float ForceFieldReplenishCooldown = 0.5;

	UPROPERTY(Category = "ForceField")
	float ForceFieldReplenishAmountPerSecond = 0.1;

	UPROPERTY(Category = "ForceField")
	float ForceFieldPanelImpactSuppression = 0.01;

	UPROPERTY(Category = "ForceField")
	float CableForceFieldDefaultDamage = 1;


	UPROPERTY(Category = "WalkerHeadForceField")
	bool HeadForceFieldIsSupressedByShooting = true;

	UPROPERTY(Category = "WalkerHeadForceField")
	float HeadForceFieldReplenishCooldown = 2.0;

	UPROPERTY(Category = "WalkerHeadForceField")
	float HeadForceFieldReplenishAmountPerSecond = 0.5;


	UPROPERTY(Category = "Leg")
	float LegExplosionRadius = 100;


	UPROPERTY(Category = "WalkingFall")
	float WalkingFallDuration = 6.0;


	UPROPERTY(Category = "Suspend")
	float SuspendCableDeployDuration = 4.0;

	UPROPERTY(Category = "Suspend")
	float SuspendAcceleration = 500.0;

	UPROPERTY(Category = "Suspend")
	float SuspendFriction = 1.3;

	UPROPERTY(Category = "HeadMovement")
	float SuspendedTurnDuration = 10.0;

	UPROPERTY(Category = "Suspend")
	float SuspendStartLiftingPause = 0.8;

	UPROPERTY(Category = "Suspend")
	float SuspendHeight = -800.0; // Some height is currently included in animation

	UPROPERTY(Category = "Suspend")
	float SuspendIntroHoistMinDuration = 6.0;

	UPROPERTY(Category = "Suspend")
	float SuspendedEndingDurationReduction = 3.0; // At around 6s before end the head sinks below the surface 

	UPROPERTY(Category = "SuspendedSlowdown")
	float SlowdownMaxDilation = 0.9;

	UPROPERTY(Category = "SuspendedSlowdown")
	float SlowdownHeightStart = 0.0;

	UPROPERTY(Category = "SuspendedSlowdown")
	float SlowdownLateralDistanceStart = 2000.0;

	UPROPERTY(Category = "SuspendedSlowdown")
	float SlowdownEnterTime = 1.2;

	UPROPERTY(Category = "SuspendedSlowdown")
	float SlowdownHoldTime = 3.0;

	UPROPERTY(Category = "SuspendedSlowdown")
	float SlowdownExitTime = 2.0;


	UPROPERTY(Category = "CablesTarget")
	float CablesTargetGrenadeDetectionRange = 500.0;


	UPROPERTY(Category = "Firewall")
	float FirewallSprayFuelDuration = 8.0;

	UPROPERTY(Category = "Firewall")
	float FirewallIgnitionPause = 2.0;

	UPROPERTY(Category = "Firewall")
	float FirewallIgniteDuration = 2.0;

	UPROPERTY(Category = "Firewall")
	float FirewallOutsidePoolRange = 500.0;

	UPROPERTY(Category = "Firewall")
	float FirewallWalkerDistanceFromPoolEdge = 1500.0;

	UPROPERTY(Category = "Firewall")
	float FirewallCooldown = 8.0;

	UPROPERTY(Category = "Firewall")
	FVector FirewallNeckOffset = FVector(500.0, 0.0, -400.0);

	UPROPERTY(Category = "Firewall")
	float FirewallSprayFuelSpeed = 5000.0;

	UPROPERTY(Category = "Firewall")
	float FirewallIgnitionFlameSpeed = 5000.0;

	UPROPERTY(Category = "Firewall")
	float FirewallDamagePerSecond = 1.0;

	UPROPERTY(Category = "Firewall")
	float FirewallBurnDuration = 4.0;

	UPROPERTY(Category = "Firewall")
	float FirewallIgnitionFlameDamageRadius = 80.0;

	UPROPERTY(Category = "Firewall")
	float FirewallDamageRadius = 600.0;

	UPROPERTY(Category = "Firewall")
	float FirewallDamageShenanigansHeight = 300.0;

	UPROPERTY(Category = "Firewall")
	float FirewallDissipateDuration = 2.0;

	UPROPERTY(Category = "Firewall")
	float FirewallPostDissipateRemainDuration = 5.0;

	UPROPERTY(Category = "ClusterMines")
	float ClusterMinesTelegraphDuration = 6.0;

	UPROPERTY(Category = "ClusterMines")
	float ClusterMinesAttackDuration = 4.0;

	UPROPERTY(Category = "ClusterMines")
	float ClusterMinesRecoverDuration = 4.0;

	UPROPERTY(Category = "ClusterMines")
	FVector ClusterMinesHoistOffset = FVector(1500.0, 0.0, -700.0);

	UPROPERTY(Category = "ClusterMines")
	int ClusterMinesPerPlayer = 8;

	UPROPERTY(Category = "ClusterMines")
	float ClusterMineDispersionInterval = 800.0;

	UPROPERTY(Category = "ClusterMines")
	float ClusterMineOutsidePoolRange = 1200.0;
	
	UPROPERTY(Category = "ClusterMines")
	float ClusterMineScatterFactor = 0.5;

	UPROPERTY(Category = "ClusterMines")
	float ClusterMinePatternHoleChance = 0.3;

	UPROPERTY(Category = "ClusterMines")
	float ClusterMineLaunchSpeed = 3000.0;

	UPROPERTY(Category = "ClusterMines")
	float ClusterMineNearPlayerRange = 300.0; 

	UPROPERTY(Category = "ClusterMines")
	float ClusterMineTelegraphExplosionTime = 2.0; 

	UPROPERTY(Category = "ClusterMines")
	float ClusterMineMaxExplosionDelay = 1000000.0; // Do not explode from timing out

	UPROPERTY(Category = "ClusterMines")
	float ClusterMineDamage = 0.9; 

	UPROPERTY(Category = "ClusterMines")
	float ClusterMineDamageRadius = 400.0;

	UPROPERTY(Category = "ClusterMines")
	float ClusterMineExpirationDelay = 5.0;

	UPROPERTY(Category = "ClusterMines")
	float ClusterMinesAttackCooldown = 5.0;

	UPROPERTY(Category = "ClusterMines")
	float ClusterMineDamageFromBullets = 0.25;


	UPROPERTY(Category = "Detach")
	float DetachIntroRiseHeight = 500.0;

	UPROPERTY(Category = "Detach")
	float DetachIntroPauseDuration = 3.0;

	UPROPERTY(Category = "Detach")
	float DetachIntroMoveSpeed = 3000.0;

	UPROPERTY(Category = "Detach")
	float DetachIntroForcefieldGrowthSpeed = 0.3;


	UPROPERTY(Category = "FireChase")
	float FireChaseDuration = 20.0;

	UPROPERTY(Category = "FireChase")
	float FireChaseMoveSpeed = 1600.0;

	UPROPERTY(Category = "FireChase")
	float FireChaseHeight = 1000.0;

	UPROPERTY(Category = "FireChase")
	float FireChaseOutsidePoolOffset = 600.0;

	UPROPERTY(Category = "FireChase")
	float FireChaseSprayRange = 1200.0;

	UPROPERTY(Category = "FireChase")
	float FireChaseDangerZoneLength = 500.0;

	UPROPERTY(Category = "FireChase")
	float FireChaseDamagePerSecond = 1.0;

	UPROPERTY(Category = "FireChase")
	float FireChaseRecoverDuration = 8.0;


	UPROPERTY(Category = "FireSwoop")
	float FireSwoopMinRange = 1000.0;

	UPROPERTY(Category = "FireSwoop")
	float FireSwoopDuration = 3.0;

	UPROPERTY(Category = "FireSwoop")
	float FireSwoopInitialTurnAngleThreshold = 30.0;

	UPROPERTY(Category = "FireSwoop")
	float FireSwoopInitialTurnDuration = 3.0;

	UPROPERTY(Category = "FireSwoop")
	float FireSwoopMaxTrackTargetDuration = 2.0;

	UPROPERTY(Category = "FireSwoop")
	float FireSwoopMoveSpeed = 3500.0;

	UPROPERTY(Category = "FireSwoop")
	float FireSwoopHeight = 1000.0;

	UPROPERTY(Category = "FireSwoop")
	float FireSwoopSprayRange = 1200.0;

	UPROPERTY(Category = "FireSwoop")
	float FireSwoopDamagePerSecond = 1.0;

	UPROPERTY(Category = "FireSwoop")
	float FireSwoopFloorBurnTime = 2.0;

	UPROPERTY(Category = "FireSwoop")
	float FireSwoopRecoverDuration = 2.0;


	UPROPERTY(Category = "FireBreaching")
	float FireBreachingMinRange = 1000.0;

	UPROPERTY(Category = "FireBreaching")
	float FireBreachingMinBreachingDuration = 3.0;

	UPROPERTY(Category = "FireBreaching")
	float FireBreachingDuration = 6.0;

	UPROPERTY(Category = "FireBreaching")
	float FireBreachingAngleThreshold = 30.0;

	UPROPERTY(Category = "FireSwoop")
	float FireBreachingMaxTrackTargetDuration = 2.0;

	UPROPERTY(Category = "FireBreaching")
	float FireBreachingAscendSpeed = 4000.0;

	UPROPERTY(Category = "FireBreaching")
	float FireBreachingMoveSpeed = 3500.0;

	UPROPERTY(Category = "FireBreaching")
	float FireBreachingHeight = 900.0;

	UPROPERTY(Category = "FireBreaching")
	float FireBreachingSprayRange = 1200.0;

	UPROPERTY(Category = "FireBreaching")
	float FireBreachingSpraySweepAmplitude = 600.0;

	UPROPERTY(Category = "FireBreaching")
	float FireBreachingDamagePerSecond = 1.0;

	UPROPERTY(Category = "FireBreaching")
	float FireBreachingFloorBurnTime = 2.0;

	UPROPERTY(Category = "FireBreaching")
	float FireBreachingRecoverDuration = 2.0;

	UPROPERTY(Category = "FireBreaching")
	float FireBreachingCooldown = 10.0;

	UPROPERTY(Category = "FireBreaching")
	float FireBreachingInitialCooldown = 18.0;


	UPROPERTY(Category = "SwimmingIntro")
	float SwimmingIntroMoveSpeed = 3000.0;

	UPROPERTY(Category = "SwimmingIntro")
	float SwimmingIntroDivePause = 4.0;

	UPROPERTY(Category = "SwimmingIntro")
	float SwimmingIntroDiveDepth = 500.0;


	UPROPERTY(Category = "SwimAround")
	float SwimAroundDepth = 200.0;

	UPROPERTY(Category = "SwimAround")
	float SwimAroundObstructedDepth = 350.0;

	UPROPERTY(Category = "SwimAround")
	float SwimAroundSpeed = 1500.0;

	UPROPERTY(Category = "SwimAround")
	float SwimAroundTurnDuration = 6.0;

	UPROPERTY(Category = "SwimAround")
	float SwimAroundDiveSpeed = 3000.0;


	UPROPERTY(Category = "HeadHurtReaction")
	float HeadHurtReactionRecoverDuration = 3.0;


	UPROPERTY(Category = "HeadMovement")
	float HeadFriction = 2.0;

	UPROPERTY(Category = "HeadMovement")
	float HeadBrakeFriction = 6.0;

	UPROPERTY(Category = "HeadMovement")
	FVector HeadWobbleFrequency	= FVector(4.3, 5.37, 2.29);

	UPROPERTY(Category = "HeadMovement")
	FVector HeadWobbleAmplitude	= FVector(15.0, 20.0, 20.0);

	UPROPERTY(Category = "HeadMovement")
	float HeadWobbleRollFrequency = 2.57;

	UPROPERTY(Category = "HeadMovement")
	float HeadWobbleRollAmplitude = 3.0;

	UPROPERTY(Category = "HeadMovement")
	float HeadTurnDuration = 4.0;

	UPROPERTY(Category = "HeadMovement")
	float HeadSwimmingMaxBuoyancy = 982.0 * 1.35;

	UPROPERTY(Category = "HeadMovement")
	float HeadSwimmingMaxBuoyancyDepth = 400.0;


	UPROPERTY(Category = "HeadGrenadeLocks")
	float HeadLocksGrenadeDetectionRange = 380.0;


	UPROPERTY(Category = "HeadCrash")
	float HeadCrashHealthThreshold = 0.75;

	UPROPERTY(Category = "HeadCrash")
	float HeadSwimmingCrashHealthThreshold = 0.25;

	UPROPERTY(Category = "HeadCrash")
	float HeadCrashRecoverAtHeadExtraDuration = 2.0;

	UPROPERTY(Category = "HeadCrash")
	float HeadCrashRecoverInteractedExtraDuration = 6.0;

	UPROPERTY(Category = "HeadCrash")
	float HeadCrashControlHeight = 2500.0;

	UPROPERTY(Category = "HeadCrash")
	float HeadCrashStayDuration = 12.0;

	UPROPERTY(Category = "HeadCrash")
	float HeadCrashRecoverDuration = 2.0;

	UPROPERTY(Category = "HeadCrash")
	float HeadCrashRecoverHealth = 0.125;

	UPROPERTY(Category = "HeadCrash")
	int HeadCrashNumThrustersToExtinguish = 3;

	UPROPERTY(Category = "HeadCrash")
	bool bHeadSwimmingCrashAllowAttacks = true;

	UPROPERTY(Category = "HeadCrash")
	float HeadCrashAttackInitialPause = 1.0;

	UPROPERTY(Category = "HeadCrash")
	float HeadCrashAttackStartRadius = 400.0;

	UPROPERTY(Category = "HeadCrash")
	float HeadCrashAttackEndRadius = 1500.0;

	UPROPERTY(Category = "HeadCrash")
	float HeadCrashAttackDamage = 0.9;

	UPROPERTY(Category = "HeadCrash")
	float HeadCrashAttackWaveHeight = 120.0;

	UPROPERTY(Category = "HeadCrash")
	float HeadCrashAttackWaveWidth = 100.0;

	UPROPERTY(Category = "HeadCrash")
	float HeadCrashAttackSpeed = 1500.0;

	UPROPERTY(Category = "HeadCrash")
	float HeadCrashAttackKnockbackForce = 1000.0;

	UPROPERTY(Category = "HeadCrash")
	float HeadCrashAttackKnockbackDuration = 1.0;

	UPROPERTY(Category = "HeadCrash")
	float HeadCrashAttackWaveExpirationDelay = 2.0;


	UPROPERTY(Category = "AcidBlob")
	int AcidBlobSquirtsPerSequence = 6;

	UPROPERTY(Category = "AcidBlob")
	float AcidBlobSquirtMinRange = 600.0;

	UPROPERTY(Category = "AcidBlob")
	float AcidBlobBounceDuration = 4.0;

	UPROPERTY(Category = "AcidBlob")
	float AcidBlobExpirationDelay = 2.0;

	// How many times initial projectile is split when there are no obstructions
	UPROPERTY(Category = "AcidBlob")
	int AcidBlobSplits = 1; 

	UPROPERTY(Category = "AcidBlob")
	int AcidBlobSplitYaw = 20.0;

	UPROPERTY(Category = "AcidBlob")
	float AcidBlobSplitSlowdown = 0.85;

	UPROPERTY(Category = "AcidBlob")
	float AcidBlobGravity = 982.0 * 2.0;

	UPROPERTY(Category = "AcidBlob")
	float AcidBlobLaunchHeight = 200.0;

	UPROPERTY(Category = "AcidBlob")
	float AcidBlobLaunchSpeed = 800.0;

	UPROPERTY(Category = "AcidBlob")
	float AcidBlobBounceElasticity = 0.9;

	UPROPERTY(Category = "AcidBlob")
	float AcidBlobDamagePlayer = 0.3;


	UPROPERTY(Category = "HeadEscape")
	float HeadEscapeSpeed = 1200.0;

	UPROPERTY(Category = "HeadEscape")
	float HeadEscapeFloodedSpeed = 4000.0; //2000.0

	UPROPERTY(Category = "HeadEscape")
	float HeadEscapeSwitchCameraDuration = 5.0;

	UPROPERTY(Category = "HeadEscape")
	float HeadEscapeTurnDuration = 2.0;

	// Impulse when players are thrown off from head. X and Y are in hatch space, though Y gets inverted if you are to the left of hatch. Z is in world space.
	UPROPERTY(Category = "HeadEscape")
	FVector HeadEscapeThrowOffPlayerImpulse = FVector(-1000.0, 800.0, 2000.0);

	UPROPERTY(Category = "HeadEscape")
	float HeadEscapePostAnimRecoverDuration = 2.0;


	UPROPERTY(Category = "HeadDestruction")
	float HeadDestroyedDuration = 0.5;


	UPROPERTY(Category = "Hatch")
	float HatchShowShootTutorialDelay = 1.0;

	UPROPERTY(Category = "Hatch")
	FVector HatchButtonMashOffset = FVector(-140.0, 0.0, 0.0);

	UPROPERTY(Category = "Hatch")
	EButtonMashDifficulty HatchButtonMashDifficulty = EButtonMashDifficulty::Hard;


	UPROPERTY(Category = "SplashAttack")
	float SplashAttackCooldown = 6.0;

	UPROPERTY(Category = "HeadCharge")
	float HeadChargeTelegraphDuration = 4.0;

	UPROPERTY(Category = "HeadCharge")
	float HeadChargeMaxYawTracking = 45.0;

	UPROPERTY(Category = "HeadCharge")
	float HeadChargeCooldown = 5.0;

	UPROPERTY(Category = "HeadCharge")
	float HeadChargeOvershoot = 0.0;

	UPROPERTY(Category = "HeadCharge")
	float HeadChargeTargetPredictionDuration = 1.0;

	UPROPERTY(Category = "HeadCharge")
	float HeadChargeSpeed = 10000.0;

	UPROPERTY(Category = "HeadCharge")
	float HeadChargeDamage = 1.0;

	UPROPERTY(Category = "HeadCharge")
	float HeadChargeAccelerationDuration = 0.5;

	UPROPERTY(Category = "HeadCharge")
	float HeadChargeHeight = 500.0;

	UPROPERTY(Category = "HeadCharge")
	float HeadChargeMaxDuration = 6.0;

	UPROPERTY(Category = "HeadCharge")
	float HeadChargeReachFactor = 1000.0;

	UPROPERTY(Category = "HeadCharge")
	FVector HeadChargeReachCurvature = FVector(0.7, 0.5, 2.5);

	// Hold the recharge state this long
	UPROPERTY(Category = "Buzzer")
	int SuspendedRechargeDuration = 15;

	// Wait this long before we start checking if we should recharge again
	UPROPERTY(Category = "Buzzer")
	int SuspendedRechargeDelayDuration = 6;

	UPROPERTY(Category = "DeployHead")
	float DeployHeadDuration = 5.0;

	UPROPERTY(Category = "DeployHead")
	float DeploySpeed = 200.0;

	UPROPERTY(Category = "DeployHead")
	FVector DeployNeckOffset = FVector(0.0, 0.0, 0.0);

	UPROPERTY(Category = "Chase")
	float ChaseMinRange = 800;

	UPROPERTY(Category = "Chase")
	float ChaseMoveSpeed = 175;

	UPROPERTY(Category = "Chase")
	float ChaseOffset = 2500;


	// Maximum this amount of spawned minions at one time
	UPROPERTY(Category = "Dyad")
	int DyadMaxSpawnCount = 3;

	// Add this amount to maximum of spawned minions at one time (used in later phases)
	UPROPERTY(Category = "Dyad")
	int DyadAdditionalMaxSpawnCount = 5;

	// Spawn new minions with this interval during a burst of spawn
	UPROPERTY(Category = "Dyad")
	float DyadSpawnBurstInterval = 0.5;

	// Wait this long before we spawn new minions after one minion is destroyed
	UPROPERTY(Category = "Dyad")
	float DyadSpawnBurstDelay = 8;

	UPROPERTY(Category = "Breath")
	float BreathDuration = 1;

	UPROPERTY(Category = "Breath")
	float BreathCooldown = 8;

	UPROPERTY(Category = "Breath")
	float BreathRingMaximumRadius = 2500;

	UPROPERTY(Category = "Breath")
	float BreathRingExpansionSpeed = 300;

	UPROPERTY(Category = "Breath")
	float BreathRingDamageWidth = 400;

	UPROPERTY(Category = "CableSuspension")
	float CableSuspensionBrokenGravity = 982.0;

	UPROPERTY(Category = "CableSuspension")
	float CableSuspensionMaxFallHeight = 700.0;

	UPROPERTY(Category = "CableSuspension")
	float CableSuspensionSingleFallHeight = 300.0;

	UPROPERTY(Category = "CableSuspension")
	float CablePushStiffness = 10.0;

	UPROPERTY(Category = "CableSuspension")
	float CablePullStiffness = 10.0;

	UPROPERTY(Category = "ForceField")
	float HeadForceFieldDefaultDamage = 0.12;

	UPROPERTY(Category = "Splash")
	float SplashDuration = 1;

	UPROPERTY(Category = "Splash")
	float SplashCooldown = 6;

	UPROPERTY(Category = "Splash")
	float SplashInitialRadius = 1000;

	UPROPERTY(Category = "Splash")
	float SplashMaximumRadius = 9000;

	UPROPERTY(Category = "Splash")
	float SplashExpansionSpeed = 1900;

	UPROPERTY(Category = "Splash")
	float SplashDamageWidth = 50;


	UPROPERTY(Category = "Charge")
	float ChargeMoveSpeed = 2000.0;

	UPROPERTY(Category = "Charge")
	float ChargeAccelerationDuration = 5.0;

	UPROPERTY(Category = "Charge")
	float ChargeTelegraphDuration = 3.0;

	UPROPERTY(Category = "Charge")
	float ChargeStopDuration = 2.0;

	UPROPERTY(Category = "Charge")
	float ChargeDamage = 1.0;

	UPROPERTY(Category = "Charge")
	float ChargeMaxDuration = 8.0;

	UPROPERTY(Category = "Charge")
	float ChargeCooldown = 12.0;

	UPROPERTY(Category = "Charge")
	float ChargeNearWallsStopRange = 4000.0;

	UPROPERTY(Category = "Targeting")
	float SwitchTargetMinInterval = 2.0;

	UPROPERTY(Category = "Targeting")
	float SwitchTargetWhileTrackingDelay = 5.0;
}

namespace DevTogglesWalker
{
	const FHazeDevToggleBool FragileHead;
	const FHazeDevToggleBool SlowCrashRecovery;
}