namespace PrisonBoss
{
	const float CircleMoveSpeed = 600.0;

	//Ground Trail
	const float GroundTrailEnterDuration = 2.6;
	const float GroundTrailSlamDelay = 2.2;
	const float GroundTrailSlamDamageRange = 500.0;
	const float GroundTrailExplodeDelay = 1.2;
	const float GroundTrailSpawnInterval = 0.4;
	const float GroundTrailDrawSpeed = 6000.0;
	const int MaxGroundTrails = 3;
	const int GroundTrailPatternAmount = 4;
	const float GroundTrailDamageRange = 70.0;
	const float GroundTrailExitDuration = 2.5;

	//Wave Slash
	const float WaveSlashEnterDuration = 1;
	const float WaveSlashInitialSpawnDelay = 0.1;
	const int WaveSlashAmount = 18;
	const int WaveSlashPhase3Amount = 8;
	const float WaveSlashInterval = 0.4;
	const float WaveSlashProjectileMoveSpeed = 1400.0;
	const float WaveSlashProjectileRotationSpeed = 120.0;
	const float WaveSlashExitDuration = 1.6;

	//Hackable Magnetic Projectile
	const float HackableMagneticProjectileEnterDuration = 2.0;
	const float HackableMagneticProjectileSpawnDelay = 0.5;
	const float HackableMagneticProjectileVolleyDelay = 1.5;
	const float HackableMagneticProjectileLaunchDelay = 0.5;
	const float HackableMagneticProjectileHitDuration = 2.0;

	//Spiral
	const float SpiralEnterDuration = 2.1;
	const float SpiralAttackDuration = 3.2;
	const float SpiralExplodeDelay = 0.5;
	const float SpiralExitDuration = 2.3;

	//Dash Slash
	const float DashSlashEnterDuration = 0.866667;
	const int DashSlashAttackAmount = 4;
	const float DashSlashTelegraphDuration = 1.1;
	const float DashSlashAlignDuration = 1.1;
	const float DashSlashAttackWindUpDuration = 0.5;
	const float DashSlashAttackWindDownDuration = 1.0;
	const float DashSlashSpeed = 6500.0;
	const float DashSlashDamageRange = 250.0;
	const float DashSlashExitDuration = 1.0;

	//Clone
	const float CloneEnterDuration = 0.6;
	const float CloneSpawnInterval = 0.1;
	const int MaxCloneAmount = 20.0;
	const float CloneAttackInterval = 0.3;
	const float CloneTelegraphDuration = 3.0;
	const float CloneAttackSpeed = 2800.0;
	const float CloneAttackDamageRange = 600.0;
	const float CloneAttackWindUp = 0.7;
	const float CloneAttackDuration = 3.266667;

	//Grab Player
	const float GrabPlayerMinStartDistance = 2000.0;
	const float GrabPlayerEnterDuration = 1.33;
	const float GrabPlayerFlySpeed = 2500.0;
	const float GrabPlayerDistance = 650.0;
	const float GrabPlayerMaxDistanceFromMid = 1000.0;
	const float GrabPlayerAdjustSpeed = 800.0;

	//Choke
	const float MaxChokeDuration = 3.75;
	const float ChokeButtonMashGainPerMagnetBurst = 0.5;
	const float ChokeFailBlackAndWhiteDelay = 3.3;
	const int ChokeMagnetBurstsRequired = 3;
	const float ChokeExitDuration = 3.0;

	//Donut
	const float DonutSpawnInterval = 4.0;
	const float DonutSpawnDelay = 0.6;
	const float DonutSpawnDuration = 1.0;
	const float DonutSpawnMinRadius = 200.0;
	const float DonutSpawnMaxRadius = 300.0;
	const float DonutMaxRadius = 6000.0;
	const float DonutRadiusIncreaseSpeed = 2600.0;

	//Grab Debris
	const float GrabDebrisGrabDuration = 2.0;
	const float GrabDebrisHoldDuration = 1.0;
	const float GrabDebrisDeflectDetachDelay = 0.8;

	//Platform Danger Zone
	const float PlatformDangerZoneSpawnDelay = 1.0;
	const float PlatformDangerZoneExitDuration = 2.0;

	//Horizontal Slash
	const float HorizontalSlashEnterDuration = 1.0;
	const float HorizontalSlashInterval = 1.0;
	const float HorizontalSlashSpawnDelay = 0.5;
	const int HorizontalSlashAmount = 5;
	const float HorizontalSlashExitDuration = 1.3;

	//Magnetic Slam
	const float MagneticSlamEnterDuration = 2.0;
	const float MagneticSlamDamageRange = 200.0;
	const float MagneticSlamGroundedDuration = 5.0;
	const int MagneticSlamBurstsRequired = 3;
	const float MagneticSlamGroundedDurationIncreasePerMagnetBurst = 0.75;
	const float MagneticSlamExitDuration = 3.0;
	const float MagneticSlamExitDamageBlastRange = 300.0;

	//ZigZag
	const float ZigZagEnterDuration = 1.0;
	const float ZigZagInterval = 0.5;
	const float ZigZagSpawnDelay = 0.1;
	const int ZigZagAmount = 12;
	const float ZigZagExitDuration = 1.4;

	//Scissors
	const float ScissorsEnterDuration = 1.3;
	const float ScissorsSweepInitialDelay = 0.5;
	const float ScissorsSpawnDelay = 0.0;
	const float ScissorsSweepDuration = 2.2;
	const float ScissorsSweepInterval = 0.5;
	const float ScissorsSweepAngle = 45.0;
	const int ScissorsSweepAmount = 3;
	const float ScissorsExitDuration = 1.0;

	//Volley
	const float VolleyPrimeDuration = 1.5;
	const float VolleyPrimeMinOffset = 320.0;
	const float VolleyPrimeMaxOffset = 400.0;

	//Take Control
	const float TakeControlGrabDebrisDeflectDetachDelay = 1.4;

	//BRAIN STUFF BELOW

	//Pulse Attack
	const int PulsesAttacksPerWave = 6;
	const float PulseAttackInterval = 0.2;
	const float PulseAttackWaveInterval = 1.8;
	const float PulseAttackProjectileSpeed = 1250.0;
	const float PulseAttackLifeTime = 6.0;
	const float PulseAttackDamage = 0.25;

	//Draw Attack
	const FVector2D DrawAttackIntervalRange = FVector2D(1.35, 1.8);
	const FVector2D DrawAttackSpeedRange = FVector2D(2200.0, 2600.0);
	const float DrawAttackLifeTime = 1.0;
	const float DrawAttackDamageDistance = 25.0;
	const float DrawAttackDamage = 0.25;
}