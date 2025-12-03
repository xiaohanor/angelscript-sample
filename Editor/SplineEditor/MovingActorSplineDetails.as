class UMovingActorSplineDetails : UHazeScriptDetailCustomization
{
	default DetailClass = UMovingActorSplineComponent;

	UHazeImmediateDrawer MainDrawer;

	UMovingActorSplineComponent MovingActorSplineComponent;
	UHazeSplineSelection Selection;
	int SelectedDataIndex = 0;

	UFUNCTION(BlueprintOverride)
	void CustomizeDetails()
	{
		FScopeIsRunningSplineEditorCode ScopeEditorCode;
		MovingActorSplineComponent = Cast<UMovingActorSplineComponent>(GetCustomizedObject());

		Selection = GetGlobalSplineSelection();

		if (MovingActorSplineComponent == nullptr)
			return;
		if (MovingActorSplineComponent.World == nullptr || MovingActorSplineComponent.World.IsPreviewWorld())
			return;

		EditCategory(n"Spline", CategoryType = EScriptDetailCategoryType::Important);
		MainDrawer = AddImmediateRow(n"Spline");
	}

	UFUNCTION(BlueprintOverride, meta = (NoSuperCall))
	void Tick(float DeltaTime)
	{
		FScopeIsRunningSplineEditorCode ScopeEditorCode;
		if (MovingActorSplineComponent == nullptr)
			return;
		if (!MovingActorSplineComponent.EditingSettings.bAllowEditing)
			return;

		SelectedDataIndex = MovingActorSplineComponent.EditorSelectedIndex;

		if (MainDrawer != nullptr && MainDrawer.IsVisible())
		{
			auto Root = MainDrawer.Begin();
			DrawMainContent(Root);
		}
	}

	void DrawMainContent(FHazeImmediateSectionHandle& Root)
	{

		if (Selection.Type == ESplineEditorSelection::Multiple)
		{
			Root.Text("Multiple Spline Points Selected");
			return;
		}

		if (MovingActorSplineComponent.SplinePoints.IsValidIndex(Selection.PointIndex))
		{
			FHazeSplinePoint& Point = MovingActorSplineComponent.SplinePoints[Selection.PointIndex];
			FSplinePointExtraData& ExtraData = MovingActorSplineComponent.SplineExtraData[Selection.PointIndex];

			auto Section = Root.Section(f"Extra Data {Selection.PointIndex}");

			// Extra Data input
			{
				float CurrentValue = ExtraData.SomeValue;
				auto ValueInput = Section.SlotPadding(2, 2, 26, 2).SlotHAlign(EHorizontalAlignment::HAlign_Fill).FloatInput();
				ValueInput.Label("Extra Data");
				ValueInput.Value(CurrentValue);

				if (ValueInput != CurrentValue)
					UpdatePointData(Selection.PointIndex, ValueInput);
			}

			ExtraData.Transform.Location = MovingActorSplineComponent.SplinePoints[Selection.PointIndex].RelativeLocation;
		}

		if (MovingActorSplineComponent.SplineExtraData.IsValidIndex(SelectedDataIndex))
		{
			Root.Text("Selected Rotation: " + SelectedDataIndex);

			auto Section = Root.Section(f"Rotation {SelectedDataIndex}");

			// Rotation input
			{
				FRotator CurRotation = MovingActorSplineComponent.SplineExtraData[SelectedDataIndex].Transform.Rotator();
				auto RotationInput = Section.SlotPadding(2, 2, 26, 2).SlotHAlign(EHorizontalAlignment::HAlign_Fill).RotatorInput();
				RotationInput.Label("Rotation");
				RotationInput.Value(CurRotation);

				if (RotationInput != CurRotation)
					UpdatePointRotation(SelectedDataIndex, RotationInput);
			}
		}
	}

	void UpdatePointData(int PointIndex, float Value)
	{
	//	FSplineDetailsTransaction Transaction(this, "Update Spline Point");

		FSplinePointExtraData& ExtraData = MovingActorSplineComponent.SplineExtraData[Selection.PointIndex];

		ExtraData.SomeValue = Value;
	}

	void UpdatePointRotation(int PointIndex, FRotator Rotation)
	{
	//	FSplineDetailsTransaction Transaction(this, "Rotate Spline Point");

		MovingActorSplineComponent.SplineExtraData[PointIndex].Transform.Rotation = Rotation.Quaternion();
	}
}