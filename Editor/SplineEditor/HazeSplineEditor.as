
class UHazeSplineEditor : UHazeScriptComponentVisualizer
{
	default VisualizedClass = UHazeSplineComponent;

	float LastLeftClickTime = -1.0;
	FName LastLeftClickProxy;

	bool bPreparedAssets = false;
	UStaticMesh Mesh_SplinePoint;
	UStaticMesh Mesh_TangentHandle;
	UMaterialInterface Mat_OverriddenTangentHandle;
	UMaterialInterface Mat_SelectedPoint;
	UMaterialInterface Mat_HoveredPoint;
	UMaterialInterface Mat_SelectedHoveredPoint;

	UHazeSplineSelection Selection;

	int LastRightClickPoint = -1;
	float LastRightClickDistance = -1.0;

	bool bAllowDuplication = false;

	float SwapDragWindowStart = 0.0;
	int SwapDragBeforeIndex = -1;
	int SwapDragAfterIndex = -1;
	FVector SwapDragBasePoint;
	FVector SwapDragTangent;

	UHazeSplineEditor()
	{
		Selection = GetGlobalSplineSelection();
	}

	void PrepareAssets()
	{
		if (bPreparedAssets)
			return;
		bPreparedAssets = true;

		Mesh_SplinePoint = Cast<UStaticMesh>(Editor::LoadAsset(n"/Game/Editor/SplineEditor/SplineEditor_Point.SplineEditor_Point"));
		Mesh_TangentHandle = Cast<UStaticMesh>(Editor::LoadAsset(n"/Game/Editor/SplineEditor/SplineEditor_TangentHandle.SplineEditor_TangentHandle"));
		Mat_OverriddenTangentHandle = Cast<UMaterialInterface>(Editor::LoadAsset(n"/Game/Editor/SplineEditor/SplineEditor_OverriddenTangentHandle_Material.SplineEditor_OverriddenTangentHandle_Material"));
		Mat_SelectedPoint = Cast<UMaterialInterface>(Editor::LoadAsset(n"/Game/Editor/SplineEditor/SplineEditor_Point_Selected_Material.SplineEditor_Point_Selected_Material"));
		Mat_HoveredPoint = Cast<UMaterialInterface>(Editor::LoadAsset(n"/Game/Editor/SplineEditor/SplineEditor_Point_Hovered_Material.SplineEditor_Point_Hovered_Material"));
		Mat_SelectedHoveredPoint = Cast<UMaterialInterface>(Editor::LoadAsset(n"/Game/Editor/SplineEditor/SplineEditor_Point_Selected_Hovered_Material.SplineEditor_Point_Selected_Hovered_Material"));
	}

