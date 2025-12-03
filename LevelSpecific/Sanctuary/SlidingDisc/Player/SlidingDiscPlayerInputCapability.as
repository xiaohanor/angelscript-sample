class USlidingDiscPlayerInputCapability : UHazePlayerCapability
{
	default TickGroup = EHazeTickGroup::Input;

	USlidingDiscPlayerComponent SlidingDiscPlayerComponent;

	float LeanLerpSpeed = 3.0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		SlidingDiscPlayerComponent = USlidingDiscPlayerComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (SlidingDiscPlayerComponent.bIsSliding)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!SlidingDiscPlayerComponent.bIsSliding)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		Player.RequestLocomotion(n"SlidingDisc", this);
		
		if (!HasControl())
			return;

		FVector2D Input = GetAttributeVector2D(AttributeVectorNames::LeftStickRaw);
		SlidingDiscPlayerComponent.Input = Input;
	//	PrintToScreen("" + Owner.Name + " is giving input to SlidingDisc" + Input, 0.0, FLinearColor::Green);

		float LeanValue = Math::Lerp(SlidingDiscPlayerComponent.Lean.Value, SlidingDiscPlayerComponent.Input.X, LeanLerpSpeed * DeltaTime);
		SlidingDiscPlayerComponent.Lean.SetValue(LeanValue);

		PrintToScreen("Lean: " + SlidingDiscPlayerComponent.Lean.Value, 0.0, FLinearColor::Green);
	}
}