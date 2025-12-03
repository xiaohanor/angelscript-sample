class UIslandDroidZiplineZiplineDestroyComponent : UAlongSplineComponent
{
	UHazeSplineComponent Spline;
	float DistanceOnSpline;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
		Spline = Spline::GetGameplaySpline(Owner, this);
		DistanceOnSpline = Spline.GetClosestSplineDistanceToWorldLocation(WorldLocation);
	}
}

#if EDITOR
class UIslandDroidZiplineZiplineDestroyVisualizer : UHazeScriptComponentVisualizer
{
	default VisualizedClass = UIslandDroidZiplineZiplineDestroyComponent;

	UFUNCTION(BlueprintOverride)
	void VisualizeComponent(const UActorComponent Component)
	{
		auto ZiplineDestroyComp = Cast<UIslandDroidZiplineZiplineDestroyComponent>(Component);
		SetHitProxy(n"Point", EVisualizerCursor::Hand);
		DrawPoint(ZiplineDestroyComp.WorldLocation, FLinearColor::Red, 40.0);
		ClearHitProxy();
	}

	UFUNCTION(BlueprintOverride)
	bool VisProxyHandleClick(FName HitProxy, FVector ClickOrigin, FVector ClickDirection, FKey Key,
							 EInputEvent Event)
	{
		if(HitProxy != n"Point")
			return false;

		if(!Key.IsMouseButton())
			return false;

		Editor::SelectComponent(EditingComponent);
		return true;
	}
}

class UIslandDroidZiplineZiplineDestroyComponentSplineContextMenuExtension : UHazeSplineContextMenuExtension
{
	bool IsValidForContextMenu(FHazeContextMenu& Menu, UHazeSplineComponent Spline,
							   UHazeSplineSelection Selection, int ClickedPoint, float ClickedDistance) const override
	{
		if(!Spline.Owner.IsA(AIslandDroidZiplineZiplineSpline))
			return false;

		return true;
	}

	FString GetSectionName() const override
	{
		return "DroidZipline Zipline";
	}

	void GenerateContextMenu(FHazeContextMenu& Menu, UHazeSplineComponent Spline, FHazeContextDelegate MenuDelegate, UHazeSplineSelection Selection, int ClickedPoint,
							 float ClickedDistance) override
	{
		if (ClickedDistance < 0.0)
			return;
		
		{
			FHazeContextOption AddRespawnZone;
			AddRespawnZone.DelegateParam = n"AddDestroyComponent";
			AddRespawnZone.Label = "Add Destroy Component";
			AddRespawnZone.Icon = n"Icons.Plus";
			AddRespawnZone.Tooltip = "Destroy the DroidZipline when it reaches this point!";
			Menu.AddOption(AddRespawnZone, MenuDelegate);
		}
	}

	void HandleContextOptionClicked(FHazeContextOption Option, UHazeSplineComponent Spline,
	                                UHazeSplineSelection Selection, float MenuClickedDistance,
	                                int MenuClickedPoint) override
	{
		const FName OptionName = Option.DelegateParam;

		if (OptionName == n"AddDestroyComponent")
		{
			auto DestroyComp = UIslandDroidZiplineZiplineDestroyComponent::Create(Spline.Owner);
			FTransform Transform = Spline.GetWorldTransformAtSplineDistance(MenuClickedDistance);
			Transform.Scale3D = FVector::OneVector;
			DestroyComp.SetWorldTransform(Transform);
			Editor::SelectComponent(DestroyComp);
			Spline.Owner.Modify();
		}
	}
}
#endif