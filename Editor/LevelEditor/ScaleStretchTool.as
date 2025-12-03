struct FScaleStretchActiveDrag
{
	TWeakObjectPtr<USceneComponent> Component;
	FVector StartLocation;
	FVector StartScale;
};

class UHazeScaleStretchPropertySet : UScriptableInteractiveToolPropertySet
{
	/** Allow selecting edges through faces that are in front of them */
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Selection")
	bool bHoverEdgesThroughFaces = false;

	bool bIsTemporaryExecution = false;
	bool bIsActive = false;
	EHazeLevelEditorWidgetMode PreviousWidgetMode;
}

class UScaleStretchTool : UEditorScriptableClickDragTool
{
	default ToolCategory = FText::FromString("Placement");
	default ToolName = FText::FromString("Stretch");
	default ToolLongName = FText::FromString("Stretch Scale");
	default CustomIconPath = "Editor/Slate/MenuIcons/StretchTool.png";

	UHazeScaleStretchPropertySet Settings;

	int DraggingEdge = -1;
	FVector DragStartPosition;
	FVector DragStartScale;
	FPlane DragPlane;

	int DraggingFace = -1;
	bool bDraggingWithConstraint = false;

	int DraggingVertex = -1;

	FVector DragConstrainOrigin;
	FVector DragConstrainDirection;

	FQuat DragRotation;
	FBox DragBox;
	TArray<FScaleStretchActiveDrag> DragComponents;

	UFUNCTION(BlueprintOverride)
	void OnScriptSetup()
	{
		EToolsFrameworkOutcomePins Outcome;
		Settings = Cast<UHazeScaleStretchPropertySet>(AddPropertySetOfType(UHazeScaleStretchPropertySet, "Settings", Outcome));
		RestorePropertySetSettings(Settings, "ScaleStretch");

		UHazeScaleStretchPropertySet.DefaultObject.bIsActive = true;
		UHazeScaleStretchPropertySet.DefaultObject.PreviousWidgetMode = Editor::GetLevelEditorWidgetMode();
		Editor::SetLevelEditorWidgetMode(EHazeLevelEditorWidgetMode::None);
	}

	UFUNCTION(BlueprintOverride)
	void OnScriptShutdown(EToolShutdownType ShutdownType)
	{
		SavePropertySetSettings(Settings, "ScaleStretch");

		if (UHazeScaleStretchPropertySet.DefaultObject.bIsTemporaryExecution)
			Blutility::ActivateSelectionMode();

		if (Editor::GetLevelEditorWidgetMode() == EHazeLevelEditorWidgetMode::None)
			Editor::SetLevelEditorWidgetMode(UHazeScaleStretchPropertySet.DefaultObject.PreviousWidgetMode);

		UHazeScaleStretchPropertySet.DefaultObject.bIsActive = false;
		UHazeScaleStretchPropertySet.DefaultObject.bIsTemporaryExecution = false;
	}

	UFUNCTION(BlueprintOverride)
	void OnScriptTick(float DeltaTime)
	{
	}

	void GetCurrentBox(FQuat& OutRotation, FBox& OutBox) const
	{
		OutBox = FBox();
		OutRotation = FQuat();

		bool bHaveBounds = false;

		for (auto Comp : Editor::GetSelectedComponents())
		{
			auto SceneComp = Cast<USceneComponent>(Comp);
			if (SceneComp == nullptr)
				continue;

			if (!bHaveBounds)
			{
				OutRotation = SceneComp.ComponentQuat;
				bHaveBounds = true;
			}

			FBox LocalBounds = SceneComp.GetComponentLocalBoundingBox();
			OutBox += OutRotation.Inverse() * SceneComp.WorldTransform.TransformPosition(LocalBounds.Min);
			OutBox += OutRotation.Inverse() * SceneComp.WorldTransform.TransformPosition(LocalBounds.Max);
		}

		if (!bHaveBounds)
		{
			for (AActor Actor : Editor::GetSelectedActors())
			{
				if (Actor.RootComponent == nullptr)
					continue;

				if (!bHaveBounds)
				{
					OutRotation = Actor.RootComponent.ComponentQuat;
					bHaveBounds = true;
				}

				FBox LocalBounds = Actor.GetActorLocalBoundingBox(true);
				OutBox += OutRotation.Inverse() * Actor.RootComponent.WorldTransform.TransformPosition(LocalBounds.Min);
				OutBox += OutRotation.Inverse() * Actor.RootComponent.WorldTransform.TransformPosition(LocalBounds.Max);
			}
		}
	}

