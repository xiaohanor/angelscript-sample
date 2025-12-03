struct FIslandGridPoint
{
	int X = 0;
	int Y = 0;

	FIslandGridPoint(int In_X, int In_Y)
	{
		X = In_X;
		Y = In_Y;
	}

	FIslandGridPoint(int In_XY)
	{
		X = In_XY;
		Y = In_XY;
	}

	FIslandGridPoint(FVector Vector)
	{
		X = Math::RoundToInt(Vector.X);
		Y = Math::RoundToInt(Vector.Y);
	}

	FIslandGridPoint(FVector2D Vector)
	{
		X = Math::RoundToInt(Vector.X);
		Y = Math::RoundToInt(Vector.Y);
	}

	FVector ToVector() const
	{
		FVector Out = FVector::ZeroVector;
		Out.X = X;
		Out.Y = Y;
		return Out;
	}

	FVector2D ToVector2D() const
	{
		FVector2D Out;
		Out.X = X;
		Out.Y = Y;
		return Out;
	}

	void opAssign(FVector Vector)
	{
		this = FIslandGridPoint(Vector);
	}

	void opAssign(FVector2D Vector2D)
	{
		this = FIslandGridPoint(Vector2D);
	}

	bool opEquals(FIslandGridPoint Other) const
	{
		return X == Other.X && Y == Other.Y;
	}

	FIslandGridPoint opAdd(FIslandGridPoint Other) const
	{
		FIslandGridPoint Out = this;
		Out.X += Other.X;
		Out.Y += Other.Y;
		return Out;
	}

	void opAddAssign(FIslandGridPoint Other)
	{
		this = opAdd(Other);
	}

	FIslandGridPoint opSub(FIslandGridPoint Other) const
	{
		FIslandGridPoint Out = this;
		Out.X -= Other.X;
		Out.Y -= Other.Y;
		return Out;
	}

	void opSubAssign(FIslandGridPoint Other)
	{
		this = opSub(Other);
	}

	FIslandGridPoint opMul(FIslandGridPoint Other) const
	{
		FIslandGridPoint Out = this;
		Out.X *= Other.X;
		Out.Y *= Other.Y;
		return Out;
	}

	void opMulAssign(FIslandGridPoint Other)
	{
		this = opMul(Other);
	}
}

UCLASS(NotBlueprintable)
class AIslandFallingPlatformsBoard : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

#if EDITOR
	UPROPERTY(DefaultComponent, Attach = Root)
	UEditorBillboardComponent EditorBillboard;
	default EditorBillboard.SetSpriteName("DanceFloor");
	default EditorBillboard.RelativeLocation = FVector(0.0, 0.0, 500.0);
	default EditorBillboard.RelativeScale3D = FVector(0.75);

	UPROPERTY(DefaultComponent)
	UIslandFallingPlatformsBoardVisualizerComponent VisualizerComp;
#endif

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedActorComp;

	/* Amount of grid points per side of the board */
	UPROPERTY(EditAnywhere)
	int BoardGridPointSize = 5;

	/* The length of a side on a grid point */
	UPROPERTY(EditAnywhere)
	float GridPointSize = 600.0;

#if EDITOR
	UPROPERTY(NotVisible, BlueprintHidden)
	bool bKeepHeightInSnapActorEditor = true;

	bool bShowGridPoints = false;
	bool bInSnapActorToGridEditor = false;
	bool bInSpawnActorOnGridPointEditor = false;

	UPROPERTY(EditInstanceOnly, AdvancedDisplay)
	TSubclassOf<AHazeActor> SpawnActorClass;

	UPROPERTY(EditInstanceOnly, AdvancedDisplay)
	TSubclassOf<AHazeActor> SnapActorClassFilter;

	AActor TempSnapEditorActor;
#endif

	TArray<FIslandGridPoint> BlockedGridPoints;

#if EDITOR
	UFUNCTION(BlueprintOverride)
	void OnActorModifiedInEditor()
	{
		// As the grid is made now, it only supports uneven amount of grid points per side.
		if((BoardGridPointSize % 2) == 0)
			BoardGridPointSize++;
	}
