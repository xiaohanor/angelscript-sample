class UKiteFlightCompanionCapability : UHazePlayerCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(KiteTags::KiteFlight);

	default TickGroup = EHazeTickGroup::Gameplay;

	UKiteFlightPlayerComponent KiteFlightComp;

	TArray<AKiteFlightKiteCompanion> ActiveCompanions;

	float CurrentKiteAngle = 0.0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		KiteFlightComp = UKiteFlightPlayerComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!KiteFlightComp.bFlightActive)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!KiteFlightComp.bFlightActive)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		ActiveCompanions.Empty();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		for (AKiteFlightKiteCompanion Companion : ActiveCompanions)
		{
			FVector DirToKite = (Companion.ActorLocation - Player.ActorLocation).GetSafeNormal().ConstrainToPlane(Player.ViewRotation.ForwardVector);
			Companion.DespawnCompanion(DirToKite);
		}
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		int DesiredCompanionAmount = Math::RoundToInt(Math::Lerp(KiteFlight::CompanionsAtMinSpeed, KiteFlight::CompanionsAtMaxSpeed, KiteFlightComp.GetSpeedAlpha()));

		if (DesiredCompanionAmount < ActiveCompanions.Num())
		{
			int CompanionsToDespawn = ActiveCompanions.Num() - DesiredCompanionAmount;
			for (int i = 0; i < CompanionsToDespawn; i++)
				DespawnCompanion();
		}
		else if (DesiredCompanionAmount > ActiveCompanions.Num())
		{
			int CompanionsToSpawn = DesiredCompanionAmount - ActiveCompanions.Num();
			for (int i = 0; i < CompanionsToSpawn; i++)
				SpawnCompanion();
		}

		float SwirlSpeed = Math::Lerp(KiteFlight::CompanionMinSwirlSpeed, KiteFlight::CompanionMaxSwirlSpeed, KiteFlightComp.GetSpeedAlpha());
		CurrentKiteAngle += SwirlSpeed * DeltaTime;
		if (CurrentKiteAngle >= 360.0)
			CurrentKiteAngle = CurrentKiteAngle - 360.0;

		float SwirlRadius = Math::Lerp(KiteFlight::CompanionMaxSwirlRadius, KiteFlight::CompanionMinSwirlRadius, KiteFlightComp.GetSpeedAlpha());

		float AnglePerKite = 360.0/ActiveCompanions.Num();
		for (int i = 0; i <= ActiveCompanions.Num() - 1; i++)
		{
			AKiteFlightKiteCompanion CurrentCompanion = ActiveCompanions[i];
			float Angle = Math::Wrap(CurrentKiteAngle + (AnglePerKite * i), 0.0, 360.0);
			FVector TargetLoc = Player.ActorCenterLocation + Player.MeshOffsetComponent.UpVector.RotateAngleAxis(Angle, Player.MeshOffsetComponent.ForwardVector) * SwirlRadius;
			TargetLoc += (Player.ViewRotation.ForwardVector * 400.0);
			FVector CurrentLoc = Math::VInterpTo(CurrentCompanion.ActorLocation, TargetLoc, DeltaTime, 15.0);
			CurrentCompanion.SetActorLocation(CurrentLoc);
			CurrentCompanion.SetActorRotation(Player.ViewRotation);
		}
	}

	void SpawnCompanion()
	{
		FVector SpawnLoc = Player.ActorLocation + (Player.ActorUpVector * 1200.0);

		AKiteFlightKiteCompanion Companion = SpawnActor(KiteFlightComp.CompanionClass, SpawnLoc, Player.MeshOffsetComponent.UpVector.Rotation());
		ActiveCompanions.Add(Companion);
	}

	void DespawnCompanion()
	{
		AKiteFlightKiteCompanion CompanionToRemove = ActiveCompanions[Math::RandRange(0, ActiveCompanions.Num() - 1)];
		ActiveCompanions.Remove(CompanionToRemove);

		FVector DirToKite = (CompanionToRemove.ActorLocation - Player.ActorLocation).GetSafeNormal().ConstrainToPlane(Player.ViewRotation.ForwardVector);
		CompanionToRemove.DespawnCompanion(DirToKite);

		UKiteFlightPlayerEffectEventEventHandler::Trigger_DespawnCompanion(Player);
		UKiteTownVOEffectEventHandler::Trigger_DespawnFlightCompanion(Game::Mio, KiteTown::GetVOEffectEventParams(Player));
	}
}