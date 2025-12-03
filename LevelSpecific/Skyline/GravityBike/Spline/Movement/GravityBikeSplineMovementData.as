class UGravityBikeSplineMovementData : UFloatingMovementData
{
	access Protected = protected, UBaseMovementResolver (inherited);

	default DefaultResolverType = UGravityBikeSplineMovementResolver;

	access:Protected
	FVector GlobalWorldUp;

	access:Protected
	bool bClampYaw = false;

	access:Protected
	float ClampAngle;

	access:Protected
	FTransform ClampReference;

	access:Protected
	FTransform SplineTransform;

	access:Protected
	float AutoAimAlpha;

	access:Protected
	FGravityBikeSplineAutoAimData AutoAimData;

	access:Protected
	FVector SplineForward;

	access:Protected
	float WallAlignMinAngleThreshold = -1;

	access:Protected
	float WallSlideAngleMin = -1;

	access:Protected
	float WallImpactDeathSplineAngleMax = -1;

	access:Protected
	float WallImpactDeathBikeAngleMax = -1;

	access:Protected
	bool bAlwaysApplyLandingImpact = false;

	access:Protected
	bool PrepareMove(const UHazeMovementComponent MovementComponent, FVector CustomWorldUp = FVector::ZeroVector) override
	{
		if(!Super::PrepareMove(MovementComponent, CustomWorldUp))
			return false;
		
		bAllowSubStep = false;
		EdgeHandling = EMovementEdgeHandlingType::Leave;

		auto GravityBike = Cast<AGravityBikeSpline>(MovementComponent.Owner);
		GlobalWorldUp = GravityBike.GetGlobalWorldUp();

		SplineTransform = GravityBike.GetSplineTransform();
		AutoAimAlpha = GravityBike.AutoAimAlpha;
		AutoAimData = GravityBike.AutoAim.Get();

		SplineForward = GravityBike.GetSplineForward();
		WallAlignMinAngleThreshold = GravityBike.Settings.WallAlignMinAngleThreshold;
		WallSlideAngleMin = GravityBike.Settings.WallSlideAngleMin;
		WallImpactDeathSplineAngleMax = GravityBike.Settings.WallImpactDeathSplineAngleMax;
		WallImpactDeathBikeAngleMax = GravityBike.Settings.WallImpactDeathBikeAngleMax;

		bAlwaysApplyLandingImpact = false;

		return true;
	}

#if EDITOR
	access:Protected
	void CopyFrom(const UBaseMovementData OtherBase) override
	{
		Super::CopyFrom(OtherBase);

		auto Other = Cast<UGravityBikeSplineMovementData>(OtherBase);
		GlobalWorldUp = Other.GlobalWorldUp;
		bClampYaw = Other.bClampYaw;
		ClampAngle = Other.ClampAngle;
		ClampReference = Other.ClampReference;
		SplineTransform = Other.SplineTransform;
		AutoAimAlpha = Other.AutoAimAlpha;
		AutoAimData = Other.AutoAimData;
		SplineForward = Other.SplineForward;
		WallAlignMinAngleThreshold = Other.WallAlignMinAngleThreshold;
		WallSlideAngleMin = Other.WallSlideAngleMin;
		WallImpactDeathSplineAngleMax = Other.WallImpactDeathSplineAngleMax;
		WallImpactDeathBikeAngleMax = Other.WallImpactDeathBikeAngleMax;
		bAlwaysApplyLandingImpact = Other.bAlwaysApplyLandingImpact;
	}
#endif

	void AddDirectionalDrag(FVector InVelocity, float DragFactor, FVector Direction)
	{
		const FVector DirVelocity = InVelocity.ProjectOnToNormal(Direction);

		const float IntegratedDragFactor = Math::Exp(-DragFactor);
		const FVector NewDirVelocity = DirVelocity * Math::Pow(IntegratedDragFactor, IterationTime);
		FVector Drag = NewDirVelocity - DirVelocity;

		Drag = Drag.GetClampedToMaxSize(InVelocity.Size());

		AddVelocity(Drag);
	}

	void AddDrag(FVector InVelocity, float DragFactor)
	{
		const float IntegratedDragFactor = Math::Exp(-DragFactor);
		const FVector NewVelocity = InVelocity * Math::Pow(IntegratedDragFactor, IterationTime);
		FVector Drag = NewVelocity - InVelocity;

		Drag = Drag.GetClampedToMaxSize(InVelocity.Size());

		AddVelocity(Drag);
	}

	void AlwaysApplyLandingImpact()
	{
		bAlwaysApplyLandingImpact = true;
	}
}