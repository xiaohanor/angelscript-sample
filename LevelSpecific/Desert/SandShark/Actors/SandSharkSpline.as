UCLASS(NotBlueprintable)
class ASandSharkSpline : ASplineActor
{
	default Spline.SplineSettings.bClosedLoop = true;

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedActorComp;

	UPROPERTY(DefaultComponent)
	UAlongSplineComponentManager AlongSplineComponentManager;

	UPROPERTY(EditAnywhere, Category = "GrappleFish")
	bool bIsGrappleFishSpline;

	UPROPERTY(EditAnywhere, Category = "GrappleFish", meta = (EditCondition = "bIsGrappleFishSpline"))
	float GrappleFishBounds = 3000;

	UPROPERTY(EditAnywhere, Category = "GrappleFish", meta = (EditCondition = "bIsGrappleFishSpline"))
	FLinearColor VisualizeColor = PlayerColor::Zoe;

	UPROPERTY(EditAnywhere, Category = "GrappleFish", meta = (EditCondition = "bIsGrappleFishSpline"))
	float VisualizeLineThickness = 5;

	UPROPERTY(EditAnywhere, Category = "GrappleFish", meta = (EditCondition = "bIsGrappleFishSpline", EditConditionHides))
	bool bVisualizeGrappleFishBounds = false;

	UPROPERTY(EditAnywhere, Category = "GrappleFish", meta = (EditCondition = "bIsGrappleFishSpline && bVisualizeGrappleFishBounds", EditConditionHides))
	float VisualizeDistanceInterval = 500;

	protected bool bInitialized = false;

#if EDITOR
	UPROPERTY(DefaultComponent)
	UEditorBillboardComponent EditorIcon;
	default EditorIcon.SpriteName = "Spawner";
	default EditorIcon.WorldScale3D = FVector(5);
#endif

	float GetGrappleFishBoundsAtSplinePosition(FSplinePosition SplinePosition) const
	{
		return GrappleFishBounds * SplinePosition.WorldScale3D.Y;
	}

#if EDITOR

	FSplinePosition GetClosestSplinePositionToSplinePoint(UHazeSplineComponent OnSpline, FHazeSplinePoint Point)
	{
		return OnSpline.GetClosestSplinePositionToWorldLocation(OnSpline.WorldTransform.TransformPosition(Point.RelativeLocation));
	}

	UFUNCTION(CallInEditor)
	void AddPointsBetweenPoints()
	{
		Editor::BeginTransaction("AddPoints");
		Spline.Modify();
		TArray<float> InsertionDistances;
		InsertionDistances.Reserve(Spline.SplinePoints.Num() * 2);
		for (int i = Spline.SplinePoints.Num() - 1; i >= 1; i--)
		{
			FSplinePosition PreviousPosition = GetClosestSplinePositionToSplinePoint(Spline, Spline.SplinePoints[i]);
			FSplinePosition NextPosition = GetClosestSplinePositionToSplinePoint(Spline, Spline.SplinePoints[i - 1]);
			float MidDist = (NextPosition.CurrentSplineDistance + PreviousPosition.CurrentSplineDistance) * 0.5;
			SplineEditing::InsertPointAtDistance(Spline, MidDist, true);
		}

		Spline.UpdateSpline();
		if (Spline.Owner != nullptr)
			Spline.Owner.RerunConstructionScripts();
		Editor::EndTransaction();
		Editor::RedrawAllViewports();
		Editor::NotifyPropertyModified(Spline, n"SplinePoints");
		// SplineEditing::InsertPointAtDistance()
	}
	
	UFUNCTION(BlueprintOverride)
	void OnActorModifiedInEditor()
	{
		MoveToLandscape();
		Spline.EditingSettings.SplineColor = VisualizeColor;
	}

