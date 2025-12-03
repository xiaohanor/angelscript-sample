#if EDITOR

class USpotSoundMultiVisualizer : UHazeScriptComponentVisualizer
{
	default VisualizedClass = USpotSoundMultiComponent;

	USpotSoundMultiSelection Selection;
	bool bAllowDuplication = true;

	USpotSoundMultiVisualizer()
	{
		Selection = GetGlobalMultiSpotSelection();
	}

	FLinearColor GetPointColor(int32 PointIndex, USpotSoundMultiComponent Component)
	{
		return Selection.IsPointSelected(PointIndex) ? FLinearColor::Yellow : Component.MultiEmitters[PointIndex].Color;
	}

	UFUNCTION(BlueprintOverride)
	void EndEditing()
	{
		Selection.Clear();
	}

	UFUNCTION(BlueprintOverride)
	void VisualizeComponent(const UActorComponent Component)
	{
		auto Spot = Cast<USpotSoundMultiComponent>(Component);
		auto EditorWorld = Spot.Owner.Level.World;
		if (Spot == nullptr)
			return;

		SetRenderForeground(true);

		const auto SpotParent = Spot.ParentSpot != nullptr ? Spot.ParentSpot : Cast<USpotSoundComponent>(UHazeAudioEditorUtils::GetSubObject(Cast<UClass>(Spot.Outer), USpotSoundComponent));

		if(SpotParent == nullptr)
			SpotParent = USpotSoundComponent::Get(Spot.Owner);

		SetHitProxy(n"SelectMultiSpot", EVisualizerCursor::CardinalCross);
		DrawWireSphere(Spot.Owner.ActorLocation, 50, SpotParent.WidgetColor, 10);

		for(int i = 0; i < Spot.MultiEmitters.Num(); ++i)
		{
			const auto& SpotPosition = Spot.MultiEmitters[i];

			// DrawPoint(SpotPosition.Transform.Location, FLinearColor::Blue, 20);

			FName PointProxy = n"SelectSpotMultiPoint";
			PointProxy.SetNumber(i);

			auto SizeFactor = 1.f;

			auto WorldPosition = Spot.WorldTransform.TransformPosition(SpotPosition.Transform.Location);

			// Draw the spline point sphere
			DrawWorldString(
				SpotPosition.EmitterName.ToString(), 
				WorldPosition, 
				GetPointColor(i, Spot),  
				1, 
				30000.0, 
				true);

			SetHitProxy(PointProxy, EVisualizerCursor::GrabHand);
			DrawCircle(WorldPosition, 50, GetPointColor(i, Spot), 10, (Editor::EditorViewLocation - WorldPosition).GetSafeNormal());
			DrawPoint(
				WorldPosition,
				GetPointColor(i, Spot),
				20.0 * SizeFactor,
			);
			DrawDashedLine(Spot.Owner.ActorLocation, WorldPosition, SpotParent.WidgetColor);
			if (SpotPosition.bSoundDefControlled)
				DrawArrow(
						WorldPosition, 
					WorldPosition + Spot.WorldTransform.TransformVector(SpotPosition.Transform.GetRotation().ForwardVector) * 100
					, FLinearColor::Red, 15, 4);
			ClearHitProxy();
		}
	}

