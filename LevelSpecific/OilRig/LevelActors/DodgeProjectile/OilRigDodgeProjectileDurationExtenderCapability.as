class UOilRigDodgeProjectileDurationExtenderCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::Gameplay;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (Player.IsAnyCapabilityActive(PlayerMovementTags::Dash) || Player.IsAnyCapabilityActive(PlayerMovementTags::AirDash))
		{
			TArray<AActor> OverlappingActors;
			Player.GetOverlappingActors(OverlappingActors, AOilRigDodgeProjectile);
			for (AActor Actor : OverlappingActors)
			{
				AOilRigDodgeProjectile Projectile = Cast<AOilRigDodgeProjectile>(Actor);
				if (Projectile != nullptr && !Projectile.bDurationExtended)
					Projectile.ExtendDuration();
			}
		}
	}
}