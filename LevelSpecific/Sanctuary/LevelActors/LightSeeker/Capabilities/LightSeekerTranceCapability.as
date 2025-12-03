class ULightSeekerTranceCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(n"LightSeekerTrance");

	default TickGroup = EHazeTickGroup::Gameplay;

	ALightSeeker LightSeeker;
	ULightSeekerTargetingComponent TargetingComp;

	FQuat WiggleRight;
	FQuat WiggleLeft;
	float WiggleInterpolation = 1.0;
	float ToTheRight = 1.0;

	float ManualActivationTimer = 0.0;
	bool bManuallyActivated = false;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		LightSeeker = Cast<ALightSeeker>(Owner);
		TargetingComp = ULightSeekerTargetingComponent::Get(LightSeeker);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!TargetingComp.HasActiveLightBirdTarget())
			return false;

		FVector ToBird = TargetingComp.GetLightBirdLocation() - LightSeeker.Head.WorldLocation;
		if (ToBird.Size() > LightSeeker.DesiredOffset + LightSeeker.DesiredOffsetAcceptedRadius)
		 	return false;

		// if (ToBird.GetSafeNormal().DotProduct(LightSeeker.Head.ForwardVector) < 0.9)
		// 	return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!TargetingComp.HasActiveLightBirdTarget())
			return true;

		FVector ToBird = TargetingComp.GetLightBirdLocation() - LightSeeker.Head.WorldLocation;
		if (ToBird.Size() > LightSeeker.DesiredOffset + LightSeeker.DesiredOffsetAcceptedRadius)
		 	return true;

		// if (ToBird.GetSafeNormal().DotProduct(LightSeeker.Head.ForwardVector) < 0.9)
		// 	return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		ManualActivationTimer = 1.0;
		bManuallyActivated = false;
	}

	private void InternalActivate()
	{
		bManuallyActivated = true;
		LightSeeker.bIsInTrance = true;
		LightSeeker.BlockCapabilities(n"LightSeekerChase", this);
		LightSeeker.BlockCapabilities(n"LightSeekerReturn", this);

		const float WigglingAmount = LightSeeker.TranceRollWiggleAngle / 180.0;
		WiggleRight = FQuat::MakeFromXZ(LightSeeker.Head.ForwardVector, (LightSeeker.Head.UpVector + LightSeeker.Head.RightVector * WigglingAmount).GetSafeNormal());
		WiggleLeft = FQuat::MakeFromXZ(LightSeeker.Head.ForwardVector, (LightSeeker.Head.UpVector - LightSeeker.Head.RightVector * WigglingAmount).GetSafeNormal());
		WiggleInterpolation = 0.5;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		if (bManuallyActivated)
			InternalDeactivate();
	}

	private void InternalDeactivate()
	{
		LightSeeker.bIsInTrance = false;
		LightSeeker.UnblockCapabilities(n"LightSeekerChase", this);
		LightSeeker.UnblockCapabilities(n"LightSeekerReturn", this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (ActiveDuration < ManualActivationTimer)
			return;

		if (!bManuallyActivated)
			InternalActivate();

		if (LightSeeker.bDebugging)
			PrintToScreen("Trance", 0.0, FLinearColor::Green);

		if (HasControl())
		{
			TargetingComp.SyncedDesiredHeadLocation.SetValue(LightSeeker.Origin.WorldLocation);
			// TargetingComp.DesiredHeadLocation = LightSeeker.Origin.WorldLocation + TargetingComp.GetOriginToBirdWithOffset();
			FVector BirdLocation = TargetingComp.GetLightBirdLocation();
			FVector HeadToTarget = BirdLocation - LightSeeker.Head.WorldLocation;
			// TargetingComp.DesiredHeadRotation = FQuat::MakeFromXZ(HeadToTarget.GetSafeNormal(), LightSeeker.Origin.UpVector);
			TargetingComp.SyncedDesiredHeadRotation.SetValue(FRotator::MakeFromXZ(HeadToTarget.GetSafeNormal(), LightSeeker.Origin.UpVector));
			//WiggleRollRotation(DeltaTime);
		}
	}

	private void WiggleRollRotation(float DeltaTime)
	{
		WiggleInterpolation = WiggleInterpolation + LightSeeker.TranceWigglingPerSecond * DeltaTime * ToTheRight;
		if (WiggleInterpolation >= 1.0 || WiggleInterpolation <= 0.0)
			ToTheRight *= -1.0;

		WiggleInterpolation = Math::Clamp(WiggleInterpolation, 0.0, 1.0);
		FQuat Interpolated = FQuat::Slerp(WiggleLeft, WiggleRight, Math::EaseInOut(0, 1, WiggleInterpolation, 2));
		TargetingComp.SyncedDesiredHeadRotation.SetValue(Interpolated.Rotator());
		if (LightSeeker.bDebugging)
			Debug::DrawDebugLine(LightSeeker.Head.WorldLocation, LightSeeker.Head.WorldLocation + LightSeeker.Head.ForwardVector * 300.0, FLinearColor::Yellow, 10.0, 0.0);
	}
};