	UFUNCTION(BlueprintOverride)
	bool HandleInputDelta(FVector& DeltaTranslate, FRotator& DeltaRotate, FVector& DeltaScale)
	{
		auto Spot = Cast<USpotSoundMultiComponent>(EditingComponent);

		if (Spot == nullptr)
			return false;

		if (Selection.Type == ESpotSoundMultiEditorSelection::Point || Selection.Type == ESpotSoundMultiEditorSelection::Multiple)
		{
			if (Selection.IsEmpty())
				return false;

			if (bAllowDuplication && IsAltPressed())
			{
				// SINGLE COPY
				if (Selection.GetSelectedCount() == 1)
				{
					Spot.MultiEmitters.Add(Spot.MultiEmitters[Selection.GetLatestPointIndex()]);
					if (Spot.bMultipleEmitterMode)
						Spot.EmitterSettings.Add(Spot.EmitterSettings[Selection.GetLatestPointIndex()]);
					
					Spot.MultiEmitters.Last().EmitterName = FName(f"Emitter_{(Selection.GetLatestPointIndex()+1):02}");
					Selection.SelectPoint(Spot.MultiEmitters.Num()-1);
				}
				// COPY SELECTION & ADD
				else 
				{
					TArray<int> PointsToDuplicate = Selection.GetAllSelected();
					PointsToDuplicate.Sort();

					Selection.Modify();
					Selection.Clear();
					for (int Point : PointsToDuplicate)
					{
						if (!Spot.MultiEmitters.IsValidIndex(Point))
							continue;

						Spot.MultiEmitters.Add(Spot.MultiEmitters[Point]);
						if (Spot.bMultipleEmitterMode)
							Spot.EmitterSettings.Add(Spot.EmitterSettings[Spot.EmitterSettings.Num()-1]);

						Spot.MultiEmitters.Last().EmitterName = FName(f"Emitter_{(Point+1):02}");

						Selection.AddPointToSelection(Spot.MultiEmitters.Num()-1);
					}

				}

				bAllowDuplication = false;
			}

			if (Selection.GetSelectedCount() > 0)
			{
				for (auto Index : Selection.GetAllSelected())
				{
					FTransform DeltaTransform = FTransform(
						DeltaRotate, 
						DeltaTranslate,
						FVector::OneVector);

					Spot.MultiEmitters[Index].Transform.Accumulate(DeltaTransform);
					Spot.MultiEmitters[Index].Transform.SetScale3D(Spot.MultiEmitters[Index].Transform.GetScale3D() + DeltaScale);
				}
				
				return true;
			}

		}
		else 
		{
			if (Selection.GetSelectedCount() > 0)
			{
				for (auto Index : Selection.GetAllSelected())
				{
					FTransform DeltaTransform = FTransform(
						DeltaRotate, 
						DeltaTranslate,
						FVector::OneVector);

					Spot.MultiEmitters[Index].Transform.Accumulate(DeltaTransform);
					Spot.MultiEmitters[Index].Transform.SetScale3D(Spot.MultiEmitters[Index].Transform.GetScale3D() + DeltaScale);
				}
				
				return true;
			}
		}

		return false;
	}

	// Used by the editor to determine where the transform gizmo ends up
	UFUNCTION(BlueprintOverride)
	bool GetWidgetLocation(FVector& OutLocation) const
	{
		auto Spot = Cast<USpotSoundMultiComponent>(EditingComponent);

		if (Spot == nullptr)
			return false;

		if (!Selection.IsEmpty() && Spot.MultiEmitters.IsValidIndex(Selection.GetFirstPointIndex()))
		{
			OutLocation = Spot.WorldTransform.TransformPosition(Spot.MultiEmitters[Selection.GetFirstPointIndex()].Transform.GetLocation());
			return true;
		}

		// Not currently overriding the gizmo location
		return false;
	}

	// void HandlePointDuplication(int SelectedPoint)

	void HandlePointSelect(int SelectedPoint)
	{
		FScopedTransaction Transaction("Select Spot Emitter");
		Selection.Modify();
		
		if (IsControlPressed())
		{
			if (Selection.IsPointSelected(SelectedPoint))
				Selection.RemovePointFromSelection(SelectedPoint);
			else 
				Selection.AddPointToSelection(SelectedPoint);
		}
		else 
		{
			Selection.SelectPoint(SelectedPoint);
		}
	}

