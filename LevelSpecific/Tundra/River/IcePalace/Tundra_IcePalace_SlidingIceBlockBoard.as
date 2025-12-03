struct FTundraGridPoint
{
	int X;
	int Y;

	FTundraGridPoint(int In_X, int In_Y)
	{
		X = In_X;
		Y = In_Y;
	}

	FTundraGridPoint(FVector Vector)
	{
		X = Math::RoundToInt(Vector.X);
		Y = Math::RoundToInt(Vector.Y);
	}

	FTundraGridPoint(FVector2D Vector)
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
		this = FTundraGridPoint(Vector);
	}

	void opAssign(FVector2D Vector2D)
	{
		this = FTundraGridPoint(Vector2D);
	}

	bool opEquals(FTundraGridPoint Other) const
	{
		return X == Other.X && Y == Other.Y;
	}

	FTundraGridPoint opAdd(FTundraGridPoint Other) const
	{
		FTundraGridPoint Out = this;
		Out.X += Other.X;
		Out.Y += Other.Y;
		return Out;
	}

	void opAddAssign(FTundraGridPoint Other)
	{
		this = opAdd(Other);
	}

	FTundraGridPoint opSub(FTundraGridPoint Other) const
	{
		FTundraGridPoint Out = this;
		Out.X -= Other.X;
		Out.Y -= Other.Y;
		return Out;
	}

	void opSubAssign(FTundraGridPoint Other)
	{
		this = opSub(Other);
	}

	FTundraGridPoint opMul(FTundraGridPoint Other) const
	{
		FTundraGridPoint Out = this;
		Out.X *= Other.X;
		Out.Y *= Other.Y;
		return Out;
	}

	void opMulAssign(FTundraGridPoint Other)
	{
		this = opMul(Other);
	}
}

class ATundra_IcePalace_SlidingIceBlockBoard : AHazeActor
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
	UTundra_IcePalace_SlidingIceBlockBoardVisualizerComponent VisualizerComp;
#endif

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedActorComp;

	/* Amount of grid points per side of the board */
	UPROPERTY(EditAnywhere)
	int BoardGridPointSize = 5;

	/* The length of a side on a grid point */
	UPROPERTY(EditAnywhere)
	float GridPointSize = 600.0;

	UPROPERTY(EditAnywhere, Category = "Visual Editing")
	FTundraGridPoint ExitNode;

#if EDITOR
	UPROPERTY(NotVisible, BlueprintHidden)
	bool bKeepHeightInSnapActorEditor = true;

	// Visualizer stuff
	bool bInExitNodeEditor = false;
	bool bShowGridPoints = false;
	bool bInSnapActorToGridEditor = false;

	UPROPERTY(EditInstanceOnly, AdvancedDisplay)
	TSubclassOf<AHazeActor> SnapActorClassFilter;

	AActor TempSnapEditorActor;
#endif

	TArray<FTundraGridPoint> BlockedGridPoints;

#if EDITOR
	UFUNCTION(BlueprintOverride)
	void OnActorModifiedInEditor()
	{
		// As the grid is made now, it only supports uneven amount of grid points per side.
		if((BoardGridPointSize % 2) == 0)
			BoardGridPointSize++;
	}