	UFUNCTION(BlueprintOverride)
	void VisualizeComponent(const UActorComponent Component)
	{
		UHazeSplineComponent Spline = Cast<UHazeSplineComponent>(Component);
		if (!Spline.EditingSettings.bShowWhenSelected)
			return;
		if (Spline.World == nullptr || Spline.World.IsPreviewWorld())
			return;

		bool bEditingThisSpline = (EditingComponent == Component);
		FScopeIsRunningSplineEditorCode ScopeEditorCode;

		PrepareAssets();
		FTransform Transform = Spline.WorldTransform;

		SetRenderForeground(true);

		// If we still have a selection on a point, but the visualizer isn't active anymore,
		// we want to force the visualizer active (this can happen after an Undo)
		if (Selection.GetSelectedCount() != 0)
		{
			if (Editor::IsComponentSelected(Spline))
			{
				Editor::ActivateVisualizer(Spline);
			}
			else
			{
				auto SelectedComponents = Editor::GetSelectedComponents();
				if (Editor::IsSelected(Spline.Owner) && SelectedComponents.Num() == 0 && Spline.EditingSettings.bSelectSplineComponentWhileEditing)
					Editor::SelectComponent(Spline, true);
				else if (Editor::IsSelected(Spline.Owner))
					Editor::ActivateVisualizer(Spline);
				else if (SelectedComponents.Num() != 1 || Cast<UHazeSplineComponent>(SelectedComponents[0]) == nullptr)
					Selection.Clear();
			}
		}

		// Determine which point or points are hovered
		int HoveredStart = -1;
		int HoveredEnd = -1;
		if (GetHoveredHitProxy().IsEqual(n"SplinePoint", bCompareNumber = false)
			&& GetHoveredVisualizerComponent() == Spline)
		{
			HoveredStart = GetHoveredHitProxy().Number;
			HoveredEnd = HoveredStart+1;
			if (IsShiftPressed() && !Selection.IsEmpty() && bEditingThisSpline)
			{
				int MaxSelected = Selection.GetMaxSelectedPoint();
				int MinSelected = Selection.GetMinSelectedPoint();

				if (HoveredStart < MaxSelected)
					HoveredEnd = MaxSelected+1;
				else
					HoveredStart = MinSelected;
			}
		}

		// Find the minimum plane below the spline
		float SplinePlaneHeight = MAX_flt;
		if (Spline.EditingSettings.HeightIndicators == ESplineHeightIndicatorMode::SplinePointsToFloor
			|| Spline.EditingSettings.HeightIndicators == ESplineHeightIndicatorMode::WholeSplineToFloor)
		{
			SplinePlaneHeight = -100000.0;
		}
		else
			{
			for (int i = 0, Count = Spline.SplinePoints.Num(); i < Count; ++i)
			{
				const FHazeSplinePoint& Point = Spline.SplinePoints[i];
				float PointHeight = Transform.TransformPosition(Point.RelativeLocation).Z;
				if (PointHeight < SplinePlaneHeight)
					SplinePlaneHeight = PointHeight;
			}
		}

		// Draw connections if we have them
		if (Spline.bSpecifyConnections)
		{
			DrawSplineConnection(
				Spline, 0.0, FLinearColor::Red, 27.0, Spline.StartConnection,
			);

			DrawSplineConnection(
				Spline, Spline.GetSplineLength(), FLinearColor::Green, 21.0, Spline.EndConnection,
			);
		}

		// Draw tangent handles for the currently selected spline point
		if (Spline.SplinePoints.IsValidIndex(Selection.PointIndex)
			&& Spline.EditingSettings.bAllowEditing
			&& Spline.SplinePoints.Num() >= 2
			&& bEditingThisSpline)
		{
			const FHazeComputedSplinePoint& SelectedPoint = Spline.ComputedSpline.Points[Selection.PointIndex];
			const FHazeSplinePoint& InputPoint = Spline.SplinePoints[Selection.PointIndex];

			FVector PointLocation = Spline.GetWorldLocationAtSplineDistance(SelectedPoint.SplineDistance);
			FVector ArriveTangent = Transform.TransformVector(SelectedPoint.ArriveTangent);
			FVector LeaveTangent = Transform.TransformVector(SelectedPoint.LeaveTangent);

			if (InputPoint.bOverrideTangent)
			{
				// Tangents are overridden
				FLinearColor Color = FLinearColor::Red;
				if (InputPoint.bDiscontinuousTangent)
					Color = FLinearColor(1.0, 0.5, 0.0, 1.0);

				DrawDashedLine(
					PointLocation,
					PointLocation - ArriveTangent,
					Color,
					DashSize = 5.0,
					Thickness = 3.0,
					bScreenSpace = true,
					);

				DrawDashedLine(
					PointLocation,
					PointLocation + LeaveTangent,
					Color,
					DashSize = 5.0,
					Thickness = 3.0,
					bScreenSpace = true,
					);
			}
			else
			{
				// Tangents are not overridden, show the auto-computed tangent
				DrawDashedLine(
					PointLocation,
					PointLocation - ArriveTangent,
					FLinearColor::Yellow,
					DashSize = 5.0,
					Thickness = 2.0,
					bScreenSpace = true,
					);

				DrawDashedLine(
					PointLocation,
					PointLocation + LeaveTangent,
					FLinearColor::Yellow,
					DashSize = 5.0,
					Thickness = 2.0,
					bScreenSpace = true,
					);
			}

			// Draw tangent handles
			if (!DoesTangentOverlapWithPoint(PointLocation - ArriveTangent))
			{
				SetHitProxy(n"ArriveTangentHandle");
				float PointScale = 0.06 * (EditorViewLocation.Distance(PointLocation - ArriveTangent) / 400.0);
				DrawMeshWithMaterial(
					Mesh_TangentHandle,
					InputPoint.bOverrideTangent ? Mat_OverriddenTangentHandle : nullptr,
					PointLocation - ArriveTangent,
					Transform.Rotation,
					FVector(PointScale, PointScale, PointScale),
				);
				ClearHitProxy();
			}

			if (!DoesTangentOverlapWithPoint(PointLocation + LeaveTangent))
			{
				SetHitProxy(n"LeaveTangentHandle");
				float PointScale = 0.06 * (EditorViewLocation.Distance(PointLocation + LeaveTangent) / 400.0);
				DrawMeshWithMaterial(
					Mesh_TangentHandle,
					InputPoint.bOverrideTangent ? Mat_OverriddenTangentHandle : nullptr,
					PointLocation + LeaveTangent,
					Transform.Rotation,
					FVector(PointScale, PointScale, PointScale),
				);
				ClearHitProxy();
			}
		}

		int SegmentCount = Spline.ComputedSpline.Segments.Num();
		int SampleCount = Spline.ComputedSpline.Samples_SplineAlpha.Num();
		int SampleStride = 1;

		// Draw scale visualization
		if (Spline.EditingSettings.bEnableVisualizeScale)
		{
			FVector PrevLeftSide;
			FVector PrevRightSide;

			for (int SampleIndex = 0; SampleIndex < SampleCount; SampleIndex += SampleStride)
			{
				FTransform SampleTransform = SplineComputation::GetRelativeTransformAtSegmentAlpha(
					Spline.ComputedSpline,
					Spline.ComputedSpline.Samples_SegmentIndex[SampleIndex],
					Spline.ComputedSpline.Samples_SegmentAlpha[SampleIndex],
				);

				FVector Offset = SampleTransform.Rotation.RightVector * SampleTransform.Scale3D.Y * Spline.EditingSettings.VisualizeScale;
				FVector LeftSide = Transform.TransformPosition(SampleTransform.Location - Offset);
				FVector RightSide = Transform.TransformPosition(SampleTransform.Location + Offset);

				if (SampleIndex != 0)
				{
					DrawLine(
						PrevLeftSide,
						LeftSide,
						Spline.EditingSettings.SplineColor,
						1.0, true
					);

					DrawLine(
						PrevRightSide,
						RightSide,
						Spline.EditingSettings.SplineColor,
						1.0, true
					);
				}

				PrevLeftSide = LeftSide;
				PrevRightSide = RightSide;
			}

			for (int PointIndex = 0, PointCount = Spline.SplinePoints.Num(); PointIndex < PointCount; ++PointIndex)
			{
				const FHazeSplinePoint& Point = Spline.SplinePoints[PointIndex];
				FTransform PointTransform;
				if (PointIndex == PointCount - 1)
				{
					PointTransform = SplineComputation::GetRelativeTransformAtSegmentAlpha(
						Spline.ComputedSpline,
						PointIndex-1, 1.0,
					);
				}
				else
				{
					PointTransform = SplineComputation::GetRelativeTransformAtSegmentAlpha(
						Spline.ComputedSpline,
						PointIndex, 0.0,
					);
				}

				FVector PointPos = Transform.TransformPosition(PointTransform.Location);

				FVector Offset = PointTransform.Rotation.RightVector * PointTransform.Scale3D.Y * Spline.EditingSettings.VisualizeScale;
				FVector WorldOffset = Transform.TransformVector(Offset);
				FVector LeftSide = Transform.TransformPosition(PointTransform.Location - Offset);
				FVector RightSide = Transform.TransformPosition(PointTransform.Location + Offset);

				FVector VerticalOffset = PointTransform.Rotation.UpVector * PointTransform.Scale3D.Z * Spline.EditingSettings.VisualizeScale;
				FVector WorldVerticalOffset = Transform.TransformVector(VerticalOffset);
				FVector UpPoint = Transform.TransformPosition(PointTransform.Location + VerticalOffset);

				DrawLine(
					PointPos,
					LeftSide,
					Spline.EditingSettings.SplineColor,
					1.0, true
				);

				DrawLine(
					PointPos,
					RightSide,
					Spline.EditingSettings.SplineColor,
					1.0, true
				);

				DrawLine(
					PointPos,
					UpPoint,
					Spline.EditingSettings.SplineColor,
					1.0, true
				);

				const int32 ArcPoints = 20;
				FVector OldArcPos = RightSide;
				for (int32 ArcIndex = 1; ArcIndex <= ArcPoints; ArcIndex++)
				{
					float Sin = 0.0;
					float Cos = 0.0;
					Math::SinCos(Sin, Cos, ArcIndex * PI / ArcPoints);

					FVector NewArcPos = PointPos + WorldOffset * Cos + WorldVerticalOffset * Sin;
					DrawLine(OldArcPos, NewArcPos, Spline.EditingSettings.SplineColor, 1.0, true);
					OldArcPos = NewArcPos;
				}
			}
		}

		// Draw spline segments
		for (int SegmentIndex = 0; SegmentIndex < SegmentCount; ++SegmentIndex)
		{
			const FHazeComputedSplineSegment& Segment = Spline.ComputedSpline.Segments[SegmentIndex];

			FName SegmentProxy = n"SplineSegment";
			SegmentProxy.SetNumber(SegmentIndex);

			int EndSampleIndex = Segment.StartSampleIndex + Segment.SampleCount - 1;
			int LastSampleIndex = Math::Min(EndSampleIndex, SampleCount-1);
			for (int SampleIndex = Segment.StartSampleIndex; SampleIndex < EndSampleIndex; SampleIndex += SampleStride)
			{
				int RightIndex = Math::Min(SampleIndex+SampleStride, LastSampleIndex);

				FVector LeftPosition = Transform.TransformPosition(SplineComputation::GetRelativeLocationAtSegmentAlpha(
					Spline.ComputedSpline,
					Spline.ComputedSpline.Samples_SegmentIndex[SampleIndex],
					Spline.ComputedSpline.Samples_SegmentAlpha[SampleIndex],
				));

				FVector RightPosition = Transform.TransformPosition(SplineComputation::GetRelativeLocationAtSegmentAlpha(
					Spline.ComputedSpline,
					Spline.ComputedSpline.Samples_SegmentIndex[RightIndex],
					Spline.ComputedSpline.Samples_SegmentAlpha[RightIndex],
				));

				// Draw the height indicator line
				if (Spline.EditingSettings.HeightIndicators >= ESplineHeightIndicatorMode::WholeSplineToLowest)
				{
					// Subsample the height lines if the segment has a low amount of samples
					// This can happen if this is a straight line segment
					if (Segment.SampleCount <= 2)
					{
						int SubsampleCount = Math::FloorToInt((Segment.EndSplineDistance - Segment.StartSplineDistance) / Spline.SplineSettings.TargetSampleInterval);
						SubsampleCount = Math::Clamp(SubsampleCount, Spline.SplineSettings.MinSamplesPerSegment, 100);

						FVector PointSplinePlanePosition = LeftPosition;
						PointSplinePlanePosition.Z = SplinePlaneHeight;

						FVector SubsampleDelta = (RightPosition - LeftPosition) / SubsampleCount;
						SetRenderForeground(false);

						for (int Subsample = 1; Subsample < SubsampleCount; ++Subsample)
						{
							DrawLine(
								LeftPosition + (SubsampleDelta * Subsample),
								PointSplinePlanePosition + (SubsampleDelta * Subsample),
								FLinearColor(0.1, 0.1, 0.1, 1.0),
								1.0, true
							);
						}

						SetRenderForeground(true);
					}
					else if (Spline.ComputedSpline.Samples_SegmentAlpha[SampleIndex] != 1.f)
					{
						if (!Math::IsNearlyEqual(LeftPosition.Z, SplinePlaneHeight, 1.0))
						{
							FVector PointSplinePlanePosition = LeftPosition;
							PointSplinePlanePosition.Z = SplinePlaneHeight;
							SetRenderForeground(false);
							DrawLine(
								LeftPosition,
								PointSplinePlanePosition,
								FLinearColor(0.1, 0.1, 0.1, 1.0),
								1.0, true
							);
							SetRenderForeground(true);
						}
					}
				}

				// Draw the actual spline line
				SetHitProxy(SegmentProxy, EVisualizerCursor::GrabHand);
				DrawLine(
					LeftPosition,
					RightPosition,
					Spline.EditingSettings.SplineColor,
					5.0, true
				);
				ClearHitProxy();

				// Draw visualization for the roll in the spline if enabled
				if (Spline.EditingSettings.bEnableVisualizeRoll)
				{
					float LeftSampleSplineDistance = Spline.ComputedSpline.Samples_SplineAlpha[SampleIndex] * Spline.ComputedSpline.SplineLength;
					float RightSampleSplineDistance = Spline.ComputedSpline.Samples_SplineAlpha[RightIndex] * Spline.ComputedSpline.SplineLength;
					float CenterSplineDistance = (LeftSampleSplineDistance + RightSampleSplineDistance) * 0.5;

					FQuat CenterRotation = Transform.TransformRotation(SplineComputation::GetRelativeRotationAtSplineDistance(
						Spline.ComputedSpline,
						CenterSplineDistance,
					));
					FVector CenterPosition = Transform.TransformPosition(SplineComputation::GetRelativeLocationAtSplineDistance(
						Spline.ComputedSpline,
						CenterSplineDistance,
					));
					FVector CenterScale = SplineComputation::GetRelativeScale3DAtSplineDistance(
						Spline.ComputedSpline,
						CenterSplineDistance,
					);

					DrawLine(
						CenterPosition,
						CenterPosition + CenterRotation.UpVector * Spline.EditingSettings.VisualizeRoll * CenterScale.Z,
						FLinearColor(0.1, 0.1, 1.1, 1.0),
						3.0, true
					);
				}
			}

			// Draw an arrow in the middle of the segment if we're visualizing direction
			if (Spline.EditingSettings.bVisualizeDirection)
			{
				float SegmentLength = Segment.EndSplineDistance - Segment.StartSplineDistance;
				FVector MiddlePosition = Spline.GetWorldLocationAtSplineDistance(
					Segment.StartSplineDistance + SegmentLength * 0.5,
				);

				float ArrowScale = 5.0 * (EditorViewLocation.Distance(MiddlePosition) / 400.0);

				FTransform BackwardTransform = Spline.GetWorldTransformAtSplineDistance(
					Segment.StartSplineDistance + SegmentLength * 0.5 - Math::Min(SegmentLength * 0.25, 1.2 * ArrowScale),
				);
				FVector RightVector = BackwardTransform.Rotation.RightVector;

				DrawLine(
					MiddlePosition,
					BackwardTransform.Location + RightVector * ArrowScale,
					Spline.EditingSettings.SplineColor,
					6.0, true
				);

				DrawLine(
					MiddlePosition,
					BackwardTransform.Location - RightVector * ArrowScale,
					Spline.EditingSettings.SplineColor,
					6.0, true
				);
			}
		}

		// Draw a slowly moving roll indicator when roll indicators are on
		if (Spline.EditingSettings.bEnableVisualizeRoll && !Selection.bIsDraggingWidget)
		{
			float SplineLength = Spline.GetSplineLength();
			float InterpSplinePosition = (Time::PlatformTimeSeconds * 100.0) % SplineLength;
			FQuat InterpRotation = Transform.TransformRotation(SplineComputation::GetRelativeRotationAtSplineDistance(
				Spline.ComputedSpline,
				InterpSplinePosition,
			));
			FVector InterpLocation = Transform.TransformPosition(SplineComputation::GetRelativeLocationAtSplineDistance(
				Spline.ComputedSpline,
				InterpSplinePosition,
			));
			FVector InterpScale = SplineComputation::GetRelativeScale3DAtSplineDistance(
				Spline.ComputedSpline,
				InterpSplinePosition,
			);

			DrawLine(
				InterpLocation,
				InterpLocation + InterpRotation.UpVector * Spline.EditingSettings.VisualizeRoll * InterpScale.Z,
				FLinearColor(0.0, 1.0, 1.0, 1.0),
				10.0, true
			);
		}

		// Draw spline points
		for (int i = 0, Count = Spline.SplinePoints.Num(); i < Count; ++i)
		{
			const FHazeSplinePoint& Point = Spline.SplinePoints[i];

			FName PointProxy = n"SplinePoint";
			PointProxy.SetNumber(i);

			FVector PointPosition = Transform.TransformPosition(Point.RelativeLocation);
			float PointScale = 0.1 * (EditorViewLocation.Distance(PointPosition) / 400.0);

			// Draw the height indicator line
			if (Spline.EditingSettings.HeightIndicators >= ESplineHeightIndicatorMode::SplinePointsToLowest)
			{
				if (!Math::IsNearlyEqual(PointPosition.Z, SplinePlaneHeight, 1.0))
				{
					FVector PointSplinePlanePosition = PointPosition;
					PointSplinePlanePosition.Z = SplinePlaneHeight;

					FVector AttachPosition = PointPosition;
					if (PointPosition.Z > SplinePlaneHeight)
						AttachPosition.Z -= PointScale * 50.0;
					else
						AttachPosition.Z += PointScale * 50.0;

					SetRenderForeground(false);
					DrawLine(
						AttachPosition,
						PointSplinePlanePosition,
						FLinearColor(0.1, 0.1, 0.1, 1.0),
						1.0, true
					);
					SetRenderForeground(true);
				}
			}

			// Draw the spline point sphere
			UMaterialInterface PointMaterial = nullptr;
			if (Spline.EditingSettings.bAllowEditing)
			{
				if (Selection.IsPointSelected(i) && bEditingThisSpline)
				{
					PointMaterial = Mat_SelectedPoint;
					PointScale *= 1.1;

					if (i >= HoveredStart && i < HoveredEnd)
						PointMaterial = Mat_SelectedHoveredPoint;
				}
				else
				{
					if (i >= HoveredStart && i < HoveredEnd)
						PointMaterial = Mat_HoveredPoint;
				}
			}

			bool bCanMoveSelected = Selection.GetFirstPointIndex() == i && bEditingThisSpline && !Selection.IsTangentSelected();
			if (bCanMoveSelected)
				SetGizmoWidgetHitProxy();
			else
				SetHitProxy(PointProxy);
			DrawMeshWithMaterial(
				Mesh_SplinePoint,
				PointMaterial,
				PointPosition,
				FQuat::Identity,
				FVector(PointScale, PointScale, PointScale),
			);
			ClearHitProxy();

			bool bIsOverlappingSplinePoint = false;
			if (i > 0 && Point.RelativeLocation.Equals(Spline.SplinePoints[i - 1].RelativeLocation))
				bIsOverlappingSplinePoint = true;
			if (i < Count-1 && Point.RelativeLocation.Equals(Spline.SplinePoints[i + 1].RelativeLocation))
				bIsOverlappingSplinePoint = true;

			if (bIsOverlappingSplinePoint && !Selection.bIsDraggingWidget)
			{
				DrawWorldString(
					f"SPLINE POINT OVERLAP",
					PointPosition + FVector(0, 0, 10),
					FLinearColor::Red,
					bCenterText = true);
				DrawLine(
					PointPosition + FVector(-50, 0, 50),
					PointPosition + FVector(50, 0, -50),
					FLinearColor::Red, 5.0);
				DrawLine(
					PointPosition + FVector(50, 0, 50),
					PointPosition + FVector(-50, 0, -50),
					FLinearColor::Red, 5.0);
			}
		}
	}

