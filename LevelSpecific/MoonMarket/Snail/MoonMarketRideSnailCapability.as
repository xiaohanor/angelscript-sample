class UMoonMarketRideSnailCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::Gameplay;

	UPlayerMovementComponent MoveComp;
	UMoonMarketRideSnailComponent SnailComp;


	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		SnailComp = UMoonMarketRideSnailComponent::Get(Player);
		MoveComp = UPlayerMovementComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(SnailComp.Snail == nullptr)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(SnailComp.Snail == nullptr)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		CapabilityInput::LinkActorToPlayerInput(SnailComp.Snail, Player);

		Player.AttachToComponent(SnailComp.Snail.RiderPosition);
		Player.BlockCapabilities(CameraTags::CameraChaseAssistance, this);
		Player.BlockCapabilities(CapabilityTags::Collision, this);
		Player.BlockCapabilities((n"SnailSlip"), this);
		Player.BlockCapabilitiesExcluding(CapabilityTags::GameplayAction, n"InteractionCancel", this);
		//Player.BlockCapabilities(n"Interaction", this);
		Player.BlockCapabilitiesExcluding(CapabilityTags::Movement, CapabilityTags::MovementInput, this);

		Player.PlaySlotAnimation(FHazeAnimationDelegate(), FHazeAnimationDelegate(this, n"OnEnterFinished"), SnailComp.Snail.RideAnimationEnter[Player]);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		CapabilityInput::LinkActorToPlayerInput(nullptr, Player);

		Player.DetachFromActor();
		Player.UnblockCapabilities(CameraTags::CameraChaseAssistance, this);
		Player.UnblockCapabilities(CapabilityTags::Collision, this);
		Player.UnblockCapabilities((n"SnailSlip"), this);
		Player.UnblockCapabilities(CapabilityTags::GameplayAction, this);
		//Player.UnblockCapabilities(n"Interaction", this);
		Player.UnblockCapabilities(CapabilityTags::Movement, this);

		Player.StopSlotAnimation();
		Player.ResetMovement();

		Player.ClearCameraSettingsByInstigator(this);

		if(UMoonMarketThunderStruckComponent::Get(Player).bThunderStruck)
		{
			Player.AddMovementImpulse( Player.ActorUpVector * 150);
		}
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
	}

	UFUNCTION()
	void OnEnterFinished()
	{
		if (IsActive())
			Player.PlaySlotAnimation(SnailComp.Snail.RideAnimation[Player]);
		
	}
};