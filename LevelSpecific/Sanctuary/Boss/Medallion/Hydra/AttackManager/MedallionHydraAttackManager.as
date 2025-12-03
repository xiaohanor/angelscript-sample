enum EMedallionPhase
{
	None,

	Sidescroller1,
	Merge1,
	Flying1,
	Flying1Loop,
	Flying1LoopBack,
	Strangle1,
	Strangle1Sequence,
	GloryKill1,
	FlyingExitReturn1,

	Sidescroller2,
	Merge2,
	Flying2,
	Flying2Loop,
	Flying2LoopBack,
	Strangle2,
	Strangle2Sequence,
	GloryKill2,
	FlyingExitReturn2,

	Sidescroller3,
	Merge3,
	Flying3,
	Flying3Loop,
	Flying3LoopBack,
	Strangle3,
	Strangle3Sequence,
	GloryKill3,
	
	Ballista1,
	BallistaNearBallista1,
	BallistaPlayersAiming1,
	BallistaArrowShot1,
	Ballista2,
	BallistaNearBallista2,
	BallistaPlayersAiming2,
	BallistaArrowShot2,
	Ballista3,
	BallistaNearBallista3,
	BallistaPlayersAiming3,
	BallistaArrowShot3,

	Skydive,
}

event void FMedallionHydraPhaseChangedSignature(EMedallionPhase Phase, bool bNaturalProgression);

class AMedallionHydraAttackManager : AHazeActor
{
	access DeathManagement = private, USanctuaryBossMedallionHydraDeathCapability;
	access ReadOnly = private, * (readonly);

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UBillboardComponent BillboardComp;

	UPROPERTY(DefaultComponent)
	UHazeActionQueueComponent QueueComp;

	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComp;
	default CapabilityComp.DefaultSheets.Add(MedallionHydraAttackSheet);

	UPROPERTY(DefaultComponent, Category = "Audio")
	USoundDefContextComponent SoundDefComp;

	UPROPERTY(BlueprintReadOnly)
	access:ReadOnly EMedallionPhase Phase = EMedallionPhase::None;

	UPROPERTY()
	FMedallionHydraPhaseChangedSignature OnPhaseChanged;

