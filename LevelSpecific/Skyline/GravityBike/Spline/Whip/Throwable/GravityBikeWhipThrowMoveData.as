struct FGravityBikeWhipThrowMoveData
{
	bool bInitialized = false;

	private FVector InitialRelativeLocation;
	private float ThrowArcHeight;
	UGravityBikeWhipThrowTargetComponent ThrowTarget;
	AGravityBikeSpline GravityBike;
	UHazeSplineComponent SplineComp;

	// Shared
	private FVector RelativeToSplineLocation;
	private FVector RelativeVelocity;

	private FVector WorldLocation;

	// Throw At Target
	private float Time = 0;
	private float Duration = 0;

	FGravityBikeWhipThrowMoveData(
		FVector InInitialWorldLocation,
		FVector InInitialWorldVelocity,
		float InThrowAtSpeed,
		float InThrowArcHeightPerSecond,
		UGravityBikeWhipThrowTargetComponent InTargetComp,
		AGravityBikeSpline InGravityBike
	)
	{
		WorldLocation = InInitialWorldLocation;
		ThrowTarget = InTargetComp;
		GravityBike = InGravityBike;
		SplineComp = GravityBike.GetActiveSplineComponent();

		if(!ensure(!WorldLocation.IsNearlyZero()))
			return;
		if(!ensure(IsValid(ThrowTarget)))
			return;
		if(!ensure(IsValid(GravityBike)))
			return;
		if(!ensure(IsValid(SplineComp)))
			return;

		const FTransform SplineTransform = GravityBike.GetSplineTransform();
		InitialRelativeLocation = SplineTransform.InverseTransformPositionNoScale(InInitialWorldLocation);
		RelativeVelocity = SplineTransform.InverseTransformVectorNoScale(InInitialWorldVelocity);

		const FQuat PlaneRotation = FQuat::MakeFromZX(FVector::UpVector, SplineTransform.Rotation.ForwardVector);
		const FTransform PlaneTransform = FTransform(PlaneRotation, SplineTransform.Location);

		FVector SourceRelativeLocation = PlaneTransform.InverseTransformPositionNoScale(InInitialWorldLocation);
		FVector TargetRelativeLocation = PlaneTransform.InverseTransformPositionNoScale(InTargetComp.WorldLocation);
		
		float HorizontalDistance = SourceRelativeLocation.Dist2D(TargetRelativeLocation, FVector::UpVector);

		Duration = HorizontalDistance / InThrowAtSpeed;

		ThrowArcHeight = InThrowArcHeightPerSecond * Duration;

		bInitialized = true;
	}

	FGravityBikeWhipThrowMoveData(FVector InInitialWorldLocation, FVector InInitialWorldVelocity, AGravityBikeSpline InGravityBike)
	{
		WorldLocation = InInitialWorldLocation;
		GravityBike = InGravityBike;
		SplineComp = GravityBike.GetActiveSplineComponent();

		if(!ensure(!WorldLocation.IsNearlyZero()))
			return;
		if(!ensure(GravityBike != nullptr))
			return;
		if(!ensure(SplineComp != nullptr))
			return;

		const FTransform SplineTransform = GravityBike.GetSplineTransform();
		RelativeVelocity = SplineTransform.InverseTransformVectorNoScale(InInitialWorldVelocity);

		bInitialized = true;
	}

	void Tick(float DeltaTime, bool&out bOutReachedEnd)
	{
		check(bInitialized);
		if(!bInitialized)
			return;

		if(IsValid(ThrowTarget))
		{
			Time += DeltaTime;
			const float Alpha = Math::Saturate(Time / Duration);

			FVector RelativeLocation = GetLerpedRelativeLocation(GravityBike.GetSplineTransform(), Alpha);
			WorldLocation =  GravityBike.GetSplineTransform().TransformPositionNoScale(RelativeLocation);

			const float ArcAlpha = Math::Sin(Alpha * (PI));
			WorldLocation += FVector::UpVector * ArcAlpha * ThrowArcHeight;

			if(Alpha > 1 - KINDA_SMALL_NUMBER)
			{
				bOutReachedEnd = true;
			}
			else
			{
				bOutReachedEnd = false;
			}
		}
		else
		{
			const FTransform SplineTransform = GravityBike.GetSplineTransform();
			FVector WorldVelocity = SplineTransform.TransformVectorNoScale(RelativeVelocity);
			WorldVelocity -= FVector::UpVector * 3000 * DeltaTime;
			RelativeVelocity = SplineTransform.InverseTransformVectorNoScale(WorldVelocity);

			WorldLocation += WorldVelocity * DeltaTime;
		}
	}

	private FVector GetLerpedRelativeLocation(FTransform SplineTransform, float Alpha) const
	{
		check(bInitialized);

		const FVector FromLocation = InitialRelativeLocation;
		const FVector ToLocation = SplineTransform.InverseTransformPositionNoScale(ThrowTarget.WorldLocation);

		return Math::Lerp(FromLocation, ToLocation, Alpha);
	}

	FVector GetWorldLocation() const
	{
		check(bInitialized);
		return WorldLocation;
	}

	bool IsOnGravityBikeSpline() const
	{
		return SplineComp == GravityBike.GetActiveSplineComponent();
	}
};