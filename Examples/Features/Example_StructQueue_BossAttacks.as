enum EExampleBossPhase
{
	PhaseOne,
	PhaseTwo,
}

struct FExampleBossIdleData
{
	float Duration;
}

struct FExampleBossJumpAttackData
{
	AHazePlayerCharacter TargetPlayer;
}

struct FExampleBossSlamAttackData
{
}

class UExampleBossAttacksComponent : UActorComponent
{
	FHazeStructQueue AttackQueue;
	EExampleBossPhase CurrentPhase = EExampleBossPhase::PhaseOne;
}

class UExampleBossAttackSelectionCapability : UHazeCapability
{
	UExampleBossAttacksComponent BossComp;
	
	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		BossComp = UExampleBossAttacksComponent::GetOrCreate(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!HasControl())
			return false;
		if (BossComp.AttackQueue.IsEmpty())
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!BossComp.AttackQueue.IsEmpty())
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (BossComp.CurrentPhase == EExampleBossPhase::PhaseOne)
		{
			Idle(2.0);
			JumpAttack(Game::Mio);
			Idle(2.0);
			JumpAttack(Game::Zoe);
			Idle(2.0);
			SlamAttack();
		}
		else if (BossComp.CurrentPhase == EExampleBossPhase::PhaseTwo)
		{
			switch (Math::RandRange(0, 1))
			{
				case 0:
					JumpAttackSequence();
					Idle(2.0);
				break;
				case 1:
					SlamAttack();
					Idle(2.0);
				break;
			}
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnLogState(FTemporalLog TemporalLog)
	{
		// The struct queue can be logged directly to the temporal log
		TemporalLog.Value("AttackQueue", BossComp.AttackQueue);
	}

	void JumpAttackSequence()
	{
		Idle(2.0);
		JumpAttack(Game::Mio);
		Idle(2.0);
		JumpAttack(Game::Zoe);
	}

	void Idle(float Duration)
	{
		FExampleBossIdleData IdleData;
		IdleData.Duration = Duration;
		BossComp.AttackQueue.Queue(IdleData);
	}
	
	void JumpAttack(AHazePlayerCharacter TargetPlayer)
	{
		FExampleBossJumpAttackData AttackData;
		AttackData.TargetPlayer = TargetPlayer;
		BossComp.AttackQueue.Queue(AttackData);
	}

	void SlamAttack()
	{
		FExampleBossSlamAttackData AttackData;
		BossComp.AttackQueue.Queue(AttackData);
	}
}

class UExampleBossIdleCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	
	UExampleBossAttacksComponent BossComp;

	FExampleBossIdleData Params;
	
	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		BossComp = UExampleBossAttacksComponent::GetOrCreate(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FExampleBossIdleData& ActivationParams) const
	{
		if (BossComp.AttackQueue.Start(this, ActivationParams))
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!BossComp.AttackQueue.IsActive(this))
			return true;
		if (ActiveDuration > Params.Duration)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FExampleBossIdleData ActivationParams)
	{
		Params = ActivationParams;
		Print("Example boss idle: "+Params.Duration);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		BossComp.AttackQueue.Finish(this);
	}
}

class UExampleBossJumpAttackCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	UExampleBossAttacksComponent BossComp;

	FExampleBossJumpAttackData Params;
	
	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		BossComp = UExampleBossAttacksComponent::GetOrCreate(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FExampleBossJumpAttackData& ActivationParams) const
	{
		if (BossComp.AttackQueue.Start(this, ActivationParams))
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!BossComp.AttackQueue.IsActive(this))
			return true;
		if (ActiveDuration > 1.0)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FExampleBossJumpAttackData ActivationParams)
	{
		Params = ActivationParams;
		Print("Example boss jump: "+Params.TargetPlayer);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		BossComp.AttackQueue.Finish(this);
	}
}

class UExampleBossSlamAttackCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	UExampleBossAttacksComponent BossComp;

	FExampleBossSlamAttackData Params;
	
	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		BossComp = UExampleBossAttacksComponent::GetOrCreate(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FExampleBossSlamAttackData& ActivationParams) const
	{
		if (BossComp.AttackQueue.Start(this, ActivationParams))
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!BossComp.AttackQueue.IsActive(this))
			return true;
		if (ActiveDuration > 1.0)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FExampleBossSlamAttackData ActivationParams)
	{
		Params = ActivationParams;
		Print("Example boss slam");
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		BossComp.AttackQueue.Finish(this);
	}
}

class AExampleBossWithAttacks : AHazeActor
{
	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComp;
	default CapabilityComp.DefaultCapabilities.Add(n"ExampleBossAttackSelectionCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"ExampleBossIdleCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"ExampleBossJumpAttackCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"ExampleBossSlamAttackCapability");

	UPROPERTY(DefaultComponent)
	UExampleBossAttacksComponent AttacksComp;
}