UCLASS(NotBlueprintable)
class UStoneBeastPlayerSplineRespawnZoneComponent : UAlongSplineComponent
{
	UPROPERTY(EditInstanceOnly)
	float Length = 500;

	UPROPERTY(EditInstanceOnly)
	float VisualizeRadius = 250;

	UPROPERTY(EditInstanceOnly)
	uint VisualizeSplineSegmentDistanceInterval = 150;

	UPROPERTY(VisibleAnywhere)
	AStoneBeastPlayerSpline PlayerSpline;

	FSplinePosition SplinePosition;
	float HalfLength;

#if EDITOR
	default EditorRadius = 0;
#endif

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		if (PlayerSpline == nullptr)
		{
			auto OwningSplineActor = Cast<AStoneBeastPlayerSpline>(Owner);
			if (OwningSplineActor == nullptr)
				return;

			PlayerSpline = OwningSplineActor;
		}

		SplinePosition = PlayerSpline.Spline.GetClosestSplinePositionToWorldLocation(WorldLocation);
	}

#if EDITOR
	UFUNCTION(BlueprintOverride)
	void OnComponentModifiedInEditor()
	{
		Super::OnComponentModifiedInEditor();
		if (PlayerSpline == nullptr)
		{
			auto OwningSplineActor = Cast<AStoneBeastPlayerSpline>(Owner);
			if (OwningSplineActor == nullptr)
				return;

			PlayerSpline = OwningSplineActor;
		}

		SplinePosition = PlayerSpline.Spline.GetClosestSplinePositionToWorldLocation(WorldLocation);
	}

	UFUNCTION(BlueprintOverride)
	void OnActorOwnerModifiedInEditor()
	{
		Super::OnActorOwnerModifiedInEditor();
		if (PlayerSpline == nullptr)
		{
			auto OwningSplineActor = Cast<AStoneBeastPlayerSpline>(Owner);
			if (OwningSplineActor == nullptr)
				return;

			PlayerSpline = OwningSplineActor;
		}

		SplinePosition = PlayerSpline.Spline.GetClosestSplinePositionToWorldLocation(WorldLocation);
	}

	void Visualize(const UHazeScriptComponentVisualizer Visualizer) const
	{
		if (PlayerSpline == nullptr)
			return;

		FSplinePosition StartPosition = PlayerSpline.Spline.GetClosestSplinePositionToWorldLocation(WorldLocation);
		float CurrentDistance = StartPosition.CurrentSplineDistance;

		FSplinePosition EndPosition;

		int CircleSegments = 16;
		Visualizer.DrawCircle(StartPosition.WorldLocation, VisualizeRadius, FLinearColor::Green, 3, StartPosition.WorldForwardVector, CircleSegments);
		Visualizer.DrawLine(StartPosition.WorldLocation, StartPosition.WorldLocation + FVector::DownVector * 5000, FLinearColor::Green, 5);
		while (CurrentDistance < SplinePosition.CurrentSplineDistance + Length)
		{
			EndPosition = PlayerSpline.Spline.GetSplinePositionAtSplineDistance(CurrentDistance + VisualizeSplineSegmentDistanceInterval);

			for (int i = 0; i < CircleSegments; i++)
			{
				float Rad = (TWO_PI / CircleSegments) * i;
				FVector Offset = FVector(0, Math::Sin(Rad) * VisualizeRadius, Math::Cos(Rad) * VisualizeRadius);
				FVector StartPoint = StartPosition.WorldTransform.TransformPosition(Offset);
				FVector EndPoint = EndPosition.WorldTransform.TransformPosition(Offset);
				Visualizer.DrawLine(StartPoint, EndPoint, FLinearColor::Green, 5, false);
			}
			Visualizer.DrawCircle(EndPosition.WorldLocation, VisualizeRadius, FLinearColor::Green, 3, EndPosition.WorldForwardVector, CircleSegments);
			StartPosition = EndPosition;

			CurrentDistance += VisualizeSplineSegmentDistanceInterval;
		}
		Visualizer.DrawLine(EndPosition.WorldLocation, EndPosition.WorldLocation + FVector::DownVector * 5000, FLinearColor::Green, 5);
	}
#endif

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
		SplinePosition = PlayerSpline.Spline.GetClosestSplinePositionToWorldLocation(WorldLocation);

		HalfLength = Length * 0.5;
	}

	bool TryGetRespawnSplinePositionInsideZone(float PlayerDistance, float MinDistancePadding, FSplinePosition&out OutSplinePosition)
	{
		float SplineDistance;
		float ZoneStartDistance = SplinePosition.CurrentSplineDistance;
		float ZoneMaxDistance = ZoneStartDistance + Length;
		if (IsDistanceInsideZone(PlayerDistance))
		{
			// We either spawn ahead of player or at end of zone
			SplineDistance = Math::Clamp(PlayerDistance + MinDistancePadding, ZoneStartDistance, ZoneMaxDistance);
		}
		else if (PlayerDistance > SplinePosition.CurrentSplineDistance + Length)
			SplineDistance = ZoneMaxDistance;
		else
			SplineDistance = ZoneStartDistance + MinDistancePadding;

		if (SplineDistance < PlayerSpline.MinRespawnSplineDistance + MinDistancePadding)
			return false;

		OutSplinePosition = PlayerSpline.Spline.GetSplinePositionAtSplineDistance(SplineDistance);
		// Debug::DrawDebugSphere(SplinePosition.WorldLocation);
		return true;
	}

	bool IsDistanceInsideZone(float Distance)
	{
		return Distance >= SplinePosition.CurrentSplineDistance && Distance <= SplinePosition.CurrentSplineDistance + Length;
	}

	bool IsClosestWorldLocationInsideZone(FVector InWorldLocation) const
	{
		FSplinePosition SplinePos = PlayerSpline.Spline.GetClosestSplinePositionToWorldLocation(InWorldLocation);
		float Distance = SplinePos.CurrentSplineDistance;
		return Distance >= SplinePosition.CurrentSplineDistance && Distance <= SplinePosition.CurrentSplineDistance + Length;
	}

	bool IsSplinePositionInsideZone(FSplinePosition InSplinePos) const
	{
		float SplineDist = InSplinePos.CurrentSplineDistance;

		if (SplineDist < SplinePosition.CurrentSplineDistance)
			return false;

		if (SplineDist > SplinePosition.CurrentSplineDistance + Length)
			return false;

		return true;
	}
};

#if EDITOR
class UStoneBeastPlayerRespawnZoneComponentVisualizer : UAlongSplineComponentVisualizer
{
	default VisualizedClass = UStoneBeastPlayerSplineRespawnZoneComponent;

	UFUNCTION(BlueprintOverride)
	void VisualizeComponent(const UActorComponent Component)
	{
		Super::VisualizeComponent(Component);

		const auto ZoneComp = Cast<UStoneBeastPlayerSplineRespawnZoneComponent>(Component);
		if (ZoneComp == nullptr)
			return;

		ZoneComp.Visualize(this);
	}
};
#endif