	void DrawSplineConnection(UHazeSplineComponent Spline, float FromDistance, FLinearColor Color, float Interval, FSpecifiedSplineConnection Spec)
	{
		AActor ConnectActor = Spec.ConnectTo.Get();
		if (ConnectActor == nullptr)
			return;

		UHazeSplineComponent OtherSpline = UHazeSplineComponent::Get(ConnectActor);
		if (OtherSpline == nullptr)
			return;

		float TargetDistance = 0.0;
		switch (Spec.ConnectType)
		{
			case ESpecifiedSplineConnectionType::ConnectToStartOfTarget:
				TargetDistance = 0.0;
			break;
			case ESpecifiedSplineConnectionType::ConnectToEndOfTarget:
				TargetDistance = OtherSpline.GetSplineLength();
			break;
			case ESpecifiedSplineConnectionType::ConnectToClosestPointOnTarget:
				TargetDistance = OtherSpline.GetClosestSplineDistanceToWorldLocation(
					Spline.GetWorldLocationAtSplineDistance(FromDistance)
				);
			break;
			case ESpecifiedSplineConnectionType::ConnectToSpecifiedDistanceOnTarget:
				TargetDistance = Math::Clamp(Spec.DistanceOnTargetSpline, 0.0, OtherSpline.GetSplineLength());
			break;
		}

		DrawDashedLine(
			Spline.GetWorldLocationAtSplineDistance(FromDistance),
			OtherSpline.GetWorldLocationAtSplineDistance(TargetDistance),
			Color,
			Interval, 2.0, true
		);
	}

