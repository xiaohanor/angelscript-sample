event void FAIslandOverloadPanelListenerSignature();

struct FIslandOverloadPanelFinishedScope
{
	AIslandOverloadPanelListener Listener;

	FIslandOverloadPanelFinishedScope(AIslandOverloadPanelListener In_Listener)
	{
		Listener = In_Listener;
		Listener.bWithinFinishedScope = true;
	}

	~FIslandOverloadPanelFinishedScope()
	{
		if(Listener == nullptr)
			return;

		Listener.bWithinFinishedScope = false;
	}
}

class AIslandOverloadPanelListener : AHazeActor
{
	default PrimaryActorTick.bStartWithTickEnabled = false;

	UPROPERTY()
	FAIslandOverloadPanelListenerSignature OnCompleted;
	
	UPROPERTY()
	FAIslandOverloadPanelListenerSignature OnReset;

	UPROPERTY(EditAnywhere, Category = "Setup")
	TArray<AIslandOverloadShootablePanel> Children;
	bool bBeingEdited = false;

	UPROPERTY(EditAnywhere, Category = "Setup")
	bool bResettable;

	UPROPERTY(EditAnywhere, Category = "Setup")
	float ResetTimer = 5;
	float TimeUntilResetTimer = ResetTimer;

	UPROPERTY(EditAnywhere, Category = "Setup")
	bool bCompletePanelsOnComplete = false;

	UPROPERTY()
	bool bFinished;
	int ChildCount;
	int ChildrenActivated;
	bool bWithinFinishedScope = false;

	UPROPERTY(EditInstanceOnly)
	TSubclassOf<UCameraShakeBase> CameraShake;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		ChildCount = Children.Num();
		for (auto Child : Children)
		{
			Child.PanelListener = this;
		}

		if (bResettable)
			SetActorTickEnabled(true);
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

		if(bWithinFinishedScope)
			return;

		ChildrenActivated = 0;
		for (auto Child : Children)
		{
			if(Child.IsOvercharged())
				ChildrenActivated++;
		}

		if(ChildrenActivated != ChildCount)
		{
			if (bResettable)
				OnReset.Broadcast();
			
			return;
		}

		if(!HasControl())
			NetFinish();
		else
			CrumbFinish();
	}

	UFUNCTION(NetFunction)
	private void NetFinish()
	{
		if(!HasControl())
			return;

		if(bFinished)
			return;

		CrumbFinish();
	}

	UFUNCTION(CrumbFunction)
	private void CrumbFinish()
	{
		// We do this because this might lead to infinite recursion
		// Child.ResetAndCooldownImpacts(); -> OverchargeComp.ResetChargeAlpha(); -> LocalOnZeroCharge(); -> OnZeroCharge.Broadcast() -> AIslandOverloadShootablePanel::HandleOnZeroCharge() ->
		// PanelListener.CheckChildren(); -> CrumbFinish();
		FIslandOverloadPanelFinishedScope Scope(this);
		// Since this might get called twice if both the remote side and control side thinks it is finished so return in that case
		if(bFinished)
			return;

		bFinished = true;
		UIslandOverloadPanelListenerEffectHandler::Trigger_OnListenerFinished(this);
		
		OnCompleted.Broadcast();
		if (CameraShake != nullptr) {
			Game::GetMio().PlayCameraShake(CameraShake, this, 1.0);
			Game::GetZoe().PlayCameraShake(CameraShake, this, 1.0);
		}

		if (bCompletePanelsOnComplete)
		{
			for (auto Child : Children)
			{
				Child.SetCompleted();
			}
		}

		if (bResettable)
			TimeUntilResetTimer = ResetTimer;
	}

	UFUNCTION()
	void ResetLocks()
	{
		devCheck(!bCompletePanelsOnComplete, "Cannot reset locks with bCompletePanelsOnComplete = true since that is weird communication to the player");
		if(!bFinished)
			return;

		bFinished = false;
		UIslandOverloadPanelListenerEffectHandler::Trigger_OnPanelsReset(this);
		OnReset.Broadcast();
	}

	UFUNCTION()
	void ForceFinishPuzzle()
	{
		if(!HasControl())
			return;

		CrumbFinish();
	}
}

UCLASS(Abstract)
class UIslandOverloadPanelListenerEffectHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnListenerFinished() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnPanelsReset() {}
}