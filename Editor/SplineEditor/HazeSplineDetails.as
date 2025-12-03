#if EDITOR
enum ESplineBuilderMode
{
	None,
	BuildCircle,
	BuildSpiral,
};

class UHazeSplineDetails : UHazeScriptDetailCustomization
{
	default DetailClass = UHazeSplineComponent;

	UHazeImmediateDrawer MainDrawer;

	UHazeSplineComponent Spline;
	UHazeSplineSelection Selection;

	ESplineBuilderMode BuilderMode;

	UFUNCTION(BlueprintOverride)
	void CustomizeDetails()
	{
		FScopeIsRunningSplineEditorCode ScopeEditorCode;
		Selection = GetGlobalSplineSelection();
		Spline = Cast<UHazeSplineComponent>(GetCustomizedObject());
		if (Spline == nullptr)
			return;
		if (Spline.World == nullptr || Spline.World.IsPreviewWorld())
			return;

		EditCategory(n"Spline", CategoryType = EScriptDetailCategoryType::Important);
		MainDrawer = AddImmediateRow(n"Spline");
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		FScopeIsRunningSplineEditorCode ScopeEditorCode;
		if (Spline == nullptr)
			return;
		if (!Spline.EditingSettings.bAllowEditing)
			return;

		if (MainDrawer != nullptr && MainDrawer.IsVisible())
		{
			auto Root = MainDrawer.Begin();
			DrawSelectionButtons(Root);
			DrawSplinePointDetails(Root);
			DrawSplineBuilder(Root);

			auto ToolButtons = Root.Section().HorizontalBox();
			auto DrawButton = ToolButtons
				.SlotHAlign(EHorizontalAlignment::HAlign_Center)
				.SlotFill()
				.Button("✏️ Draw Spline Tool")
					.Padding(20, 8)
					.Tooltip("Open the Draw Spline editor tool to draw the spline onto the surrounding geometry.")
			;
			if (DrawButton.WasClicked())
				OpenDrawTool();
		}
	}

	void DrawSelectionButtons(FHazeImmediateSectionHandle& Root)
	{
		// Selection buttons
		auto Buttons = Root.Section(f"Select Spline Point");
		{
			auto Box = Buttons.HorizontalBox();
			if (Box.Button("< Previous"))
				SelectPrevious();
			if (Box.Button("Menu"))
				OpenContextMenu();
			if (Box.Button("Next >"))
				SelectNext();
		}

		{
			auto Box = Buttons.HorizontalBox();
			if (Box.Button("First"))
				SelectFirst();
			if (Box.Button("All"))
				SelectAll();
			if (Box.Button("Last"))
				SelectLast();
		}
	}

	void OpenDrawTool()
	{
		GetGlobalSplineSelection().bSplineDrawWasTemporary = true;
		Blutility::ActivateEditorTool(UHazeSplineDrawTool);
	}

	void OpenContextMenu()
	{
		FHazeContextMenu Menu;

		auto ContextMenu = SplineContextMenu::GetSingleton();
		ContextMenu.GenerateContextMenu(Menu, Spline, Selection, Selection.GetMinSelectedPoint());

		Menu.ShowContextMenu();
	}

