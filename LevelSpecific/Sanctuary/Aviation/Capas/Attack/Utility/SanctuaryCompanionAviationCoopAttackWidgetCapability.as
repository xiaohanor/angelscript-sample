struct FSanctuaryCompanionAviationShowCoopAttackWidgetActivationParams
{
	ESanctuaryBossArenaHydraHead AttckedHeadID;
}

class USanctuaryCompanionAviationShowCoopAttackWidgetCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(AviationCapabilityTags::Aviation);
	default DebugCategory = AviationCapabilityTags::Aviation;
	default TickGroup = EHazeTickGroup::Gameplay;
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	USanctuaryCompanionAviationPlayerComponent AviationComp;
	USanctuaryCompanionAviationPlayerComponent OtherPlayerAviationComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		AviationComp = USanctuaryCompanionAviationPlayerComponent::Get(Owner);
		AviationComp.OnAttackSuccess.AddUFunction(this, n"AttackSuccess");
		AviationComp.OnAttackFailed.AddUFunction(this, n"AttackFail");
	}

	UFUNCTION()
	void AttackSuccess()
	{
		AviationComp.MashWidget.Success();
	}

	UFUNCTION()
	void AttackFail()
	{
		AviationComp.MashWidget.Fail();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FSanctuaryCompanionAviationShowCoopAttackWidgetActivationParams& Params) const
	{
		if (!AviationComp.GetIsAviationActive())
			return false;

		if (AviationComp.AviationState != EAviationState::Attacking)
			return false;

		if (CompanionAviation::bRequireInitiateAttackPrompt && !AviationComp.bHasInitiatedAttack)
			return false;

		ASanctuaryBossArenaHydraHead AttackedHead = GetAttackedHydraHead();
		if (AttackedHead == nullptr)
			return false;

		Params.AttckedHeadID = AttackedHead.HeadID;
		return true;
	}

	private ASanctuaryBossArenaHydraHead GetAttackedHydraHead() const
	{
		const FSanctuaryCompanionAviationDestinationData& DestinationData = AviationComp.GetNextDestination();
		return Cast<ASanctuaryBossArenaHydraHead>(DestinationData.Actor);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (AviationComp.MashWidget == nullptr)
			return true;

		if (AviationComp.MashWidget.bFailOrSuccessAnimationDone)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FSanctuaryCompanionAviationShowCoopAttackWidgetActivationParams Params)
	{
		ASanctuaryBossArenaHydraHead AttackedHead;
		TListedActors<ASanctuaryBossArenaHydra> Hydra;
		for (auto Head : Hydra.Single.HydraHeads)
		{
			if (Head.HeadID == Params.AttckedHeadID)
			{
				AttackedHead = Head;
				break;
			}
		}		

		AviationComp.MashWidget = Player.AddWidget(AviationComp.AviationTwoPlayerButtonMashWidgetClass);
		AviationComp.MashWidget.AttachWidgetToComponent(AttackedHead.SkeletalMesh, n"Spine40");
		AviationComp.MashWidget.SetWidgetRelativeAttachOffset(AviationComp.Settings.CoopButtonMashOffset);
		AviationComp.MashWidget.ActionName = AviationComp.Settings.ButtonMashButton;

		if (OtherPlayerAviationComp == nullptr)
			OtherPlayerAviationComp = USanctuaryCompanionAviationPlayerComponent::Get(Player.OtherPlayer);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		if (AviationComp.MashWidget != nullptr)
		{
			Player.RemoveWidget(AviationComp.MashWidget);
			AviationComp.MashWidget = nullptr;
		}
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (AviationDevToggles::Phase1::Phase1PrintKillValues.IsEnabled())
			Debug::DrawDebugString(Owner.ActorLocation, "Kill: " + AviationComp.SyncedKillValue.Value);
		if (Player.IsMio())
		{
			float MioProgress = 1.0 - AviationComp.SyncedKillValue.Value;
			if (AviationComp.MashWidget != nullptr)
				AviationComp.MashWidget.LeftProgressValue = MioProgress;
			if (OtherPlayerAviationComp != nullptr && OtherPlayerAviationComp.MashWidget != nullptr)
				OtherPlayerAviationComp.MashWidget.LeftProgressValue = MioProgress;
		}
		else
		{
			float ZoeProgress = 1.0 - AviationComp.SyncedKillValue.Value;
			if (AviationComp.MashWidget != nullptr)
				AviationComp.MashWidget.RightProgressValue = ZoeProgress;
			if (OtherPlayerAviationComp != nullptr && OtherPlayerAviationComp.MashWidget != nullptr)
				OtherPlayerAviationComp.MashWidget.RightProgressValue = ZoeProgress;
		}
	}
}