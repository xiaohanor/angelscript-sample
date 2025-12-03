class UPrisonBossWaveSlashExitCapability : UPrisonBossChildCapability
{
	default CompoundNetworkSupport = EHazeCompoundNetworkSupport::OnlyCrumbNetwork;

	FVector StartLocation;
	FVector TargetLocation;

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (ActiveDuration >= PrisonBoss::WaveSlashExitDuration)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		StartLocation = Boss.ActorLocation;
		TargetLocation = Boss.ActorLocation + (FVector::UpVector * 200.0);
		Boss.AnimationData.bIsExitingWaveSlash = true;

		UPrisonBossEffectEventHandler::Trigger_WaveSlashExit(Boss);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Boss.AnimationData.bIsExitingWaveSlash = false;
		Boss.CurrentAttackType = EPrisonBossAttackType::None;

		Boss.SetActorLocation(TargetLocation);
		Boss.OnAttackCompleted.Broadcast(EPrisonBossAttackType::WaveSlash);

		UPrisonBossEffectEventHandler::Trigger_WaveSlashFinished(Boss);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		float ExitAlpha = Math::Saturate(ActiveDuration/PrisonBoss::WaveSlashExitDuration);
		FVector Loc = Math::Lerp(StartLocation, TargetLocation, ExitAlpha);
		Boss.SetActorLocation(Loc);
	}
}