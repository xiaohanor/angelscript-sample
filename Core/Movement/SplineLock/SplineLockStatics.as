/**
 * This will lock the players movement on the provided spline
 * @param RubberBandSettings Apply 'RubberBandSettings' to force the player to stay close to each other
 * @param EnterSettings If no custom enter settings are used, the player walks smoothly into the spline
 */
UFUNCTION(Meta = (AdvancedDisplay = "Priority, LockProperties, RubberBandSettings, EnterSettings"))
mixin void LockMovementToSpline(AHazeActor Actor, AHazeActor SplineActor, FInstigator Instigator,
	EInstigatePriority Priority = EInstigatePriority::Normal, 
	FPlayerMovementSplineLockProperties LockProperties = FPlayerMovementSplineLockProperties(),
	UPlayerSplineLockRubberBandSettings RubberBandSettings = nullptr, 
	UPlayerSplineLockEnterSettings EnterSettings = nullptr
)
{
	auto Spline = Spline::GetGameplaySpline(SplineActor, Instigator);
	Actor.LockMovementToSplineComponent(Spline, Instigator, Priority, LockProperties, RubberBandSettings, EnterSettings);
}

/**
 * This will lock the players movement on the provided spline
 * @param RubberBandSettings Apply 'RubberBandSettings' to force the player to stay close to each other
 * @param EnterSettings If no custom enter settings are used, the player walks smoothly into the spline
 */
UFUNCTION(Meta = (AdvancedDisplay = "Priority, LockProperties, RubberBandSettings, EnterSettings"))
mixin void LockMovementToSplineComponent(AHazeActor Actor, UHazeSplineComponent Spline, FInstigator Instigator,
	EInstigatePriority Priority = EInstigatePriority::Normal, 
	FPlayerMovementSplineLockProperties LockProperties = FPlayerMovementSplineLockProperties(),
	UPlayerSplineLockRubberBandSettings RubberBandSettings = nullptr, 
	UPlayerSplineLockEnterSettings EnterSettings = nullptr
)
{
	auto SplineLockComp = USplineLockComponent::Get(Actor);
	if(SplineLockComp == nullptr)
	{
		devError(f"No SplineLockComponent present on {Actor}");
		return;
	}
	
	auto MoveComp = UHazeMovementComponent::Get(Actor);
	if(MoveComp == nullptr)
	{
		devError(f"No MovementComponent present on {Actor}");
		return;
	}
	
	FPlayerSplineLockSettings Settings;
	Settings.Spline = Spline;
	Settings.LockSettings = LockProperties;
	Settings.LockSettings.AllowedHorizontalDeviation = Math::Max(Settings.LockSettings.AllowedHorizontalDeviation, 0.0);
	Settings.RubberBandSettings = RubberBandSettings;
	Settings.EnterSettings = EnterSettings;

	const UHazeSplineComponent PrevSpline = SplineLockComp.GetCurrentSpline();

	// Apply the settings to the splinelock comp
	SplineLockComp.InstigatedSettings.Apply(Settings, Instigator, Priority);
	MoveComp.ApplyResolverExtension(SplineLockComp.ResolverExtensionClass, Instigator);

	// Only call lock if we get a new spline, else, we already have one
	if(Spline != PrevSpline)
	{
		// only lock horizontal so we can fall and jump
		SplineLockComp.LockOnSplineInternal(SplineLockComp.GetCurrentSettings());
	}	
}

UFUNCTION()
mixin void UnlockMovementFromSpline(AHazeActor Actor, FInstigator Instigator)
{
	auto MoveComp = UHazeMovementComponent::Get(Actor);
	auto SplineLockComp = USplineLockComponent::Get(Actor);

	if(SplineLockComp != nullptr)
	{
		const UHazeSplineComponent PrevSpline = SplineLockComp.GetCurrentSpline();

		SplineLockComp.InstigatedSettings.Clear(Instigator);
		MoveComp.ClearResolverExtension(SplineLockComp.ResolverExtensionClass, Instigator);

		// Either clear or reset the spline lock if we've changed from one spline to another
		if (PrevSpline != SplineLockComp.GetCurrentSpline())
		{
			if (SplineLockComp.GetCurrentSpline() == nullptr)
				SplineLockComp.ClearSplineLockOnInternal();
			else
				SplineLockComp.LockOnSplineInternal(SplineLockComp.GetCurrentSettings());
		}
	}
}

UFUNCTION(BlueprintPure)
mixin bool IsMovementLockedToSpline(AHazeActor Actor)
{
	auto SplineLockComp = USplineLockComponent::Get(Actor);
	if(SplineLockComp != nullptr)
		return SplineLockComp.HasActiveSplineLock();
	else
		return false;
}

namespace SplineLock
{
	const float ParallelThreshold = 0.99;

