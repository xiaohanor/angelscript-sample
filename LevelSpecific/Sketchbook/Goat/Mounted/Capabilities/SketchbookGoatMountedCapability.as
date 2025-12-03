class USketchbookGoatMountedCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	
	default CapabilityTags.Add(Sketchbook::Goat::Tags::SketchbookGoat);

	default TickGroup = EHazeTickGroup::BeforeMovement;
	default TickGroupOrder = 100;

	ASketchbookGoat Goat;
	USketchbookGoatSplineMovementComponent SplineComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Goat = Cast<ASketchbookGoat>(Owner);
		SplineComp = USketchbookGoatSplineMovementComponent::Get(Goat);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!Goat.IsMounted())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(!Goat.IsMounted())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		CapabilityInput::LinkActorToPlayerInput(Goat, Goat.MountedPlayer);

		Goat.CapsuleComp.SetCollisionProfileName(n"PlayerCharacter");
		UMovementGravitySettings::SetGravityScale(Goat, Sketchbook::Goat::GravityScale, this);

		SplineComp.SplinePosition = Sketchbook::Goat::GetClosestSplinePosition(Goat.ActorLocation);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		CapabilityInput::LinkActorToPlayerInput(Goat, nullptr);
		Goat.SetActorVelocity(FVector::ZeroVector);
		Goat.AddActorCollisionBlock(this);
		Goat.AddActorTickBlock(this);
		//Goat.CapsuleComp.SetCollisionProfileName(n"BlockAllDynamic");
		//UMovementGravitySettings::ClearGravityScale(Goat, this);
		//Goat.BlockCapabilities(CapabilityTags::Movement, this);
	}
};