#endif

	FVector GetWorldLocationOfGridPoint(FIslandGridPoint GridPoint) const
	{
		return ActorLocation + (ActorForwardVector * GridPoint.X * GridPointSize) + (ActorRightVector * GridPoint.Y * GridPointSize);
	}

	FIslandGridPoint GetClosestGridPoint(FVector WorldLocation) const
	{
		FVector LocalLocation = ActorTransform.InverseTransformPosition(WorldLocation);
		float GridPointX = LocalLocation.X / GridPointSize;
		float GridPointY = LocalLocation.Y / GridPointSize;
		int RoundedX = Math::RoundToInt(GridPointX);
		int RoundedY = Math::RoundToInt(GridPointY);
		return FIslandGridPoint(Math::Clamp(RoundedX, -BoardExtents, BoardExtents), Math::Clamp(RoundedY, -BoardExtents, BoardExtents));
	}

	bool IsGridPointWithinGrid(FIslandGridPoint GridPoint) const
	{
		if(GridPoint.X > BoardExtents)
			return false;

		if(GridPoint.X < -BoardExtents)
			return false;

		if(GridPoint.Y > BoardExtents)
			return false;

		if(GridPoint.Y < -BoardExtents)
			return false;

		return true;
	}

	bool IsGridPointOnEdge(FIslandGridPoint GridPoint, FIslandGridPoint&out EdgeNormal) const
	{
		bool bIsOnEdge = IsGridPointOnEdge(GridPoint);
		if(!bIsOnEdge)
			return false;

		FVector EdgeNormalVector = FVector::ZeroVector;
		if(GridPoint.X == BoardExtents)
			EdgeNormalVector += ActorForwardVector;
		else if(GridPoint.X == -BoardExtents)
			EdgeNormalVector += -ActorForwardVector;

		if(GridPoint.Y == BoardExtents)
			EdgeNormalVector += ActorRightVector;
		else if(GridPoint.Y == -BoardExtents)
			EdgeNormalVector += -ActorRightVector;

		int X = Math::RoundToInt(EdgeNormalVector.X);
		int Y = Math::RoundToInt(EdgeNormalVector.Y);
		EdgeNormal = FIslandGridPoint(X, Y);
		return true;
	}

	bool IsGridPointOnEdge(FIslandGridPoint GridPoint) const
	{
		return Math::Abs(GridPoint.X) == BoardExtents || Math::Abs(GridPoint.Y) == BoardExtents;
	}

	int GetBoardExtents() const property
	{
		return Math::IntegerDivisionTrunc(BoardGridPointSize, 2);
	}

	void AddGridPointBlocker(FIslandGridPoint GridPoint)
	{
		BlockedGridPoints.Add(GridPoint);
	}

	void RemoveGridPointBlocker(FIslandGridPoint GridPoint)
	{
		BlockedGridPoints.Remove(GridPoint);
	}

	bool IsGridPointBlocked(FIslandGridPoint GridPoint) const
	{
		return BlockedGridPoints.Contains(GridPoint);
	}

	// Returns true if the grid point or an adjacent grid point is blocked.
	bool IsAdjacentGridPointBlocked(FIslandGridPoint GridPoint) const
	{
		TArray<FIslandGridPoint> AdjacentGridPoints;
		GetAdjacentGridPoints(GridPoint, AdjacentGridPoints);
		AdjacentGridPoints.Add(GridPoint);

		for(FIslandGridPoint Current : AdjacentGridPoints)
		{
			if(IsGridPointBlocked(Current))
				return true;
		}

		return false;
	}

	void GetAdjacentGridPoints(FIslandGridPoint GridPoint, TArray<FIslandGridPoint>&out OutGridPoints) const
	{
		OutGridPoints.Reset();

		// Cardinal adjacent points
		OutGridPoints.Add(GridPoint + FIslandGridPoint(1, 0));
		OutGridPoints.Add(GridPoint + FIslandGridPoint(-1, 0));
		OutGridPoints.Add(GridPoint + FIslandGridPoint(0, 1));
		OutGridPoints.Add(GridPoint + FIslandGridPoint(0, -1));

		// Diagonal adjacent points
		OutGridPoints.Add(GridPoint + FIslandGridPoint(1, 1));
		OutGridPoints.Add(GridPoint + FIslandGridPoint(1, -1));
		OutGridPoints.Add(GridPoint + FIslandGridPoint(-1, 1));
		OutGridPoints.Add(GridPoint + FIslandGridPoint(-1, -1));

		for(int i = OutGridPoints.Num() - 1; i >= 0; i--)
		{
			if(!IsGridPointWithinGrid(OutGridPoints[i]))
				OutGridPoints.RemoveAt(i);
		}
	}
}

