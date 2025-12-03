class USkylineBossProximityMineAttackCapability : USkylineBossChildCapability
{
	default CapabilityTags.Add(SkylineBossTags::SkylineBossAttack);
	default CapabilityTags.Add(SkylineBossTags::SkylineBossProximityMineAttack);

	TArray<AActor> ActorsToIgnore;

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (DeactiveDuration < 10.0)
			return false;

		if (Boss.LookAtTarget.Get() == nullptr)
			return false;

		if (Owner.GetDistanceTo(Boss.LookAtTarget.Get()) < Boss.Settings.MinLongRangeAttacks)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		auto Target = Boss.LookAtTarget.Get();

		float ClosestDistance = BIG_NUMBER;
		ASkylineBossProximityMineZone ClosestZone;

		TListedActors<ASkylineBossProximityMineZone> MineZones;

		for (auto MineZone : MineZones)
		{
			if (MineZone == nullptr)
				continue;
			float TargetDistanceToZone = Target.GetDistanceTo(MineZone);
			if (TargetDistanceToZone < ClosestDistance)
			{
				ClosestDistance = TargetDistanceToZone;
				ClosestZone = MineZone;
			}
		}

		ClosestZone.SpawnMines(); 

		PrintToScreen("Spawn Mines at: " + ClosestZone, 3.0, FLinearColor::Green);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
	}
}