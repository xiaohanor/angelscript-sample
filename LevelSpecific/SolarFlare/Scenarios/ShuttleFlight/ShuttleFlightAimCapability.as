class UShuttleFlightAimCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(n"ShuttleFlightShootCapability");
	
	default TickGroup = EHazeTickGroup::Gameplay;
	default TickGroupOrder = 100;

	ASolarFlareShuttle Shuttle;
	float YawClamp = 2.0;
	float CurrentYaw;
	float CurrentPitch;

	float MaxPitchAmount = 20.0;
	float MinPitchAmount = -20.0;
	float MaxPitch;
	float MinPitch;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Shuttle = TListedActors<ASolarFlareShuttle>().GetSingle();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		CurrentYaw = Shuttle.YawRoot.RelativeRotation.Yaw;
		CurrentPitch = Shuttle.YawRoot.RelativeRotation.Pitch;
		MaxPitch = CurrentPitch + MaxPitchAmount;
		MinPitch = CurrentPitch + MinPitchAmount;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FVector2D Input = GetAttributeVector2D(AttributeVectorNames::MovementRaw);
		CurrentYaw += Input.Y * 85.0 * DeltaTime;
		CurrentPitch += Input.X * 125.0 * DeltaTime;
		CurrentYaw = Math::Clamp(CurrentYaw, -YawClamp, YawClamp);
		CurrentPitch = Math::Clamp(CurrentPitch, MinPitch, MaxPitch);
		FRotator TargetYawRot = FRotator(0.0, CurrentYaw, 0.0);
		FRotator TargetPitchRot = FRotator(CurrentPitch, 0.0, 0.0);
		FRotator CurrentYawRot = Shuttle.YawRoot.RelativeRotation;
		FRotator CurrentPitchRot = Shuttle.PitchRoot.RelativeRotation;
		Shuttle.YawRoot.RelativeRotation = Math::RInterpTo(CurrentYawRot, TargetYawRot, DeltaTime, 5.0);
		Shuttle.PitchRoot.RelativeRotation = Math::RInterpTo(CurrentPitchRot, TargetPitchRot, DeltaTime, 5.0);

		Debug::DrawDebugLine(Shuttle.PitchRoot.WorldLocation, Shuttle.PitchRoot.WorldLocation + Shuttle.PitchRoot.WorldRotation.Vector() * 15000.0, FLinearColor::Red, 95.0);
	}
}