	UFUNCTION(BlueprintOverride)
	bool GetWidgetLocation(FVector& OutLocation) const
	{
		UHazeSplineComponent Spline = Cast<UHazeSplineComponent>(EditingComponent);
		if (Spline == nullptr)
		{
			// Try to find the spline component that is selected, since we might not have visualized yet this frame
			auto Components = Editor::GetSelectedComponents();
			if (Components.Num() == 1)
				Spline = Cast<UHazeSplineComponent>(Components[0]);
		}

		if (Spline == nullptr)
			return false;
		if (!Spline.EditingSettings.bAllowEditing)
			return false;

		if (Selection.Type == ESplineEditorSelection::Point)
		{
			if (!Spline.SplinePoints.IsValidIndex(Selection.PointIndex))
				return false;
			const FHazeSplinePoint& Point = Spline.SplinePoints[Selection.PointIndex];
			OutLocation = Spline.WorldTransform.TransformPosition(Point.RelativeLocation);
			return true;
		}
		else if (Selection.Type == ESplineEditorSelection::ArriveTangent)
		{
			if (!Spline.SplinePoints.IsValidIndex(Selection.PointIndex))
				return false;
			const FHazeComputedSplinePoint& ComputedPoint = Spline.ComputedSpline.Points[Selection.PointIndex];
			OutLocation = Spline.WorldTransform.TransformPosition(ComputedPoint.RelativeLocation - ComputedPoint.ArriveTangent);
			return true;
		}
		else if (Selection.Type == ESplineEditorSelection::LeaveTangent)
		{
			if (!Spline.SplinePoints.IsValidIndex(Selection.PointIndex))
				return false;
			const FHazeComputedSplinePoint& ComputedPoint = Spline.ComputedSpline.Points[Selection.PointIndex];
			OutLocation = Spline.WorldTransform.TransformPosition(ComputedPoint.RelativeLocation + ComputedPoint.LeaveTangent);
			return true;
		}
		else if (Selection.Type == ESplineEditorSelection::Multiple)
		{
			if (Selection.IsEmpty())
				return false;

			const FHazeComputedSplinePoint& ComputedPoint = Spline.ComputedSpline.Points[Selection.MultiplePoints[0]];
			OutLocation = Spline.WorldTransform.TransformPosition(ComputedPoint.RelativeLocation);
			return true;
		}

		return false;
	}

	void ClearCachedRotationForWidget()
	{
		Selection.CachedPointIndexForRotation = -1;
	}

