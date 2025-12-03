enum ESketchbookGoatAirMovementDeactivateReason
{
	Default,
	FellBelowSpline,
	HitHeadOnOtherSpline,
};

struct FSketchbookGoatAirMovementDeactivateParams
{
	ESketchbookGoatAirMovementDeactivateReason Reason = ESketchbookGoatAirMovementDeactivateReason::Default;
	UHazeSplineComponent SplineComp;
	float HorizontalSpeed;
};

class USketchbookGoatAirMovementCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(Sketchbook::Goat::Tags::SketchbookGoat);

	default TickGroup = EHazeTickGroup::Movement;
	default SeparateInactiveTick(EHazeTickGroup::LastMovement);

	ASketchbookGoat Goat;
	USketchbookGoatSplineMovementComponent SplineComp;

	UHazeMovementComponent MoveComp;
	UTeleportingMovementData MoveData;

	FVector WorldRight;
	FVector VerticalVelocity;
	FVector InitialVelocity;
	float HorizontalSpeed = 0;


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

		if(!SplineComp.IsInAir())
			return false;

		// if(Goat.JumpZone != nullptr)
		// {
		// 	if(Time::GetGameTimeSince(Goat.RespawnTime) > 0.5)
		// 	{
		// 		if(Goat.RootOffsetComp.ForwardVector.DotProduct(Goat.JumpZone.ActorForwardVector) > 0.5)
		// 		{
		// 			Goat.bPerchJumping = true;
		// 			return false;
		// 		}
		// 	}
		// }

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate(FSketchbookGoatAirMovementDeactivateParams& Params) const
	{
		if(MoveComp.HasMovedThisFrame())
			return true;
		
		// if(!SplineComp.IsInAir())
		// {
		// 	if(SplineComp.GetCurrentSpline() == nullptr)
		// 		return true;
			
		// 	if(Cast<ASketchbookGoatSpline>(SplineComp.GetCurrentSplineActor()).bAllowJumping)
		// 		return true;

			
		// }

		if(SplineComp.IsInHole())
			return false;

		if(Goat.bPerchJumping)
			return false;

		//if(MoveComp.VerticalSpeed < 0)
		{
			
			auto ClosestSplinePosition = Goat.GetGoatSplineMoveComp().SplinePosition;
			//Debug::DrawDebugLine(Goat.ActorLocation, ClosestSplinePosition.WorldLocation, FLinearColor::Red, 10);
			if(!ClosestSplinePosition.IsAtStartOrEnd())
			{
				FTransform SplineTransform = ClosestSplinePosition.WorldTransform;
				SplineTransform.SetRotation(FQuat::MakeFromZX(SplineComp.GetWorldUp(), SplineTransform.Rotation.ForwardVector));

				FVector RelativeToSpline = SplineTransform.InverseTransformPositionNoScale(Goat.ActorLocation);

				auto Spline = Cast<ASketchbookGoatSpline>(ClosestSplinePosition.CurrentSpline.Owner);
				if(Spline.GetSplineUpAtDistanceAlongSpline(ClosestSplinePosition.CurrentSplineDistance).DotProduct(MoveComp.WorldUp) > 0)
				{
					// If we fall through a spline floor
					if(RelativeToSpline.Z < 0)
					{
						if(ClosestSplinePosition.WorldUpVector.DotProduct(InitialVelocity.GetSafeNormal()) < 0 || ClosestSplinePosition.WorldUpVector.DotProduct(Goat.ActorUpVector) >= 0.8)
						{
							Params.Reason = ESketchbookGoatAirMovementDeactivateReason::FellBelowSpline;
							Params.SplineComp = ClosestSplinePosition.CurrentSpline;
							Params.HorizontalSpeed = MoveComp.HorizontalVelocity.DotProduct(ClosestSplinePosition.WorldForwardVector);
							return true;
						}
					}
				}
				else
				{
					if(RelativeToSpline.Z < Goat.CapsuleComp.ScaledCapsuleHalfHeight * 2)
					{
						Params.Reason = ESketchbookGoatAirMovementDeactivateReason::HitHeadOnOtherSpline;
						Params.SplineComp = ClosestSplinePosition.CurrentSpline;
						Params.HorizontalSpeed = MoveComp.HorizontalVelocity.DotProduct(ClosestSplinePosition.WorldForwardVector);
						return true;
					}
				}
			}
		}

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		const FVector InputNormal = Goat.SyncedRawInput.Value.GetSafeNormal();
		float DotSplineForward = SplineComp.GetDotSplineForward(InputNormal);

		HorizontalSpeed = DotSplineForward * Sketchbook::Goat::AirMoveSpeed;
		VerticalVelocity = Goat.ActorVerticalVelocity;
		InitialVelocity = Goat.ActorVelocity;

		float Sign = Math::Sign(Goat.SyncedHorizontalInput.Value);
		if(Sign != 0)
		{
			const FQuat InitialJumpRot = FQuat::MakeFromZX(Goat.GetGoatSplineMoveComp().GetWorldUp(), SplineComp.SplinePosition.WorldForwardVector * Sign);
			Goat.SetActorRotation(InitialJumpRot);
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FSketchbookGoatAirMovementDeactivateParams Params)
	{
		switch(Params.Reason)
		{
			case ESketchbookGoatAirMovementDeactivateReason::Default:
				break;

			case ESketchbookGoatAirMovementDeactivateReason::FellBelowSpline:
				SplineComp.SplinePosition = Params.SplineComp.GetClosestSplinePositionToWorldLocation(Goat.ActorLocation);
				SplineComp.VerticalOffset = 0;
				SplineComp.HorizontalSpeed = Params.HorizontalSpeed;
				break;

			case ESketchbookGoatAirMovementDeactivateReason::HitHeadOnOtherSpline:
				SplineComp.SplinePosition = Params.SplineComp.GetClosestSplinePositionToWorldLocation(Goat.ActorLocation);
				SplineComp.VerticalOffset = 0;
				SplineComp.HorizontalSpeed = Params.HorizontalSpeed;
				break;
		}

		SplineComp.bCanExitAir = true;
		//Goat.MeshOffsetComp.ClearOffset(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		SplineComp.SplinePosition = SplineComp.GetCurrentSpline().GetClosestSplinePositionToWorldLocation(Goat.ActorLocation);
		const FVector GravityDirection = GetGravityDirection();

		if(!MoveComp.PrepareMove(MoveData, MoveComp.WorldUp))
			return;

		if(HasControl())
		{
			const FVector InputNormal = Goat.SyncedRawInput.Value.GetSafeNormal();
			float DotSplineForward = SplineComp.GetDotSplineForward(InputNormal);
				
			WorldRight = SplineComp.GetWorldRight().VectorPlaneProject(Goat.MoveComp.WorldUp).GetSafeNormal();
			float TargetHorizontalSpeed = DotSplineForward * Sketchbook::Goat::AirMoveSpeed;
			HorizontalSpeed = Math::FInterpConstantTo(HorizontalSpeed, TargetHorizontalSpeed, DeltaTime, Sketchbook::Goat::AirAcceleration);

			VerticalVelocity = Math::VInterpConstantTo(VerticalVelocity, GravityDirection * MoveComp.GravityForce, DeltaTime, Sketchbook::Goat::GravityAcceleration);

			MoveData.AddPendingImpulses();
			MoveData.AddVelocity(WorldRight * HorizontalSpeed);
			MoveData.AddVelocity(VerticalVelocity);

			const FQuat Rotation = FQuat::MakeFromZX(-GravityDirection, Goat.ActorForwardVector);
			MoveData.SetRotation(Rotation);
		}
		else
		{
			MoveData.ApplyCrumbSyncedGroundMovement();
		}

		MoveComp.ApplyMove(MoveData);

		SplineComp.VerticalOffset = FPlane(SplineComp.SplinePosition.WorldLocation, -GravityDirection).PlaneDot(Goat.ActorLocation);

		if(SplineComp.HasFallenDownHole())
		{
			// FB TODO: Move to resolver?
			FVector FinalLocation;
			FVector ConstraintPlane;
			if(SplineComp.ConstrainLocationToHole(Goat.ActorLocation, Goat.ActorVelocity, FinalLocation, ConstraintPlane))
			{
				Goat.SetActorLocation(FinalLocation);
				Goat.SetActorVelocity(Goat.ActorVelocity.VectorPlaneProject(ConstraintPlane));	
			}
		}
	}

	FVector GetGravityDirection() const
	{
		return SplineComp.GetGravityDirection(MoveComp.WorldUp);
		// FVector FromSplineToGoat = (Goat.ActorLocation - SplineComp.SplinePosition.WorldLocation);
		// FromSplineToGoat = FromSplineToGoat.VectorPlaneProject(FVector::ForwardVector);

		// if(FromSplineToGoat.IsZero())
		// 	return MoveComp.WorldUp;

		// FromSplineToGoat.Normalize();
		// return FromSplineToGoat;
	}
};