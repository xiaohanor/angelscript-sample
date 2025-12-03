class AAdultDragonFreeFlyingRubberBandSpline : ASplineActor
{
	UPROPERTY(DefaultComponent)
	UAlongSplineComponentManager AlongSplineComponentManager;

	UPROPERTY(DefaultComponent)
	protected UHazeListedActorComponent ListedActorComp;

	UPROPERTY(DefaultComponent)
	UAdultDragonFreeFlyingSplineBoundaryComponent BoundaryComp;

#if EDITOR
	UPROPERTY(DefaultComponent, ShowOnActor)
	protected UAdultDragonFreeFlyingRubberBandSplineEditorComponent EditorComp;
#endif

	protected bool bInitialized = false;

	UAdultDragonSplineRubberBandSyncPointComponent GetSyncPointAtDistanceAlongSpline(float DistanceAlongSpline) const
	{
		auto FoundComponent = AlongSplineComponentManager.FindNextComponentAlongSpline(UAdultDragonSplineRubberBandSyncPointComponent, false, DistanceAlongSpline);
		if(FoundComponent.IsSet())
		{
			auto NextSyncPointComp = Cast<UAdultDragonSplineRubberBandSyncPointComponent>(FoundComponent.Value.Component);
			if (NextSyncPointComp != nullptr)
				return NextSyncPointComp;
		}

		FoundComponent = AlongSplineComponentManager.FindPreviousComponentAlongSpline(UAdultDragonSplineRubberBandSyncPointComponent, false, DistanceAlongSpline);
		if(FoundComponent.IsSet())
		{
			return Cast<UAdultDragonSplineRubberBandSyncPointComponent>(FoundComponent.Value.Component);
		}

		return nullptr;
	}

	bool IsSplineComponentAheadOfOtherSplineComponent(const UAdultDragonSplineRubberBandSyncPointComponent&in CompA, const UAdultDragonSplineRubberBandSyncPointComponent&in CompB) const
	{
		return Spline.GetClosestSplineDistanceToWorldLocation(CompA.WorldLocation) > Spline.GetClosestSplineDistanceToWorldLocation(CompB.WorldLocation);
	}

	float GetBoundaryRadiusAtSplinePosition(FSplinePosition SplinePosition) const
	{
		return SplinePosition.WorldScale3D.Size() * BoundaryComp.BoundaryRadius;
	}

	float GetKillRadiusAtSplinePosition(FSplinePosition SplinePosition) const
	{
		return SplinePosition.WorldScale3D.Size() * BoundaryComp.KillRadius;
	}
};

#if EDITOR
class UAdultDragonFreeFlyingRubberBandSplineEditorComponent : UActorComponent
{
};

class UAdultDragonFreeFlyingRubberBandSplineEditorComponentVisualizer : UHazeScriptComponentVisualizer
{
	default VisualizedClass = UAdultDragonFreeFlyingRubberBandSplineEditorComponent;

