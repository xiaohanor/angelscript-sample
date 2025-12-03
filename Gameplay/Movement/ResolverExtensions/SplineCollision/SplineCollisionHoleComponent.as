// class URemoteHackableRaftBoundarySplineHoleComponent : UAlongSplineComponent
// {
// 	UPROPERTY(EditInstanceOnly)
// 	float HoleSize = 500;
// };

// #if EDITOR
// class URemoteHackableRaftBoundarySplineHoleComponentVisualizer : UAlongSplineComponentVisualizer
// {
// 	default VisualizedClass = URemoteHackableRaftBoundarySplineHoleComponent;

// 	const URemoteHackableRaftBoundarySplineHoleComponent HoleComp;

// 	UFUNCTION(BlueprintOverride, Meta = (NoSuperCall))
// 	void VisualizeComponent(const UActorComponent Component)
// 	{
// 		HoleComp = Cast<URemoteHackableRaftBoundarySplineHoleComponent>(Component);
// 		if(HoleComp == nullptr)
// 			return;

// 		if(GetSpline() == nullptr)
// 			return;

// 		Super::VisualizeComponent(Component);
// 	}

// 	void DrawSelectedShape() override
// 	{
// 		float StartDistance = GetSpline().Spline.GetClosestSplineDistanceToWorldLocation(HoleComp.WorldLocation);
// 		FTransform StartTransform = GetSpline().Spline.GetWorldTransformAtSplineDistance(StartDistance);
// 		DrawWireBox(StartTransform.Location, FVector(0, 25, 25), StartTransform.Rotation, FLinearColor::Green, 10, true);

// 		FSplinePosition HolePosition = FSplinePosition(GetSpline().Spline, StartDistance, true);
// 		float DistanceToAdd = HoleComp.HoleSize;
// 		while(DistanceToAdd > 0)
// 		{
// 			FVector PreviousLocation = HolePosition.WorldLocation;

// 			float DeltaToMove = Math::Min(50, DistanceToAdd);
// 			HolePosition.Move(DeltaToMove);
// 			DistanceToAdd -= DeltaToMove;

// 			FVector NextLocation = HolePosition.WorldLocation;

// 			DrawLine(PreviousLocation, NextLocation, FLinearColor::Yellow, 20, true);
// 		}

// 		FTransform EndTransform = HolePosition.WorldTransform;
// 		DrawWireBox(EndTransform.Location, FVector(0, 25, 25), EndTransform.Rotation, FLinearColor::Red, 10, true);
// 	}

// 	void DrawDeselectedShape() override
// 	{
// 		float StartDistance = GetSpline().Spline.GetClosestSplineDistanceToWorldLocation(HoleComp.WorldLocation);
// 		FTransform StartTransform = GetSpline().Spline.GetWorldTransformAtSplineDistance(StartDistance);
// 		DrawWireBox(StartTransform.Location, FVector(0, 25, 25), StartTransform.Rotation, FLinearColor::White, 10, true);

// 		FSplinePosition HolePosition = FSplinePosition(GetSpline().Spline, StartDistance, true);
// 		float DistanceToAdd = HoleComp.HoleSize;
// 		while(DistanceToAdd > 0)
// 		{
// 			FVector PreviousLocation = HolePosition.WorldLocation;

// 			float DeltaToMove = Math::Min(50, DistanceToAdd);
// 			HolePosition.Move(DeltaToMove);
// 			DistanceToAdd -= DeltaToMove;

// 			FVector NextLocation = HolePosition.WorldLocation;

// 			DrawLine(PreviousLocation, NextLocation, FLinearColor::Yellow, 20, true);
// 		}

// 		FTransform EndTransform = HolePosition.WorldTransform;
// 		DrawWireBox(EndTransform.Location, FVector(0, 25, 25), EndTransform.Rotation, FLinearColor::White, 10, true);
// 	}

// 	ARemoteHackableRaftBoundarySpline GetSpline() const
// 	{
// 		return Cast<ARemoteHackableRaftBoundarySpline>(HoleComp.Owner);
// 	}
// };
// #endif

// #if EDITOR
// class URemoteHackableRaftBoundarySplineHoleComponentContextMenuExtension : UHazeSplineContextMenuExtension
// {
// 	bool IsValidForContextMenu(FHazeContextMenu& Menu, UHazeSplineComponent Spline,
// 							   UHazeSplineSelection Selection, int ClickedPoint, float ClickedDistance) const override
// 	{
// 		if(!Spline.Owner.IsA(ARemoteHackableRaftBoundarySpline))
// 			return false;

// 		return true;
// 	}

// 	FString GetSectionName() const override
// 	{
// 		return "Raft Boundary Spline";
// 	}

// 	void GenerateContextMenu(FHazeContextMenu& Menu, UHazeSplineComponent Spline, FHazeContextDelegate MenuDelegate, UHazeSplineSelection Selection, int ClickedPoint,
// 							 float ClickedDistance) override
// 	{
// 		if (ClickedDistance < 0.0)
// 			return;
		
// 		{
// 			FHazeContextOption OverrideWaterHeight;
// 			OverrideWaterHeight.DelegateParam = n"Hole";
// 			OverrideWaterHeight.Label = "Add Hole";
// 			OverrideWaterHeight.Icon = n"Icons.Plus";
// 			Menu.AddOption(OverrideWaterHeight, MenuDelegate);
// 		}
// 	}

// 	void HandleContextOptionClicked(FHazeContextOption Option, UHazeSplineComponent Spline,
// 	                                UHazeSplineSelection Selection, float MenuClickedDistance,
// 	                                int MenuClickedPoint) override
// 	{
// 		const FName OptionName = Option.DelegateParam;

// 		if (OptionName == n"Hole")
// 		{
// 			Editor::BeginTransaction("Hole", Spline);

// 			Spline.Owner.Modify();
// 			auto OverrideComp = Editor::AddInstanceComponentInEditor(Spline.Owner, URemoteHackableRaftBoundarySplineHoleComponent, NAME_None);
// 			FTransform Transform = Spline.GetWorldTransformAtSplineDistance(MenuClickedDistance);
// 			Transform.Scale3D = FVector::OneVector;
// 			OverrideComp.SetWorldTransform(Transform);
// 			Editor::SelectComponent(OverrideComp);

// 			Editor::EndTransaction();
// 		}
// 	}
// };
// #endif