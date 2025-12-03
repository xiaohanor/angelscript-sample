class USkylinePhoneInputCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::Input;
	default TickGroupOrder = 0;

	USkylinePhoneUserComponent UserComp;

	FHazeAcceleratedVector2D CurrentCursorSpeed;
	const float MouseSensitivityMultiplier = 2;


	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		UserComp = USkylinePhoneUserComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (UserComp.Phone == nullptr)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (UserComp.Phone == nullptr)
			return true;

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
		const float Mult = Player.IsUsingGamepad() ? 1 : MouseSensitivityMultiplier;
		FVector2D Input = (GetAttributeVector2D(AttributeVectorNames::RightStickRaw) + 
							GetAttributeVector2D(AttributeVectorNames::LeftStickRaw)) * Mult;

		if(UserComp.Phone.XInputSensitivityOverride.IsSet())
			Input.X *= UserComp.Phone.XInputSensitivityOverride.Value;
		
		if(UserComp.Phone.YInputSensitivityOverride.IsSet())
			Input.Y *= UserComp.Phone.YInputSensitivityOverride.Value;


		if(Math::IsNearlyZero(Input.Size()))
			CurrentCursorSpeed.SnapTo(Input);
		else
			CurrentCursorSpeed.AccelerateTo(Input, UserComp.CursorAccelerationDuration, DeltaTime);
		
		UserComp.Phone.MoveCursor(CurrentCursorSpeed.Value * UserComp.CursorSpeed * DeltaTime);
	}
};