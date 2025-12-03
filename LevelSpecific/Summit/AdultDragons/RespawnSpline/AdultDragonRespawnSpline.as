UCLASS(NotBlueprintable)
class AAdultDragonRespawnSpline : ASplineActor
{
	UPROPERTY(DefaultComponent)
	USummitAdultDragonSplineFollowComponent SplineFollowComp;

	UPROPERTY(DefaultComponent)
	UAlongSplineComponentManager AlongSplineComponentManager;

	UPROPERTY(DefaultComponent)
	protected UHazeListedActorComponent ListedActorComp;

#if EDITOR
	UPROPERTY(DefaultComponent, ShowOnActor)
	protected UAdultDragonRespawnSplineEditorComponent EditorComp;
#endif

	protected bool bInitialized = false;
	protected TArray<UAdultDragonRespawnBlockSplineZoneComponent> ZoneComponents;

	UAdultDragonRespawnBlockSplineZoneComponent GetClosestOfMultipleRespawnBlockZoneAtDistanceAlongSpline(float DistanceAlongSpline) const
	{
		TOptional<FAlongSplineComponentData> Previous;
		TOptional<FAlongSplineComponentData> Next;
		float _;
		auto FoundComponent = AlongSplineComponentManager.FindAdjacentComponentsAlongSpline(UAdultDragonRespawnBlockSplineZoneComponent, false, DistanceAlongSpline, Previous, Next, _);

		if (!FoundComponent)
			return nullptr;

		if (!Previous.IsSet())
		{
			if (!Next.IsSet())
				return nullptr;
			else
				return Cast<UAdultDragonRespawnBlockSplineZoneComponent>(Next.Value.Component);
		}
		else if (!Next.IsSet())
		{
			return Cast<UAdultDragonRespawnBlockSplineZoneComponent>(Previous.Value.Component);
		}

		auto NextZoneComp = Cast<UAdultDragonRespawnBlockSplineZoneComponent>(Next.Value.Component);
		auto PreviousZoneComp = Cast<UAdultDragonRespawnBlockSplineZoneComponent>(Previous.Value.Component);

		if (NextZoneComp.IsDistanceInsideZone(DistanceAlongSpline))
			return NextZoneComp;
		else if (PreviousZoneComp.IsDistanceInsideZone(DistanceAlongSpline))
			return PreviousZoneComp;
		else
			return nullptr;
	}

	UAdultDragonRespawnBlockSplineZoneComponent GetClosestRespawnBlockZoneAtDistanceAlongSpline(float DistanceAlongSpline) const
	{
		
		TOptional<FAlongSplineComponentData> Data = AlongSplineComponentManager.FindClosestComponentAlongSpline(UAdultDragonRespawnBlockSplineZoneComponent, false, DistanceAlongSpline);
		if (!Data.IsSet())
			return nullptr;

		auto RespawnBlockZone = Cast<UAdultDragonRespawnBlockSplineZoneComponent>(Data.Value.Component);
		if (!RespawnBlockZone.IsDistanceInsideZone(DistanceAlongSpline))
			return nullptr;

		return Cast<UAdultDragonRespawnBlockSplineZoneComponent>(Data.Value.Component);
	}
};

#if EDITOR
class UAdultDragonRespawnSplineEditorComponent : UActorComponent
{
};

class UAdultDragonRespawnSplineEditorComponentVisualizer : UHazeScriptComponentVisualizer
{
	default VisualizedClass = UAdultDragonRespawnSplineEditorComponent;

	UFUNCTION(BlueprintOverride)
	void VisualizeComponent(const UActorComponent Component)
	{
		auto EditorComp = Cast<UAdultDragonRespawnSplineEditorComponent>(Component);
		if (EditorComp == nullptr)
			return;

		auto RespawnSpline = Cast<AAdultDragonRespawnSpline>(Component.Owner);
		if (RespawnSpline == nullptr)
			return;

		const FSplinePosition SplinePosition = RespawnSpline.Spline.GetClosestSplinePositionToLineSegment(EditorViewLocation, EditorViewLocation + EditorViewRotation.ForwardVector * 10000, false);

		FString Text = "";
		FLinearColor Color = FLinearColor::White;

		const auto Zone = RespawnSpline.GetClosestOfMultipleRespawnBlockZoneAtDistanceAlongSpline(SplinePosition.CurrentSplineDistance);

		DrawWireSphere(SplinePosition.WorldLocation, 4000, Color, 5, 4, true);
		DrawWorldString(Text, SplinePosition.WorldLocation, FLinearColor::White, 5, 50000, true);
	}
};

class UAdultDragonRespawnSplineContextMenuExtension : UHazeSplineContextMenuExtension
{
	bool IsValidForContextMenu(FHazeContextMenu& Menu, UHazeSplineComponent Spline,
							   UHazeSplineSelection Selection, int ClickedPoint, float ClickedDistance) const override
	{
		if (!Spline.Owner.IsA(AAdultDragonRespawnSpline))
			return false;

		return true;
	}

	FString GetSectionName() const override
	{
		return "AdultDragon Respawn Spline";
	}

	void GenerateContextMenu(FHazeContextMenu& Menu, UHazeSplineComponent Spline, FHazeContextDelegate MenuDelegate, UHazeSplineSelection Selection, int ClickedPoint,
							 float ClickedDistance) override
	{
		if (ClickedDistance < 0.0)
			return;

		{
			FHazeContextOption AddRespawnZone;
			AddRespawnZone.DelegateParam = n"AddRespawnBlockZone";
			AddRespawnZone.Label = "Add Respawn Block Zone";
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

		if (OptionName == n"AddRespawnBlockZone")
		{
			auto AddedZone = UAdultDragonRespawnBlockSplineZoneComponent::Create(Spline.Owner);
			FTransform Transform = Spline.GetWorldTransformAtSplineDistance(MenuClickedDistance);
			Transform.Scale3D = FVector::OneVector;
			AddedZone.SetWorldTransform(Transform);
			Editor::SelectComponent(AddedZone);
			Spline.Owner.Modify();
		}
	}
};
#endif