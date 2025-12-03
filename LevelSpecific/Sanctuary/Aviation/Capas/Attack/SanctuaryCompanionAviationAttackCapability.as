struct FSanctuaryCompanionAviationAttackDeactivateParams
{
	bool bNatural = false;
}

class USanctuaryCompanionAviationAttackCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(AviationCapabilityTags::Aviation);
	default DebugCategory = AviationCapabilityTags::Aviation;
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	
	default TickGroup = EHazeTickGroup::BeforeMovement;
	default TickGroupOrder = 100;

	USanctuaryCompanionAviationPlayerComponent AviationComp;
	USanctuaryCompanionAviationPlayerComponent OtherPlayerAviationComp;
	UInfuseEssencePlayerComponent InfuseEssenceComp;

	float SuccessTimestamp = 0.0;
	float AttackVFXCooldown = 0.0;

	FVector TempLocation;
	ASanctuaryBossArenaHydraHead AttackedHead;
	bool bLastKilledHydra = false;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		AviationComp = USanctuaryCompanionAviationPlayerComponent::Get(Owner);
		InfuseEssenceComp = UInfuseEssencePlayerComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!AviationComp.GetIsAviationActive())
			return false;

		if (!IsInStateHandledByThisCapability())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate(FSanctuaryCompanionAviationAttackDeactivateParams& Params) const
	{
		if (!AviationComp.GetIsAviationActive())
		{
			Params.bNatural = true;
			return true;
		}

		if (!IsInStateHandledByThisCapability())
		{
			Params.bNatural = true;
			return true;
		}
		
		return false;
	}

	bool IsInStateHandledByThisCapability() const
	{
		if (AviationComp.AviationState == EAviationState::Attacking)
			return true;

		if (AviationComp.AviationState == EAviationState::AttackingSuccessCircling)
			return true;

		if (AviationComp.AviationState == EAviationState::TryExitAttack)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		if (HasControl())
			AviationComp.SyncedKillValue.SetValue(1.0);
		const FSanctuaryCompanionAviationDestinationData& DestinationData = AviationComp.GetNextDestination();
		auto HydraHead = Cast<ASanctuaryBossArenaHydraHead>(DestinationData.Actor);
		if (HydraHead != nullptr)
		{
			AttackedHead = HydraHead;
			SetHydraHeadStrangleVariable(false, true);
		}
		OtherPlayerAviationComp = USanctuaryCompanionAviationPlayerComponent::Get(Player.OtherPlayer);
		AviationComp.OnAttackStart.Broadcast();
		TempLocation = Player.ActorLocation;
		bLastKilledHydra = false;
		USanctuaryCompanionAviationPlayerEventHandler::Trigger_AttackStart(Player);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FSanctuaryCompanionAviationAttackDeactivateParams Params)
	{
		if (!Params.bNatural) // when end of fight or terminating PIE
			return;

		AviationComp.RemoveCurrentDestination(true, this);

		if (AttackedHead != nullptr)
		{
			SetHydraHeadStrangleVariable(false, false);
			SetHydraHeadStrangleVariable(true, false);
			if (!bLastKilledHydra)
			{
				AttackedHead.LocalHeadState.bFreeStrangle = true;
				AviationComp.KillFail();
				for (int i = 0; i < AviationComp.Settings.FreeOrbsAfterFail; ++i)
					InfuseEssenceComp.AddOrb();
			}
		}
		AviationComp.SyncedKillValue.SetValue(1.0);
		AttackedHead.bIsTargeted = false;
		AttackedHead = nullptr;
		AviationComp.OnAttackExit.Broadcast();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		// please remember this is a local capa! uvu
		// no need to check for control~

		if (AttackedHead != nullptr && AviationComp.SyncedKillValue.Value < 0.8)
			SetHydraHeadStrangleVariable(true, true);

		bool bKilledHydra = AttackedHead.LocalHeadState.bBleedDying || AttackedHead.LocalHeadState.bDeath;

		if (bKilledHydra && !bLastKilledHydra && AviationComp.AviationState != EAviationState::TryExitAttack)
		{
			AviationComp.SetAviationState(EAviationState::AttackingSuccessCircling);
			AviationComp.KillSuccess();
		}
		else if (HasControl() && bKilledHydra && ActiveDuration >= SuccessTimestamp + AviationComp.Settings.StrangleSuccessWaitBeforePlayerMoveOn)
		{
			CrumbTryExit();
		}
		bLastKilledHydra = bKilledHydra;
	}

	UFUNCTION(CrumbFunction)
	void CrumbTryExit()
	{
		AviationComp.SetAviationState(EAviationState::TryExitAttack);
	}

	private void SetHydraHeadStrangleVariable(bool bTighten, bool bEnabled)
	{
		if (bTighten)
		{
			if (Player.IsMio())
				AttackedHead.LocalHeadState.bMioTightenStrangle = bEnabled;
			else
				AttackedHead.LocalHeadState.bZoeTightenStrangle = bEnabled;
		}
		else
		{
			if (Player.IsMio())
				AttackedHead.LocalHeadState.bMioStrangled = bEnabled;
			else
				AttackedHead.LocalHeadState.bZoeStrangled = bEnabled;
		}
	}
}
