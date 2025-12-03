class UGravityBikeSplineGroundMovementCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(GravityBikeSpline::Tags::GravityBikeSpline);
	default CapabilityTags.Add(GravityBikeSpline::MovementTags::GravityBikeSplineMovement);

	default TickGroup = EHazeTickGroup::Movement;
	default TickGroupOrder = 110;

	AGravityBikeSpline GravityBike;
	UGravityBikeSplineMovementComponent MoveComp;
	UGravityBikeSplineMovementData MoveData;

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

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(MoveComp.HasMovedThisFrame())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(!MoveComp.PrepareMove(MoveData))
			return;

		if(HasControl())
		{
			if(MoveComp.GetCurrentMovementAttachmentComponent() != nullptr)
			{
				FHazeMovementComponentAttachment FollowAttachment = MoveComp.GetCurrentMovementFollowAttachment();
				FVector Velocity = MoveComp.Velocity;
				FQuat DeltaRotation = FollowAttachment.Component.ComponentQuat * GravityBike.LastInheritedComponentRotation.Inverse();
				Velocity = DeltaRotation * Velocity;
				MoveData.AddVelocity(Velocity);
			}
			else
			{
				MoveData.AddOwnerVelocity();
			}

			const float Throttle = GravityBike.IsBoosting() ? 1 : GravityBike.Input.GetStickyThrottle();
			float DragFactor = Math::Lerp(GravityBike.Settings.ForwardNoThrottleDragFactor, GravityBike.Settings.ForwardDragFactor, Throttle);
			float Acceleration = GravityBike.GetForwardAcceleration(DeltaTime, DragFactor, true);
			
			if(GravityBike.IsBoosting())
			{
				auto BoostComp = UGravityBikeSplineBoostComponent::Get(GravityBike);
				DragFactor = BoostComp.Settings.BoostDragFactor;
				Acceleration = GravityBike.GetForwardAcceleration(DeltaTime, DragFactor, true);
			}

			const FVector Forward = GravityBike.ActorForwardVector.VectorPlaneProject(MoveComp.WorldUp).GetSafeNormal();
			const FVector Right = GravityBike.ActorRightVector.VectorPlaneProject(MoveComp.WorldUp).GetSafeNormal();

			MoveData.AddHorizontalAcceleration(Forward * Acceleration);

			MoveData.AddDirectionalDrag(MoveComp.HorizontalVelocity, DragFactor, Forward);
			MoveData.AddDirectionalDrag(MoveComp.HorizontalVelocity, GravityBike.Settings.SideDragFactor, Right);

			GravityBike.TurnBike(MoveData, DeltaTime);

			MoveData.AddGravityAcceleration();

			MoveData.AddPendingImpulses();
		}
		else
		{
			MoveData.ApplyCrumbSyncedGroundMovement();
		}

		MoveComp.ApplyMove(MoveData);
	}
}