
class USkylineBallBossSmallBossProjectileActionComponent : UActorComponent
{
	FHazeStructQueue Queue;
};

asset SkylineBallBossSmallBossProjectileSheet of UHazeCapabilitySheet
{
	AddCapability(n"SkylineBallBossSmallBossActionProjectileLoopCapability");
	AddCapability(n"SkylineBallBossSmallBossActionNodeProjectileCapability");
	AddCapability(n"SkylineBallBossSmallBossActionNodeProjectileDelayCapability");

	AddCapability(n"SkylineBallBossSmallBossProjectileCapability");
};

class USkylineBallBossSmallBossActionProjectileLoopCapability : UHazeCapability
{
	FSkylineBallBossActionActivateData Params;
	default CapabilityTags.Add(SkylineBallBossTags::BallBoss);
	default CapabilityTags.Add(SkylineBallBossTags::Action);
	ASkylineBallBossSmallBoss SmallBoss;
	USkylineBallBossSmallBossProjectileActionComponent BossComp;

	bool bQueuedFirstDelays = false;

	bool bTargetZoe = false;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		SmallBoss = Cast<ASkylineBallBossSmallBoss>(Owner);
		BossComp = USkylineBallBossSmallBossProjectileActionComponent::GetOrCreate(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!HasControl())
			return false;
		if (!SmallBoss.bActive)
			return false;
		if (!SmallBoss.bDoActions)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!SmallBoss.bActive)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (!bQueuedFirstDelays)
		{
			bQueuedFirstDelays = true;
			Delay(7.0);
		}

		if (BossComp.Queue.IsEmpty())
			ProjectileLoop();
	}

	void ProjectileLoop()
	{
		FlipFlopProjectile();
		Delay(0.2);
		FlipFlopProjectile();
		Delay(0.2);
		FlipFlopProjectile();
		Delay(0.2);
		FlipFlopProjectile();

		Delay(4.0);

		Projectile(Game::Mio);
		Delay(1.0);
		Projectile(Game::Mio);
		Delay(1.0);
		Projectile(Game::Mio);
		Delay(1.0);
		Projectile(Game::Mio);
	
		Delay(2.0);
	}

	// ---------------------

	void FlipFlopProjectile()
	{
		bTargetZoe = !bTargetZoe;
		FSkylineBallBossSmallBossActionNodeProjectileData Data;
		Data.TargetPlayer = bTargetZoe ? Game::Zoe : Game::Mio;
		BossComp.Queue.Queue(Data);
	}

	void Projectile(AHazePlayerCharacter TargetPlayer)
	{
		FSkylineBallBossSmallBossActionNodeProjectileData Data;
		Data.TargetPlayer = TargetPlayer;
		BossComp.Queue.Queue(Data);
	}

	void Delay(float Delay)
	{
		FSkylineBallBossSmallBossActionNodeProjectileDelayCapabilityData Data;
		Data.Duration = Delay;
		BossComp.Queue.Queue(Data);
	}
}
