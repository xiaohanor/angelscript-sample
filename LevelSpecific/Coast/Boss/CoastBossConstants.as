namespace CoastBossConstants
{
	const bool bUseWeakpoint = false;
	const ECoastBossPhase LastPhase = ECoastBossPhase::Phase6;

	namespace PowerUp
	{
		const float SpawnIntervalMin = 5.0; 
		const float SpawnIntervalMax = 20.0; 

		const float BarragePowerUpDuration = 6.5;
		const float BarrageDamageMultiplier = 0.25;

		const float LaserPowerUpDuration = 6.0;
		const float LaserPowerUpDamagePerSecond = 0.01;
		const float LaserPowerUpDamageCooldown = 0.1;

		const float HomingPowerUpDuration = 7.0;
		const float HomingBulletInterval = 0.3; // no performance guaranteed lel
		const float HomingBulletSpeed = 5500.0;
		const float HomingBulletDamage = (HomingBulletInterval / 64.0) * 0.4;
		const float HomingInterpSpeed = 7.0;

		const float Radius = 75.0;
		const float AliveDuration = 20.0;
		const float SinusLoopTime = 1.5;

		const float SinusWidthOffset = 70.0;
	}

	namespace Player
	{
		const float MioVerticalEnterOffset = 300.0;
		const float MioHorizontalExitOffset = 200.0;

		const float MoveSpeedHorizontal = 1500.0;
		const float MoveSpeedVertical = 1200.0;

		const float DashCooldown = 0.35;
		const float DashDuration = 0.3;
		const float DashAddedMoveMultiplier = 3.0;

		const float ShipTiltDegrees = 12.5;

		const float BulletSpeed = 5500.0;
		const float BulletInterval = 0.15; // no performance guaranteed lel

		// BULLET DAMAGE
		const float NumPhases = float(LastPhase) + 1.0;
		const float DesiredDPS = (BulletInterval / 64.0) * 0.5; // you win if you hit all shots during 100 secs. Should take 2-3min though
		const float PlayerBulletDamage = DesiredDPS; // how many shots are required to take down a plane
		// We start scaling DamageMultiplier upwards, so it becomes easier the longer a phase takes
		const float DamageEndMultiplier = 3.0;
		const float DamageEndMultiplierDuration = 20.0;

		// HP and invincible frames
		const float InvincibleFramesDuration = 1.0;

		const float ShieldRegenerationDuration = 8.0;
		const float InvincibleFramesShieldRegenerationDuration = 0.5;
	}

	// breaking some naming conventions for easier readability c:
	// could have more nested namespaces instead but I don't think you nor me really prefer that

	namespace BigDroneBoss
	{
		const float BigBossCollisionHitPlayersRadius = 400.0; // actual mesh size
		const float BigBossCollisionPlayersHitBulletRadius = 520.0; // since collison is offset this looks more correct
		const float BigBossOffsetShootBallsRadius = 650.0;

		const float GunAnticipationDuration = 0.05;
		const float GunRecoilDuration = 0.1;
		const float GunRecoilOffset = 40.0;

		const float Phase1_WaveAttack_Interval = 1.5;
		const float Phase1_WaveAttack_Duration = 1.5;
		const int Phase1_WaveAttack_NumBullets = 8;
		const float Phase1_WaveAttack_BulletSpeed = 1500.0;
		const float Phase1_WaveAttack_MoveUpPercent = 0.2;
		const float Phase1_WaveAttack_MoveDownPercent = 0.2;

		const float Phase2_CrossAttack_ShootAngleSpan = 45.0;
		const float Phase2_CrossAttack_Speed = 750.0;
		const float Phase2_CrossAttack_Cooldown = 1.8;

		const float Phase2_CrossMoveUpDown_TotalDuration = 4.0;
		const float Phase2_CrossMoveUpDown_Duration = Phase2_CrossMoveUpDown_TotalDuration * 0.5;
		const float Phase2_CrossMoveDownUp_Duration = Phase2_CrossMoveUpDown_TotalDuration * 0.5;
		const float Phase2_CrossMoveUpDown_Percent = 0.8;
		const float Phase2_CrossMoveDownUp_Percent = 0.8;

		const float Phase3_SunBurstAttack_ShootAngleSpan = 60.0;
		const float Phase3_SunBurstAttack_BulletSpeed = 1200.0;
		const float Phase3_SunMine_Health = 6.0;
		const float Phase3_RainAttack_MoveUpDuration = 1.5;
		const float Phase3_RainAttack_MoveDownDuration = 3.0;
		const float Phase3_RainAttack_MoveScreenDuration = 4.5;
		const float Phase3_RainAttack_BulletSpeedMin = 600.0;
		const float Phase3_RainAttack_BulletSpeedMax = 1000.0;
		const float Phase3_RainAttack_PendulumDuration = 0.5;
		const int Phase3_RainAttack_Repeats = 2;

		const float Phase3_RainAttack_TotalDuration =
			Phase3_RainAttack_MoveUpDuration +
			Phase3_RainAttack_MoveDownDuration +
			Phase3_RainAttack_MoveScreenDuration * 2.0 * Phase3_RainAttack_Repeats;

		const float Phase4_ChargetAttack_AnticipationDuration = 1.0;
		const float Phase4_ChargetAttack_ChargeDuration = 4.0;
		const float Phase4_BurstAttack_Duration = 1.0;

		const float Phase5_VolleyAttack_Interval = 0.8;
		const float Phase5_VolleyAttack_Cooldown = 2.0;
		const float Phase5_VolleyAttack_BulletSpeed = 1200.0;
		const float Phase5_VolleyAttack_AngleSpan = 30.0;
		const int Phase5_VolleyAttack_NumBullets = 8;

		const int Phase6_BossSpeedMin = 900.0;
		const int Phase6_BossSpeedMax = 1850.0;
		const float Phase6_PingPongVolley_BulletIntervalMin = 0.3;
		const float Phase6_PingPongVolley_BulletIntervalMax = 1.0;
		const float Phase6_PingPongVolley_BulletSpeed = 1100.0;

	}

	namespace ManyDronesBoss
	{
		const float DroneCollisionRadius = 110.0;

		const float Phase24Drones_BulletCooldown = 0.312;
		const float Phase24Drones_BulletSpeed = 1300.0;

		const float Phase20Drones_CrossCooldown = 2.4;
		const float Phase20Drones_Cross_VelocityHorizontal = 500.0;
		const float Phase20Drones_Cross_VelocityMaxVertical = 200.0;

		// for phase 16 intervals, look in CoastBossAttackQueueCapability.as -> ShootSequence16()
		const float Phase16Drones_Weather_MineExplosionRadius = 300.0;

		const float Phase16Drones_Weather_CloudUpDuration = 1.5;
		const float Phase16Drones_Weather_CloudDownDuration = 3.0;
		const float Phase16Drones_Weather_CloudMoveScreenDuration = 2.5;
		const int Phase16Drones_Weather_CloudRainLoops = 2;

		const float Phase16Drones_Weather_CloudDuration = 
			Phase16Drones_Weather_CloudUpDuration +
			Phase16Drones_Weather_CloudDownDuration +
			Phase16Drones_Weather_CloudMoveScreenDuration * 2.0 * Phase16Drones_Weather_CloudRainLoops;

		const float Phase12Drones_DrillbazzWindUpDuration = 2.0;
		const float Phase12Drones_DrillbazzAttackDuration = 4.0;
		const float Phase12Drones_DrillbazzFadeoutWindDuration = 1.0;
		const float Phase12Drones_DrillbazzRetreatDuration = 5.0;
		const float Phase12Drones_DrillbazzPauseDuration = 2.0;
		const float Phase12Drones_VolleyDuration = 2.5;
		const float Phase12Drones_DrillbazzWhirlwindOffset = 500.0;

		const float Phase8Drones_AttackInterval = 0.5;
		const float Phase8Drones_AttackCooldown = 1.3;
		const float Phase8Drones_AttackSpeed = 1200.0;
		const float Phase8Drones_AttackAngleSpread = 30.0;
		const int Phase8Drones_AttackNumBullets = 9;
		const FVector2D Phase8Drones_Attack_ClockwiseMinMaxAngles = FVector2D(140.0, 160.0); // unit circle - angles degrees
		const FVector2D Phase8Drones_Attack_CClockwiseMinMaxAngles = FVector2D(200.0, 220.0); // unit circle - angles degrees

		const int Phase4Drones_SpeedBase = 200.0;
		const int Phase4Drones_SpeedPerDrone = 200.0;
		const float Phase4Drones_TrailAttackInterval = 0.7;
		const float Phase4Drones_WaveAttackSpeed = 1100.0;
		const float Phase4Drones_WaveAttackAngleSpread = 25.0;
		const int Phase4Drones_WaveAttackNumBullets = 8;

	}
}