	FVector GetVertexPosition(FQuat Rotation, FBox Box, int VertexIndex)
	{
		switch (VertexIndex)
		{
			case 0:
				return Rotation * FVector(Box.Min.X, Box.Min.Y, Box.Min.Z);
			case 1:
				return Rotation * FVector(Box.Min.X, Box.Max.Y, Box.Min.Z);
			case 2:
				return Rotation * FVector(Box.Max.X, Box.Max.Y, Box.Min.Z);
			case 3:
				return Rotation * FVector(Box.Max.X, Box.Min.Y, Box.Min.Z);
			case 4:
				return Rotation * FVector(Box.Min.X, Box.Min.Y, Box.Max.Z);
			case 5:
				return Rotation * FVector(Box.Min.X, Box.Max.Y, Box.Max.Z);
			case 6:
				return Rotation * FVector(Box.Max.X, Box.Max.Y, Box.Max.Z);
			case 7:
				return Rotation * FVector(Box.Max.X, Box.Min.Y, Box.Max.Z);
		}

		return FVector();
	}

	FVector GetOppositeVertexPosition(FQuat Rotation, FBox Box, int VertexIndex)
	{
		switch (VertexIndex)
		{
			case 0:
				return Rotation * FVector(Box.Max.X, Box.Max.Y, Box.Max.Z);
			case 1:
				return Rotation * FVector(Box.Max.X, Box.Min.Y, Box.Max.Z);
			case 2:
				return Rotation * FVector(Box.Min.X, Box.Min.Y, Box.Max.Z);
			case 3:
				return Rotation * FVector(Box.Min.X, Box.Max.Y, Box.Max.Z);
			case 4:
				return Rotation * FVector(Box.Max.X, Box.Max.Y, Box.Min.Z);
			case 5:
				return Rotation * FVector(Box.Max.X, Box.Min.Y, Box.Min.Z);
			case 6:
				return Rotation * FVector(Box.Min.X, Box.Min.Y, Box.Min.Z);
			case 7:
				return Rotation * FVector(Box.Min.X, Box.Max.Y, Box.Min.Z);
		}

		return FVector();
	}

	FVector GetVertexNormal(FQuat Rotation, FBox Box, int VertexIndex)
	{
		return GetVertexPosition(Rotation, Box, VertexIndex) - GetOppositeVertexPosition(Rotation, Box, VertexIndex);
	}

