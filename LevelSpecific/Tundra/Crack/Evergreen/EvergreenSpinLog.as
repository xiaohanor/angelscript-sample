class AEvergreenSpinLog : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent Log;

	UPROPERTY(DefaultComponent)
	UHazeCrumbSyncedRotatorComponent SyncedRotation;
	default SyncedRotation.SyncRate = EHazeCrumbSyncRate::PlayerSynced;

	UPROPERTY(DefaultComponent)
	UHazeMovablePlayerTriggerComponent MovablePlayerTrigger;
	default MovablePlayerTrigger.TriggeredByPlayers = EHazeSelectPlayer::Mio;

	UPROPERTY(DefaultComponent)
	UHazeMovablePlayerTriggerComponent MovablePlayerExitTrigger;
	default MovablePlayerExitTrigger.TriggeredByPlayers = EHazeSelectPlayer::Mio;

	UPROPERTY(EditAnywhere)
	AEvergreenLifeManager LifeManager;

	UPROPERTY(EditAnywhere)
	float RotationSpeed = 10;

	bool bPlayerEnteredSpinLog;
	bool bPlayerIsFollowingSpinLog;
	UPlayerMovementComponent MoveComp;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SetActorControlSide(Game::Zoe);
		SyncedRotation.Value = ActorRelativeRotation;
		MovablePlayerTrigger.OnPlayerEnter.AddUFunction(this, n"OnPlayerEnterSpinLog");
		MovablePlayerExitTrigger.OnPlayerEnter.AddUFunction(this, n"OnPlayerLeaveSpinLog");
		MoveComp = UPlayerMovementComponent::Get(Game::Mio);

		FTransform TriggerTransform = MovablePlayerTrigger.WorldTransform;
		MovablePlayerTrigger.SetAbsoluteAndUpdateTransform(true, true, true, TriggerTransform);
		FTransform ExitTriggerTransform = MovablePlayerExitTrigger.WorldTransform;
		MovablePlayerExitTrigger.SetAbsoluteAndUpdateTransform(true, true, true, ExitTriggerTransform);
	}

	UFUNCTION()
	private void OnPlayerEnterSpinLog(AHazePlayerCharacter Player)
	{
		bPlayerEnteredSpinLog = true;
	}

	UFUNCTION()
	private void OnPlayerLeaveSpinLog(AHazePlayerCharacter Player)
	{
		bPlayerEnteredSpinLog = false;
		SetFollowMovement(false);
		bPlayerIsFollowingSpinLog = false;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(HasControl())
		{
			SyncedRotation.Value += FRotator(0, 0, LifeManager.LifeComp.HorizontalAlpha * RotationSpeed * DeltaSeconds);

			if(bPlayerEnteredSpinLog && !bPlayerIsFollowingSpinLog && MoveComp.HasGroundContact())
			{
				SetFollowMovement(true);
				bPlayerIsFollowingSpinLog = true;
			}
		}

		SetActorRelativeRotation(SyncedRotation.Value);
	}

	private void SetFollowMovement(bool bFollow)
	{
		if(!HasControl())
			return;

		CrumbSetFollowMovement(bFollow);
	}

	UFUNCTION(CrumbFunction)
	private void CrumbSetFollowMovement(bool bFollow)
	{
		if(bFollow)
			MoveComp.ApplyCrumbSyncedRelativePosition(this, Log);
		else
			MoveComp.ClearCrumbSyncedRelativePosition(this);
	}
};