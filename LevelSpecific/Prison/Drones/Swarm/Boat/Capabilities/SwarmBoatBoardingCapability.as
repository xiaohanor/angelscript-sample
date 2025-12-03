class USwarmDroneBoardingCapability : UHazePlayerCapability
{
	UPlayerSwarmDroneComponent SwarmDroneComponent;
	UPlayerSwarmBoatComponent SwarmBoatComponent;

	const float ShakeAmplitude = 12 ;
	const float Duration = 0.3;

	float Alpha = 0.0;

	float AlphaTarget = 0.0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		SwarmDroneComponent = UPlayerSwarmDroneComponent::Get(Owner);
		SwarmBoatComponent = UPlayerSwarmBoatComponent::Get(Owner);

		SwarmBoatComponent.OnMagnetDroneBoarded.AddUFunction(this, n"OnMagnetDroneBoarded");
		SwarmBoatComponent.OnMagnetDroneDisembarked.AddUFunction(this, n"OnMagnetDroneDisembarked");
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!SwarmDroneComponent.bFloating)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!SwarmDroneComponent.bFloating)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Alpha = 0.0;

		FVector DerivedLocation = Player.ActorLocation + Player.ActorVelocity * Time::GetActorDeltaSeconds(Owner);
		USwarmBoatEventHandler::Trigger_OnWaterEnter(Player, DerivedLocation);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		AlphaTarget = Math::Saturate(AlphaTarget - DeltaTime / Duration);
		Alpha = Math::FInterpTo(Alpha, AlphaTarget, DeltaTime, 10);

		SwarmBoatComponent.BoardingMeshRumble = (FRotator(
			Math::PerlinNoise1D(ActiveDuration * 2) * Alpha,
			Math::PerlinNoise1D(ActiveDuration * 0.3) * Alpha * 0.5,
			Math::PerlinNoise1D(ActiveDuration * 3) * Alpha,
		) * ShakeAmplitude).Quaternion();
	}

	UFUNCTION()	
	private void OnMagnetDroneBoarded()
	{
		AlphaTarget = 1.0;

		// Play camera shake and light rumble
		Player.PlayForceFeedback(SwarmBoatComponent.BoardingParams.BoardingFF, this);
		Player.PlayCameraShake(SwarmBoatComponent.CameraShakes.MagnetDroneBoardingCameraShakeClass, this, 0.5);
	}

	UFUNCTION()
	private void OnMagnetDroneDisembarked()
	{
		AlphaTarget = 0.33;

		// Play short light rumble
		Player.PlayForceFeedback(SwarmBoatComponent.BoardingParams.DisembarkingFF, this);
	}
}