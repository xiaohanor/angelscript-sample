class UBattlefieldHoverboardLevelRubberbandingCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::Gameplay;

	UBattlefieldHoverboardLevelRubberbandingComponent LevelRubberbandingComp;

	FHazeAcceleratedFloat AccRubberbandingSpeed;

	UBattlefieldHoverboardLevelRubberbandingSettings Settings;

	const float RubberbandingSpeedAccelerationDuration = 0.5;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		LevelRubberbandingComp = UBattlefieldHoverboardLevelRubberbandingComponent::GetOrCreate(Player);
		Settings = UBattlefieldHoverboardLevelRubberbandingSettings::GetSettings(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(LevelRubberbandingComp.LevelRubberBandSplineComp == nullptr)
			return false;

		if(!LevelRubberbandingComp.LevelRubberBandSplineComp.bShouldRubberband)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(LevelRubberbandingComp.LevelRubberBandSplineComp == nullptr)
			return true;

		if(!LevelRubberbandingComp.LevelRubberBandSplineComp.bShouldRubberband)
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
		UHazeSplineComponent SplineComp = LevelRubberbandingComp.LevelRubberBandSplineComp.SplineComp;
		LevelRubberbandingComp.SplinePos = SplineComp.GetClosestSplinePositionToWorldLocation(Player.ActorLocation);
		FSplinePosition OtherPlayerSplinePos = SplineComp.GetClosestSplinePositionToWorldLocation(Player.OtherPlayer.ActorLocation);

		float SpeedTarget = 0.0;
		if(!Player.IsPlayerDead()
		&& !Player.OtherPlayer.IsPlayerDead())
		{
			bool bWantsToBeAhead = Settings.PreferredAheadPlayer == Player.Player;

			float PreferredDistance;
			if(bWantsToBeAhead)
				PreferredDistance = OtherPlayerSplinePos.CurrentSplineDistance + Settings.PreferredAheadDistance * 0.5;
			else
				PreferredDistance = OtherPlayerSplinePos.CurrentSplineDistance - Settings.PreferredAheadDistance * 0.5;

			float DeltaToPreferredDistance = PreferredDistance - LevelRubberbandingComp.SplinePos.CurrentSplineDistance;
			float MaxSpeedFraction = DeltaToPreferredDistance / Settings.DeltaSplineDistanceAtWhichMaxSpeed;
			MaxSpeedFraction = Math::Clamp(MaxSpeedFraction, -Settings.SpeedLossMultiplier, Settings.SpeedGainMultiplier);
			SpeedTarget = MaxSpeedFraction * Settings.MaxRubberbandingSpeed;
		}

		AccRubberbandingSpeed.AccelerateTo(SpeedTarget, RubberbandingSpeedAccelerationDuration, DeltaTime);
		
		float PlayerAlignmentToSpline = Player.ActorForwardVector.DotProduct(LevelRubberbandingComp.SplinePos.WorldForwardVector);
		PlayerAlignmentToSpline = Math::Clamp(PlayerAlignmentToSpline, 0, 1);
		float RubberbandingSpeed = AccRubberbandingSpeed.Value * PlayerAlignmentToSpline;

		LevelRubberbandingComp.RubberbandingSpeed = RubberbandingSpeed;
		TEMPORAL_LOG(LevelRubberbandingComp)
			.Value("Rubberbanding Speed", RubberbandingSpeed)
			.Value("Alignment To Spline", PlayerAlignmentToSpline)
			.Value("Acc Rubberbanding Speed", AccRubberbandingSpeed.Value)
			.Sphere("Spline Pos", LevelRubberbandingComp.SplinePos.WorldLocation, 100, FLinearColor::White)
			.Sphere("Other Player Spline Pos", OtherPlayerSplinePos.WorldLocation, 100, FLinearColor::Black)
		;
	}
};