	UFUNCTION(BlueprintOverride)
	void OnVisualizeInEditor() const
	{
		if (!bIsGrappleFishSpline)
			return;

		if (!bVisualizeGrappleFishBounds)
			return;

		FSplinePosition StartPosition = Spline.GetSplinePositionAtSplineDistance(0);
		float CurrentDistance = 0;

		FSplinePosition EndPosition;

		int CircleSegments = 8;
		float StartBounds = GetGrappleFishBoundsAtSplinePosition(StartPosition);
		Debug::DrawDebugCircle(StartPosition.WorldLocation, StartBounds, CircleSegments, VisualizeColor, VisualizeLineThickness, StartPosition.WorldRightVector, StartPosition.WorldUpVector);
		while (CurrentDistance < Spline.SplineLength)
		{
			EndPosition = Spline.GetSplinePositionAtSplineDistance(CurrentDistance + VisualizeDistanceInterval);
			float EndBounds = GetGrappleFishBoundsAtSplinePosition(EndPosition);
			Debug::DrawDebugCircle(EndPosition.WorldLocation, EndBounds, CircleSegments, VisualizeColor, VisualizeLineThickness, EndPosition.WorldRightVector, EndPosition.WorldUpVector);
			StartBounds = EndBounds;
			StartPosition = EndPosition;

			CurrentDistance += VisualizeDistanceInterval;
		}
	}
#endif

#if EDITOR
	UFUNCTION(CallInEditor, Category = "Sand Shark Spline")
	private void MoveToLandscape()
	{
		Modify();

		FVector LandscapeLocation = ActorLocation;
		LandscapeLocation.Z = Desert::GetLandscapeHeight(ActorLocation);
		SetActorLocation(LandscapeLocation);

		for (int i = 0; i < Spline.SplinePoints.Num(); i++)
		{
			FVector SplinePointRelativeLocation = Spline.SplinePoints[i].RelativeLocation;
			FVector SplinePointWorldLocation = Spline.WorldTransform.TransformPosition(SplinePointRelativeLocation);

			SplinePointWorldLocation.Z = Desert::GetLandscapeHeight(SplinePointWorldLocation);

			SplinePointRelativeLocation = Spline.WorldTransform.InverseTransformPosition(SplinePointWorldLocation);
			Spline.SplinePoints[i].RelativeLocation = SplinePointRelativeLocation;
		}

		Spline.UpdateSpline();
	}
#endif

	const UDesertGrappleFishPlayerRespawnBlockZoneComponent GetRespawnBlockZoneAtDistanceAlongSpline(float DistanceAlongSpline) const
	{
		TOptional<FAlongSplineComponentData> Previous;
		TOptional<FAlongSplineComponentData> Next;
		float _;
		auto FoundComponent = AlongSplineComponentManager.FindAdjacentComponentsAlongSpline(UDesertGrappleFishPlayerRespawnBlockZoneComponent, false, DistanceAlongSpline, Previous, Next, _);

		if (!FoundComponent)
			return nullptr;

		if (!Previous.IsSet())
		{
			if (!Next.IsSet())
				return nullptr;
			else
				return Cast<UDesertGrappleFishPlayerRespawnBlockZoneComponent>(Next.Value.Component);
		}
		else if (!Next.IsSet())
		{
			return Cast<UDesertGrappleFishPlayerRespawnBlockZoneComponent>(Previous.Value.Component);
		}

		auto NextZoneComp = Cast<UDesertGrappleFishPlayerRespawnBlockZoneComponent>(Next.Value.Component);
		auto PreviousZoneComp = Cast<UDesertGrappleFishPlayerRespawnBlockZoneComponent>(Previous.Value.Component);

		if (NextZoneComp.IsDistanceInsideZone(DistanceAlongSpline))
			return NextZoneComp;
		else if (PreviousZoneComp.IsDistanceInsideZone(DistanceAlongSpline))
			return PreviousZoneComp;
		else
			return nullptr;
	}
	
};
#if EDITOR
class USandSharkSplineContextMenuExtension : UHazeSplineContextMenuExtension
{
	const FName RespawnZoneOptionName = n"AddRespawnBlockZone";
	const FName CameraSettingsOptionName = n"AddCameraSettingsComp";
	bool IsValidForContextMenu(FHazeContextMenu& Menu, UHazeSplineComponent Spline,
							   UHazeSplineSelection Selection, int ClickedPoint, float ClickedDistance) const override
	{
		if (!Spline.Owner.IsA(ASandSharkSpline))
			return false;

		return true;
	}

