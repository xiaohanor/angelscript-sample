class UGravityBikeBladeBarrelCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(GravityBikeSpline::Tags::GravityBikeSpline);
	default CapabilityTags.Add(GravityBikeBlade::Tags::GravityBikeBlade);

	default TickGroup = EHazeTickGroup::Movement;
	default TickGroupOrder = 20;

	AGravityBikeSpline GravityBike;
	UGravityBikeSplineMovementComponent MoveComp;
	UTeleportingMovementData MoveData;

	AHazePlayerCharacter BladePlayer;
	UGravityBikeBladePlayerComponent BladeComp;

	FVector InitialRelativeLocation;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		GravityBike = Cast<AGravityBikeSpline>(Owner);
		MoveComp = GravityBike.MoveComp;
		MoveData = MoveComp.SetupTeleportingMovementData();

		BladePlayer = GravityBikeBlade::GetPlayer();
		BladeComp = UGravityBikeBladePlayerComponent::Get(BladePlayer);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(MoveComp.HasMovedThisFrame())
			return false;

		if(BladeComp.State != EGravityBikeBladeState::Barrel)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(MoveComp.HasMovedThisFrame())
			return true;

		if(BladeComp.State != EGravityBikeBladeState::Barrel)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		BladeComp.Barrel.AttachGravityBike(GravityBike);
		InitialRelativeLocation = BladeComp.Barrel.ActorTransform.InverseTransformPosition(GravityBike.ActorLocation);

		// Force to be on the surface
		InitialRelativeLocation = InitialRelativeLocation.GetSafeNormal() * (BladeComp.TargetComp.RelativeLocation.Size() + GravityBikeSpline::Radius);

		MoveComp.AddMovementIgnoresActor(this, BladeComp.Barrel);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		MoveComp.RemoveMovementIgnoresActor(this);

		if(IsValid(BladeComp.Barrel))
			BladeComp.Barrel.DetachGravityBike();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(!MoveComp.PrepareMove(MoveData))
			return;

		if(HasControl())
		{
			const FQuat Rotation = FQuat(FVector::UpVector, ActiveDuration * -4.5);
			const FVector RelativeLocation = Rotation * InitialRelativeLocation;
			const FVector TargetLocation = BladeComp.Barrel.ActorTransform.TransformPosition(RelativeLocation);

			MoveData.AddDeltaFromMoveTo(TargetLocation);

			const FVector WorldUp = BladeComp.Barrel.ActorUpVector;
			const FVector BikeUp = (TargetLocation - BladeComp.Barrel.ActorLocation).VectorPlaneProject(WorldUp).GetSafeNormal();
			const FVector BikeForward = BikeUp.CrossProduct(WorldUp).GetSafeNormal();
			MoveData.SetRotation(FQuat::MakeFromZX(BikeUp, BikeForward));
		}
		else
		{
			MoveData.ApplyCrumbSyncedAirMovement();
		}

		MoveComp.ApplyMove(MoveData);
	}
}