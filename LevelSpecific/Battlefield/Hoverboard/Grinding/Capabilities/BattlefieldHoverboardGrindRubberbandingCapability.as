struct FBattlefieldHoverboardGrindRubberbandingActivationParams
{
	UBattlefieldHoverboardGrindSplineComponent ActivationGrindSplineComp;
	UBattlefieldHoverboardGrindSplineComponent LinkedGrindSplineComp;
}

class UBattlefieldHoverboardGrindRubberbandingCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default DebugCategory = BattlefieldHoverboardDebugCategory::Hoverboard;

	default TickGroup = EHazeTickGroup::Gameplay;

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	UBattlefieldHoverboardGrindingComponent GrindComp;
	UBattlefieldHoverboardGrindingComponent OtherGrindComp;

	UBattlefieldHoverboardGrindingSettings GrindSettings;

	UBattlefieldHoverboardGrindSplineComponent GrindCurrentlyOn;
	UBattlefieldHoverboardGrindSplineComponent LinkedGrindSplineComp;

	const float RubberbandingAccelerationDuration = 2.0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		GrindComp = UBattlefieldHoverboardGrindingComponent::Get(Player);

		GrindSettings = UBattlefieldHoverboardGrindingSettings::GetSettings(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FBattlefieldHoverboardGrindRubberbandingActivationParams& Params) const
	{
		if(!GrindComp.IsGrinding())
			return false;

		if(OtherGrindComp == nullptr)
			return false;

		if(!OtherGrindComp.IsGrinding())
			return false;

		auto PlayerGrind = GrindComp.CurrentGrindSplineComp;

		if(!PlayerGrind.bRubberbanding)
			return false;

		auto LinkedGrind = PlayerGrind.LinkedRubberbandSplineComp;

		if(LinkedGrind == nullptr)
			return false;
		
		if(!LinkedGrind.PlayerIsOnGrind(Player.OtherPlayer))
			return false;

		FSplinePosition PlayerSplinePos = GrindComp.CurrentSplinePos;
		FSplinePosition OtherPlayerSplinePos = OtherGrindComp.CurrentSplinePos;

		float ForwardDotForward = PlayerSplinePos.WorldForwardVector.DotProduct(OtherPlayerSplinePos.WorldForwardVector);

		// Splines are going in opposite direction
		if(ForwardDotForward < 0)
		 	return false;

		Params.ActivationGrindSplineComp = PlayerGrind;
		Params.LinkedGrindSplineComp = LinkedGrind;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(!GrindComp.IsGrinding())
			return true;

		if(OtherGrindComp == nullptr)
			return true;

		if(!OtherGrindComp.IsGrinding())
			return true;

		auto PlayerGrind = GrindComp.CurrentGrindSplineComp;

		if(!PlayerGrind.bRubberbanding)
			return true;

		auto LinkedGrind = PlayerGrind.LinkedRubberbandSplineComp;

		if(LinkedGrind == nullptr)
			return true;
		
		if(!LinkedGrind.PlayerIsOnGrind(Player.OtherPlayer))
			return true;

		FSplinePosition PlayerSplinePos = GrindComp.CurrentSplinePos;
		FSplinePosition OtherPlayerSplinePos = OtherGrindComp.CurrentSplinePos;

		float ForwardDotForward = PlayerSplinePos.WorldForwardVector.DotProduct(OtherPlayerSplinePos.WorldForwardVector);

		// Splines are going in opposite direction
		if(ForwardDotForward < 0)
		 	return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FBattlefieldHoverboardGrindRubberbandingActivationParams Params)
	{
		GrindCurrentlyOn = Params.ActivationGrindSplineComp;
		LinkedGrindSplineComp = Params.LinkedGrindSplineComp;

		GrindComp.bIsRubberbanding = true;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		GrindComp.bIsRubberbanding = false;
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

		float GrindLength = GrindCurrentlyOn.SplineComp.SplineLength;
		float CurrentSplineDistance;
		/* Have to check if it's forward because distance doesn't 
		care about which direction the spline position is facing*/
		if(PlayerSplinePos.IsForwardOnSpline())
			CurrentSplineDistance = GrindComp.CurrentSplinePos.CurrentSplineDistance;
		else
			CurrentSplineDistance = GrindLength - GrindComp.CurrentSplinePos.CurrentSplineDistance;
		float PlayerGrindAlpha =  CurrentSplineDistance / GrindLength;

		float LinkedGrindLength = LinkedGrindSplineComp.SplineComp.SplineLength;
		float OtherPlayerCurrentSplineDistance;
		/* Have to check if it's forward because distance doesn't 
		care about which direction the spline position is facing*/
		if(OtherPlayerSplinePos.IsForwardOnSpline())
			OtherPlayerCurrentSplineDistance = OtherGrindComp.CurrentSplinePos.CurrentSplineDistance;
		else
			OtherPlayerCurrentSplineDistance = LinkedGrindLength - OtherGrindComp.CurrentSplinePos.CurrentSplineDistance;

		float OtherPlayerGrindAlpha =  OtherPlayerCurrentSplineDistance / LinkedGrindLength;

		float DeltaAlpha = OtherPlayerGrindAlpha - PlayerGrindAlpha;

		float PercentOfMaxDeltaAlpha = Math::Abs(DeltaAlpha) / GrindCurrentlyOn.DeltaAlphaMaxRubberbandingThreshold;

		float RubberbandingSpeedTarget = Math::Sign(DeltaAlpha) * PercentOfMaxDeltaAlpha * GrindCurrentlyOn.MaxRubberbandingSpeed;
		RubberbandingSpeedTarget = Math::Clamp(RubberbandingSpeedTarget, -GrindCurrentlyOn.MaxRubberbandingSpeed, GrindCurrentlyOn.MaxRubberbandingSpeed);
		
		GrindComp.AccGrindRubberbandingSpeed.AccelerateTo(RubberbandingSpeedTarget, RubberbandingAccelerationDuration, DeltaTime);

		TEMPORAL_LOG(GrindComp)
		.Value("Rubberbanding Speed", GrindComp.AccGrindRubberbandingSpeed.Value)
		.Value("Grind Length", GrindLength)
		.Value("Current Spline Distance", CurrentSplineDistance)
		.Value("Player Grind Alpha", PlayerGrindAlpha)
		.Value("Linked Grind Length", LinkedGrindLength)
		.Value("Other Player Current Spline Distance", OtherPlayerCurrentSplineDistance)
		.Value("Other PlayerGrind Alpha", OtherPlayerGrindAlpha)
		.Value("Delta Alpha", DeltaAlpha)
		.Value("Rubberbanding Speed Target", RubberbandingSpeedTarget)
		.Value("Percent of Max Delta Alpha", PercentOfMaxDeltaAlpha)
		;
	}
};