#if EDITOR
class UIslandFallingPlatformsBoardVisualizerComponent : UActorComponent
{
	default bIsEditorOnly = true;
}

class UIslandFallingPlatformsBoardVisualizer : UHazeScriptComponentVisualizer
{
	default VisualizedClass = UIslandFallingPlatformsBoardVisualizerComponent;

	UFUNCTION(BlueprintOverride)
	void VisualizeComponent(const UActorComponent Component)
	{
		const float LineThickness = 10.0;

		auto Board = Cast<AIslandFallingPlatformsBoard>(Component.Owner);
		float BoardGridPointSize = Board.BoardGridPointSize;
		float GridPointSize = Board.GridPointSize;
		float BoardSize = BoardGridPointSize * GridPointSize;
		float BoardSizeExtents = BoardSize * 0.5;

		FVector BottomLeftCorner = Board.ActorLocation - Board.ActorForwardVector * BoardSizeExtents - Board.ActorRightVector * BoardSizeExtents;
		for(int x = 0; x <= Board.BoardGridPointSize; x++)
		{
			FVector Point1 = BottomLeftCorner + Board.ActorForwardVector * (x * GridPointSize);
			FVector Point2 = Point1 + Board.ActorRightVector * BoardSize;
			DrawLine(Point1, Point2, FLinearColor::Red, LineThickness);
		}

		for(int y = 0; y <= Board.BoardGridPointSize; y++)
		{
			FVector Point1 = BottomLeftCorner + Board.ActorRightVector * (y * GridPointSize);
			FVector Point2 = Point1 + Board.ActorForwardVector * BoardSize;
			DrawLine(Point1, Point2, FLinearColor::Red, LineThickness);
		}

		if(Board.bInSpawnActorOnGridPointEditor)
		{
			RenderSpawnActorOnGridPoint();
		}
		else if(Board.bInSnapActorToGridEditor)
		{
			RenderSnapActorToGridEditor();
		}
		else if(Board.bShowGridPoints)
		{
			RenderGridPoints();
		}

		Editor::ActivateVisualizer(Cast<UIslandFallingPlatformsBoardVisualizerComponent>(Component));
	}

	void RenderSnapActorToGridEditor()
	{
		auto Board = Cast<AIslandFallingPlatformsBoard>(GetEditingComponent().Owner);
		if(Board.TempSnapEditorActor == nullptr)
			return;

		FBox Bounds = Board.TempSnapEditorActor.GetActorLocalBoundingBox(true);
		DrawWireBox(Board.TempSnapEditorActor.ActorTransform.TransformPosition(Bounds.Center), Bounds.Extent * Board.TempSnapEditorActor.ActorScale3D, Board.TempSnapEditorActor.ActorQuat, FLinearColor::Red, 20);

		int BoardExtents = Board.BoardExtents;
		for(int x = -BoardExtents; x <= BoardExtents; x++)
		{
			for(int y = -BoardExtents; y <= BoardExtents; y++)
			{
				FIslandGridPoint GridPoint = FIslandGridPoint(x, y);

				SetRenderForeground(true);
				SetHitProxy(FName(f"{x},{y}"), EVisualizerCursor::Hand);
				DrawPoint(Board.GetWorldLocationOfGridPoint(GridPoint), FLinearColor::White, 50.0);
				ClearHitProxy();
			}
		}
	}