	void DrawSplinePointDetails(FHazeImmediateSectionHandle& Root)
	{
		if (Selection.Type == ESplineEditorSelection::Multiple)
		{
			// Only allow setting scale if we have a valid first point
			if(Selection.MultiplePoints.Num() > 1 && Spline.SplinePoints.IsValidIndex(Selection.MultiplePoints[0]))
			{
				auto Section = Root.Section(f"Scale Multiple Spline Points ({Selection.MultiplePoints.Num()}/{Spline.SplinePoints.Num()})");

				// Multiple Scale input
				{
					const FHazeSplinePoint& FirstPoint = Spline.SplinePoints[Selection.MultiplePoints[0]];
					FVector PreviousValue = FirstPoint.RelativeScale3D;

					// If any points have different scale to the first selected point, set that component to -1
					for(int i = 1; i < Selection.MultiplePoints.Num(); i++)
					{
						if(!Spline.SplinePoints.IsValidIndex(i))
							continue;
						
						PreviousValue.X = (PreviousValue.X == Spline.SplinePoints[i].RelativeScale3D.X) ? PreviousValue.X : -1;
						PreviousValue.Y = (PreviousValue.Y == Spline.SplinePoints[i].RelativeScale3D.Y) ? PreviousValue.Y : -1;
						PreviousValue.Z = (PreviousValue.Z == Spline.SplinePoints[i].RelativeScale3D.Z) ? PreviousValue.Z : -1;
					}

					if(PreviousValue != FirstPoint.RelativeScale3D)
						Section.Text("Note: Some values are not identical between all\nselected points and will be displayed as '-1'.");

					auto ScaleInput = Section.SlotPadding(2, 2, 26, 2).SlotHAlign(EHorizontalAlignment::HAlign_Fill).VectorInput();
					ScaleInput.Label("Multi Scale");
					ScaleInput.Value(PreviousValue);

					if (ScaleInput != PreviousValue)
					{
						// Apply the scale to all selected
						for(auto& PointIndex : Selection.MultiplePoints)
						{
							if(!Spline.SplinePoints.IsValidIndex(PointIndex))
								continue;

							UpdatePointScale(PointIndex, ScaleInput);
						}
					}
				}
			}
			else
			{
				Root.Section().Text("Multiple Spline Points Selected");
			}

			return;
		}

		if (!Spline.SplinePoints.IsValidIndex(Selection.PointIndex))
		{
			Root.Section().Text("No Spline Point Selected");
			return;
		}

		FHazeSplinePoint& Point = Spline.SplinePoints[Selection.PointIndex];
		auto Section = Root.Section(f"Spline Point {Selection.PointIndex}");
		// Location input
		{
			auto LocationBox = Section.HorizontalBox();
			auto LocationInput = LocationBox.SlotPadding(0).SlotFill().VectorInput();

			auto SpaceImage = LocationBox.SlotVAlign(EVerticalAlignment::VAlign_Center).BorderBox();
			SpaceImage.WidthOverride(20).HeightOverride(20);
			SpaceImage.Tooltip("Cycle the editable location between component space and world space");

			FLinearColor Tint = FLinearColor(0.3, 0.3, 0.3);
			if (SpaceImage.IsHovered())
				Tint = FLinearColor(0.0, 1.0, 0.5);

			if (Selection.bDetailsWorldLocation)
			{
				SpaceImage.BackgroundStyle("EditorViewport.RelativeCoordinateSystem_World", Tint);

				FVector WorldLocation = Spline.WorldTransform.TransformPosition(Point.RelativeLocation);
				LocationInput.Label("World Location");
				LocationInput.Value(WorldLocation);
				if (LocationInput != WorldLocation)
				{
					UpdatePointLocation(Selection.PointIndex,
						Spline.WorldTransform.InverseTransformPosition(LocationInput)
					);
				}
			}
			else
			{
				SpaceImage.BackgroundStyle("Icons.Transform", Tint);

				LocationInput.Label("Location");
				LocationInput.Value(Point.RelativeLocation);
				if (LocationInput != Point.RelativeLocation)
					UpdatePointLocation(Selection.PointIndex, LocationInput);
			}


			if (SpaceImage.WasClicked())
				Selection.bDetailsWorldLocation = !Selection.bDetailsWorldLocation;
		}

		// Scale input
		{
			auto ScaleInput = Section.SlotPadding(2, 2, 26, 2).SlotHAlign(EHorizontalAlignment::HAlign_Fill).VectorInput();
			ScaleInput.Label("Scale");
			ScaleInput.Value(Point.RelativeScale3D.Abs);

			if (ScaleInput != Point.RelativeScale3D)
				UpdatePointScale(Selection.PointIndex, ScaleInput);
		}

		// Rotation input
		{
			FRotator CurRotation = Point.RelativeRotation.Rotator();
			auto RotationInput = Section.SlotPadding(2, 2, 26, 2).SlotHAlign(EHorizontalAlignment::HAlign_Fill).RotatorInput();
			RotationInput.Label("Rotation");
			RotationInput.Value(CurRotation);

			if (RotationInput != CurRotation)
				UpdatePointRotation(Selection.PointIndex, RotationInput);
		}

		// Tangent bools
		{
			auto Box = Section.HorizontalBox();

			bool bOverrideTangents = Box.SlotPadding(10, 1, 1, 1).CheckBox()
				.Checked(Point.bOverrideTangent)
				.Label("Override Tangents")
				.Tooltip("Specify overridden tangents for this point instead of relying on the automatic ones.");

			// Update state of override tangents
			if (Point.bOverrideTangent != bOverrideTangents)
			{
				UpdatePointOverrideTangents(Selection.PointIndex, bOverrideTangents);
			}

			if (bOverrideTangents)
			{
				bool bDiscontinuousTangents = Box.SlotPadding(10, 1, 1, 1).CheckBox()
					.Checked(Point.bDiscontinuousTangent)
					.Label("Discontinuous Tangents")
					.Tooltip("Allow the arrive and leave tangents to be set to different values.");

				if (bDiscontinuousTangents != Point.bDiscontinuousTangent)
				{
					UpdatePointDiscontinuousTangents(Selection.PointIndex, bDiscontinuousTangents);
				}
			}
		}

		if (Point.bOverrideTangent)
		{
			// Arrive tangent
			auto ArriveInput = Section.SlotHAlign(EHorizontalAlignment::HAlign_Fill).VectorInput();
			ArriveInput.Label(Point.bDiscontinuousTangent ? "Arrive Tangent" : "Tangent");
			ArriveInput.Value(Point.ArriveTangent);

			if (ArriveInput != Point.ArriveTangent)
			{
				UpdateArriveTangent(Selection.PointIndex, ArriveInput);
			}

			if (Point.bDiscontinuousTangent)
			{
				// Leave tangent
				auto LeaveInput = Section.SlotHAlign(EHorizontalAlignment::HAlign_Fill).VectorInput();
				LeaveInput.Label("Leave Tangent");
				LeaveInput.Value(Point.LeaveTangent);

				if (LeaveInput != Point.LeaveTangent)
				{
					UpdateLeaveTangent(Selection.PointIndex, LeaveInput);
				}
			}
		}
	}

