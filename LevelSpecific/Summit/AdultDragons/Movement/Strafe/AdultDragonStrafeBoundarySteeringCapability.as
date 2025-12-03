class UAdultDragonStrafeBoundarySteeringCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(n"AdultDragon");
	default CapabilityTags.Add(n"AdultDragonBoundaries");

	default TickGroup = EHazeTickGroup::AfterGameplay;

	default DebugCategory = n"AdultDragon";

	UPlayerAdultDragonComponent DragonComp;
	UAdultDragonBoundaryComponent BoundsComp;
	UPlayerMovementComponent MoveComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		DragonComp = UPlayerAdultDragonComponent::Get(Player);
		BoundsComp = UAdultDragonBoundaryComponent::Get(Player);
		MoveComp = UPlayerMovementComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		// There was never any boundary to begin with
		if(BoundsComp.LastBoundaryLeft == nullptr)
			return false;

		if(BoundsComp.InsideBoundaries.Num() > 0)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		// There was never any boundary to begin with
		if(BoundsComp.LastBoundaryLeft == nullptr)
			return true;

		if(BoundsComp.InsideBoundaries.Num() > 0)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		DragonComp.bIsBeingBoundaryRedirected = true;
		Player.BlockCapabilities(n"AdultDragonSteering", this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		DragonComp.bIsBeingBoundaryRedirected = false;
		Player.UnblockCapabilities(n"AdultDragonSteering", this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FVector FlatBoundaryLocation = BoundsComp.LastBoundaryLeft.ActorLocation;
		FlatBoundaryLocation.X = Player.ActorLocation.X;
		FVector TowardsCenter = FlatBoundaryLocation - Player.ActorLocation;
		
		FRotator RotationToCenter = FRotator::MakeFromX(TowardsCenter);
		RotationToCenter.Roll = 0;
		FRotator NewRotation = Math::RInterpTo(DragonComp.WantedRotation, RotationToCenter, DeltaTime, BoundsComp.LastBoundaryLeft.SteeringSpeed);
		DragonComp.WantedRotation = NewRotation;

		FRotator LocalNewRotation = Player.ActorTransform.InverseTransformRotation(NewRotation);

		DragonComp.AnimParams.Pitching = LocalNewRotation.Pitch;
		DragonComp.AnimParams.Banking = LocalNewRotation.Yaw;
	}
};