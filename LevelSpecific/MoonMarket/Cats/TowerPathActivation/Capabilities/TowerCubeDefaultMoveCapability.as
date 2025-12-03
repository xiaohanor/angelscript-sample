class UTowerCubeDefaultMoveCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::Gameplay;

	ATowerCube Cube;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Cube = Cast<ATowerCube>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Cube.bPlayersInteracted)
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
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		Cube.ActorLocation = Math::VInterpConstantTo(Cube.ActorLocation, Cube.CubeDefaultPosition, DeltaTime, 400.0);
	}
};