class UDentistCannonLockPlayerCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::BeforeGameplay;

	ADentistCannon Cannon;

	AHazePlayerCharacter Player;
	UDentistToothCannonComponent CannonComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Cannon = Cast<ADentistCannon>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!Cannon.IsStateActive(EDentistCannonState::Aiming))
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(!Cannon.IsStateActive(EDentistCannonState::Aiming))
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Player = Cannon.GetPlayerInCannon();

		CannonComp = UDentistToothCannonComponent::Get(Player);
		CannonComp.EnterCannon(Cannon);

		CapabilityInput::LinkActorToPlayerInput(Cannon, Player);
		
		Player.AttachToComponent(Cannon.SpringTranslateComp);
		Player.BlockCapabilitiesExcluding(CapabilityTags::Movement, Dentist::Cannon::DentistCannonBlockExclusionTag, this);
		Player.BlockCapabilitiesExcluding(CapabilityTags::GameplayAction, Dentist::Cannon::DentistCannonBlockExclusionTag, this);

		UDentistCannonEventHandler::Trigger_OnPlayerEntered(Cannon);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		UDentistCannonEventHandler::Trigger_OnPlayerExited(Cannon);

		CapabilityInput::LinkActorToPlayerInput(Cannon, nullptr);

		Player.DetachFromActor();
		Player.UnblockCapabilities(CapabilityTags::Movement, this);
		Player.UnblockCapabilities(CapabilityTags::GameplayAction, this);

		Player = nullptr;
		CannonComp = nullptr;
	}
};