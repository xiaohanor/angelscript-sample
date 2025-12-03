class UIslandOverseerSettings : UHazeComposableSettings
{	
	UPROPERTY(Category = "Peek")
	float PeekTelegraphDuration = 2;

	UPROPERTY(Category = "Peek")
	float PeekDuration = 5;

	UPROPERTY(Category = "Peek")
	float PeekRecoveryDuration = 3;

	UPROPERTY(Category = "Damage")
	float IntroCombatRedBlueDamagePerSecond = 0.025;

	UPROPERTY(Category = "Damage")
	float ChaseRedBlueDamagePerSecond = 0.01;

	UPROPERTY(Category = "Damage")
	float DoorRedBlueDamagePerSecond = 0.01;

	UPROPERTY(Category = "Damage")
	float DoorCutHeadRedBlueDamagePerSecond = 0.02;

	// Ball damage
	UPROPERTY(Category = "MissileAttack")
	float MissileAttackPlayerDamage = 0.5;

	UPROPERTY(Category = "MissileAttack")
	float MissileAttackTelegraphDuration = 0.5;

	// Seconds in between launched balls
	UPROPERTY(Category = "MissileAttack")
	float MissileAttackLaunchInterval = 0.1;

	// Initial impulse speed of balls
	UPROPERTY(Category = "MissileAttack")
	float MissileAttackLaunchSpeed = 2700.0;

	UPROPERTY(Category = "MissileAttack")
	float MissileAttackLaunchGravity = 9820.0;

	// How many balls fired per wave
	UPROPERTY(Category = "MissileAttack")
	int MissileAttackProjectileAmount = 5;

	// How many spread waves
	UPROPERTY(Category = "MissileAttack")
	int MissileAttackWaves = 4;

	UPROPERTY(Category = "MissileAttack")
	int MissileAttackAdditionalWaves = 0;

	// Phase attack damage
	UPROPERTY(Category = "PhaseAttack")
	float PhaseAttackPlayerDamage = 0.2;

	// Waves
	UPROPERTY(Category = "PhaseAttack")
	int PhaseAttackWaves = 10;

	// Initial impulse speed of phase attack projectiles
	UPROPERTY(Category = "PhaseAttack")
	float PhaseAttackLaunchSpeed = 600.0;

	// Seconds in between launched waves
	UPROPERTY(Category = "PhaseAttack")
	float PhaseAttackWaveInterval = 1.5;

	// Initial impulse speed of phase attack projectiles
	UPROPERTY(Category = "PhaseAttack")
	float PhaseAttackSpawnHeightOffset = 3000.0;

	// Distance between projectiles in a wave
	UPROPERTY(Category = "PhaseAttack")
	float PhaseAttackSpawnWaveDistance = 280.0;

	// Amount of phase attack projectiles per wave
	UPROPERTY(Category = "PhaseAttack")
	int PhaseAttackSpawnWaveAmount = 7;

	// Smash attack damage
	UPROPERTY(Category = "SmashAttack")
	float SmashAttackPlayerDamage = 0.2;

	// Initial impulse speed of quake projectiles
	UPROPERTY(Category = "SmashAttack")
	float SmashAttackQuakeLaunchSpeed = 450.0;

	// Initial impulse speed of quake projectiles
	UPROPERTY(Category = "SmashAttack")
	float SmashAttackQuakeLaunchOffsetZ = -250.0;

	UPROPERTY(Category = "Flood")
	float FloodBaseSpeed = 100;

	UPROPERTY(Category = "Flood")
	float FloodCatchUpDistance = 350;

	UPROPERTY(Category = "SideChase")
	float SideChaseProximityDamageDistance = 600;

	UPROPERTY(Category = "SideChase")
	float SideChaseRespawnDistance = 2000;

	UPROPERTY(Category = "SideChase")
	float SideChaseBaseSpeed = 250;

	UPROPERTY(Category = "SideChase")
	float SideChaseCatchUpDistance = 1500;

	UPROPERTY(Category = "TowardsChase")
	float TowardsChaseBaseSpeed = 350;

	UPROPERTY(Category = "TowardsChase")
	float TowardsChaseCatchUpDistance = 1000;

	UPROPERTY(Category = "TowardsChase")
	float TowardsChaseRespawnDistance = 2500;

	UPROPERTY(Category = "TowardsChase")
	float TowardsChaseProximityDamageDistance = 1200;

	UPROPERTY(Category = "Door")
	float DoorProximityDamageDistance = 600;

	UPROPERTY(Category = "LaserAttack")
	float LaserAttackPlayerDamagePerSecond = 2.0;

	UPROPERTY(Category = "LaserBombAttack")
	float LaserBombAttackPlayerDamagePerSecond = 6.0;

	// Return grenade damage
	UPROPERTY(Category = "ReturnGrenade")
	float ReturnGrenadeBossDamage = 0.05;

	// Seconds in between launched grenades
	UPROPERTY(Category = "ReturnGrenade")
	float ReturnGrenadeLaunchInterval = 0.3;

	UPROPERTY(Category = "ReturnGrenade")
	float ReturnGrenadeCooldown = 4;

	// Initial impulse speed of grenades
	UPROPERTY(Category = "ReturnGrenade")
	float ReturnGrenadeLaunchSpeed = 3500.0;

	// How many grenades fired
	UPROPERTY(Category = "ReturnGrenade")
	int ReturnGrenadeProjectileAmount = 3;

	// How many max additional grenades fired
	UPROPERTY(Category = "ReturnGrenade")
	int ReturnGrenadeProjectileMaxAdditionalAmount = 2;

	// Maximum amount of grenades that can be out simultaneously
	UPROPERTY(Category = "ReturnGrenade")
	int ReturnGrenadeProjectileAmountMax = 14;

	UPROPERTY(Category = "ReturnGrenade")
	float ReturnGrenadePlayerDamagePerSecond = 2.25;

	UPROPERTY(Category = "ReturnGrenade")
	float ReturnGrenadeIdealMinimumDistance = 350;

	UPROPERTY(Category = "ReturnGrenade")
	float ReturnGrenadeTelegraphDuration = 2;

	// WallBomb damage
	UPROPERTY(Category = "WallBomb")
	float WallBombPlayerDamage = 0.2;

	// WallBomb damage from red blue projectiles
	UPROPERTY(Category = "WallBomb")
	float WallBombRedBlueDamagePerSecond = 3;

	// Time between launched WallBombs
	UPROPERTY(Category = "WallBomb")
	float WallBombInterval = 0.2;

	// Cooldown between WallBombs volleys
	UPROPERTY(Category = "WallBomb")
	float WallBombCooldownDuration = 1;

	// Initial impulse speed of WallBombs
	UPROPERTY(Category = "WallBomb")
	float WallBombLaunchSpeed = 3000.0;

	// How many WallBombs per attack
	UPROPERTY(Category = "WallBomb")
	int WallBombAmount = 3;

	UPROPERTY(Category = "WallBomb")
	int WallBombBaseTargetDistance = 1750;

	UPROPERTY(Category = "RollerSweep")
	int RollerSweepPlayerDamage = 1.0;

	UPROPERTY(Category = "RollerSweep")
	int RollerSweepEnterSpeed = 1000;

	UPROPERTY(Category = "RollerSweep")
	int RollerSweepExitSpeed = 2500;

	UPROPERTY(Category = "RollerSweep")
	float RollerSweepRotationSpeed = 250;

	UPROPERTY(Category = "RollerSweep")
	float RollerSweepInitialMoveSpeed = 200;

	UPROPERTY(Category = "RollerSweep")
	float RollerSweepMoveSpeed = 1200;

	// How long it takes to achieve RollerSweepMoveSpeed, from 0
	UPROPERTY(Category = "RollerSweep")
	float RollerSweepMoveAccelerationDuration = 4;

	// How long we telegraph before we start moving towards players
	UPROPERTY(Category = "RollerSweep")
	float RollerSweepTelegraphDuration = 0.15;

	UPROPERTY(Category = "RollerSweep")
	float RollerSweepRedBlueDamagePerSecond = 0.1;

	UPROPERTY(Category = "RollerSweep")
	float RollerSweepCancelHitPauseDuration = 2.0;

	UPROPERTY(Category = "RollerSweep")
	float RollerSweepSettleDuration = 1;

	UPROPERTY(Category = "RollerSweep")
	float RollerSweepScale = 1.0;

	UPROPERTY(Category = "DoorAcid")
	float DoorAcidAmount = 3;

	UPROPERTY(Category = "DoorAcid")
	float DoorAcidCooldown = 3;

	UPROPERTY(Category = "DoorAcid")
	float DoorAcidMaximumRadius = 3200;

	UPROPERTY(Category = "DoorAcid")
	float DoorAcidExpansionSpeed = 800;

	UPROPERTY(Category = "DoorAcid")
	float DoorAcidDamageWidth = 70;

	UPROPERTY(Category = "Tremor")
	float TremorAmount = 1;

	UPROPERTY(Category = "Tremor")
	float TremorCooldown = 3;

	UPROPERTY(Category = "Tremor")
	float TremorMinimumRadius = 500;

	UPROPERTY(Category = "Tremor")
	float TremorMaximumRadius = 3200;

	UPROPERTY(Category = "Tremor")
	float TremorExpansionSpeed = 800;

	UPROPERTY(Category = "Tremor")
	float TremorDamageWidth = 70;
}