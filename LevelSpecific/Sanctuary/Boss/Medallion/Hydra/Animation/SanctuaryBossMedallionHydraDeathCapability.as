struct FSanctuaryBossMedallionHydraDeathParams
{
	bool bGloriousDeath = false;
}

enum EMedallionEmergeType
{
	Normal,
	Resurrection,
	SneakyDeath
}

class USanctuaryBossMedallionHydraDeathCapability : UHazeCapability
{
	default TickGroup = EHazeTickGroup::AfterGameplay;
	UMedallionPlayerGloryKillComponent MioGloryKillComp;

	ASanctuaryBossMedallionHydra Hydra;
	ASanctuaryBossArenaDecapitatedHead DecapitatedHead = nullptr;
	UMedallionPlayerReferencesComponent RefsComp;
	USanctuaryBossMedallionHydraAnimComponent AnimComp;
	UHazeActionQueueComponent DeathQueue;

	bool bWasControlledByCutscene = false;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Hydra = Cast<ASanctuaryBossMedallionHydra>(Owner);
		DecapitatedHead = Hydra.DecapitatedHead;
		MioGloryKillComp = UMedallionPlayerGloryKillComponent::GetOrCreate(Game::Mio);
		RefsComp = UMedallionPlayerReferencesComponent::GetOrCreate(Game::Mio);
		AnimComp = USanctuaryBossMedallionHydraAnimComponent::GetOrCreate(Owner);
		DeathQueue = UHazeActionQueueComponent::Create(Owner);

		if (DecapitatedHead != nullptr)
		{
			DecapitatedHead.SetActorHiddenInGame(true);
		}
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FSanctuaryBossMedallionHydraDeathParams & Params) const
	{
		if (DecapitatedHead == nullptr)
			return false;
		if (RefsComp.Refs == nullptr)
			return false;
		if (Hydra.bDead)
			return false;
		if (Hydra.bMedallionKilled)
			return true;
		if (MioGloryKillComp.GloryKillState != EMedallionGloryKillState::ExecuteSequence)
			return false;
		if (MioGloryKillComp.AttackedHydra != Hydra)
			return false;
		Params.bGloriousDeath = true;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Hydra.bMedallionKilled)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FSanctuaryBossMedallionHydraDeathParams Params)
	{
		Hydra.SetIsDead();
		if (Params.bGloriousDeath)
		{
			bWasControlledByCutscene = true;
			USanctuaryBossMedallionHydraEventHandler::Trigger_OnDecapitation(Hydra);
			Hydra.SetIsMedallionKilled();
			Hydra.SwitchToDecapNeck();
			DecapitatedHead.SetActorHiddenInGame(false);
			//DeathQueue.Idle(4.5);
			//DeathQueue.Event(this, n"HandleIfWrongHydraKilled");
		}
		else
		{
			// sliced neck appears
			Hydra.OneshotAnimationThenWait(EFeatureTagMedallionHydra::Submerge);
			DeathQueue.Idle(AnimComp.GetAnimationLength(EFeatureTagMedallionHydra::Submerge, EFeatureSubTagMedallionHydra::Mh));
			DeathQueue.Event(Hydra, n"SwitchToDecapNeck");
			DeathQueue.Event(this, n"QueueEmerged", EMedallionEmergeType::SneakyDeath);
		}
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (bWasControlledByCutscene && !Hydra.bIsControlledByCutscene)
		{
			bWasControlledByCutscene = false;
			HandleIfWrongHydraKilled();
		}
	}

	UFUNCTION()
	private void HandleIfWrongHydraKilled()
	{
		if (DecapitatedHead != nullptr)
			DecapitatedHead.SetActorHiddenInGame(true);

		int NumKilledHeads = MedallionStatics::BP_GetNumKilledHeads(RefsComp.Refs.HydraAttackManager.Phase);
		bool bShouldBeDead = false;
		if (NumKilledHeads >= 1 && Hydra.HydraType == EMedallionHydra::ZoeBack)
			bShouldBeDead = true;
		if (NumKilledHeads >= 2 && Hydra.HydraType == EMedallionHydra::MioBack)
			bShouldBeDead = true;
		if (NumKilledHeads >= 3 && Hydra.HydraType == EMedallionHydra::ZoeRight)
			bShouldBeDead = true;

		if (bShouldBeDead)
		{
			// QueueEmerged();
			DeathQueue.Idle(1.0);
			DeathQueue.Event(this, n"QueueEmerged", EMedallionEmergeType::Normal);
		}
		else
		{
			DeathQueue.Idle(1.0);
			DeathQueue.Event(Hydra, n"ResetDecapNeck");
			DeathQueue.Event(this, n"QueueEmerged", EMedallionEmergeType::Resurrection);
			DeathQueue.Event(this, n"EnableHeadPivot");
			DeathQueue.Idle(AnimComp.GetAnimationLength(EFeatureTagMedallionHydra::Emerge, EFeatureSubTagMedallionHydra::Action));
			DeathQueue.Idle(0.5);
			DeathQueue.Event(this, n"Revive");

			RefsComp.Refs.HydraAttackManager.SetSomeHydrasDead(true);
		}
	}

	UFUNCTION()
	private void EnableHeadPivot()
	{
		Hydra.HeadPivotBlockers.Remove(MedallionConstants::Tags::StrangleBlockHeadPivot);
	}

	UFUNCTION()
	private void Revive()
	{
		Hydra.SetIsNotMedallionKilled();
	}

	UFUNCTION()
	void QueueEmerged(EMedallionEmergeType EmergeType)
	{
		if (EmergeType == EMedallionEmergeType::Resurrection)
		{
			USanctuaryBossMedallionHydraEventHandler::Trigger_OnDidSneakyResurrection(Hydra);
			FSanctuaryBossMedallionManagerHydraData Data;
			Data.Hydra = Hydra;
			UMedallionHydraAttackManagerEventHandler::Trigger_OnDidSneakyResurrection(RefsComp.Refs.HydraAttackManager, Data);
		}

		Hydra.OneshotAnimation(EFeatureTagMedallionHydra::Emerge);
		Hydra.AppendIdleAnimation();

		Timer::SetTimer(this, n"UnhideNextFrame", 0.01);
	}
	
	UFUNCTION()
	private void UnhideNextFrame()
	{
		Hydra.RemoveActorVisualsBlock(MedallionHydraTags::HydraVisibilityDeathBlocker);
	}
};