	UFUNCTION(BlueprintOverride)
	bool GetCustomInputCoordinateSystem(EVisualizerCoordinateSystem CoordSystem,
										EVisualizerWidgetMode WidgetMode, FTransform& OutTransform) const
	{
		UHazeSplineComponent Spline = Cast<UHazeSplineComponent>(EditingComponent);
		if (Spline == nullptr)
			return false;
		if (!Spline.EditingSettings.bAllowEditing)
			return false;

		if ((Selection.Type == ESplineEditorSelection::Point || Selection.Type == ESplineEditorSelection::Multiple)
			&& (CoordSystem == EVisualizerCoordinateSystem::Local || WidgetMode == EVisualizerWidgetMode::Rotate))
		{
			int PointIndex = Selection.GetLatestPointIndex();
			if (!Spline.SplinePoints.IsValidIndex(PointIndex))
				return false;

			if (Selection.CachedPointIndexForRotation != PointIndex || !Selection.bIsDraggingWidget)
			{
				const FHazeSplinePoint& Point = Spline.SplinePoints[PointIndex];
				const FHazeComputedSplinePoint& ComputedPoint = Spline.ComputedSpline.Points[PointIndex];

				int SegmentIndex = PointIndex;
				float SegmentAlpha = 0.0;
				if (PointIndex == Spline.SplinePoints.Num()-1)
				{
					SegmentIndex -= 1;
					SegmentAlpha = 1.0;
				}

				Selection.CachedRotationForWidget = SplineComputation::GetRelativeRotationAtSegmentAlpha(
					Spline.ComputedSpline, SegmentIndex, SegmentAlpha,
				);
				Selection.CachedPointIndexForRotation = PointIndex;
			}

			OutTransform = FTransform(
				Spline.WorldTransform.TransformRotation(
					Selection.CachedRotationForWidget
				)
			);
			return true;
		}

		return false;
	}

	void HandleDeltaOnPoint(int PointIndex, FVector& DeltaTranslate, FRotator& DeltaRotate, FVector& DeltaScale)
	{
		UHazeSplineComponent Spline = Cast<UHazeSplineComponent>(EditingComponent);
		if (Spline == nullptr)
			return;
		if (!Spline.EditingSettings.bAllowEditing)
			return;
		if (!Spline.SplinePoints.IsValidIndex(PointIndex))
			return;
		const FHazeComputedSplinePoint& ComputedPoint = Spline.ComputedSpline.Points[PointIndex];
		FHazeSplinePoint& Point = Spline.SplinePoints[PointIndex];

		// Apply Translation
		if (!DeltaTranslate.IsNearlyZero())
		{
			Point.RelativeLocation += Spline.WorldTransform.InverseTransformVector(DeltaTranslate);
			Selection.bIsDraggingWidget = true;
		}

		// Apply Rotation
		if (!DeltaRotate.IsNearlyZero())
		{
			Selection.bIsDraggingWidget = true;

			bool bOriginalOverride = Point.bOverrideTangent;
			if (!Point.bOverrideTangent)
			{
				Point.ArriveTangent = ComputedPoint.ArriveTangent;
				Point.LeaveTangent = ComputedPoint.LeaveTangent;
				Point.bOverrideTangent = true;
			}

			FVector NewLeaveTangent = Spline.WorldTransform.GetRotation().RotateVector(Point.LeaveTangent);
			NewLeaveTangent = DeltaRotate.RotateVector(NewLeaveTangent);
			NewLeaveTangent = Spline.WorldTransform.GetRotation().Inverse().RotateVector(NewLeaveTangent);
			Point.LeaveTangent = NewLeaveTangent;

			// Don't actually override the tangents if they didn't change
			// Can happen if we're rolling the point for example
			if (!bOriginalOverride)
			{
				if (Point.LeaveTangent.Equals(ComputedPoint.LeaveTangent, 0.01))
				{
					Point.bOverrideTangent = false;
				}
			}

			if (Point.bOverrideTangent)
			{
				if (Point.bDiscontinuousTangent)
				{
					FVector NewArriveTangent = Spline.WorldTransform.GetRotation().RotateVector(Point.ArriveTangent);
					NewArriveTangent = DeltaRotate.RotateVector(NewArriveTangent);
					NewArriveTangent = Spline.WorldTransform.GetRotation().Inverse().RotateVector(NewArriveTangent);
					Point.ArriveTangent = NewArriveTangent;
				}
				else
				{
					Point.ArriveTangent = NewLeaveTangent;
				}
			}

			int SegmentIndex = PointIndex;
			float SegmentAlpha = 0.0;
			if (PointIndex == Spline.SplinePoints.Num()-1)
			{
				SegmentIndex -= 1;
				SegmentAlpha = 1.0;
			}

			FQuat RealPointRotation = SplineComputation::GetRelativeRotationAtSegmentAlpha(Spline.ComputedSpline, SegmentIndex, SegmentAlpha);

			FQuat NewRot = Spline.WorldTransform.GetRotation() * RealPointRotation;
			NewRot = DeltaRotate.Quaternion() * NewRot;
			NewRot = Spline.WorldTransform.GetRotation().Inverse() * NewRot;
			Point.RelativeRotation = NewRot;

			ClearCachedRotationForWidget();
		}

		// Apply scale
		if (DeltaScale.X != 0.0)
		{
			Selection.bIsDraggingWidget = true;

			if (!Point.bOverrideTangent)
			{
				Point.ArriveTangent = ComputedPoint.ArriveTangent;
				Point.LeaveTangent = Point.ArriveTangent;
				Point.bOverrideTangent = true;
			}

			FVector NewTangent = Point.LeaveTangent * (1.0 + DeltaScale.X);
			Point.LeaveTangent = NewTangent;
			Point.ArriveTangent = NewTangent;
		}

		if (DeltaScale.Y != 0.0)
		{
			Selection.bIsDraggingWidget = true;

			if (Math::IsNearlyZero(Point.RelativeScale3D.Y))
				Point.RelativeScale3D.Y = 1.0;
			Point.RelativeScale3D.Y *= (1.0 + DeltaScale.Y);
		}

		if (DeltaScale.Z != 0.0)
		{
			Selection.bIsDraggingWidget = true;

			if (Math::IsNearlyZero(Point.RelativeScale3D.Z))
				Point.RelativeScale3D.Z = 1.0;
			Point.RelativeScale3D.Z *= (1.0 + DeltaScale.Z);
		}
	}