	void DrawSplineBuilder(FHazeImmediateSectionHandle& Root)
	{
		auto Section = Root.Section("Spline Builder");
		auto ButtonBox = Section.HorizontalBox();

		SplineBuilderButton(ButtonBox, ESplineBuilderMode::BuildCircle, "Circle");
		SplineBuilderButton(ButtonBox, ESplineBuilderMode::BuildSpiral, "Spiral");

		if (BuilderMode == ESplineBuilderMode::BuildCircle)
		{
			auto RadiusInput = Section.FloatInput();
			RadiusInput.Label("Radius");
			RadiusInput.MinMax(1.0, 5000.0);
			RadiusInput.Delta(100.0);
			Spline.BuilderState.Circle.Radius = RadiusInput.Value(Spline.BuilderState.Circle.Radius);

			auto PointCountInput = Section.FloatInput();
			PointCountInput.Label("Points");
			PointCountInput.MinMax(3.0, 100.0);
			PointCountInput.Delta(1.0);
			Spline.BuilderState.Circle.PointCount = Math::FloorToInt(PointCountInput.Value(Spline.BuilderState.Circle.PointCount));

			auto ArcDegreesInput = Section.FloatInput();
			ArcDegreesInput.Label("Arc (Degrees)");
			ArcDegreesInput.MinMax(-360.0, 360.0);
			ArcDegreesInput.Delta(1.0);
			Spline.BuilderState.Circle.ArcDegrees = ArcDegreesInput.Value(Spline.BuilderState.Circle.ArcDegrees);

			auto BuildButtonBox = Section.HorizontalBox();
			if (BuildButtonBox.Button("Insert Circle"))
				BuildCircle(Spline.BuilderState.Circle, false);
			if (BuildButtonBox.Button("Replace Spline with Circle"))
				BuildCircle(Spline.BuilderState.Circle, true);
		}
		else if (BuilderMode == ESplineBuilderMode::BuildSpiral)
		{
			auto OuterRadiusInput = Section.FloatInput();
			OuterRadiusInput.Label("Outer Radius");
			OuterRadiusInput.MinMax(1.0, 5000.0);
			OuterRadiusInput.Delta(100.0);
			Spline.BuilderState.Spiral.OuterRadius = OuterRadiusInput.Value(Spline.BuilderState.Spiral.OuterRadius);

			auto InnerRadiusInput = Section.FloatInput();
			InnerRadiusInput.Label("Inner Radius");
			InnerRadiusInput.MinMax(1.0, 5000.0);
			InnerRadiusInput.Delta(100.0);
			Spline.BuilderState.Spiral.InnerRadius = InnerRadiusInput.Value(Spline.BuilderState.Spiral.InnerRadius);

			auto PointCountInput = Section.FloatInput();
			PointCountInput.Label("Points");
			PointCountInput.MinMax(3.0, 100.0);
			PointCountInput.Delta(1.0);
			Spline.BuilderState.Spiral.PointCount = Math::FloorToInt(PointCountInput.Value(Spline.BuilderState.Spiral.PointCount));

			auto ArcDegreesInput = Section.FloatInput();
			ArcDegreesInput.Label("Arc (Degrees)");
			ArcDegreesInput.MinMax(-720.0, 720.0);
			ArcDegreesInput.Delta(1.0);
			Spline.BuilderState.Spiral.ArcDegrees = ArcDegreesInput.Value(Spline.BuilderState.Spiral.ArcDegrees);

			auto HeightInput = Section.FloatInput();
			HeightInput.Label("Height");
			HeightInput.MinMax(-1000.0, 1000.0);
			HeightInput.Delta(1.0);
			Spline.BuilderState.Spiral.Height = HeightInput.Value(Spline.BuilderState.Spiral.Height);

			auto BuildButtonBox = Section.HorizontalBox();
			if (BuildButtonBox.Button("Replace Spline with Spiral"))
				BuildSpiral(Spline.BuilderState.Spiral);
		}
	}

