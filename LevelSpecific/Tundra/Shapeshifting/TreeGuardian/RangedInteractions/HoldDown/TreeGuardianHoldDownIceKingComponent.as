delegate void FOnHoldDownIceKingButtonMashCompleted();
event void FHoldDownIceKingEvent();
event void FHoldDownIceKingCompletedEvent(bool bIsIceKing);

class UTreeGuardianHoldDownIceKingComponent : UActorComponent
{
	AHazePlayerCharacter Player;
	bool bButtonMashIsActive = false;

	FHoldDownIceKingCompletedEvent OnMashCompleted;
	FHoldDownIceKingEvent OnMashFailed;
	UHazeCrumbSyncedFloatComponent SyncedMashProgress;
	bool bIsIceKing = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		SyncedMashProgress = UHazeCrumbSyncedFloatComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(!bButtonMashIsActive)
			return;

		if(!HasControl())
			return;

		SyncedMashProgress.Value = Math::FInterpTo(SyncedMashProgress.Value, Player.GetButtonMashProgress(this), DeltaSeconds, 3);

		if(SyncedMashProgress.Value >= 0.95)
		{
			CrumbMashComplete();
		}

		if(SyncedMashProgress.Value <= 0)
		{
			CrumbMashFail();
		}

		float Delta = Math::Abs(Player.GetButtonMashProgress(this) - SyncedMashProgress.Value) / DeltaSeconds;
			
		float FFStrength = Math::GetMappedRangeValueClamped(FVector2D(0, 20), FVector2D(0, 1), Delta);
		float LeftFF = FFStrength;
		float RightFF = FFStrength;
		Game::Zoe.SetFrameForceFeedback(LeftFF, RightFF, 0.0, 0.0);
	}

	UFUNCTION(CrumbFunction)
	private void CrumbMashComplete()
	{
		OnMashCompleted.Broadcast(bIsIceKing);
		StopHoldDownIceKingButtonMash();
	}

	UFUNCTION(CrumbFunction)
	private void CrumbMashFail()
	{
		OnMashFailed.Broadcast();
		StopHoldDownIceKingButtonMash();
	}

	void StartHoldDownIceKingButtonMash(FButtonMashSettings ButtonMashSettings, float StartingProgress, USceneComponent InteractionComponent)
	{
		SyncedMashProgress.Value = StartingProgress;
		FButtonMashSettings TempMashSettings = ButtonMashSettings;
		
		ATundraBoss Boss = Cast<ATundraBoss>(InteractionComponent.Owner); 
		if(Boss != nullptr)
		{
			bIsIceKing = true;
			TempMashSettings.WidgetAttachComponent = Boss.OrbImpactFX;
		}
		else
		{
			bIsIceKing = false;
			TempMashSettings.WidgetAttachComponent = InteractionComponent;
		}
		
		Player.StartButtonMash(TempMashSettings, this);
		Player.SnapButtonMashProgress(this, 0.5);
		bButtonMashIsActive = true;
	}

	void StopHoldDownIceKingButtonMash()
	{
		Player.StopButtonMash(this);
		bButtonMashIsActive = false;
	}

	float GetInterpolatedMashProgress() const
	{
		return SyncedMashProgress.Value;
	}
};