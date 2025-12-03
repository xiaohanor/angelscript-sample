
UCLASS(Abstract)
class UWorld_Summit_WaterTempleInner_Interactable_WaterfallPuzzle_Waterfall_SoundDef : USoundDefBase
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	/* END OF AUTO-GENERATED CODE */

	UPROPERTY(EditDefaultsOnly)
	TSoftObjectPtr<ASummitWaterfallButton> WaterfallButtonPtr;

	UPROPERTY(EditInstanceOnly)
	bool bUseFirstButton = true;

	float WaterfallStartPosLerpTime = 0.0;
	float WaterfallEndPosLerpTime = 0.0;
	TArray<FAkSoundPosition> WaterfallSoundPositions;
	default WaterfallSoundPositions.SetNum(2);
	private bool bWaterfallActive = false;

	UFUNCTION(BlueprintEvent)
	void WaterfallActivated() {};

	UFUNCTION(BlueprintEvent)
	void WaterfallDeactivated() {};

	AHazeNiagaraActor GetWaterfallNiagaraActor() const property
	{
		return NiagaraActor;
	}

	ASpotSound SpotSoundOwner;	
	UHazeSplineComponent SplineComp;
	ASummitWaterfallButton WaterfallButton;
	AHazeNiagaraActor NiagaraActor;

	UFUNCTION(BlueprintOverride)
	void ParentSetup()
	{
		SpotSoundOwner = Cast<ASpotSound>(HazeOwner);
		SplineComp = UHazeSplineComponent::Get(SpotSoundOwner);

		WaterfallButton = WaterfallButtonPtr.Get();

		if (WaterfallButton != nullptr)
		{
			if (!bUseFirstButton)
			{
				WaterfallButton = WaterfallButton.SiblingButton;
			}

			NiagaraActor = WaterfallButton.WaterfallToActivate;
			EffectEvent::LinkActorToReceiveEffectEventsFrom(HazeOwner, WaterfallButton);
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		if (WaterfallButton.bIsActive && !bWaterfallActive)
		{
			OnButtonPress();
		}
		else if (bWaterfallActive)
		{
			OnButtonUnPress();
		}
	}

	UFUNCTION(BlueprintOverride)
	bool OverrideEmitterSceneAttachment(FName EmitterName, FName& ComponentName, AHazeActor& TargetActor,
										FName& BoneName, bool& bUseAttach)
	{
		TargetActor = WaterfallNiagaraActor;
		bUseAttach = true;
		ComponentName = EmitterName == n"DefaultEmitter" ? n"WaterfallTop" : n"WaterfallBottom";
		return true;
	}

	UPROPERTY(BlueprintReadOnly)
	float WaterfallActivationEmitterLerpTime = 3.0;

	UFUNCTION()
	void OnButtonPress()
	{
		WaterfallEndPosLerpTime = 0.0;
		bWaterfallActive = true;
		WaterfallActivated();
	}

	UFUNCTION()
	void OnButtonUnPress()
	{
		bWaterfallActive = false;
		WaterfallStartPosLerpTime = 0.0; 
		WaterfallDeactivated();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaSeconds)
	{	
		float StartPosAlpha = 0.0;
		if(!bWaterfallActive)
		{
			WaterfallStartPosLerpTime += DeltaSeconds;
			StartPosAlpha = Math::Saturate(WaterfallStartPosLerpTime / WaterfallActivationEmitterLerpTime);
		}

		WaterfallEndPosLerpTime += DeltaSeconds;
		const float EndPosAlpha = Math::Saturate(WaterfallEndPosLerpTime / WaterfallActivationEmitterLerpTime);
	
		const FVector WaterfallStartPos =  SplineComp.GetWorldLocationAtSplineDistance(SplineComp.SplineLength * StartPosAlpha);
		const FVector WaterfallEndPos = SplineComp.GetSplinePositionAtSplineDistance(SplineComp.SplineLength * EndPosAlpha).WorldLocation;

		for(auto Player : Game::GetPlayers())
		{
			FVector ClosestWaterfallPlayerPos = Math::ClosestPointOnLine(WaterfallStartPos, WaterfallEndPos, Player.ActorLocation);
			WaterfallSoundPositions[int(Player.Player)].SetPosition(ClosestWaterfallPlayerPos);
		}

		DefaultEmitter.AudioComponent.SetMultipleSoundPositions(WaterfallSoundPositions);
	}
}