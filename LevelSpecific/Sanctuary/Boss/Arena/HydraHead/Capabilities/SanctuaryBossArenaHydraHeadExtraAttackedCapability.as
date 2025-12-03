class USanctuaryBossArenaHydraHeadExtraAttackCapability : UHazeCapability
{
	default TickGroup = EHazeTickGroup::Gameplay;
	ASanctuaryBossArenaHydraHead HydraHead;
	USanctuaryCompanionAviationPlayerComponent ZoePlayerAviationComp;
	USanctuaryCompanionAviationPlayerComponent MioPlayerAviationComp;
	AHazePlayerCharacter Mio;
	AHazePlayerCharacter Zoe;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		HydraHead = Cast<ASanctuaryBossArenaHydraHead>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!IsMeetingActivationCriteria())
			return false;
		return true;
	}

	bool IsMeetingActivationCriteria() const
	{
		if (!HydraHead.HasControl())
			return false;

		if (HydraHead.GetReadableState().bShouldDive)
			return false;

		if (HydraHead.GetReadableState().bShouldSurface)
			return false;

		if (HydraHead.HeadID != ESanctuaryBossArenaHydraHead::Extra)
			return false;

		if (!HydraHead.ExtraHeadReactIncoming() && !HydraHead.ExtraHeadReactAttack())
			return false;

		if (HydraHead.Friend.ExtraHeadReactAttack())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!IsMeetingActivationCriteria())
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		HydraHead.BlockCapabilities(ArenaHydraTags::ExtraHydraLook, this);
		if (ZoePlayerAviationComp == nullptr && Game::Zoe != nullptr)
		{
			Zoe = Game::Zoe;
			ZoePlayerAviationComp = USanctuaryCompanionAviationPlayerComponent::Get(Zoe);
		}
		if (MioPlayerAviationComp == nullptr && Game::Mio != nullptr)
		{
			Mio = Game::Mio;
			MioPlayerAviationComp = USanctuaryCompanionAviationPlayerComponent::Get(Mio);
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		HydraHead.OverrideTargetHeadWorldLocation = FVector();
		HydraHead.OverrideTargetHeadWorldLookDirection = FVector();
		HydraHead.UnblockCapabilities(ArenaHydraTags::ExtraHydraLook, this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (HydraHead.ExtraHeadReactAttack())
		{
			FVector HeadLocation = HydraHead.ActorLocation;
			HeadLocation = HydraHead.ActorLocation + FVector::UpVector * 7000.0;
			HeadLocation += HydraHead.ActorForwardVector * -7500.0;

			HydraHead.OverrideTargetHeadWorldLocation = HeadLocation;

			FVector FocusLocation = HydraHead.Friend.ActorLocation;
			FocusLocation.Z = HeadLocation.Z + 5000.0;
			FVector ToFocusLocation = FocusLocation - HeadLocation;

			HydraHead.OverrideTargetHeadWorldLookDirection = ToFocusLocation.GetSafeNormal();

			if (SanctuaryHydraDevToggles::Drawing::DrawExtraHydra.IsEnabled())
			{
				Debug::DrawDebugSphere(HydraHead.OverrideTargetHeadWorldLocation, 500.0, 12, ColorDebug::Red, 5.0, 0.0, true);
				Debug::DrawDebugArrow(HeadLocation, FocusLocation, 5.0, ColorDebug::Cyan, 5.0, 0.0, true);
			}
		}
		else
		{
			FVector HeadLocation = HydraHead.ActorLocation;
			HeadLocation = HydraHead.ActorLocation + FVector::UpVector * 13000.0;
			HeadLocation += HydraHead.ActorForwardVector * -3500.0;

			HydraHead.OverrideTargetHeadWorldLocation = HeadLocation;

			FVector FocusLocation = HydraHead.Friend.HeadPivot.WorldLocation;
			if (ZoePlayerAviationComp.GetIsAviationActive())
				FocusLocation = Zoe.ActorLocation;
			if (MioPlayerAviationComp.GetIsAviationActive())
				FocusLocation = Mio.ActorLocation;

			FVector ToFocusLocation = FocusLocation - HeadLocation;
			HydraHead.OverrideTargetHeadWorldLookDirection = ToFocusLocation.GetSafeNormal();

			if (SanctuaryHydraDevToggles::Drawing::DrawExtraHydra.IsEnabled())
			{
				Debug::DrawDebugSphere(HydraHead.OverrideTargetHeadWorldLocation, 500.0, 12, ColorDebug::Red, 5.0, 0.0, true);
				Debug::DrawDebugArrow(HeadLocation, FocusLocation, 5.0, ColorDebug::Cornflower, 10.0, 0.0, true);
			}
		}
	}
};