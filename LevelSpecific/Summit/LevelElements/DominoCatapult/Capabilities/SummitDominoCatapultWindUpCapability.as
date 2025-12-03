struct FSummitDominoCatapultWindUpDeactivationParams
{
	bool bHitEnd = false;
}

class USummitDominoCatapultWindUpCapability : UHazeCapability
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
		if(Catapult.bWindUpHitEnd)
			return false;

		if(Catapult.bStatueIsHoldingCatapult)
			return false;

		if(Catapult.bIsFiring)
			return false;

		float TimeLastHitByWindUp = Time::GetGameTimeSince(Catapult.TimeLastHitByWindUpRoll);
		if(TimeLastHitByWindUp < Catapult.RollWindUpDuration)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate(FSummitDominoCatapultWindUpDeactivationParams& Params) const
	{
		float TimeLastHitByWindUp = Time::GetGameTimeSince(Catapult.TimeLastHitByWindUpRoll);
		if(TimeLastHitByWindUp >= Catapult.RollWindUpDuration)
		{
			Params.bHitEnd = false;
			return true;
		}

		if(Catapult.bStatueIsHoldingCatapult)
		{
			Params.bHitEnd = false;
			return true;
		}

		if(Catapult.bIsFiring)
		{
			Params.bHitEnd = false;
			return true;
		}

		if(Catapult.CurrentWindUpDegrees >= Catapult.MaxWindUpDegreesCurrently)
		{
			Params.bHitEnd = true;
			return true;
		}

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Catapult.bWindingUp = true;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FSummitDominoCatapultWindUpDeactivationParams Params)
	{
		Catapult.bWindUpHitEnd = Params.bHitEnd;

		float NewWindUpDegrees = Math::Clamp(Catapult.CurrentWindUpDegrees, 0, Catapult.MaxWindUpDegreesCurrently);
		Catapult.CurrentWindUpDegrees = NewWindUpDegrees;
		Catapult.WindUpRotateRoot.RelativeRotation = FRotator(0.0, 0.0, -Catapult.CurrentWindUpDegrees);
		Catapult.RotateCatapultBasedOnDegrees();
		Catapult.TimeLastStoppedWindingUp = Time::GameTimeSeconds;
		Catapult.TargetWindUpDegrees = Math::Clamp(Catapult.TargetWindUpDegrees, 0, Catapult.MaxWindUpDegrees);

		Catapult.bWindingUp = false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		float TimeLastHitByWindUp = Time::GetGameTimeSince(Catapult.TimeLastHitByWindUpRoll);
		float Alpha = TimeLastHitByWindUp / Catapult.RollWindUpDuration;
		float CurveAlpha = Catapult.WindUpRotationCurve.GetFloatValue(Alpha);

		float NewWindUpDegrees = Math::Lerp(Catapult.StartWindUpDegrees, Catapult.TargetWindUpDegrees, CurveAlpha);
		NewWindUpDegrees = Math::Clamp(NewWindUpDegrees, 0, Catapult.MaxWindUpDegreesCurrently);
		Catapult.CurrentWindUpDegrees = NewWindUpDegrees;
		Catapult.WindUpRotateRoot.RelativeRotation = FRotator(0.0, 0.0, -Catapult.CurrentWindUpDegrees);
		Catapult.RotateCatapultBasedOnDegrees();
	}
};