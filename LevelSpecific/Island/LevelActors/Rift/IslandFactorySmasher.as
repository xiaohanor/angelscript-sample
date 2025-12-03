event void FIslandFactorySmasherSignature();

class AIslandFactorySmasher : AHazeActor
{
	default PrimaryActorTick.bStartWithTickEnabled = false;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;
	
	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent DestinationComp;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MovableComp;
	
	UPROPERTY(DefaultComponent, Attach = Root)
	UBoxComponent CollisionBox;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent DestinationOneComp;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent DestinationTwoComp;

	UPROPERTY(DefaultComponent, Attach = MovableComp)
	UHazeMovablePlayerTriggerComponent KillTrigger;

	UPROPERTY(DefaultComponent, Attach = MovableComp)
	UIslandRedBlueStickyGrenadeKillTriggerComponent GrenadeKillTrigger;

	UPROPERTY(DefaultComponent)
	UHazeActionQueueComponent ActionQueue;

	UPROPERTY(EditAnywhere)
	bool bAutoPlay;

	UPROPERTY(EditAnywhere)
	float AnimationDuration = 1;
	
	UPROPERTY(EditAnywhere)
	float MoveBackDuration = 2;
	
	UPROPERTY(EditAnywhere)
	float DelayDuration = 2;

	UPROPERTY(EditAnywhere)
	float AnticipationDistance = 150;

	UPROPERTY(EditAnywhere)
	float OffsetDuration = SMALL_NUMBER;

	UPROPERTY(EditAnywhere)
	bool bWalkerSmasher;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<UDeathEffect> DeathEffect;

	UPROPERTY(EditInstanceOnly, Meta = (EditCondition = "bWalkerSmasher", EditConditionHides))
	AIslandOverloadPanelListener Listener;

	UPROPERTY()
	int WalkerHeadSmashNumber = 1;
	
	UPROPERTY(EditDefaultsOnly)
	FRuntimeFloatCurve MoveCurve;
	default MoveCurve.AddDefaultKey(0.0, 0.0);
	default MoveCurve.AddDefaultKey(1.0, 1.0);

	FTransform StartingTransform;
	FVector StartingPosition;
	FTransform EndingTransform;
	FVector EndingPosition;
	FVector AnticipationPosition;
	bool bMovingUp;

	UPROPERTY()
	FIslandFactorySmasherSignature OnFullyDown;

	bool bMoving = false;
	bool bLooping = false;
	float CurrentCurveValue;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		StartingTransform = MovableComp.GetWorldTransform();
		StartingPosition = StartingTransform.GetLocation();
		EndingTransform = DestinationComp.GetWorldTransform();
		EndingPosition = EndingTransform.GetLocation();
		AnticipationPosition = StartingPosition + (MovableComp.UpVector * AnticipationDistance);

		KillTrigger.OnPlayerEnter.AddUFunction(this, n"OnEnterKillTrigger");

		GrenadeKillTrigger.DisableTrigger(this);

