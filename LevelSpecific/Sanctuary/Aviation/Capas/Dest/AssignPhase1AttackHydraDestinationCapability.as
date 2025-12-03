class USanctuaryCompanionAviationAssignPhase1AttackHydraDestinationCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(AviationCapabilityTags::Aviation);
	default DebugCategory = AviationCapabilityTags::Aviation;
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default TickGroup = EHazeTickGroup::Gameplay;
	default TickGroupOrder = 100;

	USanctuaryCompanionAviationPlayerComponent AviationComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		AviationComp = USanctuaryCompanionAviationPlayerComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!AviationComp.GetIsAviationActive())
			return false;

		if (AviationComp.AviationState != EAviationState::InitAttack)
			return false;

		if (!AviationComp.bHasInitiatedAttack)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (AviationComp.GetIsAviationActive())
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		while (AviationComp.HasDestination())
			AviationComp.RemoveCurrentDestination(false, this);
		AddCenterHydraDestination();
	}
	
	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
	}

	UFUNCTION()
	private void AddCenterHydraDestination()
	{
		TListedActors<ASanctuaryBossArenaHydraHead> HydraHeads;
		ASanctuaryBossArenaHydraHead ChosenHead = nullptr;
		for (ASanctuaryBossArenaHydraHead HydraHead : HydraHeads)
		{
			if (CompanionAviation::bAttackCenterHydra && HydraHead.Player == EHazeSelectPlayer::None)
			{
				ChosenHead = HydraHead;
				break;
			}
		}

		if (ChosenHead == nullptr)
		{
			PrintToScreen("USanctuaryCompanionAviationChooseHydraCapability: Couldn't determine chosen head!!", 10.0, FLinearColor::Red);
			OldAddHydraDestination();
		}
		else
		{
			ChosenHead.bIsTargeted = true;
			FSanctuaryCompanionAviationDestinationData NextDestinationData;
			NextDestinationData.Actor = ChosenHead;
			NextDestinationData.SkellyMesh = ChosenHead.SkeletalMesh;
			NextDestinationData.BoneName = Player.IsMio() ? ChosenHead.DecapitationMioBoneName : ChosenHead.DecapitationZoeBoneName;
			NextDestinationData.AviationState = EAviationState::Attacking;
			NextDestinationData.OnRemoved.AddUFunction(this, n"AddArenaLandingDestination");
			AviationComp.AddDestination(NextDestinationData);
		}
	}

	private void OldAddHydraDestination()
	{
		PrintToScreen("USanctuaryCompanionAviationChooseHydraCapability: No spline found, picking arbitrary hydra", 10.0, FLinearColor::Red);

		FSanctuaryCompanionAviationDestinationData Data;
		TListedActors<ASanctuaryBossArenaHydraHead> HydraHeads;
		for (ASanctuaryBossArenaHydraHead HydraHead : HydraHeads)
		{
			if (WeAreThatPlayer(HydraHead.Player) && AviationComp.CurrentOctantSide == HydraHead.HalfSide)
			{
				Data.Actor = HydraHead;
				Data.SkellyMesh = HydraHead.SkeletalMesh;
				Data.BoneName = HydraHead.DecapitationBoneName;
				break;
			}
		}
		Data.AviationState = EAviationState::InitAttack;
		Data.OnRemoved.AddUFunction(this, n"AddArenaLandingDestination");
		AviationComp.AddDestination(Data);
	}

	UFUNCTION()
	private void AddArenaLandingDestination()
	{
		if (!AviationComp.GetIsAviationActive())
			return;

		FSanctuaryCompanionAviationDestinationData Data;
		TListedActors<ASanctuaryCompanionAviationLandingPoint> AviationLandingPoints;
		if (AviationLandingPoints.Num() == 0)
			return;
		for (auto LandingPoint : AviationLandingPoints)
		{
			if (WeAreThatPlayer(LandingPoint.Player) && LandingPoint.Side != AviationComp.CurrentQuadrantSide)
			{
				Data.Actor = LandingPoint;
				break;
			}
		}
		Data.bDisableSidescroll = true;
		AviationComp.AddDestination(Data);
	}

	private bool WeAreThatPlayer(EHazeSelectPlayer TargetedPlayer)
	{
		TArray<AHazePlayerCharacter> SelectedPlayers = Game::GetPlayersSelectedBy(TargetedPlayer);
		return SelectedPlayers.Contains(Player);
	}
}