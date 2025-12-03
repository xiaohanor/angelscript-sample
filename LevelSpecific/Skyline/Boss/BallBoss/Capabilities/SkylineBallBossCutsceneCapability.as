class USkylineBallBossCutsceneCapability : UHazeCapability
{
	default TickGroup = EHazeTickGroup::BeforeMovement;

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (Owner.bIsControlledByCutscene)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Owner.bIsControlledByCutscene)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Owner.BlockCapabilities(SkylineBallBossTags::BallBossBlockedInCutsceneTag, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Owner.UnblockCapabilities(SkylineBallBossTags::BallBossBlockedInCutsceneTag, this);

		// Reset animation so we don't have any lingering offsets on the Base bone
		ASkylineBallBoss BallBoss = Cast<ASkylineBallBoss>(Owner);
		if (BallBoss != nullptr)
			BallBoss.SkeletalMesh.ResetAllAnimation(true);
	}
};