		if (bAutoPlay)
			StartSmashLoop();
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		ActionQueue.ScrubTo(Time::PredictedGlobalCrumbTrailTime - OffsetDuration);
	}

	private void StartSmashLoop()
	{
		SetActorTickEnabled(true);
		bLooping = true;
		ActionQueue.Empty();
		ActionQueue.SetLooping(true);
		ActionQueue.Event(this, n"StartMovingDown");
		ActionQueue.Duration(AnimationDuration, this, n"Move");
		ActionQueue.Event(this, n"HitBottom");
		ActionQueue.Duration(MoveBackDuration, this, n"MoveBack");
		ActionQueue.Event(this, n"OnFullyUp");
		ActionQueue.Idle(DelayDuration / 2);
		ActionQueue.Event(this, n"Anticipation");
		ActionQueue.Duration(DelayDuration / 4, this, n"AnticipationMove");
	}

	UFUNCTION()
	private void Anticipation()
	{
	}

	UFUNCTION()
	private void AnticipationMove(float Alpha)
	{
		CurrentCurveValue = MoveCurve.GetFloatValue(Alpha);
		MovableComp.WorldLocation = Math::Lerp(StartingPosition, AnticipationPosition, CurrentCurveValue);
	}

	UFUNCTION()
	private void StartMovingDown()
	{
		UIslandFactorySmasherEffectHandler::Trigger_OnStartMovingDown(this);
		SetDeathTriggerActive(true);
		GrenadeKillTrigger.EnableTrigger(this);
		if(bWalkerSmasher && Listener != nullptr)
		{
			for(AIslandOverloadShootablePanel Panel : Listener.Children)
			{
				if(WalkerHeadSmashNumber >= 3)
					Panel.SetCompleted();
				else
					Panel.DisablePanel();
			}
		}

		bMovingUp = false;
		bMoving = true;
	}

	UFUNCTION()
	private void HitBottom()
	{
		UIslandFactorySmasherEffectHandler::Trigger_OnHitConstraint(this);
		UIslandFactorySmasherEffectHandler::Trigger_OnStartMovingUp(this);
		SetDeathTriggerActive(false);
		GrenadeKillTrigger.DisableTrigger(this);
		OnFullyDown.Broadcast();

		if (Listener != nullptr)
		{
			for(AIslandOverloadShootablePanel Panel : Listener.Children)
			{
				Panel.OverchargeComp.ResetChargeAlpha(this);
			}
		}
		
		if (bWalkerSmasher && WalkerHeadSmashNumber != 4)
			WalkerHeadSmashNumber = WalkerHeadSmashNumber + 1;

		bMovingUp = true;
	}

	UFUNCTION()
	private void OnFullyUp()
	{
		UIslandFactorySmasherEffectHandler::Trigger_OnFullyUp(this);
		if(bWalkerSmasher && Listener != nullptr && WalkerHeadSmashNumber <= 3)
		{
			for(AIslandOverloadShootablePanel Panel : Listener.Children)
			{
				Panel.EnablePanel();
			}
			Listener.ResetLocks();
		}

		bMoving = false;
	}

	private void SetDeathTriggerActive(bool bActive)
	{
		if(bActive)
			KillTrigger.EnableTrigger(this);
		else
			KillTrigger.DisableTrigger(this);
	}

	UFUNCTION()
	private void OnEnterKillTrigger(AHazePlayerCharacter Player)
	{
		Player.KillPlayer(DeathEffect = DeathEffect);
	}

	UFUNCTION()
	void Start()
	{
		if (!HasControl())
			return;

		CrumbStart(Time::PredictedGlobalCrumbTrailTime);
	}

	UFUNCTION(CrumbFunction)
	private void CrumbStart(float TimeOfStart)
	{
		if (bLooping)
			return;

		if (!bWalkerSmasher || WalkerHeadSmashNumber == 3)
		{
			OffsetDuration = TimeOfStart;
			EndingTransform = DestinationComp.GetWorldTransform();
			EndingPosition = EndingTransform.GetLocation();
			StartSmashLoop();
			return;
		}

		if (bWalkerSmasher && WalkerHeadSmashNumber != 4)
		{
			if (WalkerHeadSmashNumber == 1)
			{
				EndingTransform = DestinationOneComp.GetWorldTransform();
				EndingPosition = EndingTransform.GetLocation();
			}
			if (WalkerHeadSmashNumber == 2)
			{
				EndingTransform = DestinationTwoComp.GetWorldTransform();
				EndingPosition = EndingTransform.GetLocation();
			}
			if (WalkerHeadSmashNumber == 3)
			{
				EndingTransform = DestinationComp.GetWorldTransform();
				EndingPosition = EndingTransform.GetLocation();
			}
		}

		Smash();
	}

	private void Smash()
	{
		ActionQueue.Event(this, n"StartMovingDown");
		ActionQueue.Duration(AnimationDuration, this, n"Move");
		ActionQueue.Event(this, n"HitBottom");
		ActionQueue.Duration(MoveBackDuration, this, n"MoveBack");
		ActionQueue.Event(this, n"OnFullyUp");
	}

	UFUNCTION()
	private void Move(float Alpha)
	{
		CurrentCurveValue = MoveCurve.GetFloatValue(Alpha);
		MovableComp.WorldLocation = Math::Lerp(AnticipationPosition, EndingPosition, CurrentCurveValue);
	}

	UFUNCTION()
	private void MoveBack(float Alpha)
	{
		CurrentCurveValue = MoveCurve.GetFloatValue(Alpha);
		MovableComp.WorldLocation = Math::Lerp(EndingPosition, StartingPosition, CurrentCurveValue);
	}

	// Get the alpha of the current position of the moving platform, between 0 and 1. 0 is bottom and 1 is top
	UFUNCTION(BlueprintPure)
	float GetPositionAlpha() const
	{
		return 1.0 - CurrentCurveValue;
	}
	
	// Get the movement direction of the moving platform, 1 is up and -1 is down, 0 is not moving.
	UFUNCTION(BlueprintPure)
	int GetMoveDirection() const
	{
		if(!bMoving)
			return 0;

		return bMovingUp ? 1 : -1;
	}
}

UCLASS(Abstract)
class UIslandFactorySmasherEffectHandler : UHazeEffectEventHandler
{
	// Triggers when the moving platform starts moving upwards
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStartMovingUp() {}

	// Triggers when the moving platform starts moving downwards
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStartMovingDown() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnFullyUp() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnHitConstraint() {}
}