	void SplineBuilderButton(FHazeImmediateHorizontalBoxHandle& ButtonBox, ESplineBuilderMode Mode, FString Text)
	{
		auto Button = ButtonBox.Button(Text);
		if (Button)
		{
			if (BuilderMode == Mode)
				BuilderMode = ESplineBuilderMode::None;
			else
				BuilderMode = Mode;
		}

		if (BuilderMode == Mode)
			Button.BackgroundColor(FLinearColor(0.1, 0.3, 0.1));
	}

	void BuildCircle(FHazeSplineBuilderCircle Builder, bool bReplaceSpline)
	{
		TArray<FHazeSplinePoint> Points;

		float Angle = 0.0;
		float AngleIncrement = Math::DegreesToRadians(Builder.ArcDegrees) / Builder.PointCount;

		FVector Origin;
		FQuat CircleRotation;

		if (!bReplaceSpline)
		{
			int PointIndex = Selection.GetLatestPointIndex();
			if (Spline.SplinePoints.IsValidIndex(PointIndex))
			{
				const FHazeSplinePoint& FromPoint = Spline.SplinePoints[PointIndex];
				const FHazeComputedSplinePoint& ComputedPoint = Spline.ComputedSpline.Points[PointIndex];

				CircleRotation = FQuat::MakeFromX(ComputedPoint.LeaveTangent.GetSafeNormal2D());

				Origin = FromPoint.RelativeLocation;
				Angle = 0.0;

				if (Builder.ArcDegrees > 0.0)
				{
					Origin += CircleRotation.RightVector * Builder.Radius;
					Angle = PI;
				}
				else
				{
					Origin -= CircleRotation.RightVector * Builder.Radius;
				}

				AngleIncrement *= -1.0;
				Angle += AngleIncrement;
			}
		}

		for (int i = 0; i < Builder.PointCount; ++i)
		{
			FHazeSplinePoint Point;
			Point.RelativeLocation = Origin;

			FVector RelativePos = FVector(
					Math::Sin(Angle) * Builder.Radius,
					Math::Cos(Angle) * Builder.Radius,
					0.0
				);
			Point.RelativeLocation += CircleRotation.RotateVector(RelativePos);

			/*float TangentLength = (4.0/3.0) * Math::Tan(AngleIncrement /4.0) * Builder.Radius;
			FVector TangentDir = RelativePos.CrossProduct(FVector::UpVector).GetSafeNormal();

			Point.ArriveTangent = CircleRotation.RotateVector(TangentDir * TangentLength);
			Point.LeaveTangent = Point.ArriveTangent;
			Point.bOverrideTangent = true;*/

			Points.Add(Point);

			Angle += AngleIncrement;
		}

		FSplineDetailsTransaction Transaction(this, "Build Spline Circle");
		int LastInsertedPoint = InsertBuiltPoints(Points, bReplaceSpline);

		if (bReplaceSpline)
		{
			if (Math::Abs(Builder.ArcDegrees) > 355.0)
				Spline.SplineSettings.bClosedLoop = true;
			else
				Spline.SplineSettings.bClosedLoop = false;
		}

		Selection.Modify();
		Selection.SelectPoint(LastInsertedPoint);
	}

