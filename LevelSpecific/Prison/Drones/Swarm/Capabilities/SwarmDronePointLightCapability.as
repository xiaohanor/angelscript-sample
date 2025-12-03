class USwarmDronePointLightCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(PrisonTags::Prison);
	default CapabilityTags.Add(PrisonTags::Drones);
	default CapabilityTags.Add(SwarmDroneTags::SwarmDrone);

	UPlayerSwarmDroneComponent SwarmDroneComponent;
	FSwarmDronePointLightSettings Settings;

	// Used for ball
	UPointLightComponent PointLightComponent;

	// Used for swarm
	USpotLightComponent SpotLightComponent;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		SwarmDroneComponent = UPlayerSwarmDroneComponent::Get(Owner);
		Settings = SwarmDroneComponent.LightSettings;

		// Create point light
		PointLightComponent = UPointLightComponent::GetOrCreate(Owner, n"SwarmDronePointLight");

		PointLightComponent.SetIntensity(Settings.BallIntensity);
		PointLightComponent.SetAttenuationRadius(Settings.BallAttenuationRadius);

		PointLightComponent.SetLightColor(Settings.Color);
		PointLightComponent.SetCastShadows(false);

		PointLightComponent.SetVisibility(false);

		PointLightComponent.SetLightFunctionMaterial(SwarmDroneComponent.LightMaterial);
		PointLightComponent.SetInverseSquaredFalloff(false);
		PointLightComponent.SetLightFalloffExponent(6);

		// Create spot light
		SpotLightComponent = USpotLightComponent::GetOrCreate(Owner, n"SwarmDroneSpotLight");
		SpotLightComponent.SetAbsolute(false, true);

		SpotLightComponent.SetLightColor(Settings.Color);
		SpotLightComponent.SetOuterConeAngle(100.0);

		SpotLightComponent.SetCastShadows(false);

		SpotLightComponent.SetVisibility(false);

	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!SwarmDroneComponent.IsPossessed())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!SwarmDroneComponent.IsPossessed())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		if(PointLightComponent.AttachParent != SwarmDroneComponent.DroneMesh)
			PointLightComponent.AttachToComponent(SwarmDroneComponent.DroneMesh);
		
		PointLightComponent.SetVisibility(true);
		SpotLightComponent.SetVisibility(true);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		PointLightComponent.SetVisibility(false);
		SpotLightComponent.SetVisibility(false);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		bool bSwarmActive = IsSwarmActive();

		TickBallPointLight(!bSwarmActive, DeltaTime);
		TickSwarmSpotlight(bSwarmActive, DeltaTime);
	}

	void TickBallPointLight(bool bBallActive, float DeltaTime)
	{
		float InterpSpeed = bBallActive ? 1.0 : 10.0;

		// Intensity
		{
			float TargetIntensity = (bBallActive ? Settings.BallIntensity : 0.0) * GetSpecialMultiplier();
			float Intensity = Math::FInterpTo(PointLightComponent.Intensity, TargetIntensity, DeltaTime, InterpSpeed);

			// Add some flare
			if (bBallActive)
				Intensity = Math::Max(Intensity * 0.95, Math::Abs(Math::Sin(Time::GameTimeSeconds)) * Intensity);

			PointLightComponent.SetIntensity(Intensity);
		}

		// Source radius
		{
			float TargetSourceRadius = SwarmDroneComponent.DroneMeshRadius * (bBallActive ? 0.7 : 2.0);
			float SourceRadius = Math::FInterpTo(PointLightComponent.SourceRadius, TargetSourceRadius, DeltaTime, InterpSpeed);
			PointLightComponent.SetSourceRadius(SourceRadius);
			PointLightComponent.SetSoftSourceRadius(SourceRadius * 0.3);
		}

		// Attenuation radius
		{
			float TargetAttenuationRadius = SwarmDroneComponent.bSwarmModeActive ? Settings.SwarmAttenuationRadius : Settings.BallAttenuationRadius;
			float AttenuationRadius = Math::FInterpTo(PointLightComponent.AttenuationRadius, TargetAttenuationRadius, DeltaTime, InterpSpeed);

			PointLightComponent.SetAttenuationRadius(AttenuationRadius);
		}
	}

	void TickSwarmSpotlight(bool bSwarmActive, float DeltaTime)
	{
		float InterpSpeed = bSwarmActive ? 2.0 : 10.0;

		// Intensity
		{
			float TargetIntensity = (bSwarmActive ? Settings.SwarmIntensity : 0.0) * GetSpecialMultiplier() * 8.0;
			float Intensity = Math::FInterpTo(SpotLightComponent.Intensity, TargetIntensity, DeltaTime, InterpSpeed);

			// Add some flare
			Intensity = Math::Max(Intensity * 0.95, Math::Abs(Math::PerlinNoise1D(Time::GameTimeSeconds)) * Intensity);

			SpotLightComponent.SetIntensity(Intensity);
		}

		// Source radius
		{
			float TargetSourceRadius = SwarmDroneComponent.DroneMeshRadius * 5.0;
			float SourceRadius = Math::FInterpTo(SpotLightComponent.SourceRadius, TargetSourceRadius, DeltaTime, InterpSpeed);
			SpotLightComponent.SetSourceRadius(SourceRadius);
		}

		// Attenuation radius
		{
			float TargetAttenuationRadius = Settings.BallAttenuationRadius * 3.0;
			float AttenuationRadius = Math::FInterpTo(SpotLightComponent.AttenuationRadius, TargetAttenuationRadius, DeltaTime, InterpSpeed);

			SpotLightComponent.SetAttenuationRadius(AttenuationRadius);
		}

		SpotLightComponent.SetRelativeRotation((-Player.MovementWorldUp).Rotation());
		SpotLightComponent.SetRelativeLocation(FVector::UpVector * SwarmDroneComponent.DroneMeshRadius * 2.0);
	}

	bool IsSwarmActive() const
	{
		if (SwarmDroneComponent.bJumping)
			return true;

		if (SwarmDroneComponent.bDeswarmifying)
			return false;

		if (!SwarmDroneComponent.bSwarmModeActive)
			return false;

		return true;
	}

	float GetSpecialMultiplier() const
	{
		if (SwarmDroneComponent.bJumping)
			return 0.2;

		if (SwarmDroneComponent.bHovering)
			return 0.0;

		return 1.0;
	}
}