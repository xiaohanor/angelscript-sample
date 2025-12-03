class USketchbookGoatIdleCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::BeforeMovement;
	default TickGroupOrder = 100;

	ASketchbookGoat Goat;

	float RotationTimer = 1;
	float LastRotationTime;
	float Wiggle = 10;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Goat = Cast<ASketchbookGoat>(Owner);
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
		LastRotationTime = Time::GameTimeSeconds;
		Goat.BlockCapabilities(CapabilityTags::Movement, this);

		if(HasControl())
			CrumbSetLocationAndRotation(Goat.ActorLocation, Goat.ActorRotation);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Goat.UnblockCapabilities(CapabilityTags::Movement, this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
	}

	UFUNCTION(CrumbFunction)
	void CrumbSetLocationAndRotation(FVector Location, FRotator Rotation)
	{
		Goat.SetActorLocation(Location);
		Goat.SetActorRotation(Rotation);
	}
};