	void BuildSpiral(FHazeSplineBuilderSpiral Builder)
	{
		TArray<FHazeSplinePoint> Points;

		float Angle = 0.0;
		float AngleIncrement = -(Math::DegreesToRadians(Builder.ArcDegrees) / Builder.PointCount);

		float Height = 0.0;
		float HeightIncrement = Builder.Height / (Builder.PointCount - 1);
		
		FVector Origin;
		FQuat CircleRotation;

		for (int i = 0; i < Builder.PointCount; ++i)
		{
			const float Alpha = i / float(Builder.PointCount);
			const float Radius = Math::Lerp(Builder.InnerRadius, Builder.OuterRadius, Alpha);

			FHazeSplinePoint Point;
			Point.RelativeLocation = Origin;

			FVector RelativePos = FVector(
					Math::Sin(Angle) * Radius,
					Math::Cos(Angle) * Radius,
					Height
				);
			Point.RelativeLocation += CircleRotation.RotateVector(RelativePos);

			Points.Add(Point);

			Angle += AngleIncrement;
			Height += HeightIncrement;
		}

		FSplineDetailsTransaction Transaction(this, "Build Spline Spiral");
		int LastInsertedPoint = InsertBuiltPoints(Points, true);

		Spline.SplineSettings.bClosedLoop = false;

		Selection.Modify();
		Selection.SelectPoint(LastInsertedPoint);
	}

	int InsertBuiltPoints(TArray<FHazeSplinePoint> Points, bool bReplaceSpline)
	{
		if (bReplaceSpline)
		{
			Spline.SplinePoints = Points;
			return Points.Num() - 1;
		}

		int InsertAfterPoint = Selection.GetLatestPointIndex();
		if (!Spline.SplinePoints.IsValidIndex(InsertAfterPoint))
			InsertAfterPoint = 0;

		for (int i = 0, Count = Points.Num(); i < Count; ++i)
			Spline.SplinePoints.Insert(Points[i], InsertAfterPoint+i+1);
		return InsertAfterPoint + Points.Num();
	}

	void SelectSplinePoint(int WantedIndex)
	{
		if (!Spline.SplinePoints.IsValidIndex(WantedIndex))
			return;

		FScopedTransaction Transaction("Select Spline Point");
		Selection.Modify();
		Selection.SelectPoint(WantedIndex);

		if (!Editor::IsSelected(Spline.Owner) || Editor::IsComponentSelected(Spline))
			Editor::SelectComponent(Spline, bActivateVisualizer = true);
		else
			Editor::ActivateVisualizer(Spline);
	}

