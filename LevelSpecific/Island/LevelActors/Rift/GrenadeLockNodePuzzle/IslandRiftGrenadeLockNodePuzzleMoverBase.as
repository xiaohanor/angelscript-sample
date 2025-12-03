struct FIslandRiftGrenadeLockNodePuzzleMovingMovableData
{
	AIslandRiftGrenadeLockNodePuzzleMovable Movable;
	AIslandRiftGrenadeLockNodePuzzleNode FromNode;
	AIslandRiftGrenadeLockNodePuzzleNode ToNode;
}

struct FIslandRiftGrenadeLockNodePuzzleMoverPanelData
{
	UPROPERTY()
	AIslandOverloadShootablePanel Panel;

	UPROPERTY()
	bool bReverseDirection = false;
}

UCLASS(Abstract)
class AIslandRiftGrenadeLockNodePuzzleMoverBase : AHazeActor
{
	default PrimaryActorTick.bStartWithTickEnabled = false;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(EditAnywhere)
	private FRuntimeFloatCurve MoveInterpolation;
	default MoveInterpolation.AddDefaultKey(0.0, 0.0);
	default MoveInterpolation.AddDefaultKey(1.0, 1.0);

	UPROPERTY(EditAnywhere)
	private float MovementDuration = 1.0;

	UPROPERTY(EditInstanceOnly)
	private TArray<FIslandRiftGrenadeLockNodePuzzleMoverPanelData> ControllingShootablePanels;

	UPROPERTY(EditInstanceOnly)
	TArray<AIslandRiftGrenadeLockNodePuzzleNode> Nodes;

	TArray<FIslandRiftGrenadeLockNodePuzzleMovingMovableData> MovablesInMotion;
	float TimeOfStartMove = -100.0;
	float PreviousMoveAlpha = 0.0;
	bool bCurrentMoveShouldBeReversed = false;
	bool bNodesHaveMovables = true;
	TArray<FInstigator> MoverBlockers;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		for(FIslandRiftGrenadeLockNodePuzzleMoverPanelData Panel : ControllingShootablePanels)
		{
			AHazePlayerCharacter PanelPlayer = Game::GetPlayer(Panel.Panel.UsableByPlayer);
			if(Network::IsGameNetworked() && PanelPlayer != Game::GetFirstLocalPlayer())
				continue;

			if(Panel.Panel.UsableByPlayer == EHazePlayer::Mio)
			{
				if(Panel.bReverseDirection)
				{
					Panel.Panel.OnCompleted.AddUFunction(this, n"OnMioShootPanelCompletedReversed");
				}
				else
				{
					Panel.Panel.OnCompleted.AddUFunction(this, n"OnMioShootPanelCompleted");
				}
			}
			else
			{
				if(Panel.bReverseDirection)
				{
					Panel.Panel.OnCompleted.AddUFunction(this, n"OnZoeShootPanelCompletedReversed");
				}
				else
				{
					Panel.Panel.OnCompleted.AddUFunction(this, n"OnZoeShootPanelCompleted");
				}
			}
		}

		for(AIslandRiftGrenadeLockNodePuzzleNode Node : Nodes)
		{
			Node.OnBeginMove.AddUFunction(this, n"OnNodeBeginMove");
			Node.OnEndMove.AddUFunction(this, n"OnNodeEndMove");
		}

		HandleMoverBlockingIfNoNodesHaveMovables();
		ValidateNodes();
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if(!IsMoving())
			return;

		MoveTick(CurrentMoveAlpha);

		for(FIslandRiftGrenadeLockNodePuzzleMovingMovableData Movable : MovablesInMotion)
		{
			MovableMoveTick(Movable, CurrentMoveAlpha);
		}

		PreviousMoveAlpha = CurrentMoveAlpha;