	void RenderSpawnActorOnGridPoint()
	{
		auto Board = Cast<AIslandFallingPlatformsBoard>(GetEditingComponent().Owner);

		int BoardExtents = Board.BoardExtents;
		for(int x = -BoardExtents; x <= BoardExtents; x++)
		{
			for(int y = -BoardExtents; y <= BoardExtents; y++)
			{
				FIslandGridPoint GridPoint = FIslandGridPoint(x, y);

				SetRenderForeground(true);
				SetHitProxy(FName(f"{x},{y}"), EVisualizerCursor::Hand);
				DrawPoint(Board.GetWorldLocationOfGridPoint(GridPoint), FLinearColor::White, 50.0);
				ClearHitProxy();
			}
		}
	}

	void RenderGridPoints()
	{
		auto Board = Cast<AIslandFallingPlatformsBoard>(GetEditingComponent().Owner);
		int BoardExtents = Board.BoardExtents;
		for(int x = -BoardExtents; x <= BoardExtents; x++)
		{
			for(int y = -BoardExtents; y <= BoardExtents; y++)
			{
				FIslandGridPoint GridPoint = FIslandGridPoint(x, y);
				DrawWorldString(f"{x}, {y}", Board.GetWorldLocationOfGridPoint(GridPoint), FLinearColor::Red, bCenterText = true);
			}
		}
	}

	UFUNCTION(BlueprintOverride)
	bool VisProxyHandleClick(FName HitProxy, FVector ClickOrigin, FVector ClickDirection, FKey Key,
							 EInputEvent Event)
	{
		FString HitProxyStr = FString(HitProxy);
		FString XStr, YStr;
		HitProxyStr.Split(",", XStr, YStr);
		int X = String::Conv_StringToInt(XStr);
		int Y = String::Conv_StringToInt(YStr);
		FIslandGridPoint GridPoint = FIslandGridPoint(X, Y);

		auto Board = Cast<AIslandFallingPlatformsBoard>(GetEditingComponent().Owner);
		if(Board.bInSpawnActorOnGridPointEditor)
		{
			Editor::BeginTransaction("Spawn Actor On Grid Point", Board);
			Board.Modify();
			FVector TargetLocation = Board.GetWorldLocationOfGridPoint(GridPoint);
			TArray<AHazeActor> Actors = Editor::GetAllEditorWorldActorsOfClass(Board.SpawnActorClass);
			for(AHazeActor Actor : Actors)
			{
				float Dist = Actor.ActorLocation.DistXY(TargetLocation);
				if(Dist < Board.GridPointSize * 0.5)
				{
					Actor.DestroyActor();
					Editor::EndTransaction();
					return true;
				}
			}
			
			AHazeActor Actor = SpawnActor(Board.SpawnActorClass, TargetLocation, Board.ActorRotation);
			Editor::EndTransaction();
		}
		else if(Board.bInSnapActorToGridEditor)
		{
			Editor::BeginTransaction("Snap Actor To Grid Point", Board);
			Board.Modify();
			Board.TempSnapEditorActor.Modify();
			FVector TargetLocation = Board.GetWorldLocationOfGridPoint(GridPoint);
			if(Board.bKeepHeightInSnapActorEditor)
				TargetLocation.Z = Board.TempSnapEditorActor.ActorLocation.Z;

			Board.TempSnapEditorActor.ActorLocation = TargetLocation;
			Board.TempSnapEditorActor = nullptr;
			Board.bInSnapActorToGridEditor = false;
			Editor::EndTransaction();
		}
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool HandleInputKey(FKey Key, EInputEvent Event)
	{
		auto Board = Cast<AIslandFallingPlatformsBoard>(GetEditingComponent().Owner);
		if(!Board.bInSnapActorToGridEditor)
			return false;

		if(Board.bInSpawnActorOnGridPointEditor)
			return false;

		if(Board.TempSnapEditorActor != nullptr)
			return false;

		if(Key.KeyName != n"LeftMouseButton")
			return false;

		FHazeTraceSettings Trace = Trace::InitProfile(n"BlockAllDynamic");
		FVector MouseOrigin, TraceDirection;
		Editor::GetEditorCursorRay(MouseOrigin, TraceDirection);
		FHitResultArray Hits = Trace.QueryTraceMulti(MouseOrigin, MouseOrigin + TraceDirection * 50000.0);
		for(FHitResult Hit : Hits.BlockHits)
		{
			if(!Hit.bBlockingHit)
				continue;

			if(Board.SnapActorClassFilter != nullptr && !Hit.Actor.Class.IsChildOf(Board.SnapActorClassFilter))
				continue;
			
			Editor::BeginTransaction("Select Actor To Snap", Board);
			Board.Modify();
			Board.TempSnapEditorActor = Hit.Actor;
			Editor::RedrawAllViewports();
			Editor::EndTransaction();
			break;
		}

		return true;
	}
}

class UIslandFallingPlatformsBoardDetailsCustomization : UHazeScriptDetailCustomization
{
	default DetailClass = AIslandFallingPlatformsBoard;

