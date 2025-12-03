class UWaveRaftPlayerCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(SummitRaftTags::WaveRaft);
	default CapabilityTags.Add(SummitRaftTags::BlockedWhileInHitStagger);
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default DebugCategory = SummitRaftDebug::SummitRaft;
	default TickGroup = EHazeTickGroup::Movement;

	AWaveRaft WaveRaft;
	UWaveRaftPlayerComponent RaftComp;
	USummitRaftPaddleComponent PaddleComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		RaftComp = UWaveRaftPlayerComponent::Get(Player);
		PaddleComp = USummitRaftPaddleComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (RaftComp.WaveRaft == nullptr)
			return false;
		
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		WaveRaft = RaftComp.WaveRaft;

		if (Player.IsMio())
			Player.AttachToComponent(WaveRaft.MioAttachPoint);
		else
			Player.AttachToComponent(WaveRaft.ZoeAttachPoint);

		if (Player.IsMio())
			PaddleComp.bLastPaddledLeft = true;
		else
			PaddleComp.bLastPaddledLeft = false;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (PaddleComp.bLastPaddledLeft)
			PaddleComp.ApplyAnimationState(ERaftPaddleAnimationState::LeftSideIdle, this, EInstigatePriority::Low);
		else
			PaddleComp.ApplyAnimationState(ERaftPaddleAnimationState::RightSideIdle, this, EInstigatePriority::Low);

		FName LocomotionTag = n"Waveraft";
		if(WaveRaft.IsFalling())
		{
			RaftComp.bRaftIsFalling = true;
			LocomotionTag = n"PaddleRaftFalling";
		}
		else
		{
			RaftComp.bRaftIsFalling = false;
		}
	
		if(Player.Mesh.CanRequestLocomotion())
			Player.RequestLocomotion(LocomotionTag, this);

	}
};