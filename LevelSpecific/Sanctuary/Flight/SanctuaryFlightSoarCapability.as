class USanctuaryFlightSoarCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(CapabilityTags::MovementInput);
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(n"CylinderSoar");
	default CapabilityTags.Add(n"Flight");

	default DebugCategory = n"Movement";
	
	default TickGroup = EHazeTickGroup::ActionMovement;

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	USanctuaryFlightComponent FlightComp;
	UPlayerMovementComponent MoveComp;
	USanctuaryFlightAnimationComponent AnimComp;
	USanctuaryFlightSettings Settings;

	float Cooldown = 0.0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		FlightComp = USanctuaryFlightComponent::Get(Player);
		MoveComp = UPlayerMovementComponent::Get(Player);
		AnimComp = 	USanctuaryFlightAnimationComponent::Get(Player);
		Settings = USanctuaryFlightSettings::GetSettings(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!FlightComp.bFlying)
			return false;
		if (!IsActioning(ActionNames::MovementJump))
			return false;
		if (Time::GameTimeSeconds < Cooldown)
			return false;
		return true;		
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!FlightComp.bFlying)
			return true;
		if (!IsActioning(ActionNames::MovementJump))
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Cooldown = Time::GameTimeSeconds + Settings.SoarCooldown;

		// Initial upwards soar
		Player.AddMovementImpulse(MoveComp.WorldUp * Settings.SoarSpeed * 0.5, n"FlightSoar");

		// Continuous acceleration
		FlightComp.AdditionalAcceleration.Apply(MoveComp.WorldUp * Settings.SoarSpeed, this, EInstigatePriority::Low);

		AnimComp.BlendSpaceVertical.Apply(1.0, this, EInstigatePriority::Normal);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		FlightComp.AdditionalAcceleration.Clear(this);
		AnimComp.BlendSpaceVertical.Clear(this);
	}
}
