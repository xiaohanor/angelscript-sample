
event void MedallionStartSequenceEvent();
event void MedallionStartHighfiveSequenceEvent(FVector SequenceLocation, FRotator SequenceRotation);

class ASanctuaryBossMedallionHydraReferences : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedComp;

	UPROPERTY(EditInstanceOnly)
	TMap<EMedallionPhase, FMedallionFlyingData> FlyingPhasesDatas;

	UPROPERTY(EditInstanceOnly)
	AHazeCameraActor SplitSidescrollerCameraMio;

	UPROPERTY(EditInstanceOnly)
	AHazeCameraActor SplitSidescrollerCameraZoe;

	UPROPERTY(EditInstanceOnly)
	AHazeCameraActor FullScreenSidescrollerCamera;
	
	UPROPERTY(EditInstanceOnly)
	AStaticCameraActor FlyingCamera;

	UPROPERTY(EditInstanceOnly)
	AStaticCameraActor GloryKillCamera;

	UPROPERTY(EditInstanceOnly)
	AFocusCameraActor ReturnFlyingCameraMio;

	UPROPERTY(EditInstanceOnly)
	AFocusCameraActor ReturnFlyingCameraZoe;

	UPROPERTY(EditInstanceOnly)
	ASanctuaryBossMedallion2DPlane MedallionBossPlane2D;

	UPROPERTY(EditInstanceOnly)
	ASplineActor SideScrollerSplineLocker;

	UPROPERTY(EditInstanceOnly)
	AMedallionPlayerGenericRefActor GloryKillExitLocationMio;

	UPROPERTY(EditInstanceOnly)
	AMedallionPlayerGenericRefActor GloryKillExitLocationZoe;

	UPROPERTY(EditInstanceOnly)
	TArray<ASanctuaryBossMedallionHydra> Hydras;

	UPROPERTY(EditInstanceOnly)
	AMedallionPlayerStranglingTetherDonut GloryKillCirclingSpotTemp;

	UPROPERTY(EditInstanceOnly)
	AMedallionHydraAttackManager HydraAttackManager;

	// UPROPERTY(EditInstanceOnly)
	// ASanctuaryBossMedallionHealthActor HydraHealth;

	UPROPERTY(EditInstanceOnly)
	AMedallionPlayerMergingCompanionFocus MioMergingFocus;

	UPROPERTY(EditInstanceOnly)
	AMedallionPlayerMergingCompanionFocus ZoeMergingFocus;

	UPROPERTY(EditInstanceOnly)
	AMedallionPlayerMergingHighfiveTargetLocation HighfiveTargetLocation;

	UPROPERTY(EditInstanceOnly)
	AMedallionPlayerSidescrollerCameraFocus MioSidescrollerCameraFocus;

	UPROPERTY(EditInstanceOnly)
	AMedallionPlayerSidescrollerCameraFocus ZoeSidescrollerCameraFocus;

	UPROPERTY(EditInstanceOnly)
	AHazeLevelSequenceActor StartGloryKillSequence;

	UPROPERTY(EditInstanceOnly)
	AHazeLevelSequenceActor EndGloryKillSequence;
	UPROPERTY(EditInstanceOnly)
	AHazeLevelSequenceActor SecondEndGloryKillSequence;

	UPROPERTY(EditInstanceOnly)
	AHazeLevelSequenceActor TransitionToSplineRunSequence;

	UPROPERTY(BlueprintReadWrite)
	MedallionStartHighfiveSequenceEvent StartHighfiveEvent;
	UPROPERTY(BlueprintReadWrite)
	MedallionStartSequenceEvent StartGloryKillEvent;
	UPROPERTY(BlueprintReadWrite)
	MedallionStartSequenceEvent StartGloryKillEventWithPlayersSwapped;
	UPROPERTY(BlueprintReadWrite)
	MedallionStartSequenceEvent EndGloryKillEvent;
	MedallionStartSequenceEvent InBeforeMedallionEndSequenceEvent;
	//Attack Actors

	UPROPERTY(EditInstanceOnly)
	AMedallionHydraArcSprayAttackActor MioArcSprayAttackActor;

	UPROPERTY(EditInstanceOnly)
	AMedallionHydraArcSprayAttackActor ZoeArcSprayAttackActor;

	UPROPERTY(EditInstanceOnly)
	AMedallionHydraChaseLaserAttack MioChaseLaserAttackActor;

	UPROPERTY(EditInstanceOnly)
	AMedallionHydraChaseLaserAttack ZoeChaseLaserAttackActor;

	UPROPERTY(EditInstanceOnly)
	AMedallionHydraSlashLaser MioSlashLaserAttackActor;

	UPROPERTY(EditInstanceOnly)
	AMedallionHydraSlashLaser ZoeSlashLaserAttackActor;

	UPROPERTY(EditInstanceOnly)
	AMedallionHydraAboveProjectileAttackActor MioAboveProjectileAttackActor;

	UPROPERTY(EditInstanceOnly)
	AMedallionHydraAboveProjectileAttackActor ZoeAboveProjectileAttackActor;

	UPROPERTY(EditInstanceOnly)
	AMedallionHydraSidescrollerSpamAttackActor MioSidescrollerSpamAttackActor;

	UPROPERTY(EditInstanceOnly)
	AMedallionHydraSidescrollerSpamAttackActor ZoeSidescrollerSpamAttackActor;

	UPROPERTY(EditInstanceOnly)
	AMedallionHydraBallistaLaneLaser BallistaLaneLaser1AttackActor;

	UPROPERTY(EditInstanceOnly)
	AMedallionHydraBallistaLaneLaser BallistaLaneLaser2AttackActor;

	UPROPERTY(EditInstanceOnly)
	AMedallionHydraBallistaLaneLaser BallistaLaneLaser3AttackActor;

	UPROPERTY(EditInstanceOnly)
	AMedallionHydraBallistaLaneLaser BallistaLaneLaserAboveAttackActor;

	UPROPERTY(EditInstanceOnly)
	AMedallionHydraBallistaLaneLaser BallistaLaneLaserAboveAttackActor2;

	UPROPERTY(EditInstanceOnly)
	AMedallionHydraBallistaLaneLaser BallistaLaneLaserAboveAttackActor3;

	UPROPERTY(EditInstanceOnly)
	AMedallionHydraWaveAttack WaveAttackActor;

	UPROPERTY(EditInstanceOnly)
	AMedallionHydraMeteorAttackActor MeteorAttackActor;

	UPROPERTY(EditInstanceOnly)
	AHazeCameraActor BelowBiteCameraActor;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		UMedallionPlayerReferencesComponent TempMio = UMedallionPlayerReferencesComponent::GetOrCreate(Game::Mio);
		TempMio.Refs = this;
		UMedallionPlayerReferencesComponent TempZoe = UMedallionPlayerReferencesComponent::GetOrCreate(Game::Zoe);
		TempZoe.Refs = this;
	}

	UFUNCTION(BlueprintCallable)
	void BP_InBeforeMedallionEndSequence()
	{
		InBeforeMedallionEndSequenceEvent.Broadcast();
	}

	ASanctuaryBossMedallionHydra GetHydraByEnum(EMedallionHydra Type)
	{
		for (ASanctuaryBossMedallionHydra Hydra : Hydras)
		{
			if (Hydra.HydraType == Type)
				return Hydra;
		}
		return nullptr;
	}

	bool IsInFlyingPhase(bool bCountStrangle, bool bCountGloryKill, bool bCountReturn) const
	{
		if (HydraAttackManager == nullptr)
			return false;
		switch (HydraAttackManager.Phase)
		{
			case EMedallionPhase::Flying1:
			case EMedallionPhase::Flying1Loop:
				return true;
			case EMedallionPhase::Strangle1:
			case EMedallionPhase::Strangle1Sequence:
				return bCountStrangle;
			case EMedallionPhase::GloryKill1:
				return bCountGloryKill;
			case EMedallionPhase::FlyingExitReturn1:
				return bCountReturn;
			case EMedallionPhase::Flying2:
			case EMedallionPhase::Flying2Loop:
				return true;
			case EMedallionPhase::Strangle2:
			case EMedallionPhase::Strangle2Sequence:
				return bCountStrangle;
			case EMedallionPhase::GloryKill2:
				return bCountGloryKill;
			case EMedallionPhase::FlyingExitReturn2:
				return bCountReturn;
			case EMedallionPhase::Flying3:
			case EMedallionPhase::Flying3Loop:
				return true;
			case EMedallionPhase::Strangle3:
			case EMedallionPhase::Strangle3Sequence:
				return bCountStrangle;
			case EMedallionPhase::GloryKill3:
				return bCountGloryKill;
			default:
				return false;
		}
	}
};