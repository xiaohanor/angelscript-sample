class USteerSandFishTurnCapability : UHazeCapability
{
	default TickGroup = EHazeTickGroup::BeforeMovement;
	default TickGroupOrder = 100;

	//default CapabilityTags.Add(ArenaSandFish::Tags::ArenaSandFishTurn);

	AVortexSandFish SandFish;
	FHazeAcceleratedFloat AccTilt;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		SandFish = Cast<AVortexSandFish>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(Desert::GetDesertLevelState() != EDesertLevelState::Steer)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(Desert::GetDesertLevelState() != EDesertLevelState::Steer)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		AccTilt.SnapTo(0);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		SandFish.MeshOffsetComp.SetRelativeRotation(FQuat::Identity);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		const float MaxTilt = 0.4;
		float Tilt = 0.2;
		Tilt += -SandFish.Steering * 0.3;
		float TargetTilt = Math::Clamp(Tilt, -MaxTilt, MaxTilt);

		AccTilt.AccelerateTo(TargetTilt, 1, DeltaTime);
		FQuat TurnRotation = FQuat(FVector::ForwardVector, AccTilt.Value);

		SandFish.MeshOffsetComp.SetRelativeRotation(TurnRotation);
	}
};