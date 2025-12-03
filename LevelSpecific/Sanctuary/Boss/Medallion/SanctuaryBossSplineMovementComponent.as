UCLASS(NotBlueprintable)
class USanctuaryBossSplineMovementComponent : UActorComponent
{
	UPROPERTY(EditInstanceOnly)
	ASplineActor TestSplineActor;

	UPROPERTY()
	float CollisionRadius = 50.0;

	UHazeSplineComponent Spline;

	private FVector2D InternalLocation;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Spline = TListedActors<ASanctuaryBossMedallionHydraReferences>().Single.SideScrollerSplineLocker.Spline;

		InternalLocation = ConvertWorldLocationToSplineLocation(Owner.ActorLocation);
	}

	FVector2D GetSplineLocation() const property
	{
		return InternalLocation;
	}

	/**
	 * X = Horizontal
	 * Y = Vertical
	 * Note: This also applies the location to the actor
	 */
	FHitResult SetSplineLocation(FVector2D InLocation, bool bSweep = false)
	{
		if(bSweep)
		{

			FHazeTraceSettings TraceSettings = Trace::InitProfile(n"PlayerCharacter");
			TraceSettings.UseSphereShape(CollisionRadius);

			const FHitResult Hit = SweepToSplineLocation(InternalLocation, InLocation, TraceSettings);
			if(Hit.IsValidBlockingHit())
			{
				SetSplineLocation(ConvertWorldLocationToSplineLocation(Hit.Location), false);
				return Hit;
			}
		}
		InternalLocation = InLocation;
		const FVector WorldLocation = ConvertSplineLocationToWorldLocation(InLocation);
		Owner.SetActorLocation(WorldLocation);
		return FHitResult();
	}
	FHitResult SweepToSplineLocation(FVector2D FromLocation, FVector2D ToLocation, FHazeTraceSettings TraceSettings) const
	{
		const FVector From = ConvertSplineLocationToWorldLocation(FromLocation);
		const FVector To = ConvertSplineLocationToWorldLocation(ToLocation);
		return TraceSettings.QueryTraceSingle(From, To);
	}

	FTransform GetSplineTransform() const
	{
		return Spline.GetWorldTransformAtSplineDistance(InternalLocation.X);
	}

	/**
	 * Location
	 */

	FVector2D ConvertWorldLocationToSplineLocation(FVector InWorldLocation) const
	{
		const float SplineDistance = Spline.GetClosestSplineDistanceToWorldLocation(InWorldLocation);
		const float VerticalDistance = (InWorldLocation - Spline.GetWorldLocationAtSplineDistance(SplineDistance)).Z;
		return FVector2D(SplineDistance, VerticalDistance);
	}

	FVector ConvertSplineLocationToWorldLocation(FVector2D InSplineLocation) const
	{
		const FVector LocalLocation = Spline.GetWorldLocationAtSplineDistance(Math::Wrap(InSplineLocation.X, 0, Spline.SplineLength));
		return LocalLocation + (FVector::UpVector * InSplineLocation.Y);
	}

	/**
	 * Direction
	 */

	FVector ConvertSplineDirectionToWorldDirection(FVector2D SplineDirection) const
	{
		const FVector RelativeDirection = FVector(SplineDirection.X, 0, SplineDirection.Y);
		return Spline.GetWorldTransformAtSplineDistance(InternalLocation.X).TransformVectorNoScale(RelativeDirection);
	}

	FVector2D ConvertWorldDirectionToSplineDirection(FVector WorldDirection) const
	{
		const FVector RelativeDirection = Spline.GetWorldTransformAtSplineDistance(InternalLocation.X).InverseTransformVectorNoScale(WorldDirection);
		PrintToScreen("Direction = " + RelativeDirection, 2.0);
		return FVector2D(RelativeDirection.X, RelativeDirection.Z);
	}

	/**
	 * Rotation
	 */

	void ApplyRotation(float Angle)
	{
		Owner.SetActorRotation(ConvertAngleToWorldRotation(Angle));
	}

	/**
	 * Hannes wants 0 to be straight down...
	 */
	private float ConvertAngle(float Angle) const
	{
		return Angle - 90;
	}

	FRotator ConvertAngleToWorldRotation(float Angle) const
	{
		const FQuat SplineRotation = GetSplineTransform().Rotation;
		FQuat Rotation = FQuat(SplineRotation.RightVector, Math::DegreesToRadians(ConvertAngle(Angle)));
		const FVector WorldDirection = Rotation.ForwardVector;
		return FRotator::MakeFromXY(WorldDirection, SplineRotation.RightVector);
	}

	/**
	 * TODO: Doesn't work...
	 */
	float ConvertWorldRotationToAngle(FRotator Rotation) const
	{
		return ConvertAngle(Math::DirectionToAngleDegrees(ConvertWorldDirectionToSplineDirection(Rotation.ForwardVector)));
	}
};

UCLASS(NotBlueprintable)
class ASplineMovementTestActor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USphereComponent SphereComp;

	UPROPERTY(DefaultComponent)
	USanctuaryBossSplineMovementComponent SplineMoveComp;

	UPROPERTY(EditInstanceOnly)
	float Angle = 0;

	UPROPERTY(EditInstanceOnly)
	FVector2D Location;

#if EDITOR
	UFUNCTION(BlueprintOverride)
	void OnActorModifiedInEditor()
	{
		SplineMoveComp.SetSplineLocation(Location);
		SplineMoveComp.ApplyRotation(Angle);
	}
#endif
};

#if EDITOR
class USanctuaryBossSplineMovementComponentVisualizer : UHazeScriptComponentVisualizer
{
	default VisualizedClass = USanctuaryBossSplineMovementComponent;

	UFUNCTION(BlueprintOverride)
	void VisualizeComponent(const UActorComponent Component)
	{
		USanctuaryBossSplineMovementComponent Comp = Cast<USanctuaryBossSplineMovementComponent>(Component);
		if(Comp == nullptr)
			return;

		if(Comp.Spline == nullptr && Comp.TestSplineActor != nullptr)
			Comp.Spline = Comp.TestSplineActor.Spline;

		if(Comp.Spline == nullptr)
			return;

		FVector2D Location = Comp.ConvertWorldLocationToSplineLocation(Comp.Owner.ActorLocation);
		FVector2D Forward = Comp.ConvertWorldDirectionToSplineDirection(Comp.Owner.ActorForwardVector);
		float Angle = Comp.ConvertWorldRotationToAngle(Comp.Owner.ActorRotation);

		DrawArrow(Comp.Owner.ActorLocation, Comp.Owner.ActorLocation + Comp.Owner.ActorForwardVector * 100, FLinearColor::Red);
		DrawWorldString(f"{Location=}, {Forward=}, {Angle=}", Comp.Owner.ActorLocation);
	}
}
#endif