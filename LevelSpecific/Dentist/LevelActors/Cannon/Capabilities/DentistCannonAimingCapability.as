struct FDentistCannonAimingDeactivateParams
{
	bool bLaunch = false;
};

class UDentistCannonAimingCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::Gameplay;

	ADentistCannon Cannon;

	float SpringHeight;
	float InitialConstrainBounce;

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
	bool ShouldDeactivate(FDentistCannonAimingDeactivateParams& Params) const
	{
		if(!Cannon.IsStateActive(EDentistCannonState::Aiming))
			return true;

		if(ActiveDuration < Cannon.AimRotateDuration)
			return false;

		switch(Dentist::Cannon::LaunchTrigger)
		{
			case EDentistCannonLaunchTrigger::OnInput:
			{
				if(WasActionStarted(ActionNames::PrimaryLevelAbility))
				{
					// We clicked! Launch!
					Params.bLaunch = true;
					return true;
				}
				break;
			}

			case EDentistCannonLaunchTrigger::AfterDelay:
			{
				if(ActiveDuration > Cannon.AimRotateDuration + Cannon.LaunchDelay)
				{
					// A delay has passed, launch!
					Params.bLaunch = true;
					return true;
				}
			}
		}

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Cannon.StartAiming();

		InitialConstrainBounce = Cannon.SpringTranslateComp.ConstrainBounce;
		Cannon.SpringTranslateComp.ConstrainBounce = 0;

		const float AngleDiff = FRotator(Cannon.InitialPitch, Cannon.InitialYaw, 0).ForwardVector.GetAngleDegreesTo(FRotator(Cannon.TargetPitch, Cannon.TargetYaw, 0).ForwardVector);

		UDentistCannonEventHandler::Trigger_OnStartAiming(Cannon);

		if(Cannon.CameraToActivateWhileAiming != nullptr)
		{
			Cannon.GetPlayerInCannon().ActivateCamera(Cannon.CameraToActivateWhileAiming, Cannon.CameraBlendInTime, this);
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FDentistCannonAimingDeactivateParams Params)
	{
		UDentistCannonEventHandler::Trigger_OnStopAiming(Cannon);

		Cannon.SpringTranslateComp.ConstrainBounce = InitialConstrainBounce;

		if(Cannon.CameraToActivateWhileAiming != nullptr)
		{
			Cannon.GetPlayerInCannon().DeactivateCameraByInstigator(this, Cannon.CameraBlendOutTime);
		}

		if(Params.bLaunch)
		{
			Cannon.Launch();
		}
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		TickSpringHeight(DeltaTime);
		
		switch(Dentist::Cannon::AimMode)
		{
			case EDentistCannonAimMode::Automatic:
				TickAutomaticAiming(DeltaTime);
				break;

			case EDentistCannonAimMode::Manual:
				TickManualAiming(DeltaTime);
				break;
		}
	}

	void TickSpringHeight(float DeltaTime)
	{
		SpringHeight = Math::FInterpConstantTo(SpringHeight, Cannon.SpringTranslateComp.MinZ, DeltaTime, Dentist::Cannon::SpringDropSpeed);
		Cannon.SpringTranslateComp.ApplyImpulse(Cannon.SpringTranslateComp.WorldLocation, Cannon.SpringTranslateComp.UpVector * -500);
	}
	
	void TickAutomaticAiming(float DeltaTime)
	{
		float Alpha = Math::Saturate(ActiveDuration / Cannon.AimRotateDuration);
		Cannon.SetCannonAlpha(Alpha);
	}

	void TickManualAiming(float DeltaTime)
	{
		// FB TODO: Implement
	}
};