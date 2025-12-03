namespace KiteFlight
{
	const float MinSpeed = 2000.0;
	const float MaxSpeed = 4500.0;
	const float StrafeSpeed = 1800.0;
	const float TurnSpeed = 60.0;
	const float MaxPitch = 80.0;

	const float InitialBoost = 2500.0;
	const float BoostDecayRate = 700.0;
	const float BoostDecayDelay = 1.4;

	const int CompanionsAtMinSpeed = 1;
	const int CompanionsAtMaxSpeed = 12;
	const float CompanionMinSwirlRadius = 200.0;
	const float CompanionMaxSwirlRadius = 450.0;
	const float CompanionMinSwirlSpeed = 40.0;
	const float CompanionMaxSwirlSpeed = 180.0;

	const float RubberBandingMinDistance = 15000.0;
	const float RubberBandingMaxDistance = 40000.0;
	const float RubberBandingMaxSpeedMultiplier = 1.35;
	const float RubberBandingMaxDecayRateMultiplier = 1.75;
	const float RubberBandingMinDecayDelay = 0.7;

	float GetMaxSpeedWithRubberbanding(AHazePlayerCharacter Player)
	{
		if (!KiteTown::GetRubberBandingManager().IsPlayerLosing(Player))
			return MaxSpeed;

		float DistDif = KiteTown::GetRubberBandingManager().GetDistanceDifference();
		return Math::GetMappedRangeValueClamped(FVector2D(RubberBandingMinDistance, RubberBandingMaxDistance), FVector2D(MaxSpeed, MaxSpeed * RubberBandingMaxSpeedMultiplier), DistDif);
	}

	float GetCurrentMaxSpeedMultiplier(AHazePlayerCharacter Player)
	{
		if (!KiteTown::GetRubberBandingManager().IsPlayerLosing(Player))
			return 1.0;

		float DistDif = KiteTown::GetRubberBandingManager().GetDistanceDifference();
		return Math::GetMappedRangeValueClamped(FVector2D(RubberBandingMinDistance, RubberBandingMaxDistance), FVector2D(1.0, RubberBandingMaxSpeedMultiplier), DistDif);
	}

	float GetRubberBandingDecayRate(AHazePlayerCharacter Player)
	{
		if (!KiteTown::GetRubberBandingManager().IsPlayerLosing(Player))
			return 1.0;

		float DistDif = KiteTown::GetRubberBandingManager().GetDistanceDifference();
		return Math::GetMappedRangeValueClamped(FVector2D(RubberBandingMinDistance, RubberBandingMaxDistance), FVector2D(1.0, RubberBandingMaxDecayRateMultiplier), DistDif);
	}

	float GetRubberBandingDecayDelay(AHazePlayerCharacter Player)
	{
		if (!KiteTown::GetRubberBandingManager().IsPlayerLosing(Player))
			return 1.0;

		float DistDif = KiteTown::GetRubberBandingManager().GetDistanceDifference();
		return Math::GetMappedRangeValueClamped(FVector2D(RubberBandingMinDistance, RubberBandingMaxDistance), FVector2D(BoostDecayDelay, RubberBandingMinDecayDelay), DistDif);
	}
}