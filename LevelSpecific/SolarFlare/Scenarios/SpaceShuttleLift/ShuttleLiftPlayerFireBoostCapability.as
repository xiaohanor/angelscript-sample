class UShuttleLiftPlayerFireBoostCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(n"ShuttleLiftMove");

	default TickGroup = EHazeTickGroup::Gameplay;

	UShuttleLiftPlayerComponent UserComp;

	float MaxForce = 250.0;
	float CurrentForce;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		UserComp = UShuttleLiftPlayerComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!WasActionStarted(ActionNames::PrimaryLevelAbility))
			return false;
		if (UserComp.Lift == nullptr)
			return false;
		if (!UserComp.bIsActive)
			return false;
		if (UserComp.Lift.ValidTimer[Player] > 0)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		// if (UserComp.Lift == nullptr)
		// 	return true;
		// if (!UserComp.bIsActive)
		// 	return true;
		// return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		UserComp.Lift.FireLiftMovement(Player);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		// float Input = GetAttributeVector2D(AttributeVectorNames::LeftStickRaw).Y; 

		// PrintToScreen("Input: " + Input);

		// float Target = Input * MaxForce;
		// CurrentForce = Math::FInterpConstantTo(CurrentForce, Target, DeltaTime, MaxForce);

		// UserComp.UpdateLiftMovement(CurrentForce * DeltaTime);
	}
};