	UFUNCTION(BlueprintOverride)
	bool HandleInputDelta(FVector& DeltaTranslate, FRotator& DeltaRotate, FVector& DeltaScale)
	{
		UHazeSplineComponent Spline = Cast<UHazeSplineComponent>(EditingComponent);
		if (Spline == nullptr)
			return false;
		if (!Spline.EditingSettings.bAllowEditing)
			return false;

		if (Selection.Type == ESplineEditorSelection::Point || Selection.Type == ESplineEditorSelection::Multiple)
		{
			if (Selection.IsEmpty())
				return false;

			Spline.Modify();
			if (bAllowDuplication && IsAltPressed())
			{
				// Duplicate selected points first boefore 
				if (Selection.GetSelectedCount() == 1)
				{
					SwapDragWindowStart = Time::PlatformTimeSeconds;
					SwapDragBeforeIndex = Selection.GetLatestPointIndex();
					SwapDragAfterIndex = Selection.GetLatestPointIndex()+1;
					SwapDragTangent = Spline.ComputedSpline.Points[SwapDragBeforeIndex].LeaveTangent;
					SwapDragBasePoint = Spline.ComputedSpline.Points[SwapDragBeforeIndex].RelativeLocation;
				}

				SplineEditing::DuplicateSelectedPoints(Spline, Spline.WorldTransform.InverseTransformVector(DeltaTranslate));
				UpdateSpline();

				bAllowDuplication = false;
			}

			for (int Point : Selection.GetAllSelected())
				HandleDeltaOnPoint(Point, DeltaTranslate, DeltaRotate, DeltaScale);

			if (IsAltPressed() && SwapDragBeforeIndex != -1 && SwapDragWindowStart > Time::PlatformTimeSeconds - 0.5 && Selection.GetSelectedCount() == 1)
			{
				int CurrentPoint = Selection.GetLatestPointIndex();
				FVector NewPointLoc = Spline.ComputedSpline.Points[CurrentPoint].RelativeLocation;

				FVector Direction = NewPointLoc - SwapDragBasePoint;
				if(!Direction.IsNearlyZero() && !SwapDragTangent.IsNearlyZero())
				{
					float DirDot = Direction.GetSafeNormal().DotProduct(SwapDragTangent.GetSafeNormal());

					float DirDotThreshold = 0.0;

					if(CurrentPoint == 0)
					{
						// Bias back if first point
						DirDotThreshold = 0.3; 
					}
					else if(CurrentPoint == Spline.SplinePoints.Num() - 1)
					{
						// Bias forward if last point
						DirDotThreshold = -0.3;
					}

					const bool bShouldBeAfter = DirDot > DirDotThreshold;
					if (bShouldBeAfter)
					{
						if (CurrentPoint != SwapDragAfterIndex)
						{
							auto PointData = Spline.SplinePoints[CurrentPoint];
							Spline.SplinePoints.RemoveAt(CurrentPoint);
							Spline.SplinePoints.Insert(PointData, SwapDragAfterIndex);

							Selection.Modify();
							Selection.SelectPoint(SwapDragAfterIndex);
						}
					}
					else
					{
						if (CurrentPoint != SwapDragBeforeIndex)
						{
							auto PointData = Spline.SplinePoints[CurrentPoint];
							Spline.SplinePoints.RemoveAt(CurrentPoint);
							Spline.SplinePoints.Insert(PointData, SwapDragBeforeIndex);

							Selection.Modify();
							Selection.SelectPoint(SwapDragBeforeIndex);
						}
					}
				}
			}

			UpdateSpline();
			return true;
		}
		else if (Selection.Type == ESplineEditorSelection::ArriveTangent)
		{
			if (!Spline.SplinePoints.IsValidIndex(Selection.PointIndex))
				return false;
			Spline.Modify();
			const FHazeComputedSplinePoint& ComputedPoint = Spline.ComputedSpline.Points[Selection.PointIndex];
			FHazeSplinePoint& Point = Spline.SplinePoints[Selection.PointIndex];
			Point.ArriveTangent = ComputedPoint.ArriveTangent - Spline.WorldTransform.InverseTransformVector(DeltaTranslate);
			if (!Point.bDiscontinuousTangent)
				Point.LeaveTangent = Point.ArriveTangent;
			Point.bOverrideTangent = true;
			Selection.bIsDraggingWidget = true;
			UpdateSpline();
			return true;
		}
		else if (Selection.Type == ESplineEditorSelection::LeaveTangent)
		{
			if (!Spline.SplinePoints.IsValidIndex(Selection.PointIndex))
				return false;
			Spline.Modify();
			const FHazeComputedSplinePoint& ComputedPoint = Spline.ComputedSpline.Points[Selection.PointIndex];
			FHazeSplinePoint& Point = Spline.SplinePoints[Selection.PointIndex];
			Point.LeaveTangent = ComputedPoint.LeaveTangent + Spline.WorldTransform.InverseTransformVector(DeltaTranslate);
			if (!Point.bDiscontinuousTangent)
				Point.ArriveTangent = Point.LeaveTangent;
			Selection.bIsDraggingWidget = true;
			Point.bOverrideTangent = true;
			UpdateSpline();
			return true;
		}

		return false;
	}

	void SelectSplineComponentFromInteraction()
	{
		auto Spline = Cast<UHazeSplineComponent>(GetEditingComponent());
		if (Spline == nullptr)
			return;

		auto SelectedComponents = Editor::GetSelectedComponents();
		if (Spline.EditingSettings.bSelectSplineComponentWhileEditing || !Editor::IsSelected(Spline.Owner) || SelectedComponents.Num() != 0)
			Editor::SelectComponent(Spline, bActivateVisualizer = true);
		else
			Editor::ActivateVisualizer(Spline);
	}

	UFUNCTION(BlueprintOverride)
	bool VisProxyHandleClick(FName HitProxy, FVector ClickOrigin, FVector ClickDirection, FKey Key, EInputEvent Event)
	{
		auto Spline = Cast<UHazeSplineComponent>(GetEditingComponent());
		if (Spline == nullptr)
			return false;
		if (Key == EKeys::RightMouseButton)
		{
			LastRightClickPoint = -1;
			LastRightClickDistance = GetSplineDistanceForClickPosition(ClickOrigin, ClickDirection);
		}

		if (HitProxy.IsEqual(n"SelectSpline", bCompareNumber = false))
		{
			if (IsControlPressed())
				Editor::ToggleActorSelected(Spline.Owner);
			else
				Editor::SelectActor(Spline.Owner);
			return true;
		}
		else if (HitProxy.IsEqual(n"SelectSplinePoint", bCompareNumber = false))
		{
			if (IsControlPressed())
			{
				Editor::ToggleActorSelected(Spline.Owner);
				return true;
			}

			if (!Spline.EditingSettings.bAllowEditing)
			{
				Editor::SelectActor(Spline.Owner);
				return true;
			}

			if (Key == EKeys::RightMouseButton)
				LastRightClickPoint = HitProxy.GetNumber();

			// Clicked a spline point
			SelectSplineComponentFromInteraction();
			FScopedTransaction Transaction("Select Spline Point");
			SelectSplinePoint(HitProxy.GetNumber());
			return true;
		}
		else if (HitProxy.IsEqual(n"SplinePoint", bCompareNumber = false))
		{
			if (!Spline.EditingSettings.bAllowEditing)
				return true;

			if (Key == EKeys::RightMouseButton)
			{
				LastRightClickPoint = HitProxy.GetNumber();

				if (!Selection.IsPointSelected(LastRightClickPoint))
					Selection.SelectPoint(LastRightClickPoint);

				return true;
			}

			HandleSplinePointSelection(HitProxy.GetNumber());

			if (!Editor::IsComponentSelected(Spline))
				SelectSplineComponentFromInteraction();
			return true;
		}
		else if (HitProxy.IsEqual(n"ArriveTangentHandle", bCompareNumber = false))
		{
			if (!Spline.EditingSettings.bAllowEditing)
				return true;

			if (Key == EKeys::RightMouseButton)
				LastRightClickPoint = Selection.PointIndex;

			// Clicked a spline point
			FScopedTransaction Transaction("Select Arrive Tangent");
			SelectSplinePoint(Selection.PointIndex, ESplineEditorSelection::ArriveTangent);
			return true;
		}
		else if (HitProxy.IsEqual(n"LeaveTangentHandle", bCompareNumber = false))
		{
			if (!Spline.EditingSettings.bAllowEditing)
				return true;

			if (Key == EKeys::RightMouseButton)
				LastRightClickPoint = Selection.PointIndex;

			// Clicked a spline point
			FScopedTransaction Transaction("Select Leave Tangent");
			SelectSplinePoint(Selection.PointIndex, ESplineEditorSelection::LeaveTangent);
			return true;
		}
		else if (HitProxy.IsEqual(n"SplineSegment", bCompareNumber = false))
		{
			if (!Spline.EditingSettings.bAllowEditing)
				return true;

			if (IsControlPressed())
			{
				Editor::ToggleActorSelected(Spline.Owner);
				return true;
			}

			if (Event == EInputEvent::IE_DoubleClick && Key == EKeys::LeftMouseButton)
			{
				// Create a new spline point at the double-clicked position
				float Distance = GetSplineDistanceForClickPosition(ClickOrigin, ClickDirection);
				if (Distance == -1.0)
					return true;

				FSplineEditorTransaction Transaction(this, "Insert Spline Point");
				Spline.Modify();
				int NewPointIndex = SplineEditing::InsertPointAtDistance(Spline, Distance);
				if (NewPointIndex != -1)
					SelectSplinePoint(NewPointIndex);
				SelectSplineComponentFromInteraction();
				return true;
			}

			if (Event == EInputEvent::IE_Released && Key == EKeys::LeftMouseButton)
			{
				// Select the spline point closest to the distance we clicked
				float SplineClickedDistance = GetSplineDistanceForClickPosition(ClickOrigin, ClickDirection);

				int BestIndex = -1;
				float BestDistance = MAX_flt;
				for (int i = 0, Count = Spline.ComputedSpline.Points.Num(); i < Count; ++i)
				{
					const FHazeComputedSplinePoint& SplinePoint = Spline.ComputedSpline.Points[i];
					float Dist = Math::Abs(SplineClickedDistance - SplinePoint.SplineDistance);
					if (Dist < BestDistance)
					{
						BestIndex = i;
						BestDistance = Dist;
					}
				}

				if (BestIndex != -1)
				{
					HandleSplinePointSelection(BestIndex);
					SelectSplineComponentFromInteraction();
				}

				return true;
			}

			return true;
		}

		return false;
	}

