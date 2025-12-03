struct FDentistDoubleCannonAimingDeactivateParams
{
	bool bLaunch = false;
	float LaunchTime = 0;
	float LandTime = 0;
};

class UDentistDoubleCannonAimingCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::Gameplay;

	ADentistDoubleCannon Cannon;

	float SpringHeight;
	float InitialConstrainBounce;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Cannon = Cast<ADentistDoubleCannon>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		// Can only transition from Inactive
		if(!Cannon.IsStateActive(EDentistDoubleCannonState::Inactive))
			return false;

		if(!Cannon.HasBothPlayersRecentlyGroundPounded())
			return false;

		if(!Cannon.AreBothPlayersWithinTheBarrel())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate(FDentistDoubleCannonAimingDeactivateParams& Params) const
	{
		if(!Cannon.IsStateActive(EDentistDoubleCannonState::Aiming))
			return true;

		if(ActiveDuration > Cannon.AimRotateDuration + Cannon.LaunchDelay)
		{
			// The delay has passed, launch!
			Params.bLaunch = true;
			Params.LaunchTime = Time::PredictedGlobalCrumbTrailTime;
			Params.LandTime = Params.LaunchTime + Cannon.GetLaunchTrajectory().GetTotalTime();
			return true;
		}

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Cannon.StartAiming();

		for(auto Player : Game::Players)
		{
			auto CannonComp = UDentistToothDoubleCannonComponent::Get(Player);
			CannonComp.EnterCannon(Cannon);

			if(Cannon.CameraToActivateWhileAiming != nullptr)
					Player.ActivateCamera(Cannon.CameraToActivateWhileAiming, Cannon.CameraBlendInTime, this);
		}

		InitialConstrainBounce = Cannon.SpringTranslateComp.ConstrainBounce;
		Cannon.SpringTranslateComp.ConstrainBounce = 0;

		UDentistDoubleCannonEventHandler::Trigger_OnBothPlayerSuccess(Cannon);

		Cannon.OnPlayersEntered.Broadcast();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FDentistDoubleCannonAimingDeactivateParams Params)
	{
		Cannon.SpringTranslateComp.ConstrainBounce = InitialConstrainBounce;

		if(Cannon.CameraToActivateWhileAiming != nullptr)
		{
			for(auto Player : Game::Players)
				Player.DeactivateCameraByInstigator(this, Cannon.CameraBlendOutTime);
		}

		if(Params.bLaunch)
			Cannon.Launch(Params.LaunchTime);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		// Reset the spring
		SpringHeight = Math::FInterpConstantTo(SpringHeight, Cannon.SpringTranslateComp.MinZ, DeltaTime, Dentist::Cannon::SpringDropSpeed);
		Cannon.SpringTranslateComp.ApplyImpulse(Cannon.SpringTranslateComp.WorldLocation, Cannon.SpringTranslateComp.UpVector * -500);

		// Aim towards target
		float Alpha = Math::Saturate(ActiveDuration / Cannon.AimRotateDuration);
		Cannon.SetCannonAlpha(Alpha);
	}
};