	void SelectNext()
	{
		if (Selection.Type == ESplineEditorSelection::Multiple)
		{
			if (!Spline.SplineSettings.bClosedLoop && Selection.IsPointSelected(Spline.SplinePoints.Num() - 1))
				return;

			TArray<int> CurrentPoints = Selection.GetAllSelected();
			Selection.Clear();
			for (int Point : CurrentPoints)
			{
				int WantedPoint = Point + 1;
				if (Spline.SplineSettings.bClosedLoop)
					WantedPoint %= Spline.SplinePoints.Num();
				else if (!Spline.SplinePoints.IsValidIndex(WantedPoint))
					continue;

				Selection.AddPointToSelection(WantedPoint);
			}
		}
		else
		{
			if (Spline.SplineSettings.bClosedLoop)
				SelectSplinePoint((Selection.PointIndex + 1) % Spline.SplinePoints.Num());
			else
				SelectSplinePoint(Selection.PointIndex + 1);
		}
	}

	void SelectPrevious()
	{
		if (Selection.Type == ESplineEditorSelection::Multiple)
		{
			if (!Spline.SplineSettings.bClosedLoop && Selection.IsPointSelected(0))
				return;

			TArray<int> CurrentPoints = Selection.GetAllSelected();
			Selection.Clear();
			for (int Point : CurrentPoints)
			{
				int WantedPoint = Point - 1;
				if (Spline.SplineSettings.bClosedLoop)
				{
					WantedPoint += Spline.SplinePoints.Num();
					WantedPoint %= Spline.SplinePoints.Num();
				}
				else if (!Spline.SplinePoints.IsValidIndex(WantedPoint))
				{
					continue;
				}

				Selection.AddPointToSelection(WantedPoint);
			}
		}
		else
		{
			int WantedIndex = Selection.PointIndex >= 0 ? Selection.PointIndex - 1 : Spline.SplinePoints.Num() - 1;
			if (Spline.SplineSettings.bClosedLoop)
				SelectSplinePoint((WantedIndex + Spline.SplinePoints.Num()) % Spline.SplinePoints.Num());
			else
				SelectSplinePoint(WantedIndex);
		}
	}

	void SelectFirst()
	{
		SelectSplinePoint(0);
	}

	void SelectLast()
	{
		SelectSplinePoint(Spline.SplinePoints.Num() - 1);
	}

	void SelectAll()
	{
		FScopedTransaction Transaction("Select All Spline Points");

		Selection.Modify();
		Selection.Clear();
		for (int i = 0, Count = Spline.SplinePoints.Num(); i < Count; ++i)
			Selection.AddPointToSelection(i);

		if (!Editor::IsSelected(Spline.Owner) || Editor::IsComponentSelected(Spline))
			Editor::SelectComponent(Spline, bActivateVisualizer = true);
		else
			Editor::ActivateVisualizer(Spline);
	}

	void UpdatePointLocation(int PointIndex, FVector Location)
	{
		FSplineDetailsTransaction Transaction(this, "Move Spline Point");

		FHazeSplinePoint& SplinePoint = Spline.SplinePoints[PointIndex];
		SplinePoint.RelativeLocation = Location;
	}

	void UpdatePointScale(int PointIndex, FVector Scale)
	{
		FSplineDetailsTransaction Transaction(this, "Move Spline Point");

		FHazeSplinePoint& SplinePoint = Spline.SplinePoints[PointIndex];
		SplinePoint.RelativeScale3D = Scale.Abs;
	}

	void UpdateArriveTangent(int PointIndex, FVector Tangent)
	{
		FSplineDetailsTransaction Transaction(this, "Move Spline Point");

		FHazeSplinePoint& SplinePoint = Spline.SplinePoints[PointIndex];
		SplinePoint.ArriveTangent = Tangent;
		if (!SplinePoint.bDiscontinuousTangent)
			SplinePoint.LeaveTangent = Tangent;
	}

	void UpdateLeaveTangent(int PointIndex, FVector Tangent)
	{
		FSplineDetailsTransaction Transaction(this, "Move Spline Tangent");

		FHazeSplinePoint& SplinePoint = Spline.SplinePoints[PointIndex];
		SplinePoint.LeaveTangent = Tangent;
		if (!SplinePoint.bDiscontinuousTangent)
			SplinePoint.ArriveTangent = Tangent;
	}