	AIslandFallingPlatformsBoard Board;
	UHazeImmediateDrawer Drawer;
	TArray<AHazeActor> Actors;
	TMap<FName, UClass> ActorNameClassMap;
	TArray<FName> ActorClassNames;
	TArray<FName> FilteredClassNames;
	FString SearchBoxValue;

	UFUNCTION(BlueprintOverride)
	void CustomizeDetails()
	{
		Board = Cast<AIslandFallingPlatformsBoard>(GetCustomizedObject());
		Board.bShowGridPoints = false;
		Board.bInSnapActorToGridEditor = false;
		Board.bInSpawnActorOnGridPointEditor = false;
		Board.TempSnapEditorActor = nullptr;

		if (GetCustomizedObject().World == nullptr)
			return;

		if(ObjectsBeingCustomized.Num() > 1)
			return;
		
		Drawer = AddImmediateRow(n"Visual Editing");
		HideProperty(n"ExitNode");
		Actors = Editor::GetAllEditorWorldActorsOfClass(AHazeActor);
		ActorNameClassMap.Reset();
		ActorClassNames.Reset();

		ActorNameClassMap.Add(n"None", nullptr);
		ActorClassNames.Add(n"None");
		for(AActor Actor : Actors)
		{
			if(Actor == Board)
				continue;

			UClass CurrentClass = Actor.GetClass();
			FName CurrentName = CurrentClass.Name;
			if(!ActorNameClassMap.Contains(CurrentName))
			{
				ActorNameClassMap.Add(CurrentName, CurrentClass);
				ActorClassNames.Add(CurrentName);
			}
		}

		FilteredClassNames = ActorClassNames;
		SearchBoxValue = "";
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if(Drawer == nullptr)
			return;

		if(Board == nullptr)
			return;

		if(!Drawer.IsVisible())
			return;

		auto Section = Drawer.Begin();

		if(Section.Button(Board.bInSpawnActorOnGridPointEditor ? "Stop Editing" : "Spawn Actor On Grid Point"))
		{
			Board.bInSpawnActorOnGridPointEditor = !Board.bInSpawnActorOnGridPointEditor;
			Board.bShowGridPoints = false;
			Board.bInSnapActorToGridEditor = false;

			if(Board.bInSpawnActorOnGridPointEditor)
				Editor::RedrawAllViewports();
		}

		if(!Board.bInSpawnActorOnGridPointEditor && Section.Button(Board.bInSnapActorToGridEditor ? "Stop Editing" : "Snap Actor To Grid Point"))
		{
			Board.bInSnapActorToGridEditor = !Board.bInSnapActorToGridEditor;
			if(!Board.bInSnapActorToGridEditor)
				Board.TempSnapEditorActor = nullptr;

			Board.bShowGridPoints = false;
		}

		if(Board.bInSpawnActorOnGridPointEditor)
		{
			bool bSearched = false;

			auto HorizontalBox = Section.HorizontalBox();
			HorizontalBox.Text("Spawn Actor Class");
			HorizontalBox.SlotPadding(10.0, 0.0);

			FString PreviousSearchBoxValue = SearchBoxValue;
			SearchBoxValue = HorizontalBox.SearchBox().Value(SearchBoxValue);
			if(PreviousSearchBoxValue != SearchBoxValue)
			{
				TArray<FString> Keywords = String::ParseIntoArray(SearchBoxValue, " ");
				FilteredClassNames.Empty();
				for(FName ClassName : ActorClassNames)
				{
					bool bContainsAllKeywords = true;
					for(FString Keyword : Keywords)
					{
						FString ClassString = FString(ClassName);
						if(!ClassString.Contains(Keyword))
						{
							bContainsAllKeywords = false;
							break;
						}
					}

					if(bContainsAllKeywords)
						FilteredClassNames.Add(ClassName);
				}
				bSearched = true;
			}

			FName ClassName = n"None";
			if(Board.SpawnActorClass != nullptr)
				ClassName = Board.SpawnActorClass.Get().Name;
			int SelectedIndex = FilteredClassNames.FindIndex(ClassName);
			SelectedIndex = Math::Max(SelectedIndex, 0);
			int PreviousIndex = SelectedIndex;
			SelectedIndex = HorizontalBox.ComboBox().Items(FilteredClassNames).Value(FilteredClassNames[SelectedIndex]).SelectedIndex;
			if(bSearched || PreviousIndex != SelectedIndex)
			{
				Board.SpawnActorClass = ActorNameClassMap[FilteredClassNames[SelectedIndex]];
			}
		}
		else if(Board.bInSnapActorToGridEditor)
		{
			{
				auto HorizontalBox = Section.HorizontalBox();
				Board.bKeepHeightInSnapActorEditor = HorizontalBox.CheckBox().Checked(Board.bKeepHeightInSnapActorEditor);
				HorizontalBox.Text("Keep Current Actor Height");
			}

			if(Board.TempSnapEditorActor == nullptr)
			{
				bool bSearched = false;

				auto HorizontalBox = Section.HorizontalBox();
				HorizontalBox.Text("Snap Actor Class Filter");
				HorizontalBox.SlotPadding(10.0, 0.0);

				FString PreviousSearchBoxValue = SearchBoxValue;
				SearchBoxValue = HorizontalBox.SearchBox().Value(SearchBoxValue);
				if(PreviousSearchBoxValue != SearchBoxValue)
				{
					TArray<FString> Keywords = String::ParseIntoArray(SearchBoxValue, " ");
					FilteredClassNames.Empty();
					for(FName ClassName : ActorClassNames)
					{
						bool bContainsAllKeywords = true;
						for(FString Keyword : Keywords)
						{
							FString ClassString = FString(ClassName);
							if(!ClassString.Contains(Keyword))
							{
								bContainsAllKeywords = false;
								break;
							}
						}

						if(bContainsAllKeywords)
							FilteredClassNames.Add(ClassName);
					}
					bSearched = true;
				}

				FName ClassName = n"None";
				if(Board.SnapActorClassFilter != nullptr)
					ClassName = Board.SnapActorClassFilter.Get().Name;
				int SelectedIndex = FilteredClassNames.FindIndex(ClassName);
				SelectedIndex = Math::Max(SelectedIndex, 0);
				int PreviousIndex = SelectedIndex;
				SelectedIndex = HorizontalBox.ComboBox().Items(FilteredClassNames).Value(FilteredClassNames[SelectedIndex]).SelectedIndex;
				if(bSearched || PreviousIndex != SelectedIndex)
				{
					Board.SnapActorClassFilter = ActorNameClassMap[FilteredClassNames[SelectedIndex]];
				}
			}

			if(Board.TempSnapEditorActor == nullptr)
				Section.Text("Please Select Actor!");
			else
				Section.Text(f"Selected Actor: {Board.TempSnapEditorActor.Name}");
		}

		if(!Board.bInSnapActorToGridEditor && !Board.bInSpawnActorOnGridPointEditor && Section.Button(Board.bShowGridPoints ? "Hide Grid Points" : "Show Grid Points"))
		{
			Board.bShowGridPoints = !Board.bShowGridPoints;
		}
	}
}
#endif