	UFUNCTION(BlueprintOverride)
	void VisualizeComponent(const UActorComponent Component)
	{
		auto EditorComp = Cast<UAdultDragonFreeFlyingRubberBandSplineEditorComponent>(Component);
		if (EditorComp == nullptr)
			return;

		auto RubberbandSpline = Cast<AAdultDragonFreeFlyingRubberBandSpline>(Component.Owner);
		if (RubberbandSpline == nullptr)
			return;

		const FSplinePosition SplinePosition = RubberbandSpline.Spline.GetClosestSplinePositionToLineSegment(EditorViewLocation, EditorViewLocation + EditorViewRotation.ForwardVector * 10000, false);

		FString Text = "Rubberband Spline";
		const auto Zone = RubberbandSpline.GetSyncPointAtDistanceAlongSpline(SplinePosition.CurrentSplineDistance);
		if (Zone == nullptr || Zone.RubberBandSettings == nullptr)
		{
			return;
		}

		FLinearColor AheadColor = Zone.GetVisualizeColor();
		FLinearColor BehindColor = Zone.GetVisualizeColor();

		Text += f"\n{Zone.GetVisualName()}";

		if (Zone.RubberBandSettings.PreferredAheadPlayer == EHazePlayer::Mio)
		{
			AheadColor = PlayerColor::Mio;
			BehindColor = PlayerColor::Zoe;
		}
		else if (Zone.RubberBandSettings.PreferredAheadPlayer == EHazePlayer::Zoe)
		{
			AheadColor = PlayerColor::Zoe;
			BehindColor = PlayerColor::Mio;
		}

		Text += f"\nPreferredAhead = {Zone.RubberBandSettings.PreferredAheadPlayer}";

		float BehindDistance = Zone.RubberBandSettings.IdealPlayerDistance;

		DrawWorldString(Text, SplinePosition.WorldLocation, FLinearColor::White, 1, 50000);

		DrawWireSphere(SplinePosition.WorldLocation, 1000, AheadColor, 5, 6, true);
		DrawWireSphere(SplinePosition.WorldLocation - SplinePosition.WorldForwardVector * BehindDistance, 1000, BehindColor, 5, 6, true);

		float TotalSplineLength = RubberbandSpline.Spline.SplineLength;
		float CurrentSplineLength = 0;
		while (CurrentSplineLength <= TotalSplineLength)
		{
			CurrentSplineLength += 10000;
			auto BoundarySplinePosition = RubberbandSpline.Spline.GetSplinePositionAtSplineDistance(CurrentSplineLength);
			FVector Location = BoundarySplinePosition.WorldLocation;
			float Radius = RubberbandSpline.GetBoundaryRadiusAtSplinePosition(BoundarySplinePosition);
			float KillRadius = RubberbandSpline.GetKillRadiusAtSplinePosition(BoundarySplinePosition);

			DrawCircle(Location, Radius, FLinearColor::Blue, 100, BoundarySplinePosition.WorldForwardVector, 6);
			DrawCircle(Location, KillRadius, FLinearColor::Red, 100, BoundarySplinePosition.WorldForwardVector, 6);
		}
	}
};

class UAdultDragonFreeFlyingRubberBandSplineContextMenuExtension : UHazeSplineContextMenuExtension
{
	bool IsValidForContextMenu(FHazeContextMenu& Menu, UHazeSplineComponent Spline,
							   UHazeSplineSelection Selection, int ClickedPoint, float ClickedDistance) const override
	{
		if (!Spline.Owner.IsA(AAdultDragonFreeFlyingRubberBandSpline))
			return false;

		return true;
	}

	FString GetSectionName() const override
	{
		return "Summit - AdultDragons";
	}

	void GenerateContextMenu(FHazeContextMenu& Menu, UHazeSplineComponent Spline, FHazeContextDelegate MenuDelegate, UHazeSplineSelection Selection, int ClickedPoint,
							 float ClickedDistance) override
	{
		if (ClickedDistance < 0.0)
			return;

		{
			FHazeContextOption AddRespawnZone;
			AddRespawnZone.DelegateParam = n"AddRubberbandSyncPoint";
			AddRespawnZone.Label = "Add Rubberband SyncPoint";
			AddRespawnZone.Icon = n"Icons.Plus";
			AddRespawnZone.Tooltip = "Add a point which will be used for rubberband distance checking";
			Menu.AddOption(AddRespawnZone, MenuDelegate);
		}
	}

	void HandleContextOptionClicked(FHazeContextOption Option, UHazeSplineComponent Spline,
									UHazeSplineSelection Selection, float MenuClickedDistance,
									int MenuClickedPoint) override
	{
		const FName OptionName = Option.DelegateParam;

		if (OptionName == n"AddRubberbandSyncPoint")
		{
			auto AddedZone = UAdultDragonSplineRubberBandSyncPointComponent::Create(Spline.Owner);
			FTransform Transform = Spline.GetWorldTransformAtSplineDistance(MenuClickedDistance);
			Transform.Scale3D = FVector::OneVector;
			AddedZone.SetWorldTransform(Transform);
			Editor::SelectComponent(AddedZone);
			Spline.Owner.Modify();
		}
	}
};
#endif