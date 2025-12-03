struct FSanctuaryBossArenaHydraHeadCenterLookParams
{
	FVector HeadLocation;
	FVector LookDirection;
	float RandomDuration;
}

class USanctuaryBossArenaHydraHeadCenterLookCapability : UHazeCapability
{
	default TickGroup = EHazeTickGroup::Gameplay;
	default CapabilityTags.Add(ArenaHydraTags::ExtraHydraLook);
	ASanctuaryBossArenaHydraHead HydraHead;
	FSanctuaryBossArenaHydraHeadCenterLookParams ActivationParams;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		HydraHead = Cast<ASanctuaryBossArenaHydraHead>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FSanctuaryBossArenaHydraHeadCenterLookParams & InParams) const
	{
		if (!HydraHead.HasControl())
			return false;

		if (HydraHead.GetReadableState().bShouldDive)
			return false;

		if (HydraHead.GetReadableState().bShouldSurface)
			return false;

		if (HydraHead.GetReadableState().bDeath)
			return false;

		if (HydraHead.GetReadableState().bZoeStrangled || HydraHead.GetReadableState().bMioStrangled)
			return false;

		if (HydraHead.HeadID != ESanctuaryBossArenaHydraHead::Center)
			return false;

		// which side? right or left
		bool bRightwards = Math::RandRange(0.0, 1.0) > 0.5;
		float Sign = bRightwards ? 1.0 : -1.0 ;

		InParams.RandomDuration = Math::RandRange(5.0, 7.0);
		InParams.HeadLocation = HydraHead.ActorLocation + FVector::UpVector * 9000.0;
		InParams.HeadLocation += HydraHead.ActorForwardVector * 3000.0;
		InParams.HeadLocation += HydraHead.ActorRightVector * Sign * 1000.0;

		FVector LookDirection = FVector();
		float Dotty = 0.0;
		for (auto Player : Game::Players)
		{
			FVector TowardsPlayer = Player.ActorLocation - InParams.HeadLocation;
			// TowardsPlayer.Z = 0.0;
			TowardsPlayer = TowardsPlayer.GetSafeNormal();
			FVector CompareDirection = HydraHead.ActorRightVector * Sign;
			float ToPlayerDot = CompareDirection.DotProduct(TowardsPlayer);
			if (Dotty < ToPlayerDot)
			{
				Dotty = ToPlayerDot;
				LookDirection = TowardsPlayer;
			}
		}

		InParams.LookDirection = LookDirection;
		if (LookDirection.Size() > KINDA_SMALL_NUMBER)
			InParams.LookDirection += FVector::UpVector;
		else
			InParams.LookDirection = HydraHead.ActorForwardVector;
		InParams.LookDirection = InParams.LookDirection.GetSafeNormal();
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (HydraHead.GetReadableState().bShouldDive)
			return true;

		if (HydraHead.GetReadableState().bShouldSurface)
			return true;

		if (ActiveDuration > ActivationParams.RandomDuration)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FSanctuaryBossArenaHydraHeadCenterLookParams Params)
	{
		ActivationParams = Params;
		HydraHead.OverrideTargetHeadWorldLocation = Params.HeadLocation;
		HydraHead.OverrideTargetHeadWorldLookDirection = Params.LookDirection;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		HydraHead.OverrideTargetHeadWorldLocation = FVector();
		HydraHead.OverrideTargetHeadWorldLookDirection = FVector();
	}
};