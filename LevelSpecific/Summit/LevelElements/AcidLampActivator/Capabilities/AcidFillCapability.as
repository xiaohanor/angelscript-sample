class UAcidFillCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	default TickGroup = EHazeTickGroup::Gameplay;

	AAcidActivator Activator;

	// float TimeSinceLastHit;
	// float TimeSinceHitBuffer = 0.15;

	bool bCanFillInAlternateMode;

	bool bIsDecaying;
	bool bIsFilling;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Activator = Cast<AAcidActivator>(Owner);
		Activator.TimeSinceLastHit = 1.0;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (Activator.bIsActive)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Activator.bIsActive)
			return true;
		
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		bCanFillInAlternateMode = false;
		Activator.TimeSinceLastHit = 1.0;
		Activator.AcidAlpha.SnapTo(0.0);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Activator.AcidAlpha.SnapTo(1.0);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		Activator.TimeSinceLastHit += DeltaTime;

		//If not being hit
		if (Activator.TimeSinceLastHit > Activator.TimeSinceHitBuffer)
		{
			Activator.AcidAlpha.AccelerateTo(0.0, 1 / Activator.Settings.DecayRate, DeltaTime);
			EventDecayLogic();
		}
		else
		{
			Activator.AcidAlpha.AccelerateTo(1.0, 1 / Activator.Settings.IncreaseRate, DeltaTime);
			
			if(HasControl()
			&& Activator.AcidAlpha.Value > 0.95)
			{
				Activator.CrumbStartActivator();
			}		
			
			EventFillLogic();
		}

		UAcidActivatorEffectHandler::Trigger_UpdateAcidLampProgress(Activator, FAcidActivatorProgressParams(Activator.AcidAlpha.Value));
	}

	void EventFillLogic()
	{
		if (bIsDecaying)
		{
			bIsFilling =  true;

			if (bIsDecaying)
			{
				bIsDecaying = false;
				UAcidActivatorEffectHandler::Trigger_OnLampStopDecaying(Activator);
			}

			UAcidActivatorEffectHandler::Trigger_OnLampStartFilling(Activator);
		}		
		else
		{
			if (!bIsFilling && Activator.AcidAlpha.Value < 0.95)
			{
				bIsFilling = true;
				UAcidActivatorEffectHandler::Trigger_OnLampStartFilling(Activator);
			}
		}

		if (bIsFilling && Activator.AcidAlpha.Value > 0.95)
		{
			bIsFilling = false;
			UAcidActivatorEffectHandler::Trigger_OnLampStopFilling(Activator);
		}
	}

	void EventDecayLogic()
	{
		if (!bIsDecaying && Activator.AcidAlpha.Value > 0.05)
		{
			bIsDecaying = true;

			if (bIsFilling)
			{
				bIsFilling = false;
				UAcidActivatorEffectHandler::Trigger_OnLampStopFilling(Activator);
			}

			UAcidActivatorEffectHandler::Trigger_OnLampStartDecaying(Activator);
		}

		if (bIsDecaying && Activator.AcidAlpha.Value < 0.05)
		{
			bIsDecaying = false;
			UAcidActivatorEffectHandler::Trigger_OnLampStopDecaying(Activator);
		}
	}
};