	void GetVerticesForEdge(FQuat Rotation, FBox Box, int EdgeIndex, FVector&out OutVertexA, FVector&out OutVertexB)
	{
		switch (EdgeIndex)
		{
			case 0:
				OutVertexA = Rotation * FVector(Box.Min.X, Box.Min.Y, Box.Min.Z);
				OutVertexB = Rotation * FVector(Box.Max.X, Box.Min.Y, Box.Min.Z);
			break;
			case 1:
				OutVertexA = Rotation * FVector(Box.Max.X, Box.Min.Y, Box.Min.Z);
				OutVertexB = Rotation * FVector(Box.Max.X, Box.Max.Y, Box.Min.Z);
			break;
			case 2:
				OutVertexA = Rotation * FVector(Box.Max.X, Box.Max.Y, Box.Min.Z);
				OutVertexB = Rotation * FVector(Box.Min.X, Box.Max.Y, Box.Min.Z);
			break;
			case 3:
				OutVertexA = Rotation * FVector(Box.Min.X, Box.Max.Y, Box.Min.Z);
				OutVertexB = Rotation * FVector(Box.Min.X, Box.Min.Y, Box.Min.Z);
			break;

			case 4:
				OutVertexA = Rotation * FVector(Box.Min.X, Box.Min.Y, Box.Max.Z);
				OutVertexB = Rotation * FVector(Box.Max.X, Box.Min.Y, Box.Max.Z);
			break;
			case 5:
				OutVertexA = Rotation * FVector(Box.Max.X, Box.Min.Y, Box.Max.Z);
				OutVertexB = Rotation * FVector(Box.Max.X, Box.Max.Y, Box.Max.Z);
			break;
			case 6:
				OutVertexA = Rotation * FVector(Box.Max.X, Box.Max.Y, Box.Max.Z);
				OutVertexB = Rotation * FVector(Box.Min.X, Box.Max.Y, Box.Max.Z);
			break;
			case 7:
				OutVertexA = Rotation * FVector(Box.Min.X, Box.Max.Y, Box.Max.Z);
				OutVertexB = Rotation * FVector(Box.Min.X, Box.Min.Y, Box.Max.Z);
			break;

			case 8:
				OutVertexA = Rotation * FVector(Box.Min.X, Box.Min.Y, Box.Min.Z);
				OutVertexB = Rotation * FVector(Box.Min.X, Box.Min.Y, Box.Max.Z);
			break;
			case 9:
				OutVertexA = Rotation * FVector(Box.Min.X, Box.Max.Y, Box.Min.Z);
				OutVertexB = Rotation * FVector(Box.Min.X, Box.Max.Y, Box.Max.Z);
			break;
			case 10:
				OutVertexA = Rotation * FVector(Box.Max.X, Box.Max.Y, Box.Min.Z);
				OutVertexB = Rotation * FVector(Box.Max.X, Box.Max.Y, Box.Max.Z);
			break;
			case 11:
				OutVertexA = Rotation * FVector(Box.Max.X, Box.Min.Y, Box.Min.Z);
				OutVertexB = Rotation * FVector(Box.Max.X, Box.Min.Y, Box.Max.Z);
			break;
		}
	}

	void GetPlaneForFace(FQuat Rotation, FBox Box, int FaceIndex, FVector&out OutMin, FVector&out OutMax, FVector&out OutNormal, FVector&out OutFaceRight)
	{
		switch (FaceIndex)
		{
			case 0:
				OutMin = Rotation * FVector(Box.Min.X, Box.Min.Y, Box.Min.Z);
				OutMax = Rotation * FVector(Box.Max.X, Box.Max.Y, Box.Min.Z);
				OutNormal = Rotation * FVector(0, 0, -1);
				OutFaceRight = Rotation * FVector(-1, 0, 0);
			break;
			case 1:
				OutMin = Rotation * FVector(Box.Min.X, Box.Min.Y, Box.Max.Z);
				OutMax = Rotation * FVector(Box.Max.X, Box.Max.Y, Box.Max.Z);
				OutNormal = Rotation * FVector(0, 0, 1);
				OutFaceRight = Rotation * FVector(1, 0, 0);
			break;
			case 2:
				OutMin = Rotation * FVector(Box.Min.X, Box.Min.Y, Box.Min.Z);
				OutMax = Rotation * FVector(Box.Min.X, Box.Max.Y, Box.Max.Z);
				OutNormal = Rotation * FVector(-1, 0, 0);
				OutFaceRight = Rotation * FVector(0, 0, 1);
			break;
			case 3:
				OutMin = Rotation * FVector(Box.Max.X, Box.Min.Y, Box.Min.Z);
				OutMax = Rotation * FVector(Box.Max.X, Box.Max.Y, Box.Max.Z);
				OutNormal = Rotation * FVector(1, 0, 0);
				OutFaceRight = Rotation * FVector(0, 0, -1);
			break;
			case 4:
				OutMin = Rotation * FVector(Box.Min.X, Box.Min.Y, Box.Min.Z);
				OutMax = Rotation * FVector(Box.Max.X, Box.Min.Y, Box.Max.Z);
				OutNormal = Rotation * FVector(0, -1, 0);
				OutFaceRight = Rotation * FVector(0, 0, 1);
			break;
			case 5:
				OutMin = Rotation * FVector(Box.Min.X, Box.Max.Y, Box.Min.Z);
				OutMax = Rotation * FVector(Box.Max.X, Box.Max.Y, Box.Max.Z);
				OutNormal = Rotation * FVector(0, 1, 0);
				OutFaceRight = Rotation * FVector(0, 0, -1);
			break;
		}
	}

