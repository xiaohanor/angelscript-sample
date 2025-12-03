class UPigDizzyCapability : UHazePlayerCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(n"Stretch");

	default DebugCategory = PigTags::Pig;

	UPlayerPigStretchyLegsComponent StretchyLegsComponent;
	TArray<AHazeActor> DizzyStars;

	FRotator RotationIncrement;
	FRotator HaloRotation;

	bool bDisabledInput = false;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		StretchyLegsComponent = UPlayerPigStretchyLegsComponent::Get(Owner);	
		RotationIncrement.Yaw = Math::RadiansToDegrees(PI * 2 / Pig::StretchyLegs::Dizzy::StarsAmount);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (StretchyLegsComponent.DizzyStarsClass == nullptr) 
			return false;

		if (StretchyLegsComponent.bDizzy)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (ActiveDuration > Pig::StretchyLegs::Dizzy::Duration)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		FVector StarScale = GetStarScale();
		float InitialHaloRadius = GetHaloRadius();
		FVector HeadLocation = Player.Mesh.GetSocketLocation(n"Head");
		for (int i = 0; i < Pig::StretchyLegs::Dizzy::StarsAmount; ++i) 
		{
			AHazeActor Star = SpawnActor(StretchyLegsComponent.DizzyStarsClass);
			Star.SetActorScale3D(StarScale);
			Star.SetActorEnableCollision(false);
			FRotator InitialRotation = RotationIncrement * i;
			Star.SetActorLocation(HeadLocation + Pig::StretchyLegs::Dizzy::HaloOffset + InitialRotation.RotateVector(FVector(InitialHaloRadius, 0, 0)));
			Star.SetActorRotation(InitialRotation);
			DizzyStars.Add(Star);
		}

		bDisabledInput = true;
		Player.BlockCapabilities(CapabilityTags::MovementInput, this);
		Player.SetActorHorizontalVelocity(FVector::ZeroVector);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		StretchyLegsComponent.bDizzy = false;
		for (int i = 0; i < DizzyStars.Num(); ++i) 
		{
			DizzyStars[i].DestroyActor();
		}
		DizzyStars.Empty();

		if (bDisabledInput)
		{
			bDisabledInput = false;
			Player.UnblockCapabilities(CapabilityTags::MovementInput, this);
		}

		UStretchyPigEffectEventHandler::Trigger_OnDizzyStop(Player);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (ActiveDuration > Pig::StretchyLegs::Dizzy::DisableMovementDuration && bDisabledInput)
		{
			bDisabledInput = false;
			Player.UnblockCapabilities(CapabilityTags::MovementInput, this);
		}

		UpdateStarRotation(DeltaTime);
	}

	void UpdateStarRotation(float DeltaTime)
	{
		float NewHaloRadius = GetHaloRadius();
		FVector NewStarScale = GetStarScale();
		float DeltaAngle = Math::RadiansToDegrees(PI * 2 * GetSpeed() * DeltaTime * -1.0);
		HaloRotation.Yaw += DeltaAngle;
		FVector HeadLocation = Player.Mesh.GetSocketLocation(n"Head");
		for (int i = 0; i < DizzyStars.Num(); ++i) 
		{
			AHazeActor Star = DizzyStars[i];
			FRotator HaloStarSpotRotation = HaloRotation + RotationIncrement * i;
			Star.SetActorLocation(HeadLocation + Pig::StretchyLegs::Dizzy::HaloOffset + HaloStarSpotRotation.RotateVector(FVector(NewHaloRadius, 0, 0)));
			FRotator StarRot = HaloStarSpotRotation;
			StarRot.Yaw -= 90; // face the heading direction
			Star.SetActorRotation(StarRot);
			Star.SetActorScale3D(NewStarScale);
		}
	}

	float GetUpDownInterpolation(float NumPeaks) 
	{
		float UppedTimer = ActiveDuration * NumPeaks;
		float ModuloTimer = (UppedTimer % Pig::StretchyLegs::Dizzy::Duration);
		float FlatValue = (ModuloTimer / Pig::StretchyLegs::Dizzy::Duration);
		float Interpolation = Math::Sin((FlatValue * PI) / 2);
		if (Interpolation > 0.5)
			Interpolation = 1 - Interpolation;
		Interpolation = Interpolation * 2;
		return Interpolation;
	}

	float GetSpeed() 
	{
		return Pig::StretchyLegs::Dizzy::StarSpeed * Math::Lerp(0.7, 1, GetUpDownInterpolation(1));
	}

	float GetHaloRadius() 
	{
		return Pig::StretchyLegs::Dizzy::HaloRadius * Math::Lerp(0.6, 1, GetUpDownInterpolation(5));
	}

	FVector GetStarScale() 
	{
		return FVector::OneVector * Math::Lerp(Pig::StretchyLegs::Dizzy::StarMinScale, Pig::StretchyLegs::Dizzy::StarMaxScale, GetUpDownInterpolation(1));
	}
}