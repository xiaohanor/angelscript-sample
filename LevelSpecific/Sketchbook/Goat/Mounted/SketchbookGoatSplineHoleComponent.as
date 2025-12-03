class USketchbookGoatSplineHoleComponent : UAlongSplineComponent
{
	UPROPERTY(EditInstanceOnly)
	float HoleSize = 500;
};

#if EDITOR
class USketchbookGoatSplineHoleVisualizer : UAlongSplineComponentVisualizer
{
	default VisualizedClass = USketchbookGoatSplineHoleComponent;

	UFUNCTION(BlueprintOverride, Meta = (NoSuperCall))
	void VisualizeComponent(const UActorComponent Component)
	{
		auto HoleComp = Cast<USketchbookGoatSplineHoleComponent>(Component);
		if(HoleComp == nullptr)
			return;

		Super::VisualizeComponent(Component);
	}

	void DrawSelectedShape(UAlongSplineComponent AlongSplineComp, FLinearColor SelectedColor) const override
	{
		auto HoleComp = Cast<USketchbookGoatSplineHoleComponent>(AlongSplineComp);
		if(HoleComp == nullptr)
			return;

		auto Spline = Cast<ASketchbookGoatSpline>(HoleComp.Owner);
		if(Spline == nullptr)
			return;

		float StartDistance = Spline.Spline.GetClosestSplineDistanceToWorldLocation(HoleComp.WorldLocation);
		FTransform StartTransform = Spline.Spline.GetWorldTransformAtSplineDistance(StartDistance);
		DrawWireBox(StartTransform.Location, FVector(0, 25, 25), StartTransform.Rotation, FLinearColor::Green, 10, true);

		float HoleDistance = 0;
		while(HoleDistance < HoleComp.HoleSize)
		{
			FVector PreviousLocation = Spline.Spline.GetWorldLocationAtSplineDistance(StartDistance + HoleDistance);
			HoleDistance += Math::Min(50, HoleComp.HoleSize - HoleDistance);
			FVector NexLocation = Spline.Spline.GetWorldLocationAtSplineDistance(StartDistance + HoleDistance);
			DrawLine(PreviousLocation, NexLocation, FLinearColor::Yellow, 20, true);
		}

		FTransform EndTransform = Spline.Spline.GetWorldTransformAtSplineDistance(StartDistance + HoleComp.HoleSize);
		DrawWireBox(EndTransform.Location, FVector(0, 25, 25), EndTransform.Rotation, FLinearColor::Red, 10, true);
	}

	void DrawDeselectedShape(UAlongSplineComponent AlongSplineComp, FLinearColor DeselectedColor) const override
	{
		auto HoleComp = Cast<USketchbookGoatSplineHoleComponent>(AlongSplineComp);
		if(HoleComp == nullptr)
			return;

		auto Spline = Cast<ASketchbookGoatSpline>(HoleComp.Owner);
		if(Spline == nullptr)
			return;

		float StartDistance = Spline.Spline.GetClosestSplineDistanceToWorldLocation(HoleComp.WorldLocation);
		FTransform StartTransform = Spline.Spline.GetWorldTransformAtSplineDistance(StartDistance);
		DrawWireBox(StartTransform.Location, FVector(0, 25, 25), StartTransform.Rotation, DeselectedColor, 10, true);

		float HoleDistance = 0;
		while(HoleDistance < HoleComp.HoleSize)
		{
			FVector PreviousLocation = Spline.Spline.GetWorldLocationAtSplineDistance(StartDistance + HoleDistance);
			HoleDistance += Math::Min(50, HoleComp.HoleSize - HoleDistance);
			FVector NexLocation = Spline.Spline.GetWorldLocationAtSplineDistance(StartDistance + HoleDistance);
			DrawLine(PreviousLocation, NexLocation, FLinearColor::Yellow, 20, true);
		}

		FTransform EndTransform = Spline.Spline.GetWorldTransformAtSplineDistance(StartDistance + HoleComp.HoleSize);
		DrawWireBox(EndTransform.Location, FVector(0, 25, 25), EndTransform.Rotation, DeselectedColor, 10, true);
	}
};
#endif

#if EDITOR
class USketchbookGoatSplineHoleContextMenuExtension : UHazeSplineContextMenuExtension
{
	bool IsValidForContextMenu(FHazeContextMenu& Menu, UHazeSplineComponent Spline,
							   UHazeSplineSelection Selection, int ClickedPoint, float ClickedDistance) const override
	{
		if(!Spline.Owner.IsA(ASketchbookGoatSpline))
			return false;

		return true;
	}

	FString GetSectionName() const override
	{
		return "Goat Spline Hole";
	}

	void GenerateContextMenu(FHazeContextMenu& Menu, UHazeSplineComponent Spline, FHazeContextDelegate MenuDelegate, UHazeSplineSelection Selection, int ClickedPoint,
							 float ClickedDistance) override
	{
		if (ClickedDistance < 0.0)
			return;
		
		{
			FHazeContextOption OverrideWaterHeight;
			OverrideWaterHeight.DelegateParam = n"Hole";
			OverrideWaterHeight.Label = "Add Hole";
			OverrideWaterHeight.Icon = n"Icons.Plus";
			Menu.AddOption(OverrideWaterHeight, MenuDelegate);
		}
	}

	void HandleContextOptionClicked(FHazeContextOption Option, UHazeSplineComponent Spline,
	                                UHazeSplineSelection Selection, float MenuClickedDistance,
	                                int MenuClickedPoint) override
	{
		const FName OptionName = Option.DelegateParam;

		if (OptionName == n"Hole")
		{
			Editor::BeginTransaction("Hole", Spline);

			Spline.Owner.Modify();
			auto OverrideComp = Editor::AddInstanceComponentInEditor(Spline.Owner, USketchbookGoatSplineHoleComponent, NAME_None);
			FTransform Transform = Spline.GetWorldTransformAtSplineDistance(MenuClickedDistance);
			Transform.Scale3D = FVector::OneVector;
			OverrideComp.SetWorldTransform(Transform);
			Editor::SelectComponent(OverrideComp);

			Editor::EndTransaction();
		}
	}
};
#endif