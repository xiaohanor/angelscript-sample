class USummitDominoCatapultWindDownCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::Gameplay;

	ASummitDominoCatapult Catapult;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Catapult = Cast<ASummitDominoCatapult>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(Catapult.bWindingUp)
			return false;

		float TimeLastStoppedWindingUp = Time::GetGameTimeSince(Catapult.TimeLastStoppedWindingUp);
		if(TimeLastStoppedWindingUp < Catapult.WindUpDelayBeforeGoingBack)
			return false;

		if(Catapult.CurrentWindUpDegrees <= 0)
			return false;

		if(Catapult.bStatueIsHoldingCatapult)
			return false;

		if(Catapult.bIsFiring)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(Catapult.bWindingUp)
			return true;

		float TimeLastStoppedWindingUp = Time::GetGameTimeSince(Catapult.TimeLastStoppedWindingUp);
		if(TimeLastStoppedWindingUp < Catapult.WindUpDelayBeforeGoingBack)
			return true;

		if(Catapult.CurrentWindUpDegrees <= 0)
			return true;

		if(Catapult.bStatueIsHoldingCatapult)
			return true;

		if(Catapult.bIsFiring)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		float Alpha = ActiveDuration / Catapult.MaxWindUpRotateBackSpeedDelay;
		Alpha = Math::Clamp(Alpha, 0.0, 1.0);
		float CurveAlpha = Catapult.WindUpRotateBackAccelerationCurve.GetFloatValue(Alpha);
		float WindDownSpeed = Catapult.MaxWindUpRotateBackSpeed * CurveAlpha;

		float CurrentWindUpDegrees = Catapult.CurrentWindUpDegrees;
		if(((Catapult.TargetWindUpDegrees + 90) - CurrentWindUpDegrees) >= 180)
			Catapult.TargetWindUpDegrees -= 180.0;

		Catapult.CurrentWindUpDegrees = Math::FInterpConstantTo(Catapult.CurrentWindUpDegrees, 0.0, DeltaTime, WindDownSpeed);
		Catapult.WindUpRotateRoot.RelativeRotation = FRotator(0.0, 0.0, -Catapult.CurrentWindUpDegrees);
		Catapult.RotateCatapultBasedOnDegrees();
	}
};