	void UpdatePointRotation(int PointIndex, FRotator Rotation)
	{
		FSplineDetailsTransaction Transaction(this, "Rotate Spline Point");

		FHazeSplinePoint& SplinePoint = Spline.SplinePoints[PointIndex];
		FHazeComputedSplinePoint& ComputedPoint = Spline.ComputedSpline.Points[PointIndex];
		FRotator PrevRotator = SplinePoint.RelativeRotation.Rotator();

		bool bOriginalOverride = SplinePoint.bOverrideTangent;
		if (!SplinePoint.bOverrideTangent)
		{
			SplinePoint.bOverrideTangent = true;
			SplinePoint.ArriveTangent = ComputedPoint.ArriveTangent;
			SplinePoint.LeaveTangent = ComputedPoint.LeaveTangent;
		}

		FQuat PrevRotationInverse = SplinePoint.RelativeRotation.Inverse();
		SplinePoint.RelativeRotation = Rotation.Quaternion();
		SplinePoint.ArriveTangent = SplinePoint.RelativeRotation * (PrevRotationInverse * SplinePoint.ArriveTangent);
		SplinePoint.LeaveTangent = SplinePoint.RelativeRotation * (PrevRotationInverse * SplinePoint.LeaveTangent);

		// Don't actually override tangents if they didn't change due to this rotation (Roll)
		if (!bOriginalOverride
			&& SplinePoint.ArriveTangent.Equals(ComputedPoint.ArriveTangent, 0.01)
			&& SplinePoint.LeaveTangent.Equals(ComputedPoint.LeaveTangent, 0.01))
		{
			SplinePoint.bOverrideTangent = false;
		}
	}

	void UpdatePointOverrideTangents(int PointIndex, bool bOverrideTangent)
	{
		FSplineDetailsTransaction Transaction(this, "Override Spline Point Tangents");
		FHazeSplinePoint& SplinePoint = Spline.SplinePoints[PointIndex];
		const FHazeComputedSplinePoint& ComputedPoint = Spline.ComputedSpline.Points[PointIndex];
		if (bOverrideTangent)
		{
			SplinePoint.bOverrideTangent = true;
			SplinePoint.ArriveTangent = ComputedPoint.ArriveTangent;
			SplinePoint.LeaveTangent = ComputedPoint.LeaveTangent;
		}
		else
		{
			SplinePoint.bOverrideTangent = false;
			SplinePoint.bDiscontinuousTangent = false;
			SplinePoint.ArriveTangent = FVector::ZeroVector;
			SplinePoint.LeaveTangent = FVector::ZeroVector;
		}
	}

	void UpdatePointDiscontinuousTangents(int PointIndex, bool bDiscontinuousTangents)
	{
		FSplineDetailsTransaction Transaction(this, "Override Spline Point Tangents");
		FHazeSplinePoint& SplinePoint = Spline.SplinePoints[PointIndex];
		const FHazeComputedSplinePoint& ComputedPoint = Spline.ComputedSpline.Points[PointIndex];
		if (bDiscontinuousTangents)
		{
			SplinePoint.bDiscontinuousTangent = true;
		}
		else
		{
			SplinePoint.bDiscontinuousTangent = false;
			SplinePoint.ArriveTangent = SplinePoint.LeaveTangent;
		}
	}
}

struct FSplineDetailsTransaction
{
	UHazeSplineDetails Details;

	FSplineDetailsTransaction(UHazeSplineDetails InDetails, FString TransactionName)
	{
		Details = InDetails;
		Editor::BeginTransaction(TransactionName);
		Details.Spline.Modify();
	}

	~FSplineDetailsTransaction()
	{
		if (Details == nullptr)
			return;
		Details.NotifyPropertyModified(Details.Spline, n"SplinePoints");
		if (Details.Spline.Owner != nullptr)
			Details.Spline.Owner.RerunConstructionScripts();
		Details.Spline.UpdateSpline();
		Editor::EndTransaction();
		Editor::RedrawAllViewports();
	}
};
#endif