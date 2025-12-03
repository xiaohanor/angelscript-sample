class UPinballMagnetDroneLaunchedOffsetCapability : UHazePlayerCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Local;
	default TickGroup = EHazeTickGroup::BeforeMovement;
	default TickGroupOrder = 110;

	default CapabilityTags.Add(Pinball::Tags::BlockedWhileInRail);

	UPinballMagnetDroneLaunchedOffsetComponent LaunchedOffsetComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		LaunchedOffsetComp = UPinballMagnetDroneLaunchedOffsetComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
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
		Player.MeshOffsetComponent.SetAbsolute(true, false, false);
		Player.MeshOffsetComponent.SnapToLocation(LaunchedOffsetComp, Player.ActorLocation);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		LaunchedOffsetComp.Reset();

		Player.MeshOffsetComponent.SetAbsolute(false, false, false);
		Player.MeshOffsetComponent.SetRelativeLocation(FVector::ZeroVector);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		LaunchedOffsetComp.UpdateLaunchedOffset(DeltaTime);
	}
};