	UFUNCTION(BlueprintOverride)
	bool VisProxyHandleClick(FName HitProxy, FVector ClickOrigin, FVector ClickDirection, FKey Key, EInputEvent Event)
	{
		auto Spot = Cast<USpotSoundMultiComponent>(EditingComponent);

		if (Spot == nullptr)
			return false;

		if (HitProxy.IsEqual(n"SelectMultiSpot", bCompareNumber = false))
		{
			if (IsControlPressed())
				Editor::ToggleActorSelected(Spot.Owner);
			else
				Editor::SelectActor(Spot.Owner);
			return true;
		}
		else if (HitProxy.IsEqual(n"SelectSpotMultiPoint", bCompareNumber = false))
		{
			// if (IsControlPressed())
			// {
			// 	Editor::ToggleActorSelected(Spline.Owner);
			// 	return true;
			// }

			// if (!Spline.EditingSettings.bAllowEditing)
			// {
			// 	Editor::SelectActor(Spline.Owner);
			// 	return true;
			// }

			// if (Key == EKeys::RightMouseButton)
			// 	LastRightClickPoint = HitProxy.GetNumber();

			// Clicked a spline point
			FScopedTransaction Transaction("Select Spot Emitter");
			Editor::SelectComponent(Spot, bActivateVisualizer = true);

			auto SelectedPoint = HitProxy.GetNumber();
			HandlePointSelect(SelectedPoint);

			Selection.Modify();

			return true;
		}

		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool HandleInputKey(FKey Key, EInputEvent Event)
	{
		auto Spot = Cast<USpotSoundMultiComponent>(EditingComponent);

		if (Spot == nullptr)
			return false;

		if (Event == EInputEvent::IE_Pressed)
		{
			if (Key == EKeys::Delete)
			{
				auto PointsToDelete = Selection.MultiplePoints;
				if (Selection.Type != ESpotSoundMultiEditorSelection::Multiple)
					PointsToDelete.Add(Selection.PointIndex);
			
				if (PointsToDelete.Num() > 0)
				{
					FScopedTransaction Transaction("Delete Spline Points");

					PointsToDelete.Sort();
					for (int i = PointsToDelete.Num() - 1; i >= 0; --i)
					{
						Spot.MultiEmitters.RemoveAt(PointsToDelete[i]);
						if (Spot.bMultipleEmitterMode)
							Spot.EmitterSettings.RemoveAt(PointsToDelete[i]);
					}

					auto SelectedPoint = Selection.MultiplePoints.Num() > 0 ? Selection.MultiplePoints.Last() : Spot.MultiEmitters.Num() - 1;

					Selection.SelectPoint(Math::Min(SelectedPoint, Spot.MultiEmitters.Num() - 1));

					Spot.Modify();
					Selection.Modify();

					return true;
				}

				return false;
			}
		}
		else if (Event == EInputEvent::IE_Released)
		{
			if (Key == EKeys::LeftMouseButton)
			{
				bAllowDuplication = true;
				Selection.bIsDraggingWidget = false;
			}
		}

		// Navigate to previous/next spline point with Ctrl+Left/Right
		if (Event == EInputEvent::IE_Pressed || Event == EInputEvent::IE_Repeat)
		{
			if (Key == EKeys::Left && IsControlPressed())
			{
				if (Selection.GetMinSelectedPoint() != -1)
				{
					FScopedTransaction Transaction("Select Spot Emitter");
					Selection.SelectPoint(Math::WrapIndex(Selection.GetMinSelectedPoint() - 1, 0, Spot.MultiEmitters.Num()));
					Selection.Modify();
					return true;
				}
			}
			else if (Key == EKeys::Right && IsControlPressed())
			{
				if (Selection.GetMaxSelectedPoint() != -1)
				{
					FScopedTransaction Transaction("Select Spot Emitter");
					Selection.SelectPoint(Math::WrapIndex(Selection.GetMaxSelectedPoint() + 1, 0, Spot.MultiEmitters.Num()));
					Selection.Modify();
					return true;
				}
			}
		}

		return false;
	}
}

struct FMultiPositionEditorTransaction
{
	USpotSoundMultiVisualizer Visualizer;
	USpotSoundMultiComponent Multi;

	FMultiPositionEditorTransaction(USpotSoundMultiVisualizer InEditor, FString TransactionName)
	{
		Visualizer = InEditor;
		Multi = Cast<USpotSoundMultiComponent>(Visualizer.GetEditingComponent());
		Editor::BeginTransaction(TransactionName);
		Multi.Modify();
	}

	~FMultiPositionEditorTransaction()
	{
		if (Visualizer == nullptr)
			return;

		Visualizer.NotifyPropertyModified(Multi, n"MultiEmitters");
		Editor::EndTransaction();
		Editor::RedrawAllViewports();
	}
};

enum ESpotSoundMultiEditorSelection
{
	Point,
	Multiple,
};

USpotSoundMultiSelection GetGlobalMultiSpotSelection()
{
	auto Object = Cast<USpotSoundMultiSelection>(FindObject(GetTransientPackage(), "SpotSoundMultiSelection"));
	if (Object != nullptr)
		return Object;
	auto NewObject = NewObject(GetTransientPackage(), USpotSoundMultiSelection, n"SpotSoundMultiSelection");
	NewObject.Transactional = true;
	return NewObject;
}

class USpotSoundMultiSelection
{
	UPROPERTY(EditAnywhere)
	int PointIndex = -1;

