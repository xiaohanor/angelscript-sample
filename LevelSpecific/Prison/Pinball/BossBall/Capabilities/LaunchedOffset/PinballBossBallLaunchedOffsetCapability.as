class UPinballBossBallLaunchedOffsetCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Local;
	default TickGroup = EHazeTickGroup::AfterGameplay;
	default TickGroupOrder = 110;
	default CapabilityTags.Add(CapabilityTags::Movement);

	APinballBossBall BossBall;
	UPinballBossBallLaunchedOffsetComponent LaunchedOffsetComp;

	FPinballBossBallLaunchedOffset LaunchedOffset;
	FVector InitialOffset;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		BossBall = Cast<APinballBossBall>(Owner);
		LaunchedOffsetComp = UPinballBossBallLaunchedOffsetComponent::Get(BossBall);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
#if !RELEASE
		if(DevTogglesPinball::DisableBossBallLaunchedOffset.IsEnabled())
			return false;
#endif

		if(!LaunchedOffsetComp.HasOffsetToConsume())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
#if !RELEASE
		if(DevTogglesPinball::DisableBossBallLaunchedOffset.IsEnabled())
			return true;
#endif

		if(Time::GetGameTimeSince(LaunchedOffset.StartOffsetTime) > LaunchedOffset.ReturnOffsetDuration)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		ConsumeOffset();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		LaunchedOffset = FPinballBossBallLaunchedOffset();
		BossBall.MeshRootComp.ClearOffset(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(LaunchedOffsetComp.HasOffsetToConsume())
			ConsumeOffset();

		float Alpha = Math::Saturate(Time::GetGameTimeSince(LaunchedOffset.StartOffsetTime) / LaunchedOffset.ReturnOffsetDuration);
		FVector Offset = Math::Lerp(InitialOffset, FVector::ZeroVector, Alpha);

		if(!LaunchedOffset.OffsetPlane.IsNearlyZero())
			Offset = Offset.VectorPlaneProject(LaunchedOffset.OffsetPlane);
		
		BossBall.MeshRootComp.SnapToLocation(this, BossBall.ActorLocation + Offset);
	}

	void ConsumeOffset()
	{
		LaunchedOffset = LaunchedOffsetComp.ConsumeOffset();
		BossBall.MeshRootComp.SnapToLocation(this, LaunchedOffset.VisualLocation);
		InitialOffset = LaunchedOffset.VisualLocation - BossBall.ActorLocation;
	}
};