struct FIslandSidescrollerMovablePlatformEffectParams
{
	UPROPERTY(BlueprintReadOnly)
	int Moves;
}

event void FIslandSidescrollerMovablePlatformEvent(AIslandSidescrollerMovablePlatformShootPanel Panel);

class AIslandSidescrollerMovablePlatform : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY()
	FIslandSidescrollerMovablePlatformEvent OnMoveCompleted;

	UPROPERTY(EditInstanceOnly)
	TArray<AIslandSidescrollerMovablePlatformShootPanel> Panels;

	UPROPERTY(EditAnywhere)
	bool bStartActivated = true;

	UPROPERTY(EditAnywhere)
	int NumberOfMoves = 3;
	int CurrentMove = 0;
	int CurrentCompletedMove;

	UPROPERTY(EditAnywhere)
	float MoveDistance = 300;
	
	UPROPERTY(EditAnywhere)
	float AnimationDuration = 0.2;

	FHazeTimeLike MoveAnimation;
	default MoveAnimation.Duration = 1.0;
	default MoveAnimation.UseSmoothCurveZeroToOne();

	FVector OriginalLocation;
	FVector StartLocation;
    FVector EndLocation;
	bool bPredicting = false;

	FHazeTimeLike DelayAnimation;
	default DelayAnimation.Duration = 0.12;
	default DelayAnimation.UseLinearCurveZeroToOne();

	bool bCanMove = true;
	bool bIsMoving = false;
	AIslandSidescrollerMovablePlatformShootPanel CurrentPanel;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SetActorControlSide(Game::Zoe);

		OriginalLocation = ActorLocation;
		StartLocation = OriginalLocation;
        EndLocation = OriginalLocation + GetActorForwardVector() * MoveDistance;

		MoveAnimation.SetPlayRate(1.0 / AnimationDuration);
		MoveAnimation.BindUpdate(this, n"OnUpdate");
		MoveAnimation.BindFinished(this, n"OnFinished");

		DelayAnimation.BindFinished(this, n"OnDelayFinished");

		for(AIslandSidescrollerMovablePlatformShootPanel Panel : Panels)
		{
			Panel.SetPlatform(this);
			Panel.OnStartMovePlatform.AddUFunction(this, n"HandleOvercharge");
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (CurrentPanel != nullptr && CanMove() && CurrentPanel.QueuedUpMoves > 0)
		{
			CurrentPanel.QueuedUpMoves--;
			HandleOvercharge(CurrentPanel);
		}
	}

	UFUNCTION()
	void HandleOvercharge(AIslandSidescrollerMovablePlatformShootPanel Panel)
	{
		if(!bStartActivated)
			return;

		AHazePlayerCharacter ShootingPlayer = Game::GetPlayer(Panel.UsableByPlayer);

		if (!CanMoveAmountInDirection(Panel.bRight, 1))
			return;

		if (!CanMove())
		{
			if (HasControl() && ShootingPlayer.HasControl() && Panel.QueuedUpMoves <= 0)
				Panel.QueuedUpMoves += 1;
			return;
		}

		CurrentPanel = Panel;

		if (HasControl())
		{
			if (ShootingPlayer.HasControl())
				StartPredicting(Panel.bRight);
			NetTriggerCrumbMove(ShootingPlayer, Panel.bRight);
		}
	}

	UFUNCTION(NetFunction)
	void NetTriggerCrumbMove(AHazePlayerCharacter ShootingPlayer, bool bMovingForward)
	{
		bIsMoving = true;
		SetActorControlSide(ShootingPlayer);
		if (!HasControl() || !Network::IsGameNetworked())
		{
			SetStartAndEndLocation(bMovingForward);
			CrumbMovePlatform(bMovingForward, StartLocation, EndLocation);
		}
	}

	UFUNCTION(CrumbFunction)
	private void CrumbMovePlatform(bool bMovingForward, FVector In_StartLocation, FVector In_EndLocation)
	{
		StartLocation = In_StartLocation;
		EndLocation = In_EndLocation;
		LocalMovePlatform(bMovingForward);
	}

	private void StartPredicting(bool bMovingForward)
	{
		OnStartMoving();
		SetStartAndEndLocation(bMovingForward);
		bPredicting = true;
		MoveAnimation.SetPlayRate(1.0);
		MoveAnimation.PlayFromStart();
		bIsMoving = true;
	}

	private void LocalMovePlatform(bool bMovingForward)
	{
		devCheck(CanMoveInDirection(bMovingForward), "Tried to move in a specific direction when we can't move in that direction");

		if(!bPredicting)
		{
			bIsMoving = true;
			SetStartAndEndLocation(bMovingForward);
			OnStartMoving();
		}

		if(bMovingForward)
			CurrentMove++;
		else
			CurrentMove--;

		FIslandSidescrollerMovablePlatformEffectParams Params;
		Params.Moves = CurrentMove;
		UIslandSidescrollerMovablePlatformEffectHandler::Trigger_OnPlatformMoved(this, Params);

		if(bPredicting)
		{
			if(!MoveAnimation.IsPlaying())
			{
				ActorLocation = EndLocation;
				Internal_OnMoveCompleted();
			}
			else
			{
				MoveAnimation.SetPlayRate(1.0 / AnimationDuration);
				MoveAnimation.Play();
			}

			bPredicting = false;
		}
		else
			MoveAnimation.PlayFromStart();
	}

	private void SetStartAndEndLocation(bool bMovingForward)
	{
		StartLocation = Root.GetWorldLocation();
		if (bMovingForward)
			EndLocation = StartLocation + GetActorForwardVector() * MoveDistance;
		else
			EndLocation = StartLocation - GetActorForwardVector() * MoveDistance;
	}

	bool CanMove() const
	{
		if(!bCanMove)
			return false;

		if(bIsMoving)
			return false;

		return true;
	}

	bool CanMoveInDirection(bool bMovingForward) const
	{
		if(bMovingForward && CurrentMove < NumberOfMoves)
			return true;

		if(!bMovingForward && CurrentMove > 0)
			return true;

		return false;
	}

	bool CanMoveAmountInDirection(bool bMovingForward, int Amount) const
	{
		if(bMovingForward && CurrentCompletedMove + Amount <= NumberOfMoves)
			return true;

		if(!bMovingForward && CurrentCompletedMove - Amount >= 0)
			return true;

		return false;
	}

	UFUNCTION()
	void OnUpdate(float Alpha)
	{
		SetActorLocation(Math::Lerp(StartLocation, EndLocation, Alpha));
	}

	UFUNCTION()
	void OnFinished()
	{
		if(!bPredicting)
			Internal_OnMoveCompleted();
	}

	void OnStartMoving()
	{
		bIsMoving = true;

		for(auto Panel : Panels)
		{
			if(Panel.UsableByPlayer == CurrentPanel.UsableByPlayer)
				continue;

			Panel.Panel.OverchargeComp.BlockImpact(this);
		}
	}

	void OnStopMoving()
	{
		bIsMoving = false;

		for(auto Panel : Panels)
		{
			if(Panel.UsableByPlayer == CurrentPanel.UsableByPlayer)
				continue;

			Panel.Panel.OverchargeComp.UnblockImpact(this);
		}
	}

	private void Internal_OnMoveCompleted()
	{
		bCanMove = false;
		DelayAnimation.PlayFromStart();
	}

	UFUNCTION()
	void OnDelayFinished()
	{
		bCanMove = true;

		if(!HasControl() || !Network::IsGameNetworked())
			CrumbCompleteMove(CurrentMove);
	}

	UFUNCTION(CrumbFunction)
	private void CrumbCompleteMove(int CompletedMove)
	{
		CurrentCompletedMove = CompletedMove;
		OnStopMoving();
		OnMoveCompleted.Broadcast(CurrentPanel);
	}

	UFUNCTION()
	void ResetPlatform()
	{
		if (CurrentMove <= 0)
			return;

		bCanMove = true;
		StartLocation = Root.GetWorldLocation();
		EndLocation = StartLocation;
		CurrentMove = 0;
		MoveAnimation.PlayFromStart();
	}
}

UCLASS(Abstract)
class UIslandSidescrollerMovablePlatformEffectHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnPlatformMoved(FIslandSidescrollerMovablePlatformEffectParams Params) {}

};