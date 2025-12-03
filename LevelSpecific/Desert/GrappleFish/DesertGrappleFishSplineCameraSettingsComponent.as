UCLASS(NotBlueprintable)
class UDesertGrappleFishSplineCameraSettingsComponent : UAlongSplineComponent
{
	UPROPERTY(EditInstanceOnly)
	UHazeCameraSettingsDataAsset CameraSettings;

	UPROPERTY(EditInstanceOnly)
	float BlendInTime = 1.0;

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

		Visualizer.DrawCircle(WorldLocation, 1400, FLinearColor::LucBlue, 100, SplinePosition.WorldForwardVector, 16);
		Visualizer.DrawWorldString(CameraSettings.GetName().PlainNameString, WorldLocation, FLinearColor::LucBlue, 2, 1e5, true);
	}
#endif

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
		SplinePosition = SplineActor.Spline.GetClosestSplinePositionToWorldLocation(WorldLocation);
	}
};

#if EDITOR
class UDesertGrappleFishSplineCameraSettingsComponentVisualizer : UAlongSplineComponentVisualizer
{
	default VisualizedClass = UDesertGrappleFishSplineCameraSettingsComponent;

	UFUNCTION(BlueprintOverride)
	void VisualizeComponent(const UActorComponent Component)
	{
		Super::VisualizeComponent(Component);

		const auto ZoneComp = Cast<UDesertGrappleFishSplineCameraSettingsComponent>(Component);
		if (ZoneComp == nullptr)
			return;

		SetHitProxy(n"SplineCameraSettingsComp");
		ZoneComp.Visualize(this);
		ClearHitProxy();
	}

	UFUNCTION(BlueprintOverride)
	bool VisProxyHandleClick(FName HitProxy, FVector ClickOrigin, FVector ClickDirection, FKey Key, EInputEvent Event)
	{
		if (EditingComponent != nullptr)
		{
			auto ClickedComponent = Cast<UDesertGrappleFishSplineCameraSettingsComponent>(EditingComponent);
			if (ClickedComponent != nullptr)
			{
				Editor::SelectComponent(ClickedComponent);
				return true;
			}
		}

		return false;
	}
};
#endif