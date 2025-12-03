class UHazeAnimSlopeAlignComponent : UActorComponent
{

	private UHazeMovementComponent MoveComp;

	private FHazeAcceleratedVector InterpolatedGroundNormal;
	private FHazeAcceleratedVector InterpolatedGroundOffset;

	TInstigated<bool> bIgnoreSlope;
	default bIgnoreSlope.SetDefaultValue(false);

	private uint LastFrameRequested = 0;

	UPROPERTY()
	float ClampRotation = 45;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		MoveComp = UHazeMovementComponent::Get(Owner);
		// If movecomp is null, try to get it from the parent actor instead as we sometimes attach actors to the players
		if (MoveComp == nullptr)
			MoveComp = UHazeMovementComponent::Get(Owner.AttachParentActor);
	}

	void ResetInterpVelocity()
	{
		InterpolatedGroundNormal.Velocity = FVector::ZeroVector;
		InterpolatedGroundOffset.Velocity = FVector::ZeroVector;
	}

	void ResetInterpValues()
	{
		InterpolatedGroundNormal.Value = Owner.ActorUpVector;
		InterpolatedGroundOffset.Value = FVector::ZeroVector;
	}

	void GetSlopeTransformData(FVector& OutSlopeOffset, FRotator& OutSlopeRotaiton, float DeltaTime = 0, float BlendDuration = 0)
	{
		const FMovementHitResult GroundImpact = MoveComp.GetGroundContact();

		FVector DeltaLocation = FVector::ZeroVector;

		FVector Normal = GroundImpact.Normal;
		FVector ImpactPoint = GroundImpact.ImpactPoint;

		if (GroundImpact.IsOnAnEdge() || !GroundImpact.bBlockingHit || bIgnoreSlope.Get())
		{
			Normal = Owner.ActorUpVector;
			ImpactPoint = Owner.ActorLocation;
		}
		else
		{
			// Clamp the rotation
			const float AngleDiff = Normal.GetAngleDegreesTo(Owner.ActorUpVector);
			if (AngleDiff > ClampRotation)
			{
				Normal = Normal.RotateTowards(Owner.ActorUpVector, AngleDiff - ClampRotation);
			}

			// Make sure lines intersect before using `LinePlaneIntersection`
			const float NormalDotProduct = Normal.DotProduct(Owner.ActorUpVector);
			if (!Math::IsNearlyZero(NormalDotProduct) && !Math::IsNearlyEqual(Math::Abs(NormalDotProduct), 1))
			{
				const FVector TargetLocation = Math::LinePlaneIntersection(
					Owner.ActorLocation,
					Owner.ActorLocation + Owner.ActorUpVector,
					ImpactPoint,
					Normal);
				DeltaLocation = TargetLocation - Owner.ActorLocation;
			}
		}
		if (BlendDuration > 0)
		{
			InterpolatedGroundNormal.AccelerateTo(Normal, BlendDuration, DeltaTime);
			InterpolatedGroundOffset.AccelerateTo(DeltaLocation, BlendDuration, DeltaTime);
		}
		else
		{
			InterpolatedGroundNormal.SnapTo(Normal);
			InterpolatedGroundOffset.SnapTo(DeltaLocation);
		}

		OutSlopeOffset = InterpolatedGroundOffset.Value;
		OutSlopeRotaiton = FRotator::MakeFromZX(
			Owner.ActorTransform.InverseTransformVectorNoScale(InterpolatedGroundNormal.Value),
			FVector::ForwardVector);

		LastFrameRequested = Time::FrameNumber;
	}

	void GetPreviousSlopeTransformData(FVector& OutSlopeOffset, FRotator& OutSlopeRotaiton)
	{
		OutSlopeOffset = InterpolatedGroundOffset.Value;
		OutSlopeRotaiton = FRotator::MakeFromZX(
			Owner.ActorTransform.InverseTransformVectorNoScale(InterpolatedGroundNormal.Value),
			FVector::ForwardVector);
	}

	void InitializeSlopeTransformData(FVector& OutSlopeOffset, FRotator& OutSlopeRotaiton, bool bSnapIfNoPrevRequest = false)
	{
		// Check if we requested slope the previous tick
		if (LastFrameRequested == Time::FrameNumber - 1)
		{
			GetPreviousSlopeTransformData(OutSlopeOffset, OutSlopeRotaiton);
		}
		else
		{
			if (bSnapIfNoPrevRequest)
			{
				GetSlopeTransformData(OutSlopeOffset, OutSlopeRotaiton);
			}
			else
			{
				ResetInterpValues();
				ResetInterpVelocity();
			}
		}
	}

	void SetSlopeTransformData(FVector& OutSlopeOffset, FRotator& OutSlopeRotaiton)
	{
		InterpolatedGroundOffset.SnapTo(OutSlopeOffset);
		InterpolatedGroundNormal.SnapTo(OutSlopeRotaiton.RotateVector(Owner.ActorUpVector));
	}
};