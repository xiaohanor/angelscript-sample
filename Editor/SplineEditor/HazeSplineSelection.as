
enum ESplineEditorSelection
{
	Point,
	ArriveTangent,
	LeaveTangent,
	Multiple,
};

UHazeSplineSelection GetGlobalSplineSelection()
{
	auto Object = Cast<UHazeSplineSelection>(FindObject(GetTransientPackage(), "HazeSplineSelection"));
	if (Object != nullptr)
		return Object;
	auto NewObject = NewObject(GetTransientPackage(), UHazeSplineSelection, n"HazeSplineSelection");
	NewObject.Transactional = true;
	return NewObject;
}

class UHazeSplineSelection
{
	UPROPERTY(EditAnywhere)
	int PointIndex = -1;

	UPROPERTY(EditAnywhere)
	TArray<int> MultiplePoints;

	UPROPERTY(EditAnywhere)
	ESplineEditorSelection Type = ESplineEditorSelection::Point;

	FQuat CachedRotationForWidget;
	int CachedPointIndexForRotation = -1;
	bool bIsDraggingWidget = false;
	bool bDetailsWorldLocation = false;
	bool bIsRunningSplineEditorCode = false;
	bool bSplineDrawWasTemporary = false;

	bool IsTangentSelected()
	{
		return Type == ESplineEditorSelection::ArriveTangent || Type == ESplineEditorSelection::LeaveTangent;
	}

	bool IsPointSelected(int Point)
	{
		if (PointIndex == Point)
			return true;
		if (MultiplePoints.Contains(Point))
			return true;
		return false;
	}

	void SelectPoint(int Point, ESplineEditorSelection SelectType = ESplineEditorSelection::Point)
	{
		Type = SelectType;
		PointIndex = Point;
		MultiplePoints.Reset();
	}

	void Clear()
	{
		Type = ESplineEditorSelection::Point;
		PointIndex = -1;
		MultiplePoints.Reset();
	}

	void AddPointToSelection(int Point)
	{
		if (Type != ESplineEditorSelection::Multiple)
		{
			if (PointIndex == -1)
			{
				Type = ESplineEditorSelection::Point;
				PointIndex = Point;
			}
			else
			{
				Type = ESplineEditorSelection::Multiple;
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
		if (Type == ESplineEditorSelection::Multiple)
		{
			MultiplePoints.Remove(Point);

			if (MultiplePoints.Num() == 1)
			{
				Type = ESplineEditorSelection::Point;
				PointIndex = MultiplePoints[0];
				MultiplePoints.Reset();
			}
			else if (MultiplePoints.Num() == 0)
			{
				Type = ESplineEditorSelection::Point;
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
		if (Type == ESplineEditorSelection::Multiple)
			OutSelected.Append(MultiplePoints);
		else if (PointIndex != -1)
			OutSelected.Add(PointIndex);
		return OutSelected;
	}

	int GetFirstPointIndex()
	{
		if (Type == ESplineEditorSelection::Multiple)
			return MultiplePoints[0];
		return PointIndex;
	}

	int GetLatestPointIndex()
	{
		if (Type == ESplineEditorSelection::Multiple)
			return MultiplePoints.Last();
		return PointIndex;
	}

	void SetLatestPointIndex(int Point)
	{
		if (Type == ESplineEditorSelection::Multiple)
		{
			MultiplePoints.Remove(Point);
			MultiplePoints.Add(Point);
		}
	}

	int GetSelectedCount()
	{
		if (Type == ESplineEditorSelection::Multiple)
			return MultiplePoints.Num();
		else if (PointIndex != -1)
			return 1;
		return 0;
	}

	bool IsEmpty()
	{
		if (Type == ESplineEditorSelection::Multiple)
			return false;
		return PointIndex == -1;
	}

	int GetMaxSelectedPoint()
	{
		if (Type == ESplineEditorSelection::Multiple)
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
		if (Type == ESplineEditorSelection::Multiple)
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

struct FScopeIsRunningSplineEditorCode
{
	bool bPreviousValue = false;

	FScopeIsRunningSplineEditorCode()
	{
		UHazeSplineSelection Selection = GetGlobalSplineSelection();
		bPreviousValue = Selection.bIsRunningSplineEditorCode;
		Selection.bIsRunningSplineEditorCode = true;
	}

	~FScopeIsRunningSplineEditorCode()
	{
		GetGlobalSplineSelection().bIsRunningSplineEditorCode = bPreviousValue;
	}
}