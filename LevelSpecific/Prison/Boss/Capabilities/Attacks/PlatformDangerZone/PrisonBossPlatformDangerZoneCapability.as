class UPrisonBossPlatformDangerZoneCapability : UPrisonBossChildCapability
{
	default CompoundNetworkSupport = EHazeCompoundNetworkSupport::OnlyCrumbNetwork;

	AHazePlayerCharacter TargetPlayer;

	bool bZoneSpawned = false;

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{	
		if (Boss.CurrentAttackType != EPrisonBossAttackType::PlatformDangerZone)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (ActiveDuration >= PrisonBoss::PlatformDangerZoneSpawnDelay + PrisonBoss::PlatformDangerZoneExitDuration)
			return true;

		if (Boss.CurrentAttackType != EPrisonBossAttackType::PlatformDangerZone)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		bZoneSpawned = false;
		TargetPlayer = Game::Zoe;

		Boss.AnimationData.bIsSpawningPlatformDangerZone = true;

		UPrisonBossEffectEventHandler::Trigger_PlatformDangerZoneEnter(Boss);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Boss.SetTargetIdleTime(3.0);

		Boss.CurrentAttackType = EPrisonBossAttackType::None;
		Boss.AnimationData.bIsSpawningPlatformDangerZone = false;

		Boss.OnAttackCompleted.Broadcast(EPrisonBossAttackType::PlatformDangerZone);

		UPrisonBossEffectEventHandler::Trigger_PlatformDangerZoneExit(Boss);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FVector Loc = Math::VInterpConstantTo(Boss.ActorLocation, Boss.MiddlePoint.ActorLocation, DeltaTime, 4000.0);
		Boss.SetActorLocation(Loc);

		FVector DirToPlayer = (Game::Zoe.ActorLocation - Boss.ActorLocation).ConstrainToPlane(FVector::UpVector).GetSafeNormal();

		FRotator Rot = Math::RInterpTo(Boss.ActorRotation, DirToPlayer.Rotation(), DeltaTime, 10.0);
		Boss.SetActorRotation(Rot);

		if (bZoneSpawned)
			return;

		if (ActiveDuration >= PrisonBoss::PlatformDangerZoneSpawnDelay)
			ActivateDangerZone();
	}

	void ActivateDangerZone()
	{
		bZoneSpawned = true;
		Boss.TargetDangerZone.ActivateDangerZone(2.0);

		UPrisonBossEffectEventHandler::Trigger_PlatformDangerZoneSpawn(Boss);
	}
}