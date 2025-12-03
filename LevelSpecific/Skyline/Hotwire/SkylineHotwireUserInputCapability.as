class USkylineHotwireUserInputCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(n"SkylineHotwireToolMovement");

	default TickGroup = EHazeTickGroup::Gameplay;

	USkylineHotwireUserComponent UserComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		UserComp = USkylineHotwireUserComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!IsValid(UserComp.Tool))
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!IsValid(UserComp.Tool))
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
		FVector2D Input = GetAttributeVector2D(AttributeVectorNames::LeftStickRaw);

		UserComp.Tool.AddActorLocalRotation(FRotator(-Input.Y * UserComp.Tool.AngleSpeed * DeltaTime, 0.0, 0.0));
		UserComp.Tool.AddActorLocalOffset(FVector::RightVector * Input.X * UserComp.ToolMovementSpeed * DeltaTime);
	}
};