class UWitchPlayerMushroomBounceCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::Gameplay;

	UWitchPlayerMushroomBounceComponent MushroomBounceComponent;
	UPlayerMovementComponent MovementComponent;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MushroomBounceComponent = UWitchPlayerMushroomBounceComponent::Get(Player);
		MovementComponent = UPlayerMovementComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!MushroomBounceComponent.HasBouncedThisFrame())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(MovementComponent.HasGroundContact())
		{
			if(Cast<AWitchBouncyMushroomActor>(MovementComponent.GroundContact.Actor) == nullptr)
				return true;
		}

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Player.PlaySlotAnimation(MushroomBounceComponent.SlotAnimParams);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.StopSlotAnimation();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(MushroomBounceComponent.HasBouncedThisFrame())
			Player.PlaySlotAnimation(MushroomBounceComponent.SlotAnimParams);
	}
};