	void GetHoveredElement(FQuat Rotation, FBox Box, FVector RayOrigin, FVector RayDirection, int& OutIndex, bool& OutIsEdge, bool& OutIsVertex)
	{
		int ClosestIndex = -1;
		bool bClosestIsEdge = false;
		bool bClosestIsVertex = false;
		float ClosestDistance = BIG_NUMBER;

		for (int i = 0; i < 8; ++i)
		{
			FVector Vertex = GetVertexPosition(Rotation, Box, i);
			FVector RayPoint = Math::ClosestPointOnLine(RayOrigin, RayOrigin + RayDirection * 1e10, Vertex);

			float CameraDistance = Editor::EditorViewLocation.Distance(Vertex);
			float SizeOfPoint = 10.0 * Math::Clamp(CameraDistance / 1000.0, 1.0, 5.0);
			if (RayPoint.Distance(Vertex) > SizeOfPoint)
				continue;

			float Distance = RayPoint.Distance(RayOrigin);
			if (Settings.bHoverEdgesThroughFaces)
				Distance = 0;

			if (Distance < ClosestDistance)
			{
				ClosestDistance = Distance;
				bClosestIsVertex = true;
				bClosestIsEdge = false;
				ClosestIndex = i;
			}
		}

		if (ClosestIndex == -1)
		{
			for (int i = 0; i < 12; ++i)
			{
				FVector VertexA;
				FVector VertexB;
				GetVerticesForEdge(Rotation, Box, i, VertexA, VertexB);

				FVector RayPoint;
				FVector EdgePoint;

				Math::FindNearestPointsOnLineSegments(
					RayOrigin, RayOrigin + RayDirection * 1e10,
					VertexA, VertexB,
					RayPoint, EdgePoint
				);

				float CameraDistance = Editor::EditorViewLocation.Distance(RayPoint);
				float SizeOfLine = 10.0 * Math::Clamp(CameraDistance / 1000.0, 1.0, 5.0);
				if (RayPoint.Distance(EdgePoint) > SizeOfLine)
					continue;

				float Distance = EdgePoint.Distance(RayOrigin);
				if (Settings.bHoverEdgesThroughFaces)
					Distance = RayPoint.Distance(EdgePoint);

				if (Distance < ClosestDistance)
				{
					ClosestDistance = Distance;
					bClosestIsEdge = true;
					bClosestIsVertex = false;
					ClosestIndex = i;
				}
			}
		}

		if (!Settings.bHoverEdgesThroughFaces || ClosestIndex == -1)
		{
			for (int i = 0; i < 6; ++i)
			{
				FVector FaceMin;
				FVector FaceMax;
				FVector FaceNormal;
				FVector FaceRight;
				GetPlaneForFace(Rotation, Box, i, FaceMin, FaceMax, FaceNormal, FaceRight);

				FVector LocalFaceMin = Rotation.Inverse() * FaceMin;
				FVector LocalFaceMax = Rotation.Inverse() * FaceMax;

				FVector Intersect = Math::RayPlaneIntersection(RayOrigin, RayDirection, FPlane((FaceMin + FaceMax) * 0.5, FaceNormal));
				FVector LocalIntersect = Rotation.Inverse() * Intersect;
				if (!Math::IsWithin(LocalIntersect.X, LocalFaceMin.X - 0.1, LocalFaceMax.X + 0.1))
					continue;
				if (!Math::IsWithin(LocalIntersect.Y, LocalFaceMin.Y - 0.1, LocalFaceMax.Y + 0.1))
					continue;
				if (!Math::IsWithin(LocalIntersect.Z, LocalFaceMin.Z - 0.1, LocalFaceMax.Z + 0.1))
					continue;

				float Distance = RayOrigin.Distance(Intersect);
				if (Distance < ClosestDistance)
				{
					ClosestDistance = Distance;
					ClosestIndex = i;
					bClosestIsEdge = false;
					bClosestIsVertex = false;
				}
			}
		}

		OutIndex = ClosestIndex;
		OutIsEdge = bClosestIsEdge;
		OutIsVertex = bClosestIsVertex;
	}

