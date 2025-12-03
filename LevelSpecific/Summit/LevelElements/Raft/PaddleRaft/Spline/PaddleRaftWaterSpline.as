class APaddleRaftWaterSpline : ASplineActor
{
	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedActorComp;

#if EDITOR
	UPROPERTY(DefaultComponent)
	UPaddleRaftWaterSplineDummyComponent DummyComp;
#endif

	TArray<UPaddleRaftWaterSplineRaftSettingsComponent> RaftSettingsComponents;

	private uint LastFrameRefreshed;

	UPROPERTY(EditAnywhere)
	TArray<TSoftObjectPtr<APropLine>> WaterPropLines;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		RefreshRaftSettingsComponents();
	}

#if EDITOR
	UFUNCTION(BlueprintOverride)
	void OnActorModifiedInEditor()
	{
		RefreshRaftSettingsComponents();
	}

	UFUNCTION(BlueprintOverride)
	void OnVisualizeInEditor() const
	{
	}

	UFUNCTION(CallInEditor)
	void CreateSplineFromPropLines()
	{
		FScopedTransaction("Create Water Spline");
		Spline.Modify();
		Spline.SplinePoints.Empty();
		TArray<FHazeSplinePoint> NewPoints;
		for (auto PropLine : WaterPropLines)
		{
			if (!PropLine.IsValid())
			{
				devError(f"Assigned PropLine was not valid, exiting!");
				break;
			}

			bool bWasGameplaySpline = PropLine.Get().bGameplaySpline;
			if (!bWasGameplaySpline)
				PropLine.Get().bGameplaySpline = true;
			auto GameplaySpline = Spline::GetGameplaySpline(PropLine.Get());
			for (auto Point : Spline::GetGameplaySpline(PropLine.Get()).SplinePoints)
			{
				auto WorldPoint = Point;
				WorldPoint.RelativeLocation = Spline.WorldTransform.InverseTransformPosition(GameplaySpline.WorldTransform.TransformPosition(Point.RelativeLocation));
				WorldPoint.RelativeScale3D = Point.RelativeScale3D / GameplaySpline.WorldTransform.Scale3D.ComponentMax(FVector(0.001, 0.001, 0.001));
				WorldPoint.RelativeRotation = Spline.WorldTransform.InverseTransformRotation(GameplaySpline.WorldTransform.TransformRotation(Point.RelativeRotation));
				WorldPoint.ArriveTangent = Spline.WorldTransform.InverseTransformVector(GameplaySpline.WorldTransform.TransformVector(Point.ArriveTangent));
				WorldPoint.LeaveTangent = Spline.WorldTransform.InverseTransformVector(GameplaySpline.WorldTransform.TransformVector(Point.LeaveTangent));
				NewPoints.Add(WorldPoint);
			}
			if (!bWasGameplaySpline)
				PropLine.Get().bGameplaySpline = false;
		}

		int Pos;
		FHazeSplinePoint Point;
		for (int i = 1; i < NewPoints.Num(); i++)
		{
			Point = NewPoints[i];
			Pos = i - 1;

			while (Pos >= 0 && NewPoints[Pos].RelativeLocation.X > Point.RelativeLocation.X)
			{
				NewPoints[Pos + 1] = NewPoints[Pos];
				Pos = Pos - 1;
			}
			NewPoints[Pos + 1] = Point;
		}

		Spline.SplinePoints.Append(NewPoints);
	}
