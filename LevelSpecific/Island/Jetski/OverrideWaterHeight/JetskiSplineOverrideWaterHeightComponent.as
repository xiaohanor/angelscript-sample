UCLASS(NotBlueprintable)
class UJetskiSplineOverrideWaterHeightComponent : UAlongSplineComponent
{
	UPROPERTY(EditInstanceOnly, Category = "Override Water Height")
	bool bOverride = true;

	UPROPERTY(EditInstanceOnly, Category = "Override Water Height", Meta = (EditCondition = "bOverride && ActorHeight == nullptr"))
	private float WaterHeight = 0;

	UPROPERTY(EditInstanceOnly, Category = "Override Water Height", Meta = (EditCondition = "bOverride"))
	private TSoftObjectPtr<AActor> ActorHeight = nullptr;

	UPROPERTY(EditInstanceOnly, Category = "Override Water Height", Meta = (EditCondition = "bOverride && ActorHeight != nullptr", EditConditionHides))
	private float ActorHeightOffset = 0;

	float GetWaterHeight() const
	{
		check(bOverride);

		if(ActorHeight != nullptr)
			return ActorHeight.Get().ActorLocation.Z + ActorHeightOffset;

		return WaterHeight;
	}
};

#if EDITOR
class UJetskiSplineOverrideWaterHeightVisualizer : UAlongSplineComponentVisualizer
{
	default VisualizedClass = UJetskiSplineOverrideWaterHeightComponent;

	UFUNCTION(BlueprintOverride)
	void VisualizeComponent(const UActorComponent Component)
	{
		Super::VisualizeComponent(Component);

		const auto WaterHeightComp = Cast<UJetskiSplineOverrideWaterHeightComponent>(Component);
		if(WaterHeightComp == nullptr)
			return;

		FLinearColor Color = WaterHeightComp.bOverride ? FLinearColor::LucBlue : FLinearColor::Red;

		DrawWireBox(WaterHeightComp.WorldLocation, FVector(0, 500, 300), WaterHeightComp.ComponentQuat, Color, 3, true);

		if(WaterHeightComp.bOverride)
		{
			DrawWorldString(f"Override Height: {WaterHeightComp.GetWaterHeight():.0}", WaterHeightComp.WorldLocation, Color, bCenterText = true);
		}
		else
		{
			DrawWorldString("Clear Override", WaterHeightComp.WorldLocation, Color, bCenterText = true);
		}
	}
};
#endif

#if EDITOR
class UJetskiSplineOverrideWaterHeightContextMenuExtension : UHazeSplineContextMenuExtension
{
	bool IsValidForContextMenu(FHazeContextMenu& Menu, UHazeSplineComponent Spline,
							   UHazeSplineSelection Selection, int ClickedPoint, float ClickedDistance) const override
	{
		if(!Spline.Owner.IsA(AJetskiSpline))
			return false;

		return true;
	}

	FString GetSectionName() const override
	{
		return "Jetski Override Water Height";
	}

	void GenerateContextMenu(FHazeContextMenu& Menu, UHazeSplineComponent Spline, FHazeContextDelegate MenuDelegate, UHazeSplineSelection Selection, int ClickedPoint,
							 float ClickedDistance) override
	{
		if (ClickedDistance < 0.0)
			return;
		
		{
			FHazeContextOption OverrideWaterHeight;
			OverrideWaterHeight.DelegateParam = n"OverrideWaterHeight";
			OverrideWaterHeight.Label = "Override Water Height";
			OverrideWaterHeight.Icon = n"Icons.Plus";
			Menu.AddOption(OverrideWaterHeight, MenuDelegate);
		}

		{
			FHazeContextOption ClearWaterHeight;
			ClearWaterHeight.DelegateParam = n"ClearWaterHeight";
			ClearWaterHeight.Label = "Clear Water Height";
			ClearWaterHeight.Icon = n"Icons.Minus";
			Menu.AddOption(ClearWaterHeight, MenuDelegate);
		}
	}

	void HandleContextOptionClicked(FHazeContextOption Option, UHazeSplineComponent Spline,
	                                UHazeSplineSelection Selection, float MenuClickedDistance,
	                                int MenuClickedPoint) override
	{
		const FName OptionName = Option.DelegateParam;

		if (OptionName == n"OverrideWaterHeight")
		{
			Editor::BeginTransaction("OverrideWaterHeight", Spline);

			Spline.Owner.Modify();
			auto OverrideComp = Editor::AddInstanceComponentInEditor(Spline.Owner, UJetskiSplineOverrideWaterHeightComponent, NAME_None);
			FTransform Transform = Spline.GetWorldTransformAtSplineDistance(MenuClickedDistance);
			Transform.Scale3D = FVector::OneVector;
			OverrideComp.bOverride = true;
			OverrideComp.SetWorldTransform(Transform);
			Editor::SelectComponent(OverrideComp);

			Editor::EndTransaction();
		}
		else if (OptionName == n"ClearWaterHeight")
		{
			Editor::BeginTransaction("ClearWaterHeight", Spline);

			Spline.Owner.Modify();
			auto OverrideComp = Editor::AddInstanceComponentInEditor(Spline.Owner, UJetskiSplineOverrideWaterHeightComponent, NAME_None);
			FTransform Transform = Spline.GetWorldTransformAtSplineDistance(MenuClickedDistance);
			Transform.Scale3D = FVector::OneVector;
			OverrideComp.bOverride = false;
			OverrideComp.SetWorldTransform(Transform);
			Editor::SelectComponent(OverrideComp);

			Editor::EndTransaction();
		}
	}
};
#endif