	FString GetSectionName() const override
	{
		return "SandShark Spline";
	}

	void GenerateContextMenu(FHazeContextMenu& Menu, UHazeSplineComponent Spline, FHazeContextDelegate MenuDelegate, UHazeSplineSelection Selection, int ClickedPoint,
							 float ClickedDistance) override
	{
		if (ClickedDistance < 0.0)
			return;

		Menu.BeginSubMenu("Vortex");
		{
			FHazeContextOption AddRespawnBlockZone;
			AddRespawnBlockZone.DelegateParam = RespawnZoneOptionName;
			AddRespawnBlockZone.Label = "Add Player Respawn Block Zone";
			AddRespawnBlockZone.Icon = n"Icons.Plus";
			AddRespawnBlockZone.Tooltip = "From this zone and forward, apply these settings to respawning.";
			Menu.AddOption(AddRespawnBlockZone, MenuDelegate);

			FHazeContextOption AddCameraSettingsComp;
			AddCameraSettingsComp.DelegateParam = CameraSettingsOptionName;
			AddCameraSettingsComp.Label = "Add Camera Settings Component";
			AddCameraSettingsComp.Icon = n"Icons.Plus";
			AddCameraSettingsComp.Tooltip = "Camera settings that will be used by player when passing the components.";
			Menu.AddOption(AddCameraSettingsComp, MenuDelegate);
		}
		Menu.EndSubMenu();
	}

	void HandleContextOptionClicked(FHazeContextOption Option, UHazeSplineComponent Spline,
									UHazeSplineSelection Selection, float MenuClickedDistance,
									int MenuClickedPoint) override
	{
		const FName OptionName = Option.DelegateParam;
		if (OptionName == RespawnZoneOptionName)
		{
			auto AddedZone = UDesertGrappleFishPlayerRespawnBlockZoneComponent::Create(Spline.Owner);
			auto SplinePosition = Spline.GetSplinePositionAtSplineDistance(MenuClickedDistance);
			AddedZone.SetWorldTransform(SplinePosition.WorldTransform);
			Editor::SelectComponent(AddedZone);
			// AddedZone.SplinePosition = SplinePosition;
			Spline.Owner.Modify();
		}
		else if (OptionName == CameraSettingsOptionName)
		{
			auto AddedComp = UDesertGrappleFishSplineCameraSettingsComponent::Create(Spline.Owner);
			auto SplinePosition = Spline.GetSplinePositionAtSplineDistance(MenuClickedDistance);
			AddedComp.SetWorldTransform(SplinePosition.WorldTransform);
			Editor::SelectComponent(AddedComp);
			// AddedZone.SplinePosition = SplinePosition;
			Spline.Owner.Modify();
		}
	}
}
#endif
namespace SandShark
{
	namespace Spline
	{
		ASandSharkSpline GetClosestSpline(FVector Location)
		{
			TArray<ASandSharkSpline> Splines = TListedActors<ASandSharkSpline>().Array;

			if (Splines.IsEmpty())
				return nullptr;

			float ClosestDistanceSquared = BIG_NUMBER;
			int ClosestIndex = 0;
			for (int i = 0; i < Splines.Num(); i++)
			{
				FVector ClosestLocation = Splines[i].Spline.GetClosestSplineWorldLocationToWorldLocation(Location);
				float DistanceSquared = ClosestLocation.DistSquared(Location);
				if (DistanceSquared < ClosestDistanceSquared)
				{
					ClosestDistanceSquared = DistanceSquared;
					ClosestIndex = i;
				}
			}

			return Splines[ClosestIndex];
		}
	}
}