class USkylineFlyingCarGotyDeathCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default TickGroup = EHazeTickGroup::AfterGameplay;

	ASkylineFlyingCar CarOwner;

	// Feels weird to do this here... but would also suck to have death capability per player plus car
	UPlayerRespawnComponent PilotRespawnComponent = nullptr;
	UPlayerRespawnComponent GunnerRespawnComponent = nullptr;

	int RespawnCount = 0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		CarOwner = Cast<ASkylineFlyingCar>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!CarOwner.IsCarExploding())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (RespawnCount >= 2)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		// Block car, pilot and gunner caps!!
		CarOwner.BlockCapabilities(FlyingCarTags::FlyingCarMovement, this);
		CarOwner.CurrentPilot.BlockCapabilities(FlyingCarTags::FlyingCarPilot, this);
		CarOwner.CurrentGunner.BlockCapabilities(FlyingCarTags::FlyingCarGunner, this);

		// Register respawn events
		if (HasControl())
		{
			PilotRespawnComponent = UPlayerRespawnComponent::Get(CarOwner.CurrentPilot);
			GunnerRespawnComponent = UPlayerRespawnComponent::Get(CarOwner.CurrentGunner);
			PilotRespawnComponent.OnPlayerRespawned.AddUFunction(this, n"OnPilotRespawn");
			GunnerRespawnComponent.OnPlayerRespawned.AddUFunction(this, n"OnGunnerRespawn");
		}

		Time::SetWorldTimeDilation(1.0);
		// Hide car
		CarOwner.Gun.Root.SetVisibility(false, true);
		CarOwner.Mesh.SetVisibility(false, true);

		CarOwner.ResetMovement(true);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		// Show car again
		CarOwner.Gun.Root.SetVisibility(true, true);
		CarOwner.Mesh.SetVisibility(true, true);

		CarOwner.UnblockCapabilities(FlyingCarTags::FlyingCarMovement, this);
		CarOwner.CurrentPilot.UnblockCapabilities(FlyingCarTags::FlyingCarPilot, this);
		CarOwner.CurrentGunner.UnblockCapabilities(FlyingCarTags::FlyingCarGunner, this);

		if (HasControl())
		{
			PilotRespawnComponent.OnPlayerRespawned.UnbindObject(this);
			GunnerRespawnComponent.OnPlayerRespawned.UnbindObject(this);
			PilotRespawnComponent = nullptr;
			GunnerRespawnComponent = nullptr;
		}

		RespawnCount = 0;
	}

	UFUNCTION()
	private void OnPilotRespawn(AHazePlayerCharacter RespawnedPlayer)
	{
		if (HasControl())
			CrumbOnPilotRespawn(RespawnedPlayer);
	}

	UFUNCTION(CrumbFunction)
	private void CrumbOnPilotRespawn(AHazePlayerCharacter RespawnedPlayer)
	{
		RespawnCount++;

		// Teleport car owner actor and reset pilot's relative transform
		CarOwner.TeleportActor(RespawnedPlayer.ActorLocation, RespawnedPlayer.ActorRotation, this);
		RespawnedPlayer.RootComponent.SetRelativeTransform(FTransform::Identity);
	}

	UFUNCTION()
	private void OnGunnerRespawn(AHazePlayerCharacter RespawnedPlayer)
	{
		if (HasControl())
			CrumbOnGunnerRespawn(RespawnedPlayer);
	}

	UFUNCTION(CrumbFunction)
	private void CrumbOnGunnerRespawn(AHazePlayerCharacter RespawnedPlayer)
	{
		RespawnCount++;

		// Snap back to gunner seat
		CarOwner.TeleportActor(RespawnedPlayer.ActorLocation, RespawnedPlayer.ActorRotation, this);
		RespawnedPlayer.RootComponent.SetRelativeTransform(FTransform::Identity);
	}
}