	void HandleSplinePointSelection(int PointIndex)
	{
		// Clicked a spline point
		FScopedTransaction Transaction("Select Spline Point");
		if (IsControlPressed())
		{
			Selection.Modify();
			if (Selection.IsPointSelected(PointIndex))
				Selection.RemovePointFromSelection(PointIndex);
			else
				Selection.AddPointToSelection(PointIndex);
		}
		else if (IsShiftPressed())
		{
			Selection.Modify();
			if (Selection.IsEmpty())
			{
				Selection.AddPointToSelection(PointIndex);
			}
			else
			{
				int MaxSelected = Selection.GetMaxSelectedPoint();
				int MinSelected = Selection.GetMinSelectedPoint();

				int ClickedPoint = PointIndex;
				if (ClickedPoint < MaxSelected)
				{
					for (int i = ClickedPoint; i < MaxSelected; ++i)
						Selection.AddPointToSelection(i);
				}
				else
				{
					for (int i = MinSelected+1; i <= ClickedPoint; ++i)
						Selection.AddPointToSelection(i);
				}
			}
		}
		else
		{
			SelectSplinePoint(PointIndex);
		}
	}

	UFUNCTION(BlueprintOverride)
	bool HandleInputKey(FKey Key, EInputEvent Event)
	{
		auto Spline = Cast<UHazeSplineComponent>(GetEditingComponent());
		if (Spline == nullptr)
			return false;
		if (!Spline.EditingSettings.bAllowEditing)
			return false;

		if (Event == EInputEvent::IE_Pressed)
		{
			if (Key == EKeys::Delete)
			{
				if (Selection.Type == ESplineEditorSelection::Multiple)
				{
					FSplineEditorTransaction Transaction(this, "Delete Spline Points");

					Selection.MultiplePoints.Sort();
					for (int i = 0, Count = Selection.MultiplePoints.Num(); i < Count; ++i)
						SplineEditing::DeleteSplinePoint(Spline, Selection.MultiplePoints[i] - i);
					SelectSplinePoint(Math::Min(Selection.MultiplePoints.Last(), Spline.SplinePoints.Num() - 1));

					return true;
				}
				else if (Selection.PointIndex != -1)
				{
					if (Selection.Type == ESplineEditorSelection::Point)
					{
						FSplineEditorTransaction Transaction(this, "Delete Spline Point");
						SplineEditing::DeleteSplinePoint(Spline, Selection.PointIndex);
						SelectSplinePoint(Math::Min(Selection.PointIndex, Spline.SplinePoints.Num() - 1));
					}
					else if (Selection.Type == ESplineEditorSelection::ArriveTangent
							|| Selection.Type == ESplineEditorSelection::LeaveTangent)
					{
						FHazeSplinePoint& Point = Spline.SplinePoints[Selection.PointIndex];
						if (Point.bOverrideTangent)
						{
							FSplineEditorTransaction Transaction(this, "Delete Spline Tangents");
							Point.bOverrideTangent = false;
							Point.ArriveTangent = FVector::ZeroVector;
							Point.LeaveTangent = FVector::ZeroVector;
						}
					}

					return true;
				}

				return false;
			}
			else if (Key == EKeys::X && IsControlPressed())
			{
				if (!Selection.IsEmpty())
				{
					FSplineEditorTransaction Transaction(this, "Delete Spline Points");
					SplineEditing::CopySelectedPoints(Spline);
					SplineEditing::DeleteSelectedPoints(Spline);
					return true;
				}
				return false;
			}
			else if (Key == EKeys::C && IsControlPressed())
			{
				if (!Selection.IsEmpty())
				{
					SplineEditing::CopySelectedPoints(Spline);
					return true;
				}
				return false;
			}
			else if (Key == EKeys::V && IsControlPressed())
			{
				if (!Selection.IsEmpty())
				{
					FSplineEditorTransaction Transaction(this, "Paste Spline Points");
					SplineEditing::PasteSplinePoints(Spline, true, false);
					return true;
				}
				return false;
			}
			else if (Key == EKeys::V && IsShiftPressed())
			{
				// Move the spline point to the location under the cursor with Shift+V
				if (!Selection.IsEmpty())
				{
					FVector Location;
					FQuat Rotation;
					if (LevelEditor::GetActorPlacementPositionAtCursor(Location, Rotation))
					{
						FSplineEditorTransaction Transaction(this, "Move Spline Point to Cursor");

						FHazeSplinePoint& Point = Spline.SplinePoints[Selection.GetLatestPointIndex()];
						Point.RelativeLocation = Spline.WorldTransform.InverseTransformPosition(Location);
					}
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
				SwapDragWindowStart = 0.0;
				SwapDragBeforeIndex = -1;
				SwapDragAfterIndex = -1;
				ClearCachedRotationForWidget();

				if (Selection.bIsDraggingWidget)
				{
					Selection.bIsDraggingWidget = false;
					if (Editor::IsComponentSelected(Spline))
					{
						Spline.Owner.RerunConstructionScripts();
						Spline.UpdateSpline();
					}
				}
			}
		}

		// Navigate to previous/next spline point with Ctrl+Left/Right
		if (Event == EInputEvent::IE_Pressed || Event == EInputEvent::IE_Repeat)
		{
			if (Key == EKeys::Left && IsControlPressed())
			{
				if (Selection.GetMinSelectedPoint() != -1)
				{
					FScopedTransaction Transaction("Select Spline Point");
					SelectSplinePoint(Math::WrapIndex(Selection.GetMinSelectedPoint() - 1, 0, Spline.SplinePoints.Num()));
					return true;
				}
			}
			else if (Key == EKeys::Right && IsControlPressed())
			{
				if (Selection.GetMaxSelectedPoint() != -1)
				{
					FScopedTransaction Transaction("Select Spline Point");
					SelectSplinePoint(Math::WrapIndex(Selection.GetMaxSelectedPoint() + 1, 0, Spline.SplinePoints.Num()));
					return true;
				}
			}
		}

		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool HandleBoxSelect(FBox InBox)
	{
		auto Spline = Cast<UHazeSplineComponent>(GetEditingComponent());
		if (Spline == nullptr)
			return false;

		FScopedTransaction Transaction("Select Spline Points");
		Selection.Modify();
		Selection.Clear();

		FTransform Transform = Spline.WorldTransform;
		for (int PointIndex = 0, PointCount = Spline.SplinePoints.Num(); PointIndex < PointCount; ++PointIndex)
		{
			FVector WorldLocation = Transform.TransformPosition(Spline.SplinePoints[PointIndex].RelativeLocation);
			if (InBox.IsInsideOrOn(WorldLocation))
				Selection.AddPointToSelection(PointIndex);
		}

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool HandleFrustumSelect(FHazeEditorFrustum Frustum)
	{
		auto Spline = Cast<UHazeSplineComponent>(GetEditingComponent());
		if (Spline == nullptr)
			return false;

		FScopedTransaction Transaction("Select Spline Points");
		Selection.Modify();
		Selection.Clear();

		FTransform Transform = Spline.WorldTransform;
		for (int PointIndex = 0, PointCount = Spline.SplinePoints.Num(); PointIndex < PointCount; ++PointIndex)
		{
			FVector WorldLocation = Transform.TransformPosition(Spline.SplinePoints[PointIndex].RelativeLocation);
			if (Frustum.ContainsPoint(WorldLocation))
				Selection.AddPointToSelection(PointIndex);
		}

		return true;
	}

	UFUNCTION(BlueprintOverride)
	void EndEditing()
	{
		if (Editor::IsTransacting())
		{
			auto Spline = Cast<UHazeSplineComponent>(GetEditingComponent());
			if (Spline != nullptr && IsValid(Spline))
			{
				if (Selection.GetSelectedCount() != 0 && Editor::IsComponentSelected(Spline))
				{
					Editor::ActivateVisualizer(Spline);
				}
			}
		}
		else
		{
			auto Spline = Cast<UHazeSplineComponent>(GetEditingComponent());
			if (Spline == nullptr || !Editor::IsComponentSelected(Spline))
				Selection.Clear();
		}
	}

	void SelectSplinePoint(int SplinePoint, ESplineEditorSelection Type = ESplineEditorSelection::Point)
	{
		Selection.Modify();
		Selection.SelectPoint(SplinePoint, Type);
	}

	float GetSplineDistanceForClickPosition(FVector ClickOrigin, FVector ClickDirection)
	{
		auto Spline = Cast<UHazeSplineComponent>(GetEditingComponent());
		if (Spline == nullptr)
			return -1.0;

		FVector TraceEnd = ClickOrigin + ClickDirection * 10000.0;

		FVector BestPoint;
		float BestSplineDistance = -1.0;
		float BestDistance = MAX_flt;

		// Check each sample segment and get the closest spline distance
		for (int i = 0, Count = Spline.ComputedSpline.Samples_SplineAlpha.Num() - 1; i < Count; ++i)
		{
			float LeftSampleSplineDistance = Spline.ComputedSpline.Samples_SplineAlpha[i] * Spline.ComputedSpline.SplineLength;
			float RightSampleSplineDistance = Spline.ComputedSpline.Samples_SplineAlpha[i+1] * Spline.ComputedSpline.SplineLength;

			FVector LeftLocation = Spline.GetWorldLocationAtSplineDistance(LeftSampleSplineDistance);
			FVector RightLocation = Spline.GetWorldLocationAtSplineDistance(RightSampleSplineDistance);

			FVector PlaneForward = (RightLocation - LeftLocation).GetSafeNormal();
			FVector PlaneRight = PlaneForward.CrossProduct(FVector::UpVector);
			FVector PlaneNormal = PlaneRight.CrossProduct(PlaneForward);

			if (PlaneNormal.IsNearlyZero())
				continue;

			// Project from the cursor trace onto the plane described by the spline sample segment
			FVector PointOnPlane = Math::LinePlaneIntersection(ClickOrigin, TraceEnd, LeftLocation, PlaneNormal);

			// Find the closest point on the sample line from here
			FVector ClosestOnLine = Math::ClosestPointOnLine(LeftLocation, RightLocation, PointOnPlane);

			float Distance = ClosestOnLine.Distance(PointOnPlane);
			if (Distance < BestDistance)
			{
				BestDistance = Distance;
				BestPoint = ClosestOnLine;

				float SampleAlpha = (ClosestOnLine - LeftLocation).Size() / (RightLocation - LeftLocation).Size();
				BestSplineDistance = LeftSampleSplineDistance + SampleAlpha * (RightSampleSplineDistance - LeftSampleSplineDistance);
			}
		}

		return BestSplineDistance;
	}

	void UpdateSpline()
	{
		auto Spline = Cast<UHazeSplineComponent>(GetEditingComponent());
		if (Spline == nullptr)
			return;

		NotifyPropertyModified(Spline, n"SplinePoints");
		Spline.UpdateSpline();
		Editor::RedrawAllViewports();
	}

	bool DoesTangentOverlapWithPoint(FVector TangentLocation)
	{
		auto Spline = Cast<UHazeSplineComponent>(GetEditingComponent());
		if (Spline == nullptr)
			return false;

		FVector TangentRelative = Spline.WorldTransform.InverseTransformPosition(TangentLocation);
		for (const auto& Point : Spline.SplinePoints)
		{
			if (Point.RelativeLocation.PointsAreNear(TangentRelative, 0.5))
				return true;
		}
		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool GenerateContextMenu(FHazeContextMenu& Menu)
	{
		auto Spline = Cast<UHazeSplineComponent>(GetEditingComponent());
		if (Spline == nullptr)
			return false;

		auto ContextMenu = SplineContextMenu::GetSingleton();
		ContextMenu.GenerateContextMenu(Menu, Spline, Selection, LastRightClickPoint, LastRightClickDistance);
		return true;
	}
};

struct FSplineEditorTransaction
{
	UHazeSplineEditor Editor;
	UHazeSplineComponent Spline;

	FSplineEditorTransaction(UHazeSplineEditor InEditor, FString TransactionName)
	{
		Editor = InEditor;
		Spline = Cast<UHazeSplineComponent>(Editor.GetEditingComponent());
		Editor::BeginTransaction(TransactionName);
		Spline.Modify();
	}

	~FSplineEditorTransaction()
	{
		if (Editor == nullptr)
			return;
		Editor.NotifyPropertyModified(Spline, n"SplinePoints");
		if (Spline.Owner != nullptr)
			Spline.Owner.RerunConstructionScripts();
		Spline.UpdateSpline();
		Editor::EndTransaction();
		Editor::RedrawAllViewports();
	}
};