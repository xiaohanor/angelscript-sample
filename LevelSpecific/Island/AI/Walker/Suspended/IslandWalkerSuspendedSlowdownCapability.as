class UIslandWalkerSuspendedSlowdownCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	UIslandWalkerPhaseComponent PhaseComp;
	UIslandWalkerComponent WalkerComp;
	UIslandWalkerNeckRoot NeckRoot;
	UIslandWalkerSettings Settings;

	TPerPlayer<float> SlowdownStartTimes;
	TPerPlayer<float> HandledLaunchTimes;
	TPerPlayer<UIslandOverloadJumpPadPlayerComponent> JumpPadComps;
	TPerPlayer<UGentlemanComponent> GentlemanComps;
	TPerPlayer<UIslandWalkerPlayerSlowdownComponent> SlowdownComps;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		PhaseComp = UIslandWalkerPhaseComponent::GetOrCreate(Owner);
		WalkerComp = UIslandWalkerComponent::GetOrCreate(Owner);
		NeckRoot = UIslandWalkerNeckRoot::Get(Owner);
		Settings = UIslandWalkerSettings::GetSettings(Owner); 
		for (AHazePlayerCharacter Player : Game::Players)
		{
			JumpPadComps[Player] = UIslandOverloadJumpPadPlayerComponent::GetOrCreate(Player);
			GentlemanComps[Player] = UGentlemanComponent::GetOrCreate(Player);
			HandledLaunchTimes[Player] = 0.0;	
			SlowdownComps[Player] = UIslandWalkerPlayerSlowdownComponent::GetOrCreate(Player);				
		}
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(PhaseComp.Phase != EIslandWalkerPhase::Suspended)
			return false;
		if(!WalkerComp.bSuspended)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(PhaseComp.Phase != EIslandWalkerPhase::Suspended)
			return true;
		if(!WalkerComp.bSuspended)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		for(AHazePlayerCharacter Player: Game::Players)
		{
			SlowdownStartTimes[Player] = BIG_NUMBER;

			// Require a new launch until this can be triggered. 
			// Note that if this behaviour is e.g. blocked and unblocked while player is in air the slowdown will not occur.
			HandledLaunchTimes[Player] = JumpPadComps[Player].LastLaunchedTime; 
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		for(AHazePlayerCharacter Player: Game::Players)
		{
			SlowdownComps[Player].SpeedFactor = 1.0;
			HandledLaunchTimes[Player] = JumpPadComps[Player].LastLaunchedTime;
			GentlemanComps[Player].ClearInvalidTarget(this);
		}
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		for(AHazePlayerCharacter Player : Game::Players)
		{
			if (JumpPadComps[Player].LastLaunchedTime < HandledLaunchTimes[Player] + 1.01)
			{
				// No new slowdown can be started until we've been launched again
				continue;
			}

			if (ActiveDuration < SlowdownStartTimes[Player])
			{
				// Haven't started slowdown yet, check if it's time
				if (ShouldStartSlowdown(Player))
					SlowdownStartTimes[Player] = ActiveDuration;	
				continue;
			}

			float SlowdownDuration = ActiveDuration - SlowdownStartTimes[Player];
			if (SlowdownDuration > Settings.SlowdownEnterTime + Settings.SlowdownHoldTime + Settings.SlowdownExitTime)
			{
				// Slowdown is over
				SlowdownComps[Player].SpeedFactor = 1.0;
				SlowdownStartTimes[Player] = BIG_NUMBER;
				HandledLaunchTimes[Player] = JumpPadComps[Player].LastLaunchedTime;
				GentlemanComps[Player].ClearInvalidTarget(this);
				continue;
			}

			// Slow down!
			float DilationAlpha = 1.0;
			if (SlowdownDuration < Settings.SlowdownEnterTime)
				DilationAlpha = Math::EaseOut(0.0, 1.0, SlowdownDuration / Settings.SlowdownEnterTime, 2.0);
			else if (SlowdownDuration > Settings.SlowdownEnterTime + Settings.SlowdownHoldTime)
				DilationAlpha = Math::EaseIn(1.0, 0.0, (SlowdownDuration - Settings.SlowdownEnterTime - Settings.SlowdownHoldTime) / Settings.SlowdownExitTime, 1.5);
			DilationAlpha = Math::Clamp(DilationAlpha, 0.0, 1.0);		
			SlowdownComps[Player].SpeedFactor = 1.0 - Settings.SlowdownMaxDilation * DilationAlpha;

			// Do not attack player while time dilated
			if (DilationAlpha > 0.2)
				GentlemanComps[Player].SetInvalidTarget(this);
		}
	}

	bool ShouldStartSlowdown(AHazePlayerCharacter Player)
	{
		if (Player.ActorLocation.Z < Owner.ActorLocation.Z + Settings.SlowdownHeightStart)
			return false; // Too low
		if (Math::Abs(Owner.ActorRightVector.DotProduct(Owner.ActorLocation - Player.ActorLocation)) > Settings.SlowdownLateralDistanceStart)
			return false; // Too far away to the left/right
		return true;
	}
}