	UPROPERTY(EditAnywhere)
	TArray<int> MultiplePoints;

	UPROPERTY(EditAnywhere)
	ESpotSoundMultiEditorSelection Type = ESpotSoundMultiEditorSelection::Point;

	FQuat CachedRotationForWidget;
	int CachedPointIndexForRotation = -1;
	bool bIsDraggingWidget = false;
	bool bDetailsWorldLocation = false;

	bool IsPointSelected(int Point)
	{
		if (PointIndex == Point)
			return true;
		if (MultiplePoints.Contains(Point))
			return true;
		return false;
	}

	void SelectPoint(int Point, ESpotSoundMultiEditorSelection SelectType = ESpotSoundMultiEditorSelection::Point)
	{
		Type = SelectType;
		PointIndex = Point;
		MultiplePoints.Reset();
	}

	void Clear()
	{
		Type = ESpotSoundMultiEditorSelection::Point;
		PointIndex = -1;
		MultiplePoints.Reset();
	}

	void AddPointToSelection(int Point)
	{
		if (Type != ESpotSoundMultiEditorSelection::Multiple)
		{
			if (PointIndex == -1)
			{
				Type = ESpotSoundMultiEditorSelection::Point;
				PointIndex = Point;
			}
			else
			{
				Type = ESpotSoundMultiEditorSelection::Multiple;
				MultiplePoints.AddUnique(PointIndex);
				MultiplePoints.AddUnique(Point);
				PointIndex = -1;
			}
		}
		else
		{
			MultiplePoints.AddUnique(Point);
		}
	}

	void RemovePointFromSelection(int Point)
	{
		if (Type == ESpotSoundMultiEditorSelection::Multiple)
		{
			MultiplePoints.Remove(Point);

			if (MultiplePoints.Num() == 1)
			{
				Type = ESpotSoundMultiEditorSelection::Point;
				PointIndex = MultiplePoints[0];
				MultiplePoints.Reset();
			}
			else if (MultiplePoints.Num() == 0)
			{
				Type = ESpotSoundMultiEditorSelection::Point;
				PointIndex = -1;
			}
		}
		else
		{
			if (Point == PointIndex)
				PointIndex = -1;
		}
	}

	TArray<int> GetAllSelected()
	{
		TArray<int> OutSelected;
		if (Type == ESpotSoundMultiEditorSelection::Multiple)
			OutSelected.Append(MultiplePoints);
		else if (PointIndex != -1)
			OutSelected.Add(PointIndex);
		return OutSelected;
	}

	int GetFirstPointIndex()
	{
		if (Type == ESpotSoundMultiEditorSelection::Multiple)
			return MultiplePoints[0];
		return PointIndex;
	}

	int GetLatestPointIndex()
	{
		if (Type == ESpotSoundMultiEditorSelection::Multiple)
			return MultiplePoints.Last();
		return PointIndex;
	}

	void SetLatestPointIndex(int Point)
	{
		if (Type == ESpotSoundMultiEditorSelection::Multiple)
		{
			MultiplePoints.Remove(Point);
			MultiplePoints.Add(Point);
		}
	}

	int GetSelectedCount()
	{
		if (Type == ESpotSoundMultiEditorSelection::Multiple)
			return MultiplePoints.Num();
		else if (PointIndex != -1)
			return 1;
		return 0;
	}

	bool IsEmpty()
	{
		if (Type == ESpotSoundMultiEditorSelection::Multiple)
			return false;
		return PointIndex == -1;
	}

	int GetMaxSelectedPoint()
	{
		if (Type == ESpotSoundMultiEditorSelection::Multiple)
		{
			int MaxIndex = -1;
			for (int Point : MultiplePoints)
			{
				if (Point > MaxIndex)
					MaxIndex = Point;
			}
			return MaxIndex;
		}

		return PointIndex;
	}

	int GetMinSelectedPoint()
	{
		if (Type == ESpotSoundMultiEditorSelection::Multiple)
		{
			int MinIndex = MAX_int32;
			for (int Point : MultiplePoints)
			{
				if (Point < MinIndex)
					MinIndex = Point;
			}
			return MinIndex;
		}

		return PointIndex;
	}
};
#endif