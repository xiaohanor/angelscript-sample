
UCLASS(Abstract)
class UCharacter_Boss_Sanctuary_Hydra_Medallion_Tether_SoundDef : USoundDefBase
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	UFUNCTION(BlueprintEvent)
	void OnHydraGloryKillCompleted(FSanctuaryBossHydraPlayerTetherEventParams Params){}

	UFUNCTION(BlueprintEvent)
	void OnStartHydraGloryKill(FSanctuaryBossHydraPlayerTetherEventParams Params){}

	UFUNCTION(BlueprintEvent)
	void OnTetherDeactivated(){}

	UFUNCTION(BlueprintEvent)
	void OnTetherActivated(){}

	/* END OF AUTO-GENERATED CODE */

	UMedallionPlayerTetherComponent TetherComp;

	UPROPERTY(BlueprintReadWrite)
	ASanctuaryBossMedallionHydra GloryKillTargetHydra;

	private UHazeAudioEmitter HydraGloryKillEmitter;

	UFUNCTION(BlueprintPure)
	UHazeAudioEmitter GetHydraGloryKillEmitter(ASanctuaryBossMedallionHydra Hydra)
	{
		if(HydraGloryKillEmitter != nullptr)
			return HydraGloryKillEmitter;

		if(Hydra == nullptr)
			return nullptr;

		FHazeAudioEmitterAttachmentParams AttachParams;
		AttachParams.Attachment = Hydra.Root;
		AttachParams.Instigator = this;
		AttachParams.Owner = Hydra;
		AttachParams.bCanAttach = true;

		HydraGloryKillEmitter = Audio::GetPooledEmitter(AttachParams);
		return HydraGloryKillEmitter;
	}

	UFUNCTION(BlueprintCallable)
	void ReturnHydraGloryKillEmitter()
	{
		Audio::ReturnPooledEmitter(this, HydraGloryKillEmitter);
		HydraGloryKillEmitter = nullptr;
	}

	UFUNCTION(BlueprintOverride)
	bool OverrideEmitterSceneAttachment(FName EmitterName, FName& ComponentName, AHazeActor& TargetActor,
										FName& BoneName, bool& bUseAttach)
	{
		TargetActor = HazeOwner;
		bUseAttach = false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void ParentSetup()
	{
		TetherComp = UMedallionPlayerTetherComponent::Get(PlayerOwner);
	}

	UFUNCTION(BlueprintPure)
	float GetTetherLength()
	{
		return PlayerOwner.GetDistanceTo(PlayerOwner.OtherPlayer);
	}

	UFUNCTION(BlueprintPure)
	float GetGloryKillProgress()
	{
		if(GloryKillTargetHydra == nullptr)
			return 0.0;

		return PlayerOwner.GetButtonMashProgress(MedallionTags::MedallionGloryKillButtonmashInstigator);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaSeconds)
	{
		const FVector TetherMiddlePoint = Math::Lerp(PlayerOwner.ActorLocation, PlayerOwner.OtherPlayer.ActorLocation, 0.5);
		DefaultEmitter.SetEmitterLocation(TetherMiddlePoint, true);
	}
}