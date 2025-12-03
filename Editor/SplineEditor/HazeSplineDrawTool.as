class UHazeSplineDrawPropertySet : UScriptableInteractiveToolPropertySet
{
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Draw Spline")
	TWeakObjectPtr<AActor> ExistingActor;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Draw Spline")
	float MinPointSpacing = 200.0;

	/* Whether spline lines should always be drawn with straight tangents. */
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Draw Spline")
	bool bDrawStraightLines = false;

	/* Automatically detect the closest end of the spline to draw from. If false, only draw from the end of the spline, never the start. */
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Draw Spline")
	bool bDrawFromClosestEnd = true;

	/* Whether to orient the spline points so their up vector points away from the surface. */
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Draw Spline")
	bool bPointSplinePointsAwayFromSurface = true;

	/* If true, moving points with Shift will move along the surface. Otherwise, the point will stay at its original height. */
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Move Points")
	bool bMovePointsAlongSurface = true;

	/* Whether to trace to the world and use it as a surface for drawing. */
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Surface")
	bool bTraceToWorldSurface = true;

	/* Use the height of the previous spline point as a surface for drawing. */
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Surface")
	bool bSplineHeightSurface = false;

	/* Specify a custom plane in the world to use as a surface for drawing. */
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Surface")
	bool bCustomPlaneSurface = false;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Surface", Meta = (EditCondition = "bCustomPlaneSurface", EditConditionHides))
	FVector CustomPlaneOrigin;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Surface", Meta = (EditCondition = "bCustomPlaneSurface", EditConditionHides))
	FRotator CustomPlaneRotation;

	const float EraseRange = 100.0;
	const float MoveRange = 100.0;

	UFUNCTION(CallInEditor, Category = "Tools")
	void ClearSpline()
	{
		Editor::BeginTransaction("Clear Spline");

		auto Spline = UHazeSplineComponent::Get(ExistingActor);
		if (Spline != nullptr)
			Spline.SplinePoints.Reset();

		Spline.UpdateSpline();
		Editor::NotifyPropertyModified(Spline, n"SplinePoints");
		Editor::EndTransaction();
	}

	UFUNCTION(CallInEditor, Category = "Tools")
	void CreateNewSplineActor()
	{
		Editor::BeginTransaction("Create New Spline Actor");
		auto SplineActor = ASplineActor::Spawn();
		SplineActor.Spline.SplinePoints.Reset();
		ExistingActor = SplineActor;
		Editor::SelectActor(SplineActor);
		Editor::EndTransaction();
	}
}

class UHazeSplineDrawTool : UEditorScriptableClickDragTool
{
	default ToolCategory = FText::FromString("Splines");
	default ToolName = FText::FromString("Draw");
	default ToolLongName = FText::FromString("Draw Spline");
	default CustomIconPath = "Editor/Slate/MenuIcons/GeometryDrawSpline.svg";

	UHazeSplineDrawPropertySet Settings;
	UHazeSplineComponent Spline;

	TArray<FHazeSplinePoint> OriginalSplinePoints;

	bool bHasCustomPlaneGizmo = false;
	bool bIsDrawingReverse = false;
	bool bIsErasing = false;
	bool bIsMoving = false;
	bool bHasMovedVertically = false;
	int MovingPoint = -1;