#endif

	UFUNCTION(CallInEditor, Category = "Setup")
	void RefreshRaftSettingsComponents()
	{
		if (LastFrameRefreshed == Time::FrameNumber)
			return;

		RaftSettingsComponents.Empty();
		GetComponentsByClass(UPaddleRaftWaterSplineRaftSettingsComponent, RaftSettingsComponents);

		for (auto Comp : RaftSettingsComponents)
		{
			Comp.SplinePos = Spline.GetClosestSplinePositionToWorldLocation(Comp.WorldLocation);
		}

		RaftSettingsComponents.Sort();
		LastFrameRefreshed = Time::FrameNumber;
	}

	UPaddleRaftSettings GetSettingsAtLength(float DistanceAlongSpline)
	{
		UPaddleRaftSettings Settings;

		if (RaftSettingsComponents.IsEmpty())
			return Settings;

		if (DistanceAlongSpline < RaftSettingsComponents[0].SplinePos.CurrentSplineDistance)
			return Settings;

		if (DistanceAlongSpline > RaftSettingsComponents.Last().SplinePos.CurrentSplineDistance)
			return RaftSettingsComponents.Last().Settings;

		for (int i = 0; i < RaftSettingsComponents.Num() - 1; i++)
		{
			if (RaftSettingsComponents[i].SplinePos.CurrentSplineDistance < DistanceAlongSpline && RaftSettingsComponents[i + 1].SplinePos.CurrentSplineDistance > DistanceAlongSpline)
				return RaftSettingsComponents[i].Settings;
		}

		return Settings;
	}
};
#if EDITOR
class UPaddleRaftWaterSplineCurrentContextMenuExtension : UHazeSplineContextMenuExtension
{
	bool IsValidForContextMenu(FHazeContextMenu& Menu, UHazeSplineComponent Spline,
							   UHazeSplineSelection Selection, int ClickedPoint, float ClickedDistance) const override
	{
		if (!Spline.Owner.IsA(APaddleRaftWaterSpline))
			return false;

		return true;
	}

	FString GetSectionName() const override
	{
		return "Raft Settings";
	}

	void GenerateContextMenu(FHazeContextMenu& Menu, UHazeSplineComponent Spline,
							 FHazeContextDelegate MenuDelegate, UHazeSplineSelection Selection,
							 int ClickedPoint, float ClickedDistance) override
	{
		if (ClickedDistance < 0.0)
			return;

		{
			FHazeContextOption AddWaterCurrent;
			AddWaterCurrent.DelegateParam = n"AddRaftSettingsComponent";
			AddWaterCurrent.Label = "Add Raft Settings Component";
			AddWaterCurrent.Icon = n"Icons.Plus";
			AddWaterCurrent.Tooltip = "From this component and forward, apply these settings to raft.";
			Menu.AddOption(AddWaterCurrent, MenuDelegate);
		}
	}

	void HandleContextOptionClicked(FHazeContextOption Option, UHazeSplineComponent Spline,
									UHazeSplineSelection Selection, float MenuClickedDistance,
									int MenuClickedPoint) override
	{
		const FName OptionName = Option.DelegateParam;

		if (OptionName == n"AddRaftSettingsComponent")
		{
			auto AddedComp = UPaddleRaftWaterSplineRaftSettingsComponent::Create(Spline.Owner);
			FTransform Transform = Spline.GetWorldTransformAtSplineDistance(MenuClickedDistance);
			Transform.Scale3D = FVector::OneVector;
			AddedComp.SetWorldTransform(Transform);
			Editor::SelectComponent(AddedComp);
			Spline.Owner.Modify();
		}
	}
}
#endif

#if EDITOR
class UPaddleRaftWaterSplineDummyComponent : UActorComponent
{};
class UPaddleRaftWaterSplineComponentVisualizer : UHazeScriptComponentVisualizer
{
	default VisualizedClass = UPaddleRaftWaterSplineDummyComponent;

	UFUNCTION(BlueprintOverride)
	void VisualizeComponent(const UActorComponent Component)
	{
		auto Comp = Cast<UPaddleRaftWaterSplineDummyComponent>(Component);
		if (Comp == nullptr)
			return;

		auto Spline = Cast<APaddleRaftWaterSpline>(Comp.Owner);
		if (Spline == nullptr)
			return;

		Spline.RefreshRaftSettingsComponents();
		VisualizeRaftSettingsComponents(Spline);
	}

	void VisualizeRaftSettingsComponents(APaddleRaftWaterSpline Spline)
	{
		for (auto SettingsComp : Spline.RaftSettingsComponents)
		{
			DrawWireSphere(SettingsComp.SplinePos.WorldLocation, 40, FLinearColor::Blue, 40, 2);
			DrawWorldString(f"{SettingsComp.Name}", SettingsComp.SplinePos.WorldLocation, FLinearColor::LucBlue);

			FVector Extent = FVector(5, 2000, 5);
			DrawWireBox(SettingsComp.SplinePos.WorldLocation, Extent, SettingsComp.SplinePos.WorldRotation, FLinearColor::Blue, 10);
		}
	}
}
#endif