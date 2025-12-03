class UBattlefieldHoverboardSameGrindRubberbandingCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default DebugCategory = n"Hoverboard";

	default TickGroup = EHazeTickGroup::Gameplay;

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	UBattlefieldHoverboardGrindingComponent GrindComp;
	UBattlefieldHoverboardGrindingComponent OtherGrindComp;

	UBattlefieldHoverboardGrindingSettings GrindSettings;
	UBattlefieldHoverboardLevelRubberbandingSettings RubberbandingSettings;

	const float RubberbandingAccelerationDuration = 2.0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		GrindComp = UBattlefieldHoverboardGrindingComponent::Get(Player);
		OtherGrindComp = UBattlefieldHoverboardGrindingComponent::Get(Player.OtherPlayer);

		GrindSettings = UBattlefieldHoverboardGrindingSettings::GetSettings(Player);
		RubberbandingSettings = UBattlefieldHoverboardLevelRubberbandingSettings::GetSettings(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!GrindComp.IsGrinding())
			return false;

		if(OtherGrindComp == nullptr
		|| !OtherGrindComp.IsGrinding())
			return false;

		auto PlayerGrind = GrindComp.CurrentGrindSplineComp;

		// Both players are not on the same grind
		if(!(PlayerGrind.PlayerIsOnGrind(Player.OtherPlayer) && PlayerGrind.PlayerIsOnGrind(Player.OtherPlayer)))
			return false;

		if(GrindComp.CurrentSplinePos.IsForwardOnSpline() != OtherGrindComp.CurrentSplinePos.IsForwardOnSpline())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(!GrindComp.IsGrinding())
			return true;

		if(OtherGrindComp == nullptr
		|| !OtherGrindComp.IsGrinding())
			return true;

		auto PlayerGrind = GrindComp.CurrentGrindSplineComp;

		// Both players are not on the same grind
		if(!(PlayerGrind.PlayerIsOnGrind(Player.OtherPlayer) && PlayerGrind.PlayerIsOnGrind(Player.OtherPlayer)))
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
	void PreTick(float DeltaTime)
	{
		if(OtherGrindComp == nullptr)
			OtherGrindComp = UBattlefieldHoverboardGrindingComponent::Get(Player.OtherPlayer);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FSplinePosition PlayerSplinePos = GrindComp.CurrentSplinePos;
		FSplinePosition OtherPlayerSplinePos = OtherGrindComp.CurrentSplinePos;

		bool bWantsToBeAhead = RubberbandingSettings.PreferredAheadPlayer == Player.Player;

		float PreferredDistance;
		float PreferredAheadDistance = RubberbandingSettings.PreferredAheadDistance * 0.5;
		if(!PlayerSplinePos.IsForwardOnSpline())
			PreferredAheadDistance *= -1;

		if(bWantsToBeAhead)
			PreferredDistance = OtherPlayerSplinePos.CurrentSplineDistance + PreferredAheadDistance;
		else
			PreferredDistance = OtherPlayerSplinePos.CurrentSplineDistance - PreferredAheadDistance;

		float DeltaToPreferedDistance = PreferredDistance - PlayerSplinePos.CurrentSplineDistance;
		if(!PlayerSplinePos.IsForwardOnSpline())
			DeltaToPreferedDistance = PlayerSplinePos.CurrentSplineDistance - PreferredDistance;
		float MaxSpeedFraction = DeltaToPreferedDistance / RubberbandingSettings.DeltaSplineDistanceAtWhichMaxSpeed;
		MaxSpeedFraction = Math::Clamp(MaxSpeedFraction, -RubberbandingSettings.SpeedLossMultiplier, RubberbandingSettings.SpeedGainMultiplier);
		float SpeedTarget = MaxSpeedFraction * RubberbandingSettings.MaxRubberbandingSpeed;

		GrindComp.AccGrindRubberbandingSpeed.AccelerateTo(SpeedTarget, RubberbandingAccelerationDuration, DeltaTime);
	}
};