UCLASS(NotBlueprintable)
class UAdultDragonRespawnBlockSplineZoneComponent : UAlongSplineComponent
{
	UPROPERTY(EditAnywhere)
	float ZoneSplineLength = 2000;

	UPROPERTY(EditAnywhere)
	float ZoneRadius = 1000;

	UPROPERTY(EditAnywhere)
	float VisualizeDistanceInterval = 500;

	UPROPERTY(VisibleAnywhere)
	ASplineActor SplineActor;

	FSplinePosition SplinePosition;

	bool IsDistanceInsideZone(float SplineDistance) const
	{
		if (SplineDistance < SplinePosition.CurrentSplineDistance)
			return false;

		if (SplineDistance > SplinePosition.CurrentSplineDistance + ZoneSplineLength)
			return false;

		return true;
	}

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
	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
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
		FLinearColor VisualizeColor = FLinearColor(1.00, 0.00, 0.00);

		int CircleSegments = 8;
		Debug::DrawDebugCircle(StartPosition.WorldLocation, ZoneRadius * EndPosition.WorldScale3D.Y, CircleSegments, VisualizeColor, 75, StartPosition.WorldRightVector, StartPosition.WorldUpVector);
		while (CurrentDistance < ZoneSplineLength)
		{
			EndPosition = SplinePosition.CurrentSpline.GetSplinePositionAtSplineDistance(SplinePosition.CurrentSplineDistance + CurrentDistance + VisualizeDistanceInterval);
			Debug::DrawDebugCircle(EndPosition.WorldLocation, ZoneRadius * EndPosition.WorldScale3D.Y, CircleSegments, VisualizeColor, 75, EndPosition.WorldRightVector, EndPosition.WorldUpVector);
			StartPosition = EndPosition;
			CurrentDistance += VisualizeDistanceInterval;
		}
	}
#endif
};

#if EDITOR
class UAdultDragonRespawnSplineZoneComponentVisualizer : UAlongSplineComponentVisualizer
{
	default VisualizedClass = UAdultDragonRespawnBlockSplineZoneComponent;

	UFUNCTION(BlueprintOverride)
	void VisualizeComponent(const UActorComponent Component)
	{
		Super::VisualizeComponent(Component);

		const auto ZoneComp = Cast<UAdultDragonRespawnBlockSplineZoneComponent>(Component);
		if (ZoneComp == nullptr)
			return;

		ZoneComp.Visualize(this);
	}
};
#endif