	FSplinePosition GetClosestSplineHorizontalLocation(UHazeSplineComponent CurrentSpline, FVector CurrentWorldLocation, FVector UpVector, float DistanceBetweenLocations)
	{	
		auto Horizontal = CurrentSpline.GetPlaneConstrainedClosestSplinePositionToWorldLocation(CurrentWorldLocation, UpVector);
		auto Closest = CurrentSpline.GetClosestSplinePositionToWorldLocation(CurrentWorldLocation);

		FVector VerticalDistance = (Horizontal.WorldLocation - Closest.WorldLocation).ProjectOnToNormal(UpVector);
		float DistSqs = VerticalDistance.SizeSquared();
		float MaxDist = Math::Square(DistanceBetweenLocations * 2);
		float UseClosestAlpha = 0;
		if(DistSqs > 0)
			UseClosestAlpha = Math::Min(Math::Max(DistSqs - MaxDist, 0) / DistSqs, 1);
		if(UseClosestAlpha < SMALL_NUMBER)
			return Horizontal;

		auto PositivePosition = Horizontal.Lerp(Closest, UseClosestAlpha, ESplineMovementPolarity::Positive);
		auto NegativePosition = Horizontal.Lerp(Closest, UseClosestAlpha, ESplineMovementPolarity::Negative);
		float PositiveDist = PositivePosition.WorldLocation.DistSquared(CurrentWorldLocation);
		float NegativeDist = NegativePosition.WorldLocation.DistSquared(CurrentWorldLocation);
		if(PositiveDist <= NegativeDist)
			return PositivePosition;
		else
			return NegativePosition;
	}

	FVector GetUpVector(EPlayerSplineLockPlaneType LockType, FSplinePosition SplinePosition, FVector MovementWorldUp)
	{
		switch(LockType)
		{
			case EPlayerSplineLockPlaneType::Horizontal:
			{
				if(SplinePosition.WorldForwardVector.Parallel(MovementWorldUp, ParallelThreshold))
				{
					// Our WorldUp is parallel with the spline forward.
					// This means that we will fail to do a cross product and get a good right vector later.
					// Return the SplinePosition Up instead, as a fail-safe.
					return SplinePosition.WorldUpVector;
				}

				return MovementWorldUp;
			}

			case EPlayerSplineLockPlaneType::SplinePlane:
			case EPlayerSplineLockPlaneType::SplinePlaneAllowMovingWithinHorizontalDeviation:
			{
				if(Math::Abs(SplinePosition.WorldRightVector.DotProduct(MovementWorldUp)) < 0.9)
					return SplinePosition.WorldUpVector;
				else
					return SplinePosition.WorldRightVector;
			}
		}
	}

	FVector GetMovementForward(EPlayerSplineLockPlaneType LockType, FSplinePosition SplinePosition, FVector MovementWorldUp)
	{
		switch(LockType)
		{
			case EPlayerSplineLockPlaneType::Horizontal:
			{
				if(Math::Abs(SplinePosition.WorldForwardVector.DotProduct(MovementWorldUp)) < 0.9)	
					return SplinePosition.WorldForwardVector.VectorPlaneProject(MovementWorldUp).GetSafeNormal();

				return MovementWorldUp;
			}

			case EPlayerSplineLockPlaneType::SplinePlane:
			case EPlayerSplineLockPlaneType::SplinePlaneAllowMovingWithinHorizontalDeviation:
			{
				return SplinePosition.WorldForwardVector;
			}
		}
	}

	FVector GetDeviationRight(EPlayerSplineLockPlaneType LockType, FSplinePosition SplinePosition, FVector MovementWorldUp)
	{
		const FVector Up = GetUpVector(LockType, SplinePosition, MovementWorldUp);
		const FVector Forward = GetMovementForward(LockType, SplinePosition, MovementWorldUp);
		return Up.CrossProduct(Forward).GetSafeNormal();
	}

	float GetSplinePositionDeviation(
		EPlayerSplineLockPlaneType PlaneLockType,
		FSplinePosition SplinePosition,
		FVector WorldLocation,
		FVector MovementWorldUp)
	{
		switch(PlaneLockType)
		{
			case EPlayerSplineLockPlaneType::Horizontal:
			{
				const FVector UpVector = SplineLock::GetUpVector(PlaneLockType, SplinePosition, MovementWorldUp);
				const FVector SplineLocation = SplinePosition.WorldLocation.VectorPlaneProject(UpVector);
				const FVector PlayerLocation = WorldLocation.VectorPlaneProject(UpVector);
				const FVector WorldRightVector = SplineLock::GetDeviationRight(PlaneLockType, SplinePosition, MovementWorldUp);
				const FVector Delta = PlayerLocation - SplineLocation;
				return Delta.DotProduct(WorldRightVector);
			}

			case EPlayerSplineLockPlaneType::SplinePlane:
			case EPlayerSplineLockPlaneType::SplinePlaneAllowMovingWithinHorizontalDeviation:
			{
				const FVector WorldRightVector = SplineLock::GetDeviationRight(PlaneLockType, SplinePosition, MovementWorldUp);
				const FVector Delta = (WorldLocation - SplinePosition.WorldLocation);
				return Delta.DotProduct(WorldRightVector);
			}
		}
	}
}