class UGravityBikeSplineAirMovementCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(GravityBikeSpline::Tags::GravityBikeSpline);
	default CapabilityTags.Add(GravityBikeSpline::MovementTags::GravityBikeSplineMovement);

	default TickGroup = EHazeTickGroup::Movement;
	default TickGroupOrder = 100;

	AGravityBikeSpline GravityBike;
	UGravityBikeSplineMovementComponent MoveComp;
	UGravityBikeSplineMovementData MoveData;

	FQuat PreviousRotation;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		GravityBike = Cast<AGravityBikeSpline>(Owner);
		MoveComp = UGravityBikeSplineMovementComponent::Get(GravityBike);
		MoveData = MoveComp.SetupMovementData(UGravityBikeSplineMovementData);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(MoveComp.HasMovedThisFrame())
			return false;

		if(!GravityBike.IsAirborne.Get())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(MoveComp.HasMovedThisFrame())
			return true;

		if(!GravityBike.IsAirborne.Get())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		GravityBike.SteeringComp.SteeringMultiplier.Apply(GravityBike.Settings.AirSteerMultiplier, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		GravityBike.SteeringComp.SteeringMultiplier.Clear(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		const FVector WorldUp = GravityBike.GetGlobalWorldUp();

		if(!MoveComp.PrepareMove(MoveData, WorldUp.GetSafeNormal()))
			return;

		if(HasControl())
		{
			MoveData.AddOwnerVelocity();
			
			float DragFactor = GravityBike.Settings.AirForwardDragFactor;
			
			if(GravityBike.IsBoosting())
			{
				auto BoostComp = UGravityBikeSplineBoostComponent::Get(GravityBike);
				DragFactor = BoostComp.Settings.BoostDragFactor;
			}

			float Acceleration = GravityBike.GetForwardAcceleration(DeltaTime, DragFactor, false);

			if(!GravityBike.IsBoosting())
			{
				Acceleration *= GravityBike.Settings.AirAccelerateMultiplier;
			}

			const FVector Forward = GravityBike.ActorForwardVector.VectorPlaneProject(WorldUp).GetSafeNormal();
			const FVector Right = GravityBike.ActorRightVector.VectorPlaneProject(WorldUp).GetSafeNormal();

			MoveData.AddAcceleration(Forward * Acceleration);


			float DirectionalDragFactor = 1;

			if(GravityBike.bIsAutoAiming)
			{
				float Multiplier = Math::Lerp(1, GravityBike.AutoAim.Get().SteeringFraction, GravityBike.AutoAimAlpha);
				DirectionalDragFactor = Multiplier;
			}

			const float ForwardDrag = DragFactor * DirectionalDragFactor;
			const float SideDrag = GravityBike.Settings.AirSideDragFactor * DirectionalDragFactor;
			const float OmniDirectionalDrag = DragFactor * (1 - DirectionalDragFactor);

			if(ForwardDrag > KINDA_SMALL_NUMBER)
				MoveData.AddDirectionalDrag(MoveComp.Velocity, ForwardDrag, Forward);

			if(SideDrag > KINDA_SMALL_NUMBER)
				MoveData.AddDirectionalDrag(MoveComp.Velocity, SideDrag, Right);

			if(OmniDirectionalDrag > KINDA_SMALL_NUMBER)
				MoveData.AddDrag(MoveComp.Velocity, OmniDirectionalDrag);

			GravityBike.TurnBike(MoveData, DeltaTime);

			MoveData.AddGravityAcceleration();
			MoveData.AddPendingImpulses();

			PreviousRotation = GravityBike.ActorQuat;
		}
		else
		{
			MoveData.ApplyCrumbSyncedAirMovement();
		}

		MoveComp.ApplyMove(MoveData);
	}
}