	UFUNCTION(BlueprintOverride)
	void OnDragBegin(FInputDeviceRay StartPosition, FScriptableToolModifierStates Modifiers)
	{
		Editor::BeginTransaction("Stretch Scale");
		GetCurrentBox(DragRotation, DragBox);

		bDraggingWithConstraint = false;

		int HoveredIndex = -1;
		bool bHoveredIsEdge = false;
		bool bHoveredIsVertex = false;
		GetHoveredElement(DragRotation, DragBox, StartPosition.WorldRay.Origin, StartPosition.WorldRay.Direction, HoveredIndex, bHoveredIsEdge, bHoveredIsVertex);

		if (HoveredIndex != -1 && bHoveredIsEdge)
		{
			DraggingEdge = HoveredIndex;

			FVector VertexA;
			FVector VertexB;
			GetVerticesForEdge(DragRotation, DragBox, DraggingEdge, VertexA, VertexB);

			FVector RayPoint;
			FVector EdgePoint;

			Math::FindNearestPointsOnLineSegments(
				StartPosition.WorldRay.Origin, StartPosition.WorldRay.Origin + StartPosition.WorldRay.Direction * 1e10,
				VertexA, VertexB,
				RayPoint, EdgePoint
			);

			DragPlane = FPlane(EdgePoint, (VertexB - VertexA).GetSafeNormal());
			DragStartPosition = Math::RayPlaneIntersection(StartPosition.WorldRay.Origin, StartPosition.WorldRay.Direction, DragPlane);

			DragConstrainOrigin = DragStartPosition;
			DragConstrainDirection = (VertexA - (DragRotation * DragBox.Center)).ConstrainToPlane(
				DragPlane.Normal
			).GetSafeNormal();
		}
		else if(HoveredIndex != -1 && bHoveredIsVertex)
		{
			DraggingVertex = HoveredIndex;
			DragConstrainOrigin = GetVertexPosition(DragRotation, DragBox, DraggingVertex);
			DragConstrainDirection = GetVertexNormal(DragRotation, DragBox, DraggingVertex);
		}
		else if(HoveredIndex != -1)
		{
			DraggingFace = HoveredIndex;

			FVector FaceMin;
			FVector FaceMax;
			FVector FaceNormal;
			FVector FaceRight;

			GetPlaneForFace(DragRotation, DragBox, DraggingFace, FaceMin, FaceMax, FaceNormal, FaceRight);

			FVector PointOnFace = Math::RayPlaneIntersection(StartPosition.WorldRay.Origin, StartPosition.WorldRay.Direction, FPlane((FaceMin + FaceMax) * 0.5, FaceNormal));
			DragPlane = FPlane(PointOnFace, FaceRight);
			DragStartPosition = PointOnFace;
		}

		if (HoveredIndex != -1)
		{
			DragComponents.Reset();
			for (UActorComponent Comp : Editor::GetSelectedComponents())
			{
				auto SceneComp = Cast<USceneComponent>(Comp);
				if (SceneComp == nullptr)
					continue;

				SceneComp.Modify();

				FScaleStretchActiveDrag Drag;
				Drag.Component = SceneComp;
				Drag.StartLocation = SceneComp.WorldLocation;
				Drag.StartScale = SceneComp.WorldScale;
				DragComponents.Add(Drag);
			}

			if (DragComponents.Num() == 0)
			{
				for (AActor Actor : Editor::GetSelectedActors())
				{
					if (Actor.RootComponent == nullptr)
						continue;

					Actor.RootComponent.Modify();

					FScaleStretchActiveDrag Drag;
					Drag.Component = Actor.RootComponent;
					Drag.StartLocation = Actor.RootComponent.WorldLocation;
					Drag.StartScale = Actor.RootComponent.WorldScale;
					DragComponents.Add(Drag);
			}
			}
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnDragEnd(FInputDeviceRay EndPosition, FScriptableToolModifierStates Modifiers)
	{
		DraggingEdge = -1;
		DraggingFace = -1;
		DraggingVertex = -1;
		Editor::EndTransaction();
		DragComponents.Reset();
	}

	UFUNCTION(BlueprintOverride)
	void OnDragUpdatePosition(FInputDeviceRay NewPosition, FScriptableToolModifierStates Modifiers)
	{
		FVector DragTargetPosition;

		if (DraggingVertex != -1)
		{
			FVector RayPoint;
			FVector ConstrainPoint;

			Math::FindNearestPointsOnLineSegments(
				NewPosition.WorldRay.Origin, NewPosition.WorldRay.Direction * 1e10,
				DragConstrainOrigin - DragConstrainDirection * 1e10, DragConstrainOrigin + DragConstrainDirection * 1e10,
				RayPoint, ConstrainPoint
			);

			// Debug::DrawDebugLine(DragConstrainOrigin - DragConstrainDirection * 1000, DragConstrainOrigin + DragConstrainDirection * 1000);
			// Debug::DrawDebugPoint(ConstrainPoint, 10, FLinearColor::Green);

			DragTargetPosition = ConstrainPoint;

			if (Editor::IsGridEnabled())
				DragTargetPosition = DragTargetPosition.GridSnap(Editor::GetGridSize());
		}
		else
		{
			DragTargetPosition = Math::RayPlaneIntersection(NewPosition.WorldRay.Origin, NewPosition.WorldRay.Direction, DragPlane);
			if ((DragTargetPosition - NewPosition.WorldRay.Origin).DotProduct(NewPosition.WorldRay.Direction) < 0)
				return;

			if (Editor::IsGridEnabled())
			{
				DragTargetPosition = DragTargetPosition.GridSnap(Editor::GetGridSize());
				DragTargetPosition = DragTargetPosition.PointPlaneProject(DragPlane.Origin, DragPlane.Normal);
			}

			if ((Modifiers.bCtrlDown || bDraggingWithConstraint) && !DragConstrainDirection.IsNearlyZero())
			{
				DragTargetPosition = Math::ProjectPositionOnInfiniteLine(
					DragConstrainOrigin, DragConstrainDirection,
					DragTargetPosition, 
				);
				bDraggingWithConstraint = true;
			}
		}

		FVector LocalDragPos = DragRotation.Inverse() * DragTargetPosition;
		FVector NewScaleFactor = FVector(1, 1, 1);
		FVector LocalPositionOffset = FVector(0, 0, 0);

		if (DraggingEdge == 0 || DraggingEdge == 4 || DraggingEdge == 8 || DraggingEdge == 11 || DraggingFace == 4 || DraggingVertex == 0 || DraggingVertex == 3 || DraggingVertex == 4 || DraggingVertex == 7)
		{
			float NewExtent = Math::Max((DragBox.Max.Y - LocalDragPos.Y) * 0.5, 0.01);
			NewScaleFactor.Y = NewExtent / DragBox.Extent.Y;
			LocalPositionOffset.Y -= (NewExtent - DragBox.Extent.Y);
		}
		else if (DraggingEdge == 2 || DraggingEdge == 6 || DraggingEdge == 9 || DraggingEdge == 10 || DraggingFace == 5 || DraggingVertex != -1)
		{
			float NewExtent = Math::Max((LocalDragPos.Y - DragBox.Min.Y) * 0.5, 0.01);
			NewScaleFactor.Y = NewExtent / DragBox.Extent.Y;
			LocalPositionOffset.Y += (NewExtent - DragBox.Extent.Y);
		}

		if (DraggingEdge == 3 || DraggingEdge == 7 || DraggingEdge == 8 || DraggingEdge == 9 || DraggingFace == 2 || DraggingVertex == 0 || DraggingVertex == 1 || DraggingVertex == 4 || DraggingVertex == 5)
		{
			float NewExtent = Math::Max((DragBox.Max.X - LocalDragPos.X) * 0.5, 0.01);
			NewScaleFactor.X = NewExtent / DragBox.Extent.X;
			LocalPositionOffset.X -= (NewExtent - DragBox.Extent.X);
		}
		else if (DraggingEdge == 1 || DraggingEdge == 5 || DraggingEdge == 10 || DraggingEdge == 11 || DraggingFace == 3 || DraggingVertex != -1)
		{
			float NewExtent = Math::Max((LocalDragPos.X - DragBox.Min.X) * 0.5, 0.01);
			NewScaleFactor.X = NewExtent / DragBox.Extent.X;
			LocalPositionOffset.X += (NewExtent - DragBox.Extent.X);
		}

		if (DraggingEdge == 0 || DraggingEdge == 1 || DraggingEdge == 2 || DraggingEdge == 3 || DraggingFace == 0 || DraggingVertex == 0 || DraggingVertex == 1 || DraggingVertex == 2 || DraggingVertex == 3)
		{
			float NewExtent = Math::Max((DragBox.Max.Z - LocalDragPos.Z) * 0.5, 0.01);
			NewScaleFactor.Z = NewExtent / DragBox.Extent.Z;
			LocalPositionOffset.Z -= (NewExtent - DragBox.Extent.Z);
		}
		else if (DraggingEdge == 4 || DraggingEdge == 5 || DraggingEdge == 6 || DraggingEdge == 7 || DraggingFace == 1 || DraggingVertex != -1)
		{
			float NewExtent = Math::Max((LocalDragPos.Z - DragBox.Min.Z) * 0.5, 0.01);
			NewScaleFactor.Z = NewExtent / DragBox.Extent.Z;
			LocalPositionOffset.Z += (NewExtent - DragBox.Extent.Z);
		}

		FVector NewDragBoxCenter = DragBox.Center + LocalPositionOffset;
		for (FScaleStretchActiveDrag Drag : DragComponents)
		{
			FVector OriginalPivotOffset = (DragRotation.Inverse() * Drag.StartLocation) - DragBox.Center;
			if (Drag.Component.IsValid())
			{
				Drag.Component.Get().SetWorldScale3D(NewScaleFactor * Drag.StartScale);
				Drag.Component.Get().SetWorldLocation(DragRotation * (NewDragBoxCenter + OriginalPivotOffset * NewScaleFactor));
			}
		}
	}

	UFUNCTION(BlueprintOverride)
	FInputRayHit TestIfCanBeginClickDrag(FInputDeviceRay ClickPos, FScriptableToolModifierStates Modifiers)
	{
		FQuat Rotation;
		FBox Box;
		GetCurrentBox(Rotation, Box);

		int HoveredIndex = -1;
		bool bHoveredIsEdge = false;
		bool bHoveredIsVertex = false;

		GetHoveredElement(Rotation, Box, ClickPos.WorldRay.Origin, ClickPos.WorldRay.Direction, HoveredIndex, bHoveredIsEdge, bHoveredIsVertex);

		FInputRayHit Hit;
		if (HoveredIndex != -1)
			Hit.bHit = true;

		return Hit;
	}

	UFUNCTION(BlueprintOverride)
	void OnScriptRender(UScriptableTool_RenderAPI RenderAPI)
	{
		FQuat Rotation;
		FBox Box;
		GetCurrentBox(Rotation, Box);

		FVector CursorRayOrigin;
		FVector CursorRayDirection;
		Editor::GetEditorCursorRay(CursorRayOrigin, CursorRayDirection);

		int HoveredIndex = -1;
		bool bHoveredIsEdge = false;
		bool bHoveredIsVertex = false;

		GetHoveredElement(Rotation, Box, CursorRayOrigin, CursorRayDirection, HoveredIndex, bHoveredIsEdge, bHoveredIsVertex);

		// Draw edges
		for (int i = 0; i < 12; ++i)
		{
			FVector VertexA;
			FVector VertexB;
			GetVerticesForEdge(Rotation, Box, i, VertexA, VertexB);

			FLinearColor Color;
			if (i == DraggingEdge)
				Color = ColorDebug::Red;
			else if (i == HoveredIndex && bHoveredIsEdge && DraggingEdge == -1 && DraggingFace == -1 && DraggingVertex == -1)
				Color = ColorDebug::Yellow;
			else
				Color = ColorDebug::Blush;

			RenderAPI.DrawLine(VertexA, VertexB, Color, 10, 0, false);
		}

		// Draw faces
		if (DraggingFace != -1)
		{
			FLinearColor Color = ColorDebug::Red;

			FVector FaceMin;
			FVector FaceMax;
			FVector FaceNormal;
			FVector FaceRight;

			GetPlaneForFace(Rotation, Box, DraggingFace, FaceMin, FaceMax, FaceNormal, FaceRight);

			FVector FaceMinRight = FaceMin + (FaceMax - FaceMin).ConstrainToDirection(FaceRight);
			FVector FaceMaxRight = FaceMin + (FaceMax - FaceMin).ConstrainToPlane(FaceRight);

			RenderAPI.DrawLine(FaceMin, FaceMax, Color, 5.0, 0, false);
			RenderAPI.DrawLine(FaceMinRight, FaceMaxRight, Color, 5.0, 0, false);
		}
		else if (HoveredIndex != -1 && !bHoveredIsEdge && !bHoveredIsVertex && DraggingEdge == -1 && DraggingFace == -1 && DraggingVertex == -1)
		{
			FLinearColor Color = ColorDebug::Leaf;

			FVector FaceMin;
			FVector FaceMax;
			FVector FaceNormal;
			FVector FaceRight;

			GetPlaneForFace(Rotation, Box, HoveredIndex, FaceMin, FaceMax, FaceNormal, FaceRight);

			FVector FaceMinRight = FaceMin + (FaceMax - FaceMin).ConstrainToDirection(FaceRight);
			FVector FaceMaxRight = FaceMin + (FaceMax - FaceMin).ConstrainToPlane(FaceRight);

			RenderAPI.DrawLine(FaceMin, FaceMax, Color, 5.0, 0, false);
			RenderAPI.DrawLine(FaceMinRight, FaceMaxRight, Color, 5.0, 0, false);
		}

		// Draw vertex
		if (DraggingVertex != -1)
		{
			FLinearColor Color = ColorDebug::Red;
			FVector Vertex = GetVertexPosition(Rotation, Box, DraggingVertex);

			RenderAPI.DrawLine(Vertex, Vertex, Color, 30, 0, false);
		}
		else if (HoveredIndex != -1 && bHoveredIsVertex && DraggingEdge == -1 && DraggingFace == -1 && DraggingVertex == -1)
		{
			FLinearColor Color = ColorDebug::Yellow;
			FVector Vertex = GetVertexPosition(Rotation, Box, HoveredIndex);

			RenderAPI.DrawLine(Vertex, Vertex, Color, 30, 0, false);
		}
	}
}

class UScaleStretchEditorSubsystem : UHazeEditorSubsystem
{
	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		// Switching editor modes closes the tool
		if (UHazeScaleStretchPropertySet.DefaultObject.bIsActive
			&& Editor::GetLevelEditorWidgetMode() != EHazeLevelEditorWidgetMode::None)
		{
			if (UHazeScaleStretchPropertySet.DefaultObject.bIsTemporaryExecution)
				Blutility::ActivateSelectionMode();
			else
				Blutility::DeactivateEditorTool(EToolShutdownType::Cancel);
		}
	}
}

const FConsoleCommand Command_OutputCookList("Haze.Editor.ToggleStretchScaleTool", n"ToggleStretchScaleTool");
void ToggleStretchScaleTool(TArray<FString> Arguments)
{
	if (UHazeScaleStretchPropertySet.DefaultObject.bIsActive)
	{
		UHazeScaleStretchPropertySet.DefaultObject.bIsTemporaryExecution = true;
		if (Editor::GetLevelEditorWidgetMode() == EHazeLevelEditorWidgetMode::None)
			Editor::SetLevelEditorWidgetMode(UHazeScaleStretchPropertySet.DefaultObject.PreviousWidgetMode);
		Blutility::ActivateSelectionMode();
	}
	else
	{
		UHazeScaleStretchPropertySet.DefaultObject.bIsTemporaryExecution = true;
		Blutility::ActivateEditorTool(UScaleStretchTool);
	}
}