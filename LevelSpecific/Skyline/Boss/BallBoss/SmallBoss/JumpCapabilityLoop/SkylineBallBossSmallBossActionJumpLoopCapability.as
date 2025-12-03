
class USkylineBallBossSmallBossJumpActionComponent : UActorComponent
{
	FHazeStructQueue Queue;
};

asset SkylineBallBossSmallBossJumpSheet of UHazeCapabilitySheet
{
	AddCapability(n"SkylineBallBossSmallBossActionJumpLoopCapability");
	AddCapability(n"SkylineBallBossSmallBossActionNodeJumpCapability");
	AddCapability(n"SkylineBallBossSmallBossActionNodeJumpDelayCapability");

	AddCapability(n"SkylineBallBossSmallBossJumpCapability");

	AddCapability(n"SkylineBallBossSmallBossActionNodeLaserCapability");
	AddCapability(n"SkylineBallBossSmallBossLaserCapability");
};

class USkylineBallBossSmallBossActionJumpLoopCapability : UHazeCapability
{
	FSkylineBallBossActionActivateData Params;
	default CapabilityTags.Add(SkylineBallBossTags::BallBoss);
	default CapabilityTags.Add(SkylineBallBossTags::Action);
	ASkylineBallBossSmallBoss SmallBoss;
	USkylineBallBossSmallBossJumpActionComponent BossComp;

	bool bQueuedFirstDelays = false;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		SmallBoss = Cast<ASkylineBallBossSmallBoss>(Owner);
		BossComp = USkylineBallBossSmallBossJumpActionComponent::Get(Owner);
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
			Delay(5.0);
		}

		if (BossComp.Queue.IsEmpty())
			JumpLoop();
	}

	void JumpLoop()
	{
		Jump();
		Delay(3.5);
		Jump();
		Delay(0.75);
		Jump();
		Delay(0.75);
		Jump();
		Delay(3.0);
		Laser();
	}

	void Jump()
	{
		FSkylineBallBossSmallBossActionNodeJumpCapabilityData Data;
		BossComp.Queue.Queue(Data);
	}

	void Laser()
	{
		FSkylineBallBossSmallBossActionNodeLaserCapabilityData Data;
		BossComp.Queue.Queue(Data);
	}

	void Delay(float Delay)
	{
		FSkylineBallBossSmallBossActionNodeJumpDelayCapabilityData Data;
		Data.Duration = Delay;
		BossComp.Queue.Queue(Data);
	}
}
