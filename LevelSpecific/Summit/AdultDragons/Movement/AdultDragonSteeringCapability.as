class UAdultDragonSteeringCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(CapabilityTags::Input);
	default CapabilityTags.Add(n"AdultDragon");
	default CapabilityTags.Add(n"AdultDragonSteering");

	default TickGroup = EHazeTickGroup::Input;
	default TickGroupOrder = 100;

	default DebugCategory = n"AdultDragon";

	// default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	UPlayerAdultDragonComponent DragonComp;
	UAdultDragonAirBreakComponent AirBreakComp;
	UPlayerMovementComponent MoveComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		DragonComp = UPlayerAdultDragonComponent::Get(Player);
		AirBreakComp = UAdultDragonAirBreakComponent::Get(Player);
		MoveComp = UPlayerMovementComponent::Get(Player);
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
		Player.BlockCapabilities(CapabilityTags::MovementInput, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.UnblockCapabilities(CapabilityTags::MovementInput, this);
		Player.ClearMovementInput(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FVector Input;
		if (HasControl())
		{
			FVector2D LeftStickRaw = GetAttributeVector2D(AttributeVectorNames::MovementRaw);
			Input.X = LeftStickRaw.X;
			Input.Y = LeftStickRaw.Y;

			if (Player.IsSteeringPitchInverted())
				Input.X *= -1;

			Player.ApplyMovementInput(Input, this, EInstigatePriority::Low);
		}
		else
		{
			Input = MoveComp.GetSyncedMovementInputForAnimationOnly();
		}

		DragonComp.AnimParams.Banking = Input.Y;
		DragonComp.AnimParams.Pitching = Input.X;
	}
};