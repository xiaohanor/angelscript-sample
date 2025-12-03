event void FAIslandOverloadScrewListenerSignature();

UCLASS(Abstract)
class AIslandSidescrollerShootableScrewListener : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;

	UPROPERTY()
	FAIslandOverloadScrewListenerSignature OnCompleted;
	
	UPROPERTY()
	FAIslandOverloadScrewListenerSignature OnReset;

	UPROPERTY(EditAnywhere, Category = "Setup")
	TArray<AIslandSidescrollerShootableScrew> Children;

	UPROPERTY(EditAnywhere, Category = "Setup")
	bool bResettable;

	UPROPERTY(EditAnywhere, Category = "Setup")
	float ResetTimer = 5;
	float TimeUntilResetTimer = ResetTimer;

	UPROPERTY(EditAnywhere, Category = "Setup")
	bool bDisablePanelsOnComplete;

	UPROPERTY()
	bool bFinished;
	int ChildCount;
	int ChildrenActivated;

	UPROPERTY(EditInstanceOnly)
	TSubclassOf<UCameraShakeBase> CameraShake;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		ChildCount = Children.Num();
		for (auto Child : Children)
		{
			Child.ScrewListener = this;
		}

		if (!bResettable)
			SetActorTickEnabled(false);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (!bFinished)
			return;

		TimeUntilResetTimer = TimeUntilResetTimer - DeltaSeconds;
		if (TimeUntilResetTimer <= 0)
		{
			ResetLocks();
		}
	}

	UFUNCTION()
	void CheckChildren()
	{
		if(bFinished)
			return;

		bool bShouldFinish = false;
		for (auto Child : Children)
		{
			if(Child.bIsOvercharged)
			{
				bShouldFinish = true;
				ChildrenActivated++;
			}
			if(Child.bIsOvercharged == false)
			{
				bShouldFinish = false;
			}
		}
		for (auto Child : Children)
		{
			if(Child.bIsOvercharged == false)
			{
				bShouldFinish = false;
			}
		}

		if(!bShouldFinish)
		{
			if (bResettable)
				OnReset.Broadcast();
			
			return;
		}

		// Call this on both sides so that if one side has finished the puzzle it is also finished on the other side.
		CrumbFinish();
	}

	UFUNCTION(CrumbFunction)
	private void CrumbFinish()
	{
		// Since this might get called twice if both the remote side and control side thinks it is finished so return in that case
		if(bFinished)
			return;

		bFinished = true;
		UIslandShootableScrewListenerEffectHandler::Trigger_OnListenerFinished(this);
		
		OnCompleted.Broadcast();
		if (CameraShake != nullptr) {
			Game::GetMio().PlayCameraShake(CameraShake, this, 1.0);
			Game::GetZoe().PlayCameraShake(CameraShake, this, 1.0);
		}

		if (bDisablePanelsOnComplete)
		{
			for (auto Child : Children)
			{
				Child.DisableScrew();
			}
		}

		if (bResettable)
			TimeUntilResetTimer = ResetTimer;
	}

	UFUNCTION()
	void ResetLocks()
	{
		if(!bFinished)
			return;

		bFinished = false;
		UIslandShootableScrewListenerEffectHandler::Trigger_OnPanelsReset(this);
		OnReset.Broadcast();
	}

	UFUNCTION()
	void ForceFinishPuzzle()
	{
		for (auto Child : Children)
		{
			Child.bIsOvercharged = true;
		}
		CheckChildren();
	}
}

UCLASS(Abstract)
class UIslandShootableScrewListenerEffectHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnListenerFinished() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnPanelsReset() {}
}