class USketchbookGoatGroundMovementCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(Sketchbook::Goat::Tags::SketchbookGoat);

	default TickGroup = EHazeTickGroup::Movement;
	default TickGroupOrder = 100;

	ASketchbookGoat Goat;
	USketchbookGoatSplineMovementComponent SplineComp;

	UHazeMovementComponent MoveComp;
	UTeleportingMovementData MoveData;

	float BobTime = 0;
	float WiggleTime = 0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Goat = Cast<ASketchbookGoat>(Owner);
		SplineComp = USketchbookGoatSplineMovementComponent::Get(Goat);
		
		MoveComp = UHazeMovementComponent::Get(Goat);
		MoveData = MoveComp.SetupTeleportingMovementData();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(MoveComp.HasMovedThisFrame())
			return false;

		if(SplineComp.IsInAir())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(MoveComp.HasMovedThisFrame())
			return true;

		if(SplineComp.IsInAir())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		// Don't look at this
		const FVector WorldUp = SplineComp.GetWorldUp();
		SplineComp.HorizontalSpeed = Goat.ActorVelocity.VectorPlaneProject(WorldUp).Size() * Math::Sign(Goat.ActorVelocity.DotProduct(SplineComp.GetWorldRight()));
		SplineComp.SplinePosition = SplineComp.GetCurrentSplineActor().Spline.GetClosestSplinePositionToWorldLocation(Owner.ActorLocation);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		//Goat.MeshOffsetComp.ResetOffsetWithLerp(this, 0.2);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(Goat.bPerchJumping)
			return;
		
		const FVector WorldUp = SplineComp.GetWorldUp();

		if(!MoveComp.PrepareMove(MoveData, WorldUp))
			return;

		if(HasControl())
		{
			float TargetHorizontalSpeed = 0;
			if(Math::Abs(Goat.SyncedHorizontalInput.Value) > 0.7)
			{
				TargetHorizontalSpeed = Math::Sign(Goat.SyncedHorizontalInput.Value) * Sketchbook::Goat::GroundMoveSpeed;
			}
			else
			{
				const FVector InputNormal = Goat.SyncedRawInput.Value.GetSafeNormal();
				float DotSplineForward = SplineComp.GetDotSplineForward(InputNormal);
				TargetHorizontalSpeed = DotSplineForward * Sketchbook::Goat::GroundMoveSpeed;
				float Sign = Math::Sign(DotSplineForward);
				TargetHorizontalSpeed = Math::Abs(TargetHorizontalSpeed) * Sign;
			}


			SplineComp.HorizontalSpeed = Math::FInterpConstantTo(SplineComp.HorizontalSpeed, TargetHorizontalSpeed, DeltaTime, Sketchbook::Goat::GroundAcceleration);

			if(!Math::IsNearlyZero(SplineComp.HorizontalSpeed))
			{
				UHazeSplineComponent PreviousSpline = SplineComp.SplinePosition.CurrentSpline;

				if(SplineComp.SplinePosition.Move(SplineComp.HorizontalSpeed * DeltaTime))
				{
					if(SplineComp.SplinePosition.CurrentSpline == PreviousSpline)
					{
						MoveData.AddDeltaFromMoveTo(SplineComp.SplinePosition.WorldLocation);

						float Sign = Math::Sign(SplineComp.HorizontalSpeed);
							
						const bool bIsInputting = Sign != 0;
						if(bIsInputting)
						{
							const FQuat Rotation = FQuat::MakeFromZX(WorldUp, SplineComp.SplinePosition.WorldForwardVector * Sign);
							MoveData.SetRotation(Rotation);
						}
						
						MoveData.AddPendingImpulses();
					}
					else
					{
						if(Goat.JumpZone != nullptr)
						{
							Goat.bPerchJumping = true;
						}
					}
				}
				else
				{
					SplineComp.HorizontalSpeed = 0;
				}
			}
		}
		else
		{
			SplineComp.SplinePosition = SplineComp.GetCurrentSplineActor().Spline.GetClosestSplinePositionToWorldLocation(Owner.ActorLocation);
			MoveData.ApplyCrumbSyncedGroundMovement();
		}

		MoveComp.ApplyMove(MoveData);
	}
};