		float TimeAlpha = Math::Saturate(Time::GetGameTimeSince(TimeOfStartMove) / MovementDuration);
		if(TimeAlpha == 1.0)
			StopMove();
	}

	bool IsMoving() const
	{
		return MovablesInMotion.Num() > 0;
	}

	UFUNCTION()
	void AddMoverBlocker(FInstigator Instigator)
	{
		bool bWasBlocked = IsMoverBlocked();
		MoverBlockers.AddUnique(Instigator);

		if(!bWasBlocked)
		{
			OnMoverBlocked();
		}
	}

	UFUNCTION()
	void RemoveMoverBlocker(FInstigator Instigator)
	{
		bool bWasBlocked = IsMoverBlocked();
		MoverBlockers.RemoveSingleSwap(Instigator);

		if(!IsMoverBlocked() && bWasBlocked)
		{
			OnMoverUnblocked();
		}
	}

	UFUNCTION(BlueprintPure)
	bool IsMoverBlocked() const
	{
		return MoverBlockers.Num() > 0;
	}

	protected void OnMoverBlocked()
	{
		for(FIslandRiftGrenadeLockNodePuzzleMoverPanelData Panel : ControllingShootablePanels)
		{
			Panel.Panel.DisablePanel();
		}
	}

	protected void OnMoverUnblocked()
	{
		for(FIslandRiftGrenadeLockNodePuzzleMoverPanelData Panel : ControllingShootablePanels)
		{
			Panel.Panel.EnablePanel();
		}
	}

	UFUNCTION()
	private void OnMioShootPanelCompleted()
	{
		TryStartMove();
	}

	UFUNCTION()
	private void OnMioShootPanelCompletedReversed()
	{
		TryStartMove(true);
	}

	UFUNCTION()
	private void OnZoeShootPanelCompleted()
	{
		TryStartMove();
	}

	UFUNCTION()
	private void OnZoeShootPanelCompletedReversed()
	{
		TryStartMove(true);
	}

	UFUNCTION()
	private void OnNodeBeginMove(AIslandRiftGrenadeLockNodePuzzleMoverBase Mover)
	{
		if(Mover == this)
			return;

		AddMoverBlocker(Mover);
	}

	UFUNCTION()
	private void OnNodeEndMove(AIslandRiftGrenadeLockNodePuzzleMoverBase Mover)
	{
		if(Mover == this)
			return;

		RemoveMoverBlocker(Mover);
		HandleMoverBlockingIfNoNodesHaveMovables();
	}

	private void HandleMoverBlockingIfNoNodesHaveMovables()
	{
		SnapMovablesToClosestNode();

		bool bNewNodesHaveMovables = DoesNodesHaveMovables();

		if(bNewNodesHaveMovables != bNodesHaveMovables)
		{
			if(bNewNodesHaveMovables)
				RemoveMoverBlocker(this);
			else
				AddMoverBlocker(this);
		}

		bNodesHaveMovables = bNewNodesHaveMovables;
	}

	private void SnapMovablesToClosestNode()
	{
		TListedActors<AIslandRiftGrenadeLockNodePuzzleMovable> ListedMovables;

		for(AIslandRiftGrenadeLockNodePuzzleMovable Movable : ListedMovables.Array)
		{
			if(!Movable.bHasSnappedMovableToNode)
				Movable.SnapMovableToClosestNode();
		}
	}

	private bool DoesNodesHaveMovables()
	{
		for(AIslandRiftGrenadeLockNodePuzzleNode Node : Nodes)
		{
			if(Node.Movable != nullptr)
				return true;
		}

		return false;
	}

	UFUNCTION(NetFunction)
	private void NetTryStartMove(bool bReversed = false)
	{
		if(!HasControl())
			return;

		TryStartMove(bReversed);
	}

	private void TryStartMove(bool bReversed = false)
	{
		if(IsMoverBlocked())
			return;

		if(IsMoving())
			return;

		if(!HasControl())
		{
			NetTryStartMove(bReversed);
			return;
		}
		
		bCurrentMoveShouldBeReversed = bReversed;

		for(int i = 0; i < Nodes.Num(); i++)
		{
			AIslandRiftGrenadeLockNodePuzzleNode Node = Nodes[i];
			if(Node.Movable == nullptr)
				continue;

			FIslandRiftGrenadeLockNodePuzzleMovingMovableData Data;
			Data.Movable = Node.Movable;

			Data.FromNode = Node;
			Data.ToNode = GetDestinationNodeForMovable(i);
			MovablesInMotion.Add(Data);
		}

		CrumbRemoteOnStartMove(MovablesInMotion, bCurrentMoveShouldBeReversed);

		if(MovablesInMotion.Num() > 0)
		{
			StartMove();
		}
	}

	UFUNCTION(CrumbFunction)
	private void CrumbRemoteOnStartMove(TArray<FIslandRiftGrenadeLockNodePuzzleMovingMovableData> CurrentMovablesInMotion, bool bCurrentMoveReversed)
	{
		// Only call on remote!
		if(HasControl())
			return;

		// If we are already moving, stop the current move
		if(IsMoving())
		{
			if(!HasControl())
				return;

			StopMove();
		}

		MovablesInMotion = CurrentMovablesInMotion;
		bCurrentMoveShouldBeReversed = bCurrentMoveReversed;
		StartMove();
	}

	private void StartMove()
	{
		for(auto Node : Nodes)
		{
			Node.Movable = nullptr;
		}

		OnStartMove();
		TimeOfStartMove = Time::GetGameTimeSeconds();
		SetActorTickEnabled(true);
		PreviousMoveAlpha = 0.0;
		UIslandRiftGrenadeLockNodePuzzleEffectHandler::Trigger_OnStartMoving(this);

		for(AIslandRiftGrenadeLockNodePuzzleNode Node : Nodes)
		{
			Node.SetCurrentMover(this);
		}
	}

	// Put ensures in here to make sure the nodes are configured correctly for the specific type of movable.
	protected void ValidateNodes() {}

	// Gets the destination node for the current movable (get the current node with Nodes[CurrentNodeIndex], you can also get its movable from here).
	protected AIslandRiftGrenadeLockNodePuzzleNode GetDestinationNodeForMovable(int CurrentNodeIndex)
	{
		devError("Forgot to implement GetDestinationNode!");
		return nullptr;
	}

	// Gets called once when the mover is started, fill the movables in motion array here!
	protected void OnStartMove() {}

	// Gets called once when the mover has stopped moving
	protected void OnStopMove() {}

	// Gets called every tick for each movable in motion
	protected void MovableMoveTick(FIslandRiftGrenadeLockNodePuzzleMovingMovableData MovableData, float MoveAlpha) {}

	// Gets called every tick once
	protected void MoveTick(float MoveAlpha) {}

	// Will snap the current movables to their destination and end the move
	private void StopMove()
	{
		// Snap complete the move before stopping the move!
		MoveTick(1.0);
		for(FIslandRiftGrenadeLockNodePuzzleMovingMovableData Movable : MovablesInMotion)
		{
			MovableMoveTick(Movable, 1.0);
		}
		PreviousMoveAlpha = 1.0;

		for(FIslandRiftGrenadeLockNodePuzzleMovingMovableData MovableData : MovablesInMotion)
		{
			MovableData.ToNode.Movable = MovableData.Movable;
		}

		OnStopMove();
		UIslandRiftGrenadeLockNodePuzzleEffectHandler::Trigger_OnStopMoving(this);

		for(AIslandRiftGrenadeLockNodePuzzleNode Node : Nodes)
		{
			Node.ClearCurrentMover(this);
		}

		MovablesInMotion.Reset();
		SetActorTickEnabled(false);
	}

	float GetCurrentMoveAlpha() const property
	{
		devCheck(IsMoving(), "Tried to get current move alpha when the mover is not moving");
		float TimeAlpha = Math::Saturate(Time::GetGameTimeSince(TimeOfStartMove) / MovementDuration);
		return MoveInterpolation.GetFloatValue(TimeAlpha);
	}
}