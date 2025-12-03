enum ESolarFlareQuickCoverInteractionSide
{
	None,
	Left,
	Right
}

UCLASS(Abstract)
class UWorld_SolarFlare_Shared_Interactable_QuickCover_SoundDef : USoundDefBase
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	UFUNCTION(BlueprintEvent)
	void QuickCoverImpact(FSolarFlareQuickCoverGeneralParams Params){}

	UFUNCTION(BlueprintEvent)
	void QuickCoverOff(FSolarFlareQuickCoverGeneralParams Params){}

	UFUNCTION(BlueprintEvent)
	void QuickCoverOn(FSolarFlareQuickCoverGeneralParams Params){}

	UFUNCTION(BlueprintEvent)
	void QuickCoverButtonMashing(FSolarFlareQuickCoverButtonMashParams Params){}

	/* END OF AUTO-GENERATED CODE */

	UPROPERTY(BlueprintReadOnly)
	ASolarFlareQuickCover QuickCover;

	// InteractionComp 2
	UPROPERTY(BlueprintReadOnly, VisibleAnywhere)
	UHazeAudioEmitter LeftInteractionEmitter;

	// InteractionComp 1	
	UPROPERTY(BlueprintReadOnly, VisibleAnywhere)
	UHazeAudioEmitter RightInteractionEmitter;

	private TPerPlayer<UHazeAudioEmitter> PlayerInteractionEmitters;

	UFUNCTION(BlueprintOverride)
	void ParentSetup()
	{
		QuickCover = Cast<ASolarFlareQuickCover>(HazeOwner);
	}

	UFUNCTION(BlueprintCallable)
	void SetPlayerInteractionEmitter(AHazePlayerCharacter Player, const ESolarFlareQuickCoverInteractionSide Side = ESolarFlareQuickCoverInteractionSide::None)
	{
		UHazeAudioEmitter EmitterToSet = nullptr;
		switch(Side)
		{
			case(ESolarFlareQuickCoverInteractionSide::Left): EmitterToSet = LeftInteractionEmitter; break;
			case(ESolarFlareQuickCoverInteractionSide::Right): EmitterToSet = RightInteractionEmitter; break;
			default: break;
		}

		PlayerInteractionEmitters[Player] = EmitterToSet;
	}

	UFUNCTION(BlueprintPure)
	void GetInteractionEmitterForPlayer(AHazePlayerCharacter Player, UHazeAudioEmitter&out Emitter)
	{
		Emitter = PlayerInteractionEmitters[Player];
	}
}