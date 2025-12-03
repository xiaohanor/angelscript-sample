namespace SplineEditing
{

void DeleteSplinePoint(UHazeSplineComponent Spline, int PointIndex)
{
	if (Spline == nullptr)
		return;
	if (!Spline.SplinePoints.IsValidIndex(PointIndex))
		return;

	Spline.SplinePoints.RemoveAt(PointIndex);
	Spline.OnEditorSplinePointRemovedAtIndex(PointIndex);
}

void SelectSplinePoint(int SplinePoint, ESplineEditorSelection Type = ESplineEditorSelection::Point)
{
	auto Selection = GetGlobalSplineSelection();
	Selection.Modify();
	Selection.SelectPoint(SplinePoint, Type);
}

void DeleteSelectedPoints(UHazeSplineComponent Spline)
{
	if (Spline == nullptr)
		return;

	TArray<int> PointsToDelete = GetGlobalSplineSelection().GetAllSelected();
	PointsToDelete.Sort();

	for (int i = 0, Count = PointsToDelete.Num(); i < Count; ++i)
		DeleteSplinePoint(Spline, PointsToDelete[i] - i);

	SelectSplinePoint(Math::Min(PointsToDelete[0], Spline.SplinePoints.Num() - 1));
}

void CopySelectedPoints(UHazeSplineComponent Spline)
{
	FString CopyString;

	TArray<int> PointsToCopy = GetGlobalSplineSelection().GetAllSelected();
	PointsToCopy.Sort();
	for (int Point : PointsToCopy)
	{
		CopyString += GetSplinePointCopyString(Spline, Point);
		CopyString += "|";
	}
	Editor::CopyToClipBoard(CopyString);
}

void DuplicateSelectedPoints(UHazeSplineComponent Spline, FVector Direction)
{
	if (Spline == nullptr)
		return;

	auto Selection = GetGlobalSplineSelection();
	if (Selection.IsEmpty())
		return;

	TArray<FHazeSplinePoint> DuplicatePoints;

	TArray<int> PointsToDuplicate = Selection.GetAllSelected();
	PointsToDuplicate.Sort();

	for (int Point : PointsToDuplicate)
	{
		if (!Spline.SplinePoints.IsValidIndex(Point))
			continue;
		DuplicatePoints.Add(Spline.SplinePoints[Point]);
	}

	// Calculate offset to apply to duplicated points
	FVector PlaceOffset;

	int PlaceIndex = Selection.GetLatestPointIndex();
	PlaceOffset -= DuplicatePoints[0].RelativeLocation;
	PlaceOffset += Spline.SplinePoints[PlaceIndex].RelativeLocation;

	/*FVector Pos = Spline.ComputedSpline.Points[PlaceIndex].RelativeLocation;
	FVector Tangent = Spline.ComputedSpline.Points[PlaceIndex].LeaveTangent;
	Debug::DrawDebugLine(
		Spline.WorldTransform.TransformPosition(Pos),
		Spline.WorldTransform.TransformPosition(Pos + Tangent.GetSafeNormal() * 100.0),
		FLinearColor::Blue, 10.0, 5.0
	);

	Debug::DrawDebugLine(
		Spline.WorldTransform.TransformPosition(Pos - Tangent.GetSafeNormal().CrossProduct(FVector::UpVector) * 500.0),
		Spline.WorldTransform.TransformPosition(Pos + Tangent.GetSafeNormal().CrossProduct(FVector::UpVector) * 500.0),
		FLinearColor::Red, 10.0, 5.0
	);

	Debug::DrawDebugLine(
		Spline.WorldTransform.TransformPosition(Pos),
		Spline.WorldTransform.TransformPosition(Pos + Direction.GetSafeNormal() * 100.0),
		FLinearColor::Green, 10.0, 5.0
	);*/

	// Determine whether we want to go before or after the placement point based on the direction
	bool bInsertReverse = false;
	if (!Direction.IsNearlyZero())
	{
		float DirDot = Direction.GetSafeNormal().DotProduct(
			Spline.ComputedSpline.Points[PlaceIndex].LeaveTangent.GetSafeNormal()
		);

		float DirDotThreshold = 0.0;

		if(PlaceIndex == 0)
		{
			// Bias back if first point
			DirDotThreshold = 0.3; 
		}
		else if(PlaceIndex == Spline.SplinePoints.Num() - 1)
		{
			// Bias forward if last point
			DirDotThreshold = -0.3;
		}

		const bool bShouldBeAfter = DirDot > DirDotThreshold;
		if (bShouldBeAfter)
		{
			PlaceIndex = PointsToDuplicate.Last() + 1;
			bInsertReverse = true;
		}
	}

	// Add new points
	Selection.Modify();
	Selection.Clear();
	for (int i = 0, Count = DuplicatePoints.Num(); i < Count; ++i)
	{
		int InsertIndex = PlaceIndex + i;
		int PointIndex = i;

		Spline.SplinePoints.Insert(DuplicatePoints[PointIndex], InsertIndex);
		Spline.SplinePoints[InsertIndex].RelativeLocation += PlaceOffset;

		Spline.OnEditorSplinePointAddedAtIndex(InsertIndex);
		Selection.AddPointToSelection(InsertIndex);
	}

	Selection.SetLatestPointIndex(PlaceIndex);
}

void PasteSplinePoints(UHazeSplineComponent Spline, bool bRelative, bool bReplace, float PlaceDistance = -1.0)
{
	if (Spline == nullptr)
		return;

	auto Selection = GetGlobalSplineSelection();

	TArray<FHazeSplinePoint> PastedPoints = GetSplinePointsInClipboard(Spline.WorldTransform, !bRelative);
	if (PastedPoints.Num() == 0)
		return;

	// Calculate offset to apply to pasted points
	FVector PlaceOffset;
	if (bRelative)
		PlaceOffset = -PastedPoints[0].RelativeLocation;

	int PlaceIndex = 0;

	// Delete points to be replaced
	if (bReplace)
	{
		TArray<int> PointsToDelete = Selection.GetAllSelected();
		PointsToDelete.Sort();

		if (PointsToDelete.Num() != 0 && Spline.SplinePoints.IsValidIndex(PointsToDelete[0]))
		{
			PlaceIndex = PointsToDelete[0];
			if (bRelative)
				PlaceOffset += Spline.SplinePoints[PointsToDelete[0]].RelativeLocation;
		}

		for (int i = 0, Count = PointsToDelete.Num(); i < Count; ++i)
			DeleteSplinePoint(Spline, PointsToDelete[i] - i);
	}
	else
	{
		if (PlaceDistance == -1.0)
		{
			int LastPoint = Selection.GetLatestPointIndex();
			if (LastPoint != -1)
			{
				PlaceIndex = LastPoint+1;
				PlaceOffset += Spline.SplinePoints[LastPoint].RelativeLocation;
			}
			else if (Spline.SplinePoints.Num() != 0)
			{
				PlaceIndex = Spline.SplinePoints.Num();
				PlaceOffset += Spline.SplinePoints.Last().RelativeLocation;
			}
			else
			{
				PlaceIndex = 0;
			}
		}
		else
		{
			float AtDistance = Math::Clamp(PlaceDistance, 0.0, Spline.SplineLength);

			int SegmentIndex = 0;
			float Alpha = 0.0;
			SplineComputation::GetSegmentAlphaAtSplineDistance(Spline.ComputedSpline, AtDistance, SegmentIndex, Alpha);

			PlaceIndex = Math::Min(SegmentIndex+1, Spline.SplinePoints.Num());
			if (bRelative)
				PlaceOffset += SplineComputation::GetRelativeLocationAtSegmentAlpha(Spline.ComputedSpline, SegmentIndex, Alpha);
		}
	}

	// Insert new points
	Selection.Modify();
	Selection.Clear();
	for (int i = 0, Count = PastedPoints.Num(); i < Count; ++i)
	{
		int InsertIndex = PlaceIndex + i;
		Spline.SplinePoints.Insert(PastedPoints[i], InsertIndex);
		Spline.SplinePoints[InsertIndex].RelativeLocation += PlaceOffset;

		Spline.OnEditorSplinePointAddedAtIndex(InsertIndex);
		Selection.AddPointToSelection(InsertIndex);
	}
}

int InsertPointAtDistance(UHazeSplineComponent Spline, float SplineDistance, bool bKeepRelativeRotation = false)
{
	// Find the first spline point that is after this distance
	if (Spline == nullptr)
		return -1;

	int PointIndex = 0;
	for (int i = 0, Count = Spline.ComputedSpline.Points.Num(); i < Count; ++i)
	{
		const FHazeComputedSplinePoint& Point = Spline.ComputedSpline.Points[i];
		if (Point.SplineDistance >= SplineDistance)
		{
			PointIndex = i;
			break;
		}
	}

	const FTransform RelativeTransform = SplineComputation::GetRelativeTransformAtSplineDistance(Spline.ComputedSpline, SplineDistance);
	FQuat RelativeRotation = FQuat::Identity;
	if(bKeepRelativeRotation)
		RelativeRotation = RelativeTransform.Rotation;

	return InsertPointBeforePoint(
		Spline,
		PointIndex,
		RelativeTransform.Location,
		RelativeRotation,
		RelativeTransform.Scale3D,
	);
}

int InsertPointBeforePoint(UHazeSplineComponent Spline, int BeforePointIndex, FVector RelativeLocation, FQuat RelativeRotation, FVector RelativeScale3D)
{
	if (Spline == nullptr)
		return -1;

	FHazeSplinePoint NewPoint;
	NewPoint.RelativeLocation = RelativeLocation;
	NewPoint.RelativeRotation = RelativeRotation;
	NewPoint.RelativeScale3D = RelativeScale3D;

	Spline.SplinePoints.Insert(NewPoint, BeforePointIndex);
	Spline.OnEditorSplinePointAddedAtIndex(BeforePointIndex);

	return BeforePointIndex;
}

FString GetSplinePointCopyString(UHazeSplineComponent Spline, int PointIndex)
{
	if (Spline == nullptr)
		return "";
	if (!Spline.SplinePoints.IsValidIndex(PointIndex))
		return "";

	const FHazeSplinePoint& Point = Spline.SplinePoints[PointIndex];

	FString Str;
	Str += "SplinePoint;";
	Str += Point.RelativeLocation.ToString() + ";";
	Str += Point.RelativeScale3D.ToString() + ";";
	Str += Point.RelativeRotation.ToString() + ";";

	FTransform SplineTransform = Spline.WorldTransform;
	Str += SplineTransform.TransformPosition(Point.RelativeLocation).ToString() + ";";
	Str += (Point.RelativeScale3D * SplineTransform.Scale3D).ToString() + ";";
	Str += SplineTransform.TransformRotation(Point.RelativeRotation).ToString() + ";";

	if (Point.bOverrideTangent)
		Str += "true;";
	else
		Str += "false;";

	if (Point.bDiscontinuousTangent)
		Str += "true;";
	else
		Str += "false;";

	Str += Point.ArriveTangent.ToString() + ";";
	Str += Point.LeaveTangent.ToString() + ";";

	Str += SplineTransform.TransformVector(Point.ArriveTangent).ToString() + ";";
	Str += SplineTransform.TransformVector(Point.LeaveTangent).ToString() + ";";

	return Str;
}

bool HasSplinePointsInClipboard()
{
	FString String;
	Editor::PasteFromClipBoard(String);
	if (String.Len() == 0)
		return false;

	TArray<FString> PointStrings;
	String.ParseIntoArray(PointStrings, "|");
	if (PointStrings.Num() == 0)
		return false;

	for (const FString& PointStr : PointStrings)
	{
		TArray<FString> PointData;
		PointStr.ParseIntoArray(PointData, ";");
		if (PointData.Num() != 13)
			return false;
		if (PointData[0] != "SplinePoint")
			return false;
	}

	return true;
}

void ReverseSplinePointsOrder(UHazeSplineComponent Spline)
{
	// Store the current selection so that we can re-select it after reversing order
	auto Selection = GetGlobalSplineSelection();
	TArray<int> PreviousSelectedIndices;
	ESplineEditorSelection PreviousSelectionType = Selection.Type;

	switch(Selection.Type)
	{
		case ESplineEditorSelection::Point:
		case ESplineEditorSelection::ArriveTangent:
		case ESplineEditorSelection::LeaveTangent:
			PreviousSelectedIndices.Add(Selection.PointIndex);
			break;

		case ESplineEditorSelection::Multiple:
			PreviousSelectedIndices = Selection.MultiplePoints;
			break;
	}

	Selection.Clear();

	{
		// Reverse the order of the spline points
		TArray<FHazeSplinePoint> ReversedSplinePoints;
		ReversedSplinePoints.Reserve(Spline.SplinePoints.Num());

		for(int i = Spline.SplinePoints.Num() - 1; i >= 0; i--)
		{
			// Create a new array with the points in the reverse order
			ReversedSplinePoints.Add(Spline.SplinePoints[i]);

			int LastIndex = ReversedSplinePoints.Num() - 1;

			if(Spline.SplinePoints[i].bOverrideTangent)
			{
				ReversedSplinePoints[LastIndex].ArriveTangent = -Spline.SplinePoints[i].LeaveTangent;
				ReversedSplinePoints[LastIndex].LeaveTangent = -Spline.SplinePoints[i].ArriveTangent;
			}
		}

		Spline.SplinePoints = ReversedSplinePoints;
	}

	switch(PreviousSelectionType)
	{
		case ESplineEditorSelection::Point:
		{
			// Select the same point as before, but at index (LastIndex - Selected)
			int NewIndex = (Spline.SplinePoints.Num() - 1) - PreviousSelectedIndices[0];
			Selection.SelectPoint(NewIndex, ESplineEditorSelection::Point);
			break;
		}

		case ESplineEditorSelection::ArriveTangent:
		{
			// Select the same point as before, but switch tangent
			int NewIndex = (Spline.SplinePoints.Num() - 1) - PreviousSelectedIndices[0];
			Selection.SelectPoint(NewIndex, ESplineEditorSelection::LeaveTangent);
			break;
		}

		case ESplineEditorSelection::LeaveTangent:
		{
			// Select the same point as before, but switch tangent
			int NewIndex = (Spline.SplinePoints.Num() - 1) - PreviousSelectedIndices[0];
			Selection.SelectPoint(NewIndex, ESplineEditorSelection::ArriveTangent);
			break;
		}

		case ESplineEditorSelection::Multiple:
		{
			// Select the same points as before, but at index (LastIndex - Selected)
			Selection.Type = PreviousSelectionType;
			for(int PreviousIndex : PreviousSelectedIndices)
			{
				int NewIndex = (Spline.SplinePoints.Num() - 1) - PreviousIndex;
				Selection.AddPointToSelection(NewIndex);
			}
			break;
		}
	}
}

TArray<FHazeSplinePoint> GetSplinePointsInClipboard(FTransform SplineTransform, bool bWorldPosition)
{
	TArray<FHazeSplinePoint> Points;

	FString String;
	Editor::PasteFromClipBoard(String);
	if (String.Len() == 0)
		return Points;

	TArray<FString> PointStrings;
	String.ParseIntoArray(PointStrings, "|");
	if (PointStrings.Num() == 0)
		return Points;

	for (const FString& PointStr : PointStrings)
	{
		TArray<FString> PointData;
		PointStr.ParseIntoArray(PointData, ";");
		if (PointData.Num() != 13)
			continue;
		if (PointData[0] != "SplinePoint")
			continue;

		FHazeSplinePoint Point;

		if (bWorldPosition)
		{
			Point.RelativeLocation.InitFromString(PointData[4]);
			Point.RelativeScale3D.InitFromString(PointData[5]);
			Point.RelativeRotation.InitFromString(PointData[6]);

			Point.RelativeLocation = SplineTransform.InverseTransformPosition(Point.RelativeLocation);
			Point.RelativeScale3D = Point.RelativeScale3D / SplineTransform.Scale3D.ComponentMax(FVector(0.001, 0.001, 0.001));
			Point.RelativeRotation = SplineTransform.InverseTransformRotation(Point.RelativeRotation);

			Point.ArriveTangent.InitFromString(PointData[11]);
			Point.LeaveTangent.InitFromString(PointData[12]);

			Point.ArriveTangent = SplineTransform.InverseTransformVector(Point.ArriveTangent);
			Point.LeaveTangent = SplineTransform.InverseTransformVector(Point.LeaveTangent);
		}
		else
		{
			Point.RelativeLocation.InitFromString(PointData[1]);
			Point.RelativeScale3D.InitFromString(PointData[2]);
			Point.RelativeRotation.InitFromString(PointData[3]);

			Point.ArriveTangent.InitFromString(PointData[9]);
			Point.LeaveTangent.InitFromString(PointData[10]);
		}

		Point.bOverrideTangent = (PointData[7] == "true");
		Point.bDiscontinuousTangent = (PointData[8] == "true");

		Points.Add(Point);
	}

	return Points;
}

void SetStraightTangentsOnPoint(UHazeSplineComponent Spline, int InPoint, bool bArriveTangent = true, bool bLeaveTangent = true)
{
	int Point = InPoint;
	if (Spline.SplineSettings.bClosedLoop)
		Point = Math::WrapIndex(Point, 0, Spline.SplinePoints.Num());
	if (!Spline.SplinePoints.IsValidIndex(Point))
		return;

	FHazeSplinePoint& EditPoint = Spline.SplinePoints[Point];
	EditPoint.bOverrideTangent = true;
	EditPoint.bDiscontinuousTangent = true;

	if (bArriveTangent)
	{
		if (Spline.SplinePoints.IsValidIndex(Point - 1))
			EditPoint.ArriveTangent = EditPoint.RelativeLocation - Spline.SplinePoints[Point - 1].RelativeLocation;
		else if (Spline.IsClosedLoop())
			EditPoint.ArriveTangent = EditPoint.RelativeLocation - Spline.SplinePoints.Last().RelativeLocation;
		else if (Spline.SplinePoints.Num() >= 2)
			EditPoint.ArriveTangent = Spline.SplinePoints[1].RelativeLocation - EditPoint.RelativeLocation;
		else
			EditPoint.ArriveTangent = -FVector::ForwardVector;
	}

	if (bLeaveTangent)
	{
		if (Spline.SplinePoints.IsValidIndex(Point + 1))
			EditPoint.LeaveTangent = Spline.SplinePoints[Point + 1].RelativeLocation - EditPoint.RelativeLocation;
		else if (Spline.IsClosedLoop())
			EditPoint.LeaveTangent = Spline.SplinePoints[0].RelativeLocation - EditPoint.RelativeLocation;
		else if (Spline.SplinePoints.Num() >= 2)
			EditPoint.LeaveTangent = EditPoint.RelativeLocation - Spline.SplinePoints[Spline.SplinePoints.Num() - 2].RelativeLocation;
		else
			EditPoint.LeaveTangent = FVector::ForwardVector;
	}
}

void SelectPointsAfterDistance(UHazeSplineComponent Spline, float SplineDistance)
{
	auto Selection = GetGlobalSplineSelection();
	Selection.Modify();
	for (int i = Spline.ComputedSpline.Points.Num() - 1; i >= 0; i--)
	{
		const FHazeComputedSplinePoint& Point = Spline.ComputedSpline.Points[i];
		if (Point.SplineDistance < SplineDistance)
		{
			break;
		}
		Selection.AddPointToSelection(i);
	}
}

void SelectPointsBeforeDistance(UHazeSplineComponent Spline, float SplineDistance)
{
	auto Selection = GetGlobalSplineSelection();
	Selection.Modify();
	for (int i = 0; i < Spline.ComputedSpline.Points.Num(); i++)
	{
		const FHazeComputedSplinePoint& Point = Spline.ComputedSpline.Points[i];
		if (Point.SplineDistance > SplineDistance)
		{
			break;
		}
		Selection.AddPointToSelection(i);
	}
}

void SelectPointsAfterPoint(UHazeSplineComponent Spline, int InPoint)
{
	auto Selection = GetGlobalSplineSelection();
	Selection.Modify();
	for (int i = InPoint; i < Spline.ComputedSpline.Points.Num(); i++)
	{
		Selection.AddPointToSelection(i);
	}
}

void SelectPointsBeforePoint(UHazeSplineComponent Spline, int InPoint)
{
	auto Selection = GetGlobalSplineSelection();
	Selection.Modify();
	for (int i = InPoint; i >= 0; i--)
	{
		Selection.AddPointToSelection(i);
	}
}

void SnapSelectionToGround(UHazeSplineComponent Spline)
{
	TArray<int> PointsToSnapToGround = GetGlobalSplineSelection().GetAllSelected();
	if(PointsToSnapToGround.IsEmpty())
		return;

	FAngelscriptGameThreadScopeWorldContext WorldContext(Spline);

	for(auto PointIndex : PointsToSnapToGround)
	{
		FHazeSplinePoint& Point = Spline.SplinePoints[PointIndex];

		FHazeTraceSettings Trace = Trace::InitChannel(ECollisionChannel::WorldGeometry);
		Trace.UseLine();

		const float DistanceAlongSpline = Spline.GetSplineDistanceAtSplinePointIndex(PointIndex);
		const FVector TraceStart = Spline.GetWorldLocationAtSplineDistance(DistanceAlongSpline) + FVector::UpVector * 100;
		const FVector TraceEnd = TraceStart + FVector::DownVector * 10000;
		FHitResult Hit = Trace.QueryTraceSingle(TraceStart, TraceEnd);

		if(Hit.IsValidBlockingHit())
		{
			Point.RelativeLocation = Spline.WorldTransform.InverseTransformPosition(Hit.Location);
		}
	}
}

void MirrorSplinePoints(UHazeSplineComponent Spline, bool bMirrorX, bool bMirrorY, bool bMirrorZ)
{
	TArray<int> PointsToMirror = GetGlobalSplineSelection().GetAllSelected();
	if(PointsToMirror.IsEmpty())
		return;

	FAngelscriptGameThreadScopeWorldContext WorldContext(Spline);

	for(auto PointIndex : PointsToMirror)
	{
		FHazeSplinePoint& Point = Spline.SplinePoints[PointIndex];
		if (bMirrorX)
		{
			Point.RelativeLocation.X = Point.RelativeLocation.X * -1.0;
			if (Point.bOverrideTangent)
			{
				Point.ArriveTangent.X = Point.ArriveTangent.X * -1.0;
				Point.LeaveTangent.X = Point.LeaveTangent.X * -1.0;
			}
		}
		if (bMirrorY)
		{
			Point.RelativeLocation.Y = Point.RelativeLocation.Y * -1.0;
			if (Point.bOverrideTangent)
			{
				Point.ArriveTangent.Y = Point.ArriveTangent.Y * -1.0;
				Point.LeaveTangent.Y = Point.LeaveTangent.Y * -1.0;
			}
		}
		if (bMirrorZ)
		{
			Point.RelativeLocation.Z = Point.RelativeLocation.Z * -1.0;
			if (Point.bOverrideTangent)
			{
				Point.ArriveTangent.Z = Point.ArriveTangent.Z * -1.0;
				Point.LeaveTangent.Z = Point.LeaveTangent.Z * -1.0;
			}
		}
	}
}

};