class UDragonFlyingAudioCapability : UHazeCapability
{
	UDragonMovementAudioComponent DragonMoveComp;
	UAdultDragonFlyingComponent FlyingComp;

	AAdultDragon AdultDragon;

	FVector LastLeftWingLocation;
	FVector LastRightWingLocation;
	FVector LastDragonLocation;
	float MaxVelo;

	const float MAX_WING_VELOCITY_RANGE = 7500;
	const float WING_DIRECTION_VELOCITY_THRESHOLD = 1500;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		AdultDragon = Cast<AAdultDragon>(Owner);

		DragonMoveComp = UDragonMovementAudioComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!FlyingComp.bIsFlying)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(!FlyingComp.bIsFlying && !FlyingComp.bIsStartingFlying)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		if(FlyingComp == nullptr)
			FlyingComp = UAdultDragonFlyingComponent::Get(AdultDragon.DragonComponent.Owner);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		const FVector LeftWingLocation = AdultDragon.Mesh.GetSocketLocation(MovementAudio::Dragons::LeftWingSocketName);
		const FVector RightWingLocation = AdultDragon.Mesh.GetSocketLocation(MovementAudio::Dragons::RightWingSocketName);
		const FVector DragonLocation = AdultDragon.GetActorCenterLocation();
		const FVector DragonVelo = DragonLocation - LastDragonLocation;

		FVector LeftWingVelo = (LeftWingLocation - LastLeftWingLocation) - DragonVelo;	
		LeftWingVelo = LeftWingVelo.ConstrainToPlane(AdultDragon.Mesh.GetUpVector());	

		float LeftWingSign = Math::Sign(LastLeftWingLocation.Z - LeftWingLocation.Z);
		LeftWingSign *= -1;

		float LeftWingSpeed = LeftWingVelo.Size() / DeltaTime;
		if(LeftWingSpeed < WING_DIRECTION_VELOCITY_THRESHOLD)
			LeftWingSign = 0;

		LeftWingSpeed = Math::Clamp(LeftWingSpeed / MAX_WING_VELOCITY_RANGE, 0, 1);

		FVector RightWingVelo = (RightWingLocation - LastRightWingLocation) - DragonVelo;
		RightWingVelo = RightWingVelo.ConstrainToPlane(AdultDragon.Mesh.GetUpVector());

		float RightWingSign = Math::Sign(LastRightWingLocation.Z - RightWingLocation.Z);
		RightWingSign *= -1;

		float RightWingSpeed = RightWingVelo.Size() / DeltaTime;
		if(RightWingSpeed < WING_DIRECTION_VELOCITY_THRESHOLD)
			RightWingSign = 0;

		RightWingSpeed = Math::Clamp(RightWingSpeed / MAX_WING_VELOCITY_RANGE, 0, 1);

		DragonMoveComp.SetWingSocketsRelativeSpeed(LeftWingSpeed, RightWingSpeed, LeftWingSign, RightWingSign);

		LastLeftWingLocation = LeftWingLocation;
		LastRightWingLocation = RightWingLocation;
		LastDragonLocation = DragonLocation;
	}
}