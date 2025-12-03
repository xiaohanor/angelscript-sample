struct FSanctuaryBossArenaHydraHeadExtraLookParams
{
	FVector HeadLocation;
	FVector LookDirection;
	float RandomDuration;
}

class USanctuaryBossArenaHydraHeadExtraLookCapability : UHazeCapability
{
	default TickGroup = EHazeTickGroup::Gameplay;
	default CapabilityTags.Add(ArenaHydraTags::ExtraHydraLook);
	ASanctuaryBossArenaHydraHead HydraHead;
	FSanctuaryBossArenaHydraHeadExtraLookParams ActivationParams;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		HydraHead = Cast<ASanctuaryBossArenaHydraHead>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FSanctuaryBossArenaHydraHeadExtraLookParams & InParams) const
	{
		if (!HydraHead.HasControl())
			return false;

		if (HydraHead.GetReadableState().bShouldDive)
			return false;

		if (HydraHead.GetReadableState().bShouldSurface)
			return false;

		if (HydraHead.HeadID != ESanctuaryBossArenaHydraHead::Extra)
			return false;

		// which side? right or left
		bool bRightwards = Math::RandRange(0.0, 1.0) > 0.5;
		float Sign = bRightwards ? 1.0 : -1.0 ;

		InParams.RandomDuration = Math::RandRange(3.0, 5.0);
		InParams.HeadLocation = HydraHead.ActorLocation + FVector::UpVector * 11000.0;
		InParams.HeadLocation += HydraHead.ActorForwardVector * -3000.0;
		InParams.HeadLocation += HydraHead.ActorRightVector * Sign * 3000.0;

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
	void OnActivated(FSanctuaryBossArenaHydraHeadExtraLookParams Params)
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