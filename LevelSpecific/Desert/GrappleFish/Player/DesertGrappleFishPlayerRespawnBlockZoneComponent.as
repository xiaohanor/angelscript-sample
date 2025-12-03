UCLASS(NotBlueprintable)
class UDesertGrappleFishPlayerRespawnBlockZoneComponent : UAlongSplineComponent
{
	UPROPERTY(EditInstanceOnly)
	float Length = 5000;

	UPROPERTY(EditInstanceOnly)
	float VisualizeRadius = 4000;

	UPROPERTY(EditInstanceOnly)
	float VisualizeDistanceInterval = 500;

	UPROPERTY(VisibleAnywhere)
	ASplineActor SplineActor;

	FSplinePosition SplinePosition;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		if (SplineActor == nullptr)
		{
			auto OwningSplineActor = Cast<ASplineActor>(Owner);
			if (OwningSplineActor == nullptr)
				return;

			SplineActor = OwningSplineActor;
		}

		SplinePosition = SplineActor.Spline.GetClosestSplinePositionToWorldLocation(WorldLocation);
	}

#if EDITOR
	UFUNCTION(BlueprintOverride)
	void OnComponentModifiedInEditor()
	{
		Super::OnComponentModifiedInEditor();
		if (SplineActor == nullptr)
		{
			auto OwningSplineActor = Cast<ASplineActor>(Owner);
			if (OwningSplineActor == nullptr)
				return;

			SplineActor = OwningSplineActor;
		}

		SplinePosition = SplineActor.Spline.GetClosestSplinePositionToWorldLocation(WorldLocation);
	}

	UFUNCTION(BlueprintOverride)
	void OnActorOwnerModifiedInEditor()
	{
		Super::OnActorOwnerModifiedInEditor();
		if (SplineActor == nullptr)
		{
			auto OwningSplineActor = Cast<ASplineActor>(Owner);
			if (OwningSplineActor == nullptr)
				return;

			SplineActor = OwningSplineActor;
		}

		SplinePosition = SplineActor.Spline.GetClosestSplinePositionToWorldLocation(WorldLocation);
	}

	void Visualize(const UHazeScriptComponentVisualizer Visualizer) const
	{
		if (SplineActor == nullptr)
			return;

		FSplinePosition StartPosition = SplinePosition;
		float CurrentDistance = 0;

		FSplinePosition EndPosition;
		FLinearColor VisualizeColor = FLinearColor(1.0, 0, 0.4);

		int CircleSegments = 8;
		Debug::DrawDebugCircle(StartPosition.WorldLocation, VisualizeRadius * EndPosition.WorldScale3D.Y, CircleSegments, VisualizeColor, 20, StartPosition.WorldRightVector, StartPosition.WorldUpVector);
		while (CurrentDistance < Length)
		{
			EndPosition = SplinePosition.CurrentSpline.GetSplinePositionAtSplineDistance(SplinePosition.CurrentSplineDistance + CurrentDistance + VisualizeDistanceInterval);
			for (int i = 0; i < CircleSegments; i++)
			{
				float Rad = (TWO_PI / CircleSegments) * i;
				FVector StartOffset = FVector(0, Math::Sin(Rad) * VisualizeRadius * StartPosition.WorldScale3D.Y, Math::Cos(Rad) * VisualizeRadius);
				FVector StartPoint = StartPosition.WorldTransform.TransformPosition(StartOffset);
				FVector EndOffset = FVector(0, Math::Sin(Rad) * VisualizeRadius * EndPosition.WorldScale3D.Y, Math::Cos(Rad) * VisualizeRadius);
				FVector EndPoint = EndPosition.WorldTransform.TransformPosition(EndOffset);
				Debug::DrawDebugLine(StartPoint, EndPoint, VisualizeColor, 20);
			}
			Debug::DrawDebugCircle(EndPosition.WorldLocation, VisualizeRadius * EndPosition.WorldScale3D.Y, CircleSegments, VisualizeColor, 20, EndPosition.WorldRightVector, EndPosition.WorldUpVector);
			StartPosition = EndPosition;
			CurrentDistance += VisualizeDistanceInterval;
		}
	}
#endif

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
		SplinePosition = SplineActor.Spline.GetClosestSplinePositionToWorldLocation(WorldLocation);
	}

	bool IsDistanceInsideZone(float SplineDistance) const
	{
		if (SplineDistance < SplinePosition.CurrentSplineDistance)
			return false;

		if (SplineDistance > SplinePosition.CurrentSplineDistance + Length)
			return false;

		return true;
	}
};

#if EDITOR
class UDesertGrappleFishPlayerRespawnBlockZoneComponentVisualizer : UAlongSplineComponentVisualizer
{
	default VisualizedClass = UDesertGrappleFishPlayerRespawnBlockZoneComponent;

	UFUNCTION(BlueprintOverride)
	void VisualizeComponent(const UActorComponent Component)
	{
		Super::VisualizeComponent(Component);

		const auto ZoneComp = Cast<UDesertGrappleFishPlayerRespawnBlockZoneComponent>(Component);
		if (ZoneComp == nullptr)
			return;

		ZoneComp.Visualize(this);
	}
};
#endif