#endif

	FVector GetWorldLocationOfGridPoint(FTundraGridPoint GridPoint) const
	{
		return ActorLocation + (ActorForwardVector * GridPoint.X * GridPointSize) + (ActorRightVector * GridPoint.Y * GridPointSize);
	}

	FTundraGridPoint GetClosestGridPoint(FVector WorldLocation) const
	{
		FVector LocalLocation = ActorTransform.InverseTransformPosition(WorldLocation);
		float GridPointX = LocalLocation.X / GridPointSize;
		float GridPointY = LocalLocation.Y / GridPointSize;
		int RoundedX = Math::RoundToInt(GridPointX);
		int RoundedY = Math::RoundToInt(GridPointY);
		return FTundraGridPoint(Math::Clamp(RoundedX, -BoardExtents, BoardExtents), Math::Clamp(RoundedY, -BoardExtents, BoardExtents));
	}

	bool IsGridPointWithinGrid(FTundraGridPoint GridPoint) const
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

	bool IsGridPointExitNode(FTundraGridPoint GridPoint) const
	{
		return GridPoint == ExitNode;
	}

	bool IsGridPointOnEdge(FTundraGridPoint GridPoint, FTundraGridPoint&out EdgeNormal) const
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
		EdgeNormal = FTundraGridPoint(X, Y);
		return true;
	}

	bool IsGridPointOnEdge(FTundraGridPoint GridPoint) const
	{
		return Math::Abs(GridPoint.X) == BoardExtents || Math::Abs(GridPoint.Y) == BoardExtents;
	}

	int GetBoardExtents() const property
	{
		return Math::IntegerDivisionTrunc(BoardGridPointSize, 2);
	}

	void AddGridPointBlocker(FTundraGridPoint GridPoint)
	{
		BlockedGridPoints.Add(GridPoint);
	}

	void RemoveGridPointBlocker(FTundraGridPoint GridPoint)
	{
		BlockedGridPoints.Remove(GridPoint);
	}

	bool IsGridPointBlocked(FTundraGridPoint GridPoint) const
	{
		return BlockedGridPoints.Contains(GridPoint);
	}
}

#if EDITOR
class UTundra_IcePalace_SlidingIceBlockBoardVisualizerComponent : UActorComponent
{
	default bIsEditorOnly = true;
}

class UTundra_IcePalace_SlidingIceBlockBoardVisualizer : UHazeScriptComponentVisualizer
{
	default VisualizedClass = UTundra_IcePalace_SlidingIceBlockBoardVisualizerComponent;

	UFUNCTION(BlueprintOverride)
	void VisualizeComponent(const UActorComponent Component)
	{
		const float LineThickness = 10.0;

		auto Board = Cast<ATundra_IcePalace_SlidingIceBlockBoard>(Component.Owner);
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

		if(Board.bInSnapActorToGridEditor)
		{
			RenderSnapActorToGridEditor();
		}
		else if(Board.bInExitNodeEditor)
		{
			RenderExitNodeEditor();
		}
		else if(Board.bShowGridPoints)
		{
			RenderGridPoints();
		}
		else
		{
			DrawWorldString("Exit Node", Board.GetWorldLocationOfGridPoint(Board.ExitNode), FLinearColor::Red, 1.5, bCenterText = true);
		}

		Editor::ActivateVisualizer(Cast<UTundra_IcePalace_SlidingIceBlockBoardVisualizerComponent>(Component));
	}

	void RenderExitNodeEditor()
	{
		auto Board = Cast<ATundra_IcePalace_SlidingIceBlockBoard>(GetEditingComponent().Owner);
		int BoardExtents = Board.BoardExtents;
		for(int x = -BoardExtents; x <= BoardExtents; x++)
		{
			for(int y = -BoardExtents; y <= BoardExtents; y++)
			{
				if(Math::Abs(x) != BoardExtents && Math::Abs(y) != BoardExtents)
					continue;

				FTundraGridPoint GridPoint = FTundraGridPoint(x, y);

				SetRenderForeground(true);
				SetHitProxy(FName(f"{x},{y}"), EVisualizerCursor::Hand);
				DrawPoint(Board.GetWorldLocationOfGridPoint(GridPoint), GridPoint == Board.ExitNode ? FLinearColor::Red : FLinearColor::White, 50.0);
				ClearHitProxy();
			}
		}
	}

	void RenderSnapActorToGridEditor()
	{
		auto Board = Cast<ATundra_IcePalace_SlidingIceBlockBoard>(GetEditingComponent().Owner);
		if(Board.TempSnapEditorActor == nullptr)
			return;

		FBox Bounds = Board.TempSnapEditorActor.GetActorLocalBoundingBox(true);
		DrawWireBox(Board.TempSnapEditorActor.ActorTransform.TransformPosition(Bounds.Center), Bounds.Extent * Board.TempSnapEditorActor.ActorScale3D, Board.TempSnapEditorActor.ActorQuat, FLinearColor::Red, 20);

		int BoardExtents = Board.BoardExtents;
		for(int x = -BoardExtents; x <= BoardExtents; x++)
		{
			for(int y = -BoardExtents; y <= BoardExtents; y++)
			{
				FTundraGridPoint GridPoint = FTundraGridPoint(x, y);

				SetRenderForeground(true);
				SetHitProxy(FName(f"{x},{y}"), EVisualizerCursor::Hand);
				DrawPoint(Board.GetWorldLocationOfGridPoint(GridPoint), FLinearColor::White, 50.0);
				ClearHitProxy();
			}
		}
	}