	private ASanctuaryBossMedallionHydraReferences Refs;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
	}

	UFUNCTION(BlueprintCallable)
	void BP_ForceBallistaPhaseInCutscene()
	{
		SetPhase(EMedallionPhase::Ballista1, false);
	}

	UFUNCTION(BlueprintCallable)
	void BP_SetPhaseFromCheckpoint(EMedallionPhase NewPhase, bool bNaturalProgression = true)
	{
		if (bNaturalProgression)
			return;
		SetPhase(NewPhase, bNaturalProgression);
	}

	UFUNCTION(NotBlueprintCallable)
	void SetPhase(EMedallionPhase NewPhase, bool bNaturalProgression = true)
	{
		if (NewPhase == Phase)
			return;

		Phase = NewPhase;
		QueueComp.Empty();
		OnPhaseChanged.Broadcast(Phase, bNaturalProgression);
		FSanctuaryBossMedallionManagerEventPhaseData Data;
		Data.Phase = NewPhase;
		Data.bNaturalProgression = bNaturalProgression;
		UMedallionHydraAttackManagerEventHandler::Trigger_OnBossPhaseChanged(this, Data);
		if (!bNaturalProgression)
		{
			SetSomeHydrasDead(false);
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
#if !RELEASE
		TEMPORAL_LOG(this, "Medallion").Value("Phase", Phase);
		if (SanctuaryMedallionHydraDevToggles::Draw::Phase.IsEnabled())
			PrintToScreenScaled("Phase: " + Phase, 0.0, ColorDebug::Lavender, 1.5);
#endif
	}

	EMedallionPhase GetFlyingPhase() const
	{
		switch (Phase)
		{
			// 1 -------------------------------------------
			case EMedallionPhase::None:
			case EMedallionPhase::Sidescroller1:
			case EMedallionPhase::Merge1:
			case EMedallionPhase::Flying1:
			case EMedallionPhase::Strangle1:
			case EMedallionPhase::Strangle1Sequence:
			case EMedallionPhase::GloryKill1:
			case EMedallionPhase::FlyingExitReturn1:
				
				return EMedallionPhase::Flying1;

			case EMedallionPhase::Flying1Loop: return EMedallionPhase::Flying1Loop;
			case EMedallionPhase::Flying1LoopBack: return EMedallionPhase::Flying1LoopBack;
			
			// 2 -------------------------------------------
			case EMedallionPhase::Sidescroller2:
			case EMedallionPhase::Merge2:
			case EMedallionPhase::Flying2:
			case EMedallionPhase::Strangle2:
			case EMedallionPhase::Strangle2Sequence:
			case EMedallionPhase::GloryKill2:
			case EMedallionPhase::FlyingExitReturn2:
				
				return EMedallionPhase::Flying2;
			case EMedallionPhase::Flying2Loop: return EMedallionPhase::Flying2Loop;
			case EMedallionPhase::Flying2LoopBack: return EMedallionPhase::Flying2LoopBack;

			// 3+ -------------------------------------------
			case EMedallionPhase::Sidescroller3:
			case EMedallionPhase::Merge3:
			case EMedallionPhase::Flying3:
			case EMedallionPhase::Strangle3:
			case EMedallionPhase::Strangle3Sequence:
			case EMedallionPhase::GloryKill3:
			case EMedallionPhase::Ballista1:
			case EMedallionPhase::Ballista2:
			case EMedallionPhase::Ballista3:
			case EMedallionPhase::BallistaNearBallista1:
			case EMedallionPhase::BallistaNearBallista2:
			case EMedallionPhase::BallistaNearBallista3:
			case EMedallionPhase::BallistaPlayersAiming1:
			case EMedallionPhase::BallistaPlayersAiming2:
			case EMedallionPhase::BallistaPlayersAiming3:
			case EMedallionPhase::BallistaArrowShot1:
			case EMedallionPhase::BallistaArrowShot2:
			case EMedallionPhase::BallistaArrowShot3:
			case EMedallionPhase::Skydive:

				return EMedallionPhase::Flying3;

			case EMedallionPhase::Flying3Loop: return EMedallionPhase::Flying3Loop;
			case EMedallionPhase::Flying3LoopBack: return EMedallionPhase::Flying3LoopBack;
		}
	}

	access : DeathManagement void SetSomeHydrasDead(bool bNaturalProgression)
	{
		// kill some hydras
		int HeadsToKill = MedallionStatics::BP_GetNumKilledHeads(Phase);
		TListedActors<ASanctuaryBossMedallionHydraReferences> LevelReferences;
		if (LevelReferences.Num() > 0)
		{
			Refs = LevelReferences.Single;
			for (int iHydra = 0; iHydra < Refs.Hydras.Num(); ++iHydra)
			{
				ASanctuaryBossMedallionHydra Hydra = Refs.Hydras[iHydra];
				if (Hydra.HydraType == EMedallionHydra::ZoeBack && HeadsToKill >= 1)
				{
					DeathifyHydra(Refs.Hydras[iHydra], bNaturalProgression);
				}
				if (Hydra.HydraType == EMedallionHydra::MioBack && HeadsToKill >= 2)
				{
					DeathifyHydra(Refs.Hydras[iHydra], bNaturalProgression);
				}
				if (Hydra.HydraType == EMedallionHydra::ZoeRight && HeadsToKill >= 3)
				{
					DeathifyHydra(Refs.Hydras[iHydra], bNaturalProgression);
				}
				if (Hydra.HydraType == EMedallionHydra::MioLeft && Phase >= EMedallionPhase::Ballista2)
				{
					DeathifyHydra(Refs.Hydras[iHydra], bNaturalProgression);
				}
				if (Hydra.HydraType == EMedallionHydra::ZoeLeft && Phase >= EMedallionPhase::Ballista3)
				{
					DeathifyHydra(Refs.Hydras[iHydra], bNaturalProgression);
				}
				if (Hydra.HydraType == EMedallionHydra::MioRight && Phase >= EMedallionPhase::BallistaArrowShot3)
				{
					DeathifyHydra(Refs.Hydras[iHydra], bNaturalProgression);
				}
			}
		}
	}

	private void DeathifyHydra(ASanctuaryBossMedallionHydra Hydra, bool bNaturalProgression)
	{
		if (bNaturalProgression)
		{
			USanctuaryBossMedallionHydraEventHandler::Trigger_OnDidSneakyDeath(Hydra);
			FSanctuaryBossMedallionManagerHydraData Data;
			Data.Hydra = Hydra;
			UMedallionHydraAttackManagerEventHandler::Trigger_OnDidSneakyDeath(this, Data);
		}
		Hydra.SetIsDead();
		Hydra.SwitchToDecapNeck();
	}
};