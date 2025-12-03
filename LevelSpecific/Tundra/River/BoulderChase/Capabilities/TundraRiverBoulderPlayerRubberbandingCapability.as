class UTundraRiverBoulderPlayerRubberbandingCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	default TickGroup = EHazeTickGroup::AfterGameplay;
	
	ATundraRiverBoulder Boulder;

	AHazePlayerCharacter Mio;
	AHazePlayerCharacter Zoe;

	UPlayerFloorMotionSettings MioFloorMotionSettings;
	UPlayerAirMotionSettings MioAirMotionSettings;

	UPlayerFloorMotionSettings ZoeFloorMotionSettings;
	UPlayerAirMotionSettings ZoeAirMotionSettings;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Boulder = Cast<ATundraRiverBoulder>(Owner);
		Mio = Game::Mio;
		Zoe = Game::Zoe;

		MioFloorMotionSettings = UPlayerFloorMotionSettings::GetSettings(Mio);
		MioAirMotionSettings = UPlayerAirMotionSettings::GetSettings(Mio);

		ZoeFloorMotionSettings = UPlayerFloorMotionSettings::GetSettings(Zoe);
		ZoeAirMotionSettings = UPlayerAirMotionSettings::GetSettings(Zoe);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!Boulder.bIsActive)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(!Boulder.bIsActive)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Mio.ClearSettingsByInstigator(this);
		Zoe.ClearSettingsByInstigator(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		Mio.ClearSettingsByInstigator(this);
		Zoe.ClearSettingsByInstigator(this);

		const float MioMultiplier = GetMultiplierForPlayer(Mio);
		const float ZoeMultiplier = GetMultiplierForPlayer(Zoe);

		if(MioMultiplier > 1.0)
		{
			PrintToScreen(f"{MioMultiplier=}");
			FloorMotion(Mio, MioMultiplier, MioFloorMotionSettings);
			AirMotion(Mio, MioMultiplier, MioAirMotionSettings);
		}

		if(ZoeMultiplier > 1.0)
		{
			PrintToScreen(f"{ZoeMultiplier=}");
			FloorMotion(Zoe, ZoeMultiplier, ZoeFloorMotionSettings);
			AirMotion(Zoe, ZoeMultiplier, ZoeAirMotionSettings);
		}
	}

	void FloorMotion(AHazePlayerCharacter Player, float PlayerMultiplier, UPlayerFloorMotionSettings FloorMotionSettings)
	{
		UPlayerFloorMotionSettings::SetMaximumSpeed(Player, FloorMotionSettings.MaximumSpeed * PlayerMultiplier, this);
		UPlayerFloorMotionSettings::SetMaximumSpeedAfterPeriod(Player, FloorMotionSettings.MaximumSpeedAfterPeriod * PlayerMultiplier, this);
		UPlayerFloorMotionSettings::SetMinimumSpeed(Player, FloorMotionSettings.MinimumSpeed * PlayerMultiplier, this);
		UPlayerFloorMotionSettings::SetAcceleration(Player, FloorMotionSettings.Acceleration * PlayerMultiplier, this);
		UPlayerFloorMotionSettings::SetDeceleration(Player, FloorMotionSettings.Deceleration * PlayerMultiplier, this);
		UPlayerFloorMotionSettings::SetFallOfEdgeMinSpeed(Player, FloorMotionSettings.FallOfEdgeMinSpeed * PlayerMultiplier, this);
	}

	void AirMotion(AHazePlayerCharacter Player, float PlayerMultiplier, UPlayerAirMotionSettings AirMotionSettings)
	{
		UPlayerAirMotionSettings::SetHorizontalMoveSpeed(Player, AirMotionSettings.HorizontalMoveSpeed * PlayerMultiplier, this);
		UPlayerAirMotionSettings::SetMaximumHorizontalMoveSpeedBeforeDrag(Player, AirMotionSettings.MaximumHorizontalMoveSpeedBeforeDrag * PlayerMultiplier, this);
		UPlayerAirMotionSettings::SetHorizontalVelocityInterpSpeed(Player, AirMotionSettings.HorizontalVelocityInterpSpeed * PlayerMultiplier, this);
	}

	float GetMultiplierForPlayer(AHazePlayerCharacter Player)
	{
		const float DotToCurrent = Boulder.ActorForwardVector.DotProduct(Player.ActorLocation - Boulder.ActorLocation);
		const float DotToOther = Boulder.ActorForwardVector.DotProduct(Player.OtherPlayer.ActorLocation - Boulder.ActorLocation);

		// This player is ahead of the other player so their multiplier is 1
		if(DotToCurrent > DotToOther)
			return 1.0;

		const float Delta = DotToOther - DotToCurrent;
		float Time = Delta / Boulder.PlayerRubberbandingMaxDistance;
		Time = Math::Clamp(Time, 0.0, 1.0);

		float CurveValue = Boulder.PlayerRubberbandingCurve.GetFloatValue(Time);
		CurveValue = Math::Clamp(CurveValue, 0.0, 1.0);

		return Math::Lerp(1.0, Boulder.PlayerRubberbandingMaxMultiplier, CurveValue);
	}
}