	UFUNCTION(BlueprintOverride)
	void OnScriptSetup()
	{
		EToolsFrameworkOutcomePins Outcome;
		Settings = Cast<UHazeSplineDrawPropertySet>(AddPropertySetOfType(UHazeSplineDrawPropertySet, "Settings", Outcome));
		RestorePropertySetSettings(Settings, "DrawSpline");

		TArray<AActor> Selection = Editor::GetSelectedActors();
		if (Selection.Num() != 0)
		{
			if (UHazeSplineComponent::Get(Selection[0]) != nullptr)
				Settings.ExistingActor = Selection[0];
		}

		if (!Settings.bCustomPlaneSurface && Settings.ExistingActor.IsValid())
		{
			auto SelectedSpline = UHazeSplineComponent::Get(Settings.ExistingActor.Get());
			if (SelectedSpline != nullptr)
				Settings.CustomPlaneOrigin = SelectedSpline.WorldLocation;
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnScriptRender(UScriptableTool_RenderAPI RenderAPI)
	{
		if (Settings.bCustomPlaneSurface)
		{
			FTransform PlaneTransform(Settings.CustomPlaneRotation, Settings.CustomPlaneOrigin);
			RenderAPI.DrawRectWidthHeightXY(PlaneTransform, 250, 250, FLinearColor::Red);
			RenderAPI.DrawRectWidthHeightXY(PlaneTransform, 500, 500, FLinearColor::Red);
			RenderAPI.DrawRectWidthHeightXY(PlaneTransform, 1000, 1000, FLinearColor::Red);
			RenderAPI.DrawRectWidthHeightXY(PlaneTransform, 2000, 2000, FLinearColor::Red);
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnScriptShutdown(EToolShutdownType ShutdownType)
	{
		if (bHasCustomPlaneGizmo)
		{
			EToolsFrameworkOutcomePins Outcome;
			DestroyTRSGizmo("CustomPlane", Outcome);
		}

		SavePropertySetSettings(Settings, "DrawSpline");
		if (GetGlobalSplineSelection().bSplineDrawWasTemporary)
		{
			GetGlobalSplineSelection().bSplineDrawWasTemporary = false;
			Blutility::ActivateSelectionMode();
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnGizmoTransformChanged(FString GizmoIdentifier, FTransform NewTransform)
	{
		if (GizmoIdentifier == "CustomPlane")
		{
			Settings.CustomPlaneOrigin = NewTransform.Location;
			Settings.CustomPlaneRotation = NewTransform.Rotator();
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnScriptTick(float DeltaTime)
	{
		UHazeSplineComponent SelectedSpline;
		if (Settings.ExistingActor != nullptr)
			SelectedSpline = UHazeSplineComponent::Get(Settings.ExistingActor);
		if (Spline != SelectedSpline)
		{
			if (Spline != nullptr)
				OriginalSplinePoints = Spline.SplinePoints;
			Spline = SelectedSpline;
			if (!Editor::IsSelected(Spline.Owner))
				Editor::SelectActor(Spline.Owner);
		}

		if (Settings.bCustomPlaneSurface)
		{
			if (!bHasCustomPlaneGizmo)
			{
				EToolsFrameworkOutcomePins Outcome;
				FScriptableToolGizmoOptions GizmoOptions;
				CreateTRSGizmo(
					"CustomPlane",
					FTransform(Settings.CustomPlaneRotation, Settings.CustomPlaneOrigin),
					GizmoOptions, Outcome);
				bHasCustomPlaneGizmo = true;
			}
		}
		else
		{
			if (bHasCustomPlaneGizmo)
			{
				EToolsFrameworkOutcomePins Outcome;
				DestroyTRSGizmo("CustomPlane", Outcome);
				bHasCustomPlaneGizmo = false;
			}
		}
	}

	void TraceTargetPosition(FRay Ray, FVector LastPosition, FVector& OutLocation, FVector& OutNormal)
	{
		FVector CandidatePoint;
		FVector CandidateNormal;
		float CandidateDistance = BIG_NUMBER;
		bool bHaveCandidate = false;

		if (Settings.bTraceToWorldSurface)
		{
			FHazeTraceSettings Trace;
			Trace.TraceWithChannel(ECollisionChannel::ECC_Visibility);
			Trace.UseLine();
			Trace.IgnoreActor(Spline.Owner);

			FHitResult Hit = Trace.QueryTraceSingle(Ray.Origin, Ray.Origin + Ray.Direction * 1e5);
			if (Hit.bBlockingHit)
			{
				float Distance = Hit.ImpactPoint.Distance(Ray.Origin);
				if (Distance < CandidateDistance)
				{
					CandidateDistance = Distance;
					CandidatePoint = Hit.ImpactPoint;
					CandidateNormal = Hit.ImpactNormal;
					bHaveCandidate = true;
				}
			}
		}

		if (Settings.bSplineHeightSurface)
		{
			if (Spline != nullptr && Spline.SplinePoints.Num() != 0)
			{
				FVector SplinePoint;
				if (bIsMoving && MovingPoint != -1)
					SplinePoint = Spline.WorldTransform.TransformPosition(Spline.SplinePoints[MovingPoint].RelativeLocation);
				else if (bIsDrawingReverse)
					SplinePoint = Spline.WorldTransform.TransformPosition(Spline.SplinePoints[0].RelativeLocation);
				else
					SplinePoint = Spline.WorldTransform.TransformPosition(Spline.SplinePoints.Last().RelativeLocation);

				FVector Point = Math::RayPlaneIntersection(
					Ray.Origin, Ray.Direction,
					FPlane(SplinePoint, FVector::UpVector));

				float Distance = Point.Distance(Ray.Origin);
				if (Distance < CandidateDistance)
				{
					CandidateDistance = Distance;
					CandidatePoint = Point;
					CandidateNormal = FVector::ZeroVector;
					bHaveCandidate = true;
				}
			}
		}

		if (Settings.bCustomPlaneSurface)
		{
			FVector Point = Math::RayPlaneIntersection(
				Ray.Origin, Ray.Direction,
				FPlane(Settings.CustomPlaneOrigin, Settings.CustomPlaneRotation.UpVector));

			float Distance = Point.Distance(Ray.Origin);
			if (Distance < CandidateDistance)
			{
				CandidateDistance = Distance;
				CandidatePoint = Point;
				CandidateNormal = Settings.CustomPlaneRotation.UpVector;
				bHaveCandidate = true;
			}
		}

		if (bHaveCandidate)
		{
			OutLocation = CandidatePoint;
			OutNormal = CandidateNormal;
		}
		else
		{
			OutLocation = Math::LinePlaneIntersection(Ray.Origin, Ray.Origin + Ray.Direction, LastPosition, FVector::UpVector);
			OutNormal = FVector::UpVector;
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnDragBegin(FInputDeviceRay StartPosition, FScriptableToolModifierStates Modifiers)
	{
		if (Spline == nullptr)
			return;

		Editor::BeginTransaction("Draw Spline");
		GetGlobalSplineSelection().bIsDraggingWidget = true;

		if (Modifiers.bShiftDown)
		{
			bIsErasing = false;
			bIsMoving = true;
			if (Modifiers.bCtrlDown)
				bHasMovedVertically = true;
			else
				bHasMovedVertically = false;
			MovingPoint = -1;
		}
		else if (Modifiers.bCtrlDown)
		{
			bIsErasing = true;
			bIsMoving = false;
		}
		else
		{
			bIsErasing = false;
			bIsMoving = false;

			FVector TargetPoint;
			FVector TargetNormal;
			TraceTargetPosition(StartPosition.WorldRay, Spline.WorldLocation, TargetPoint, TargetNormal);

			float DistanceToStart = Spline.GetWorldLocationAtSplineFraction(0.0).Distance(TargetPoint);
			float DistanceToEnd = Spline.GetWorldLocationAtSplineFraction(1.0).Distance(TargetPoint);

			bIsDrawingReverse = Settings.bDrawFromClosestEnd && DistanceToStart < DistanceToEnd;
			TraceTargetPosition(StartPosition.WorldRay, Spline.WorldLocation, TargetPoint, TargetNormal);

			if (Modifiers.bAltDown || Spline.SplinePoints.Num() <= 1)
			{
				Spline.SplinePoints.Reset();
				Spline.Owner.SetActorLocation(TargetPoint);
			}

			FHazeSplinePoint SplinePoint;
			SplinePoint.RelativeLocation = Spline.WorldTransform.InverseTransformPosition(TargetPoint);

			if (!TargetNormal.IsNearlyZero() && Settings.bPointSplinePointsAwayFromSurface)
				SplinePoint.RelativeRotation = Spline.WorldTransform.InverseTransformRotation(FQuat::MakeFromZ(TargetNormal));

			if (bIsDrawingReverse)
				Spline.SplinePoints.Insert(SplinePoint, 0);
			else
				Spline.SplinePoints.Add(SplinePoint);

			// Duplicate the initial point if we didn't have any to start with
			if (Spline.SplinePoints.Num() < 2)
				Spline.SplinePoints.Add(SplinePoint);

			if (Settings.bDrawStraightLines)
			{
				if (bIsDrawingReverse)
				{
					SplineEditing::SetStraightTangentsOnPoint(Spline, 0);
					SplineEditing::SetStraightTangentsOnPoint(Spline, 1, bLeaveTangent = false);
				}
				else
				{
					SplineEditing::SetStraightTangentsOnPoint(Spline, Spline.SplinePoints.Num() - 1);
					SplineEditing::SetStraightTangentsOnPoint(Spline, Spline.SplinePoints.Num() - 2, bArriveTangent = false);
				}
			}

			Spline.UpdateSpline();
			Editor::NotifyPropertyModified(Spline, n"SplinePoints");
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnDragEnd(FInputDeviceRay EndPosition, FScriptableToolModifierStates Modifiers)
	{
		if (Spline == nullptr)
			return;

		Editor::EndTransaction();
		GetGlobalSplineSelection().bIsDraggingWidget = false;
	}

	UFUNCTION(BlueprintOverride)
	void OnDragUpdatePosition(FInputDeviceRay NewPosition, FScriptableToolModifierStates Modifiers)
	{
		if (Spline == nullptr)
			return;

		FTransform SplineTransform = Spline.WorldTransform;

		if (bIsErasing)
		{
			bool bAnyChange = false;
			for (int i = Spline.SplinePoints.Num() - 1; i >= 0; --i)
			{
				FHazeSplinePoint& Point = Spline.SplinePoints[i];
				FVector WorldPoint = SplineTransform.TransformPosition(Point.RelativeLocation);

				FVector ClosestOnLine = Math::ClosestPointOnInfiniteLine(
					NewPosition.WorldRay.Origin, NewPosition.WorldRay.Origin + NewPosition.WorldRay.Direction,
					WorldPoint);

				float DistanceToRay = ClosestOnLine.Distance(WorldPoint);
				if (DistanceToRay < Settings.EraseRange)
				{
					Spline.Modify();
					bAnyChange = true;

					Spline.SplinePoints.RemoveAt(i);

					if (Settings.bDrawStraightLines)
					{
						SplineEditing::SetStraightTangentsOnPoint(Spline, i-1, bArriveTangent = false);
						SplineEditing::SetStraightTangentsOnPoint(Spline, i, bLeaveTangent = false);
					}

					break;
				}
			}

			// Update the spline
			if (bAnyChange)
			{
				Spline.UpdateSpline();
				Editor::NotifyPropertyModified(Spline, n"SplinePoints");
			}
		}
		else if (bIsMoving)
		{
			if (MovingPoint == -1)
			{
				// Find the closest point we should be able to move. If one doesn't exist, insert a new point
				Spline.Modify();

				int ClosestPoint = -1;
				float ClosestDistance = Settings.MoveRange;

				for (int i = Spline.SplinePoints.Num() - 1; i >= 0; --i)
				{
					FHazeSplinePoint& Point = Spline.SplinePoints[i];
					FVector WorldPoint = SplineTransform.TransformPosition(Point.RelativeLocation);

					FVector ClosestOnLine = Math::ClosestPointOnInfiniteLine(
						NewPosition.WorldRay.Origin, NewPosition.WorldRay.Origin + NewPosition.WorldRay.Direction,
						WorldPoint);

					float DistanceToRay = ClosestOnLine.Distance(WorldPoint);
					if (DistanceToRay < ClosestDistance)
					{
						// Close enough to this point, drag it
						ClosestPoint = i;
						ClosestDistance = DistanceToRay;
						break;
					}
				}

				MovingPoint = ClosestPoint;
				if (MovingPoint == -1)
				{
					FSplinePosition ClosestOnSpline = Spline.GetClosestSplinePositionToLineSegment(
						NewPosition.WorldRay.Origin, NewPosition.WorldRay.Origin + NewPosition.WorldRay.Direction * 1e5,
						false
					);

					FVector ClosestOnLine = Math::ClosestPointOnInfiniteLine(
						NewPosition.WorldRay.Origin, NewPosition.WorldRay.Origin + NewPosition.WorldRay.Direction,
						ClosestOnSpline.WorldLocation);

					float DistanceToRay = ClosestOnLine.Distance(ClosestOnSpline.WorldLocation);
					if (DistanceToRay < Settings.MoveRange)
					{
						// We moved close to a segment, insert a new point here and move that
						MovingPoint = SplineEditing::InsertPointAtDistance(Spline, ClosestOnSpline.CurrentSplineDistance);
					}
				}
			}
			
			if (MovingPoint != -1)
			{
				// Drag around the point we're moving
				FHazeSplinePoint& CurrentPoint = Spline.SplinePoints[MovingPoint];

				FVector WorldTargetPoint;
				FVector WorldTargetNormal;
				if (Modifiers.bCtrlDown)
				{
					WorldTargetPoint = Math::RayPlaneIntersection(
						NewPosition.WorldRay.Origin, NewPosition.WorldRay.Direction,
						FPlane(SplineTransform.TransformPosition(CurrentPoint.RelativeLocation), NewPosition.WorldRay.Direction));
					WorldTargetNormal = FVector::ZeroVector;
					bHasMovedVertically = true;
				}
				else if (Settings.bMovePointsAlongSurface && !bHasMovedVertically)
				{
					TraceTargetPosition(
						NewPosition.WorldRay, SplineTransform.TransformPosition(CurrentPoint.RelativeLocation),
						WorldTargetPoint, WorldTargetNormal);
				}
				else
				{
					WorldTargetPoint = Math::RayPlaneIntersection(
						NewPosition.WorldRay.Origin, NewPosition.WorldRay.Direction,
						FPlane(SplineTransform.TransformPosition(CurrentPoint.RelativeLocation), FVector::UpVector));
					WorldTargetNormal = FVector::UpVector;
				}

				FVector LocalTargetPoint = SplineTransform.InverseTransformPosition(WorldTargetPoint);
				CurrentPoint.RelativeLocation = LocalTargetPoint;

				if (!WorldTargetNormal.IsNearlyZero() && Settings.bPointSplinePointsAwayFromSurface)
					CurrentPoint.RelativeRotation = SplineTransform.InverseTransformRotation(FQuat::MakeFromZ(WorldTargetNormal));
				else
					CurrentPoint.RelativeRotation = FQuat::Identity;

				if (Settings.bDrawStraightLines)
				{
					SplineEditing::SetStraightTangentsOnPoint(Spline, MovingPoint);
					SplineEditing::SetStraightTangentsOnPoint(Spline, MovingPoint-1, bArriveTangent = false);
					SplineEditing::SetStraightTangentsOnPoint(Spline, MovingPoint+1, bLeaveTangent = false);
				}

				// Update the spline
				Spline.UpdateSpline();
				Editor::NotifyPropertyModified(Spline, n"SplinePoints");
			}
		}
		else
		{
			Spline.Modify();

			FHazeSplinePoint& CurrentPoint = bIsDrawingReverse ? Spline.SplinePoints[0] : Spline.SplinePoints[Spline.SplinePoints.Num() - 1];
			FHazeSplinePoint& PreviousPoint = bIsDrawingReverse ? Spline.SplinePoints[1] : Spline.SplinePoints[Spline.SplinePoints.Num() - 2];

			FVector WorldTargetPoint;
			FVector WorldTargetNormal;
			TraceTargetPosition(NewPosition.WorldRay, SplineTransform.TransformPosition(CurrentPoint.RelativeLocation),
				WorldTargetPoint, WorldTargetNormal);

			FVector LocalTargetPoint = SplineTransform.InverseTransformPosition(WorldTargetPoint);
			FQuat LocalTargetRotation;

			if (!WorldTargetNormal.IsNearlyZero() && Settings.bPointSplinePointsAwayFromSurface)
				LocalTargetRotation = SplineTransform.InverseTransformRotation(FQuat::MakeFromZ(WorldTargetNormal));
			else
				LocalTargetRotation = FQuat::Identity;

			float DistanceFromPrevious = WorldTargetPoint.Distance(SplineTransform.TransformPosition(PreviousPoint.RelativeLocation));
			if (DistanceFromPrevious > Settings.MinPointSpacing && !Settings.bDrawStraightLines)
			{
				// If we've moved too far, create a new spline point
				FHazeSplinePoint NewPoint;
				NewPoint.RelativeLocation = LocalTargetPoint;
				CurrentPoint.RelativeRotation = LocalTargetRotation;

				if (bIsDrawingReverse)
					Spline.SplinePoints.Insert(NewPoint, 0);
				else
					Spline.SplinePoints.Add(NewPoint);
			}
			else
			{
				// Otherwise move the current spline point
				CurrentPoint.RelativeLocation = LocalTargetPoint;
				CurrentPoint.RelativeRotation = LocalTargetRotation;

				if (Settings.bDrawStraightLines)
				{
					if (bIsDrawingReverse)
					{
						if (Spline.SplineSettings.bClosedLoop)
							SplineEditing::SetStraightTangentsOnPoint(Spline, -1);
						SplineEditing::SetStraightTangentsOnPoint(Spline, 0);
						SplineEditing::SetStraightTangentsOnPoint(Spline, 1, bLeaveTangent = false);
					}
					else
					{
						if (Spline.SplineSettings.bClosedLoop)
							SplineEditing::SetStraightTangentsOnPoint(Spline, 0);
						SplineEditing::SetStraightTangentsOnPoint(Spline, Spline.SplinePoints.Num() - 1);
						SplineEditing::SetStraightTangentsOnPoint(Spline, Spline.SplinePoints.Num() - 2, bArriveTangent = false);
					}
				}
			}

			// Update the spline
			Spline.UpdateSpline();
			Editor::NotifyPropertyModified(Spline, n"SplinePoints");
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnDragSequenceCancelled()
	{
	}
}

class USplineDrawDetails : UHazeScriptDetailCustomization
{
	default DetailClass = UHazeSplineDrawPropertySet;

	UHazeImmediateDrawer Drawer;

	UFUNCTION(BlueprintOverride)
	void CustomizeDetails()
	{
		Drawer = AddImmediateRow(n"Help", "Help", false);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (Drawer != nullptr && Drawer.IsVisible())
		{
			auto Root = Drawer.BeginVerticalBox();
			HelpRow(Root, "🖱️", "Draw Points");
			HelpRow(Root, "Control + 🖱️", "Erase Points");
			HelpRow(Root, "Shift + 🖱️", "Move or Insert Points");
			HelpRow(Root, "Control + Shift + 🖱️", "Move Points Vertically");
		}
	}

	void HelpRow(FHazeImmediateVerticalBoxHandle Root, FString Label, FString Description)
	{
		auto Row = Root.HorizontalBox();
		Row
			.BorderBox().WidthOverride(150)
			.Text(Label)
			.Bold()
			.Color(ColorDebug::Orchid)
		;
		Row.Text(Description);
	}

}