class UCentipedeForceFeedbackCapability : UHazePlayerCapability
{
	UPlayerCentipedeComponent CentipedeComponent;
	UCentipedeBiteComponent BiteComponent;

	float CurrentTriggerEffectStartPosition = 0;

	bool bWasBiteTargetInRange = false;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		CentipedeComponent = UPlayerCentipedeComponent::Get(Owner);
		BiteComponent = UCentipedeBiteComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!CentipedeComponent.IsCentipedeActive())
			return false;

		if (BiteComponent.IsBitingSomething())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!CentipedeComponent.IsCentipedeActive())
			return true;

		if (BiteComponent.IsBitingSomething())
		{
			// Remove effect only when player stahps messing around with trigger
			float TriggerAxisValue = GetAttributeFloat(AttributeNames::PrimaryLevelAbilityAxis);
			if (TriggerAxisValue <= CurrentTriggerEffectStartPosition)
				return true;
		}

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		bWasBiteTargetInRange = false;
		CurrentTriggerEffectStartPosition = 0;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		CurrentTriggerEffectStartPosition = 0;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (BiteComponent.IsInBitingRange())
		{
			if (!BiteComponent.GetBiteActioning(this))
				TickBiteableInRange(DeltaTime);

			if (!bWasBiteTargetInRange)
			{
				bWasBiteTargetInRange = true;
				CurrentTriggerEffectStartPosition = 0.25;
			}
		}
		else
		{
			if (bWasBiteTargetInRange)
			{
				bWasBiteTargetInRange = false;
				CurrentTriggerEffectStartPosition = 0.25;
			}
		}
	}

	void TickBiteableInRange(float DeltaTime)
	{
		float Strength = Math::Min(1.0, 1.0 - (BiteComponent.GetInRangeFraction() - 0.5));

		FHazeFrameForceFeedback FF;
		FF.RightTrigger = 0.1;
		FF.RightMotor = 0.2;
		Player.SetFrameForceFeedback(FF, Strength);
	}
}