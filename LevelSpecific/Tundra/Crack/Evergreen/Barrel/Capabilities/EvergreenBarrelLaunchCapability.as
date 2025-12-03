class UEvergreenBarrelLaunchCapability : UHazePlayerCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(BlockedWhileIn::FloorMotion);
	default CapabilityTags.Add(BlockedWhileIn::PoleClimb);

	default DebugCategory = n"Movement";

	default TickGroup = EHazeTickGroup::InfluenceMovement;
	default TickGroupOrder = 1;

	UPlayerMovementComponent MoveComp;
	UPlayerPoleClimbComponent PoleClimbComp;
	UEvergreenBarrelPlayerComponent BarrelPlayerComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MoveComp = UPlayerMovementComponent::Get(Player);
		PoleClimbComp = UPlayerPoleClimbComponent::Get(Player);
		BarrelPlayerComp = UEvergreenBarrelPlayerComponent::GetOrCreate(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(CurrentBarrel == nullptr)
			return false;

		if(!CurrentBarrel.bLaunchMonkey)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		// This capability will mainly deactivate by being blocked
		if(CurrentBarrel != nullptr)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		FVector ShootDirection = CurrentBarrel.SkeletalMesh.UpVector;
		AEvergreenBarrel Barrel;
		if(CurrentBarrel.IsWithinAutoAimRange(Barrel))
		{
			ShootDirection = (Barrel.ActorLocation - Player.ActorLocation).GetSafeNormal();
		}

		UEvergreenBarrelEffectHandler::Trigger_OnShootMonkey(CurrentBarrel);
		MoveComp.AddPendingImpulse(ShootDirection * CurrentBarrel.MioShootOutImpulse, n"EvergreenBarrel");
		UMovementGravitySettings::SetGravityAmount(Player, CurrentBarrel.MioGravityUntilHittingGroundOrPoleClimb, this, EHazeSettingsPriority::Final);
		CurrentBarrel.bLaunchMonkey = false;
		BarrelPlayerComp.BarrelToBlock = CurrentBarrel;
		BarrelPlayerComp.ExitBarrel();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		UMovementGravitySettings::ClearGravityAmount(Game::Mio, this, EHazeSettingsPriority::Final);
		BarrelPlayerComp.BarrelToBlock = nullptr;
	}

	AEvergreenBarrel GetCurrentBarrel() const property
	{
		return BarrelPlayerComp.CurrentBarrel;
	}
}