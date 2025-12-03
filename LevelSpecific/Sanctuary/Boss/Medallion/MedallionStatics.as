namespace MedallionStatics
{
	UFUNCTION(BlueprintPure, DisplayName = "Sanctuary Medallion Hydra Get Killed Heads", Category = "Sanctuary|Boss")
	int BP_GetNumKilledHeads(EMedallionPhase Phase)
	{
		int KilledHeads = 0;
		switch (Phase)
		{
			case EMedallionPhase::None:
			case EMedallionPhase::Sidescroller1:
			case EMedallionPhase::Merge1:
			case EMedallionPhase::Flying1:
			case EMedallionPhase::Flying1Loop:
			case EMedallionPhase::Flying1LoopBack:
			case EMedallionPhase::Strangle1:
			case EMedallionPhase::Strangle1Sequence:
			break;

			case EMedallionPhase::GloryKill1:
			case EMedallionPhase::FlyingExitReturn1:
			case EMedallionPhase::Merge2:
			case EMedallionPhase::Sidescroller2:
			case EMedallionPhase::Flying2:
			case EMedallionPhase::Flying2Loop:
			case EMedallionPhase::Flying2LoopBack:
			case EMedallionPhase::Strangle2:
			case EMedallionPhase::Strangle2Sequence:
			KilledHeads = 1;
			break;
			case EMedallionPhase::GloryKill2:
			case EMedallionPhase::FlyingExitReturn2:
			case EMedallionPhase::Merge3:
			case EMedallionPhase::Sidescroller3:
			case EMedallionPhase::Flying3:
			case EMedallionPhase::Flying3Loop:
			case EMedallionPhase::Flying3LoopBack:
			case EMedallionPhase::Strangle3:
			case EMedallionPhase::Strangle3Sequence:
			KilledHeads = 2;
			break;
			case EMedallionPhase::GloryKill3:
			case EMedallionPhase::Ballista1:
			case EMedallionPhase::BallistaNearBallista1:
			case EMedallionPhase::BallistaPlayersAiming1:
			case EMedallionPhase::BallistaArrowShot1:
			case EMedallionPhase::Ballista2:
			case EMedallionPhase::BallistaNearBallista2:
			case EMedallionPhase::BallistaPlayersAiming2:
			case EMedallionPhase::BallistaArrowShot2:
			case EMedallionPhase::Ballista3:
			case EMedallionPhase::BallistaNearBallista3:
			case EMedallionPhase::BallistaPlayersAiming3:
			case EMedallionPhase::BallistaArrowShot3:
			case EMedallionPhase::Skydive:
			KilledHeads = 3;
			break;
		}
		return KilledHeads;
	}

	UFUNCTION(BlueprintPure, DisplayName = "Sanctuary Medallion Get Phase", Category = "Sanctuary|Boss")
	EMedallionPhase BP_GetMedallionPhase()
	{
		UMedallionPlayerReferencesComponent MedRefs = UMedallionPlayerReferencesComponent::GetOrCreate(Game::Mio);
		if (MedRefs.Refs == nullptr)
			return EMedallionPhase::None;
		return MedRefs.Refs.HydraAttackManager.Phase;
	}

	UFUNCTION(BlueprintPure, DisplayName = "Sanctuary Medallion Use First Cutscenes", Category = "Sanctuary|Boss")
	bool BP_UseFirstCutscenes()
	{
		UMedallionPlayerReferencesComponent MedRefs = UMedallionPlayerReferencesComponent::GetOrCreate(Game::Mio);
		if (MedRefs.Refs == nullptr)
			return true;
		return MedRefs.Refs.HydraAttackManager.Phase <= EMedallionPhase::FlyingExitReturn2;
	}

	UFUNCTION(BlueprintPure, DisplayName = "Sanctuary Medallion Get Attacked Hydra", Category = "Sanctuary|Boss")
	ASanctuaryBossMedallionHydra BP_GetCutsceneHydra()
	{
		UMedallionPlayerGloryKillComponent MedallionComp = UMedallionPlayerGloryKillComponent::GetOrCreate(Game::Mio);
		return MedallionComp.GetCutsceneHydra();
	}

	FName SanctuaryGetMedallionName(AHazePlayerCharacter Player)
	{
		FString MedallionName = "MedallionMedallion_";
		if (Player.IsMio())
			MedallionName += "Mio";
		else
			MedallionName += "Zoe";
		return FName(MedallionName);
	}

	UFUNCTION(BlueprintPure, DisplayName = "Sanctuary Medallion Get Cutscene Amulet Mio", Category = "Sanctuary|Boss")
	AMedallionMedallionActor BP_GetCutsceneAmuletMio()
	{
		UMedallionPlayerComponent MedallionComp = UMedallionPlayerComponent::GetOrCreate(Game::Mio);
		return MedallionComp.MedallionActor;
	}

	UFUNCTION(BlueprintPure, DisplayName = "Sanctuary Medallion Get Cutscene Amulet Zoe", Category = "Sanctuary|Boss")
	AMedallionMedallionActor BP_GetCutsceneAmuletZoe()
	{
		UMedallionPlayerComponent MedallionComp = UMedallionPlayerComponent::GetOrCreate(Game::Zoe);
		return MedallionComp.MedallionActor;
	}

	void DisableHideActor(AActor Actor, FInstigator Instigator)
	{
		Actor.SetActorEnableCollision(false);
		Actor.SetActorHiddenInGame(true);
		Actor.AddActorDisable(Instigator);
	}

	UFUNCTION(BlueprintCallable, DisplayName = "Sanctuary Medallion Ballista Dev Progress", Category = "Sanctuary|Boss")
	void BP_SetUsingBallistaDevProgressPoint()
	{
		UBallistaHydraActorReferencesComponent RefsComp = UBallistaHydraActorReferencesComponent::GetOrCreate(Game::Mio);
		if (RefsComp.Refs == nullptr)
			return;
		RefsComp.Refs.Spline.bUseDevProgressSetup = true;
	}

	UFUNCTION(BlueprintCallable, DisplayName = "Sanctuary Medallion Hide Ballistas", Category = "Sanctuary|Boss")
	void BP_HideBallistasByPhase(EMedallionPhase Phase)
	{
		UBallistaHydraActorReferencesComponent RefsComp = UBallistaHydraActorReferencesComponent::GetOrCreate(Game::Mio);
		if (RefsComp.Refs == nullptr)
			return;
		FName NamespaceInstigator = n"MedallionStatics";
		TArray<AActor> Children;
		if (Phase >= EMedallionPhase::Ballista2)
		{
			RefsComp.Refs.FirstBallista.GetAttachedActors(Children, true, true);
			for (AActor Child : Children)
			{
				if (!Child.IsA(AWorldSettings))
					DisableHideActor(Child, NamespaceInstigator);
			}
			DisableHideActor(RefsComp.Refs.FirstBallista, NamespaceInstigator);
		}
		if (Phase >= EMedallionPhase::Ballista3)
		{
			RefsComp.Refs.SecondBallista.GetAttachedActors(Children, true, true);
			for (AActor Child : Children)
			{
				if (!Child.IsA(AWorldSettings))
					DisableHideActor(Child, NamespaceInstigator);
			}
			DisableHideActor(RefsComp.Refs.SecondBallista, NamespaceInstigator);
		}
		if (Phase >= EMedallionPhase::Skydive)
		{
			RefsComp.Refs.ThirdBallista.GetAttachedActors(Children, true, true);
			for (AActor Child : Children)
			{
				if (!Child.IsA(AWorldSettings))
					DisableHideActor(Child, NamespaceInstigator);
			}
			DisableHideActor(RefsComp.Refs.ThirdBallista, NamespaceInstigator);
		}
	}

	UFUNCTION(BlueprintCallable, DisplayName = "Sanctuary Medallion Set Tether Visible", Category = "Sanctuary|Boss")
	void BP_SetMedallionTetherVisible()
	{
		UMedallionPlayerComponent MioMed = UMedallionPlayerComponent::GetOrCreate(Game::Mio);
		MioMed.bCutsceneAllowShowTether = true;
		UMedallionPlayerComponent ZoeMed = UMedallionPlayerComponent::GetOrCreate(Game::Zoe);
		ZoeMed.bCutsceneAllowShowTether = true;
	}

	UFUNCTION(BlueprintCallable, DisplayName = "Sanctuary Medallion Hydra Allow Cinematic Head Pivot", Category = "Sanctuary|Boss")
	void BP_SetHydrasAllowCinematicHeadPivot(bool bAllowed)
	{
		UMedallionPlayerReferencesComponent RefsComp = UMedallionPlayerReferencesComponent::GetOrCreate(Game::Mio);
		if (RefsComp.Refs == nullptr)
			return;
		for (ASanctuaryBossMedallionHydra Hydra : RefsComp.Refs.Hydras)
			Hydra.bAllowCinematicHeadPivot = bAllowed;
	}

	UFUNCTION(BlueprintCallable, DisplayName = "Sanctuary Medallion Allow Cutscene Hover", Category = "Sanctuary|Boss")
	void BP_SetMedallionAllowCutsceneHover(bool bMedallionAllowHover)
	{
		UMedallionPlayerComponent MioMed = UMedallionPlayerComponent::GetOrCreate(Game::Mio);
		UMedallionPlayerComponent ZoeMed = UMedallionPlayerComponent::GetOrCreate(Game::Zoe);
		MioMed.bAllowCutsceneHover = bMedallionAllowHover;
		ZoeMed.bAllowCutsceneHover = bMedallionAllowHover;
	}

	UFUNCTION(BlueprintCallable, DisplayName = "Sanctuary Medallion Cutscene Allow Flying", Category = "Sanctuary|Boss")
	void BP_SetMedallionCutsceneAllowFlying()
	{
		UMedallionPlayerComponent MioMed = UMedallionPlayerComponent::GetOrCreate(Game::Mio);
		UMedallionPlayerComponent ZoeMed = UMedallionPlayerComponent::GetOrCreate(Game::Zoe);
		MioMed.bCutsceneAllowFlying = true;
		ZoeMed.bCutsceneAllowFlying = true;
	}

	UFUNCTION(BlueprintCallable, DisplayName = "Sanctuary Medallion Set Is ForceHidden", Category = "Sanctuary|Boss")
	void BP_SetMedallionForceHidden(bool bForceHidden = true)
	{
		UMedallionPlayerComponent MioMed = UMedallionPlayerComponent::GetOrCreate(Game::Mio);
		UMedallionPlayerComponent ZoeMed = UMedallionPlayerComponent::GetOrCreate(Game::Zoe);
		MioMed.bForceHidden = bForceHidden;
		ZoeMed.bForceHidden = bForceHidden;
	}

	UFUNCTION(BlueprintCallable, DisplayName = "Sanctuary Medallion Set Is Inside", Category = "Sanctuary|Boss")
	void BP_SetMedallionInside(AActor ZoeFakeMedallionActor, bool bShowMioMedallion)
	{
		UMedallionPlayerComponent MioMed = UMedallionPlayerComponent::GetOrCreate(Game::Mio);
		if (ZoeFakeMedallionActor != nullptr)
			MioMed.InsideZoeFakeMedallion = ZoeFakeMedallionActor;
		MioMed.bShowMioInsideMedallion = bShowMioMedallion;
	}

	UFUNCTION(BlueprintCallable, DisplayName = "Sanctuary Medallion Set Mio Medallion Is Chill", Category = "Sanctuary|Boss")
	void BP_SetMedallionMioChill(bool bShouldBeChill)
	{
		UMedallionPlayerComponent MioMed = UMedallionPlayerComponent::GetOrCreate(Game::Mio);
		MioMed.bMioMedallionChill = bShouldBeChill;
	}

	void MedallionPlayersStartHighfive()
	{
		UMedallionPlayerReferencesComponent RefsComp = UMedallionPlayerReferencesComponent::GetOrCreate(Game::Mio);
		if (RefsComp.Refs == nullptr)
			return;
		for (ASanctuaryBossMedallionHydra Hydra : RefsComp.Refs.Hydras)
			USanctuaryBossMedallionHydraEventHandler::Trigger_OnPlayersStartTryHighfive(Hydra);
	}

	void MedallionPlayersStartStrangle(ASanctuaryBossMedallionHydra AttackedHydra)
	{
		UMedallionPlayerReferencesComponent RefsComp = UMedallionPlayerReferencesComponent::GetOrCreate(Game::Mio);
		if (RefsComp.Refs == nullptr)
			return;
		for (ASanctuaryBossMedallionHydra Hydra : RefsComp.Refs.Hydras)
		{
			FSanctuaryBossMedallionHydraEventDecapitationStartData Data;
			Data.AttackedHydra = AttackedHydra;
			USanctuaryBossMedallionHydraEventHandler::Trigger_OnDecapitationMashStart(Hydra, Data);
		}
	}

}