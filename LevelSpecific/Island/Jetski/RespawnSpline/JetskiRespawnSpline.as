UCLASS(NotBlueprintable)
class AJetskiRespawnSpline : ASplineActor
{
	UPROPERTY(DefaultComponent)
	UAlongSplineComponentManager AlongSplineComponentManager;

	UPROPERTY(DefaultComponent)
	protected UHazeListedActorComponent ListedActorComp;

#if EDITOR
	UPROPERTY(DefaultComponent, ShowOnActor)
	protected UJetskiRespawnSplineEditorComponent EditorComp;
#endif

	protected bool bInitialized = false;
	protected TArray<UJetskiRespawnSplineZoneComponent> ZoneComponents;
};

#if EDITOR
class UJetskiRespawnSplineEditorComponent : UActorComponent
{
};

class UJetskiRespawnSplineEditorComponentVisualizer : UHazeScriptComponentVisualizer
{
	default VisualizedClass = UJetskiRespawnSplineEditorComponent;

	UFUNCTION(BlueprintOverride)
	void VisualizeComponent(const UActorComponent Component)
	{
		auto EditorComp = Cast<UJetskiRespawnSplineEditorComponent>(Component);
		if(EditorComp == nullptr)
			return;

		auto RespawnSpline = Cast<AJetskiRespawnSpline>(Component.Owner);
		if(RespawnSpline == nullptr)
			return;

		const FSplinePosition SplinePosition = RespawnSpline.Spline.GetClosestSplinePositionToLineSegment(EditorViewLocation, EditorViewLocation + EditorViewRotation.ForwardVector * 10000, false);

		FString Text = "Respawn Spline";
		FLinearColor Color = FLinearColor::White;
		
		const TOptional<FAlongSplineComponentData> ZoneData = RespawnSpline.Spline.FindPreviousComponentAlongSpline(UJetskiRespawnSplineZoneComponent, false, SplinePosition.CurrentSplineDistance);
		if(ZoneData.IsSet())
		{
			const auto ZoneComp = Cast<UJetskiRespawnSplineZoneComponent>(ZoneData.Value.Component);
			Text += f"\n{ZoneComp.GetVisualName()}";
			Color = ZoneComp.GetVisualizeColor();
		}

		DrawWireSphere(SplinePosition.WorldLocation, Jetski::Radius, Color, 1, 24);
		DrawWorldString(Text, SplinePosition.WorldLocation, FLinearColor::White, 1, 10000, true);
	}
};

class UJetskiRespawnSplineContextMenuExtension : UHazeSplineContextMenuExtension
{
	bool IsValidForContextMenu(FHazeContextMenu& Menu, UHazeSplineComponent Spline,
							   UHazeSplineSelection Selection, int ClickedPoint, float ClickedDistance) const override
	{
		if(!Spline.Owner.IsA(AJetskiRespawnSpline))
			return false;

		return true;
	}

	FString GetSectionName() const override
	{
		return "Jetski Respawn Spline";
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
			auto AddedZone = UJetskiRespawnSplineZoneComponent::Create(Spline.Owner);
			FTransform Transform = Spline.GetWorldTransformAtSplineDistance(MenuClickedDistance);
			Transform.Scale3D = FVector::OneVector;
			AddedZone.SetWorldTransform(Transform);
			Editor::SelectComponent(AddedZone);
			Spline.Owner.Modify();
		}
	}
};
#endif