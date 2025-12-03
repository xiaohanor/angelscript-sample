UCLASS(NotBlueprintable)
class AStoneBeastPlayerSpline : ASplineActor
{
	UPROPERTY(DefaultComponent)
	UAlongSplineComponentManager AlongSplineComponentManager;

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedActorComp;

	float MinRespawnSplineDistance = 0;

	default Spline.EditingSettings.SplineColor = FLinearColor::Teal;

#if EDITOR
	UFUNCTION(BlueprintOverride)
	void OnVisualizeInEditor() const
	{
		Debug::DrawDebugSphere(Spline.GetWorldLocationAtSplineDistance(MinRespawnSplineDistance), 100, 4, FLinearColor::Red, 5);
	}
#endif
};

#if EDITOR
class UAStoneBeastPlayerSplineContextMenuExtension : UHazeSplineContextMenuExtension
{
	bool IsValidForContextMenu(FHazeContextMenu& Menu, UHazeSplineComponent Spline,
							   UHazeSplineSelection Selection, int ClickedPoint, float ClickedDistance) const override
	{
		if (!Spline.Owner.IsA(AStoneBeastPlayerSpline))
			return false;

		return true;
	}

	FString GetSectionName() const override
	{
		return "StoneBeast Player Spline";
	}

	void GenerateContextMenu(FHazeContextMenu& Menu, UHazeSplineComponent Spline, FHazeContextDelegate MenuDelegate, UHazeSplineSelection Selection, int ClickedPoint,
							 float ClickedDistance) override
	{
		if (ClickedDistance < 0.0)
			return;

		{
			FHazeContextOption AddRespawnZone;
			AddRespawnZone.DelegateParam = n"AddRespawnZone";
			AddRespawnZone.Label = "Add Respawn Zone";
			AddRespawnZone.Icon = n"Icons.Plus";
			AddRespawnZone.Tooltip = "From this zone and forward, apply these settings to respawning.";
			Menu.AddOption(AddRespawnZone, MenuDelegate);
		}
	}

	void HandleContextOptionClicked(FHazeContextOption Option, UHazeSplineComponent Spline,
									UHazeSplineSelection Selection, float MenuClickedDistance,
									int MenuClickedPoint) override
	{
		const FName OptionName = Option.DelegateParam;

		if (OptionName == n"AddRespawnZone")
		{
			auto AddedZone = UStoneBeastPlayerSplineRespawnZoneComponent::Create(Spline.Owner);
			FTransform Transform = Spline.GetWorldTransformAtSplineDistance(MenuClickedDistance);
			Transform.Scale3D = FVector::OneVector;
			AddedZone.SetWorldTransform(Transform);
			Editor::SelectComponent(AddedZone);
			Spline.Owner.Modify();
		}
	}
};
#endif