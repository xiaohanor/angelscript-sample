
UCLASS(Abstract)
class UWorld_Tundra_Swamp_Platform_QuicksandPoleClimb_SoundDef : USoundDefBase
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	/* END OF AUTO-GENERATED CODE */

	FVector BaseActorLocation;

	TPerPlayer<bool> PlayersOnPole;

	private bool bDelayedActivationDone = false;

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!IsAnyPlayerClimbing())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(!bDelayedActivationDone)
			return false;

		if(!Math::IsNearlyZero(GetSinkingDistanceNormalized(), 0.1))
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		bDelayedActivationDone = false;
		Timer::SetTimer(this, n"TriggerDelayedActivation", 0.25);
	}

	UFUNCTION(BlueprintEvent)
	void OnPlayerEnter(AHazePlayerCharacter Player) {}

	UFUNCTION(BlueprintEvent)
	void OnPlayerExit(AHazePlayerCharacter Player) {}

	UFUNCTION(BlueprintOverride)
	void ParentSetup()
	{
		APoleClimbActor PoleClimb = Cast<APoleClimbActor>(HazeOwner);
		PoleClimb.OnStartPoleClimb.AddUFunction(this, n"OnPlayerStartClimbingInternal");
		PoleClimb.OnStopPoleClimb.AddUFunction(this, n"OnPlayerStopClimbingInternal");

		PoleClimb.PerchPointComp.OnPlayerStartedPerchingEvent.AddUFunction(this, n"OnPlayerStartPerchingInternal");
		PoleClimb.PerchPointComp.OnPlayerStoppedPerchingEvent.AddUFunction(this, n"OnPlayerStopPerchingInternal");
	}

	UFUNCTION(BlueprintPure)
	float GetSinkingDistanceNormalized() const
	{
		const float AbsDist = Math::Abs((BaseActorLocation.Z - HazeOwner.GetActorLocation().Z));
		const float NormalizedDistance = Math::GetMappedRangeValueClamped(FVector2D(2500.0, 1250.0), FVector2D(0.0, 1.0), AbsDist);
		return NormalizedDistance;
	}

	UFUNCTION(NotBlueprintCallable)
	void OnPlayerStartPerchingInternal(AHazePlayerCharacter Player, UPerchPointComponent PerchPointComp)
	{
		PlayersOnPole[Player] = true;
	}

	UFUNCTION(NotBlueprintCallable)
	void OnPlayerStopPerchingInternal(AHazePlayerCharacter Player, UPerchPointComponent PerchPointComp)
	{
		OnPlayerExit(Player);
		PlayersOnPole[Player] = false;
	}

	UFUNCTION(NotBlueprintCallable)
	void OnPlayerStartClimbingInternal(AHazePlayerCharacter Player, APoleClimbActor PoleClimb)
	{
		OnPlayerEnter(Player);
		PlayersOnPole[Player] = true;
	}

	UFUNCTION(NotBlueprintCallable)
	void OnPlayerStopClimbingInternal(AHazePlayerCharacter Player, APoleClimbActor PoleClimb)
	{
		PlayersOnPole[Player] = false;
		OnPlayerExit(Player);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaSeconds)
	{
		UpdateClimbingPlayers();
	}

	private void UpdateClimbingPlayers()
	{
		if(IsBothPlayersClimbing())
			DefaultEmitter.SetRTPC(Audio::Rtpc_SpeakerPanning_LR, 0.0, 1000);
		else
		{
			for(AHazePlayerCharacter Player : Game::GetPlayers())
			{
				if(!PlayersOnPole[Player])
					continue;

				DefaultEmitter.SetPlayerPanning(Player);
			}
		}

		const float SpatializationMixRtpcValue = IsAnyPlayerClimbing() ? 0.0 : 1.0;
		DefaultEmitter.SetRTPC(Audio::Rtpc_Spatialization_SpeakerPanning_Mix, SpatializationMixRtpcValue, 500);
	}

	private bool IsAnyPlayerClimbing() const
	{
		for(auto PlayerClimbing : PlayersOnPole)
		{
			if(PlayerClimbing)
				return true;
		}

		return false;
	}

	private bool IsBothPlayersClimbing() const
	{
		for(auto PlayerClimbing : PlayersOnPole)
		{
			if(!PlayerClimbing)
				return false;
		}

		return true;
	}

	UFUNCTION(NotBlueprintCallable)
	void TriggerDelayedActivation()
	{
		bDelayedActivationDone = true;
	}

}