	void RenderGridPoints()
	{
		auto Board = Cast<ATundra_IcePalace_SlidingIceBlockBoard>(GetEditingComponent().Owner);
		int BoardExtents = Board.BoardExtents;
		for(int x = -BoardExtents; x <= BoardExtents; x++)
		{
			for(int y = -BoardExtents; y <= BoardExtents; y++)
			{
				FTundraGridPoint GridPoint = FTundraGridPoint(x, y);
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
		FTundraGridPoint GridPoint = FTundraGridPoint(X, Y);

		auto Board = Cast<ATundra_IcePalace_SlidingIceBlockBoard>(GetEditingComponent().Owner);
		if(Board.bInSnapActorToGridEditor)
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
		else if(Board.bInExitNodeEditor)
		{
			Editor::BeginTransaction("Select Exit Node", Board);
			Board.Modify();
			Board.ExitNode = GridPoint;
			Editor::EndTransaction();
		}
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool HandleInputKey(FKey Key, EInputEvent Event)
	{
		auto Board = Cast<ATundra_IcePalace_SlidingIceBlockBoard>(GetEditingComponent().Owner);
		if(!Board.bInSnapActorToGridEditor)
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

class UTundra_IcePalace_SlidingIceBlockBoardDetailsCustomization : UHazeScriptDetailCustomization
{
	default DetailClass = ATundra_IcePalace_SlidingIceBlockBoard;

	ATundra_IcePalace_SlidingIceBlockBoard Board;
	UHazeImmediateDrawer Drawer;
	TArray<AHazeActor> Actors;
	TMap<FName, UClass> ActorNameClassMap;
	TArray<FName> ActorClassNames;
	TArray<FName> FilteredClassNames;
	FString SearchBoxValue;

	UFUNCTION(BlueprintOverride)
	void CustomizeDetails()
	{
		Board = Cast<ATundra_IcePalace_SlidingIceBlockBoard>(GetCustomizedObject());
		Board.bInExitNodeEditor = false;
		Board.bShowGridPoints = false;
		Board.bInSnapActorToGridEditor = false;
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

		if(!Board.IsGridPointOnEdge(Board.ExitNode))
			Board.ExitNode = FTundraGridPoint(-Board.BoardExtents, -Board.BoardExtents);

		if(!Board.bInExitNodeEditor && Section.Button(Board.bInSnapActorToGridEditor ? "Stop Editing" : "Snap Actor To Grid Point"))
		{
			Board.bInSnapActorToGridEditor = !Board.bInSnapActorToGridEditor;
			if(!Board.bInSnapActorToGridEditor)
				Board.TempSnapEditorActor = nullptr;

			Board.bInExitNodeEditor = false;
			Board.bShowGridPoints = false;
		}

		if(Board.bInSnapActorToGridEditor)
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

		if(!Board.bInSnapActorToGridEditor)
		{
			auto HorizontalBox = Section.HorizontalBox();
			if(HorizontalBox.Button(Board.bInExitNodeEditor ? "Stop Editing" : "Edit Exit Node"))
			{
				Board.bInExitNodeEditor = !Board.bInExitNodeEditor;
				if(Board.bInExitNodeEditor)
					Editor::RedrawAllViewports();

				Board.bShowGridPoints = false;
			}

			HorizontalBox.Text(f"Current Exit Node: {Board.ExitNode.X}, {Board.ExitNode.Y}");
		}

		if(!Board.bInExitNodeEditor && !Board.bInSnapActorToGridEditor && Section.Button(Board.bShowGridPoints ? "Hide Grid Points" : "Show Grid Points"))
		{
			Board.bShowGridPoints = !Board.bShowGridPoints;
		}
	}
}
#endif