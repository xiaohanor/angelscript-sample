
class UDentistBossLeftArmSwatAwayPlayerCapability : UDentistBossArmSwatAwayPlayerCapability { default bLeftArm = true; }
class UDentistBossRightArmSwatAwayPlayerCapability : UDentistBossArmSwatAwayPlayerCapability { default bLeftArm = false; }

class UDentistBossArmSwatAwayPlayerCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::Gameplay;
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	ADentistBoss Dentist;

	TArray<AHazePlayerCharacter> PlayersWhoEnteredSwatZone;
	TPerPlayer<float> LastTimeSwatted;
	TPerPlayer<bool> HasBeenSwatted;
	TPerPlayer<bool> BeenInsideSwatTrigger;

	const float SwattingImpulseSize = 2000.0;
	const float SwattingCooldown = 0.7;
	const float SwattingDuration = 0.7;
	const float SwatDelay = 0.1;

	bool bLeftArm = false;

	UHazeMovablePlayerTriggerComponent SwatTrigger;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Dentist = TListedActors<ADentistBoss>().GetSingle();

		if(bLeftArm)
			SwatTrigger = Dentist.LeftHandSwattingPlayerTrigger;
		else
			SwatTrigger = Dentist.RightHandSwattingPlayerTrigger;

		SwatTrigger.OnPlayerEnter.AddUFunction(this, n"PlayerEnteredSwatTrigger");
		SwatTrigger.OnPlayerLeave.AddUFunction(this, n"PlayerLeftSwatTrigger");
	}

	UFUNCTION()
	private void PlayerEnteredSwatTrigger(AHazePlayerCharacter Player)
	{	
		if(Dentist.HasSwatAmnesty[Player])
			return;

		PlayersWhoEnteredSwatZone.Add(Player);
		if(IsActive())
		{
			BeenInsideSwatTrigger[Player] = true;
		}
	}

	UFUNCTION()
	private void PlayerLeftSwatTrigger(AHazePlayerCharacter Player)
	{
		if(PlayersWhoEnteredSwatZone.Contains(Player))
			PlayersWhoEnteredSwatZone.RemoveSingleSwap(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(Dentist.CurrentState == EDentistBossState::Defeated)
			return false;
		
		if(bLeftArm)
		{
			if(Dentist.bDenturesAttachedLeftHand)
				return false;
			if(Dentist.bLeftArmDestroyed)
				return false;
		}
		else
		{
			if(Dentist.bDenturesAttachedRightHand)
				return false;
			if(Dentist.bRightArmDestroyed)
				return false;
		}

		for(auto Player : PlayersWhoEnteredSwatZone)
		{
			if(Player.IsPlayerDead())
				continue;

			return true;
		}

		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(Dentist.CurrentState == EDentistBossState::Defeated)
			return true;

		if(bLeftArm)
		{
			if(Dentist.bDenturesAttachedLeftHand)
				return true;
			if(Dentist.bLeftArmDestroyed)
				return true;
		}
		else
		{
			if(Dentist.bDenturesAttachedRightHand)
				return true;
			if(Dentist.bRightArmDestroyed)
				return true;
		}

		if(ActiveDuration > SwattingDuration)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		if(bLeftArm)
			Dentist.bSwatLeftHand = true;
		else
			Dentist.bSwatRightHand = true;

		for(auto Player : Game::Players)
		{
			HasBeenSwatted[Player] = false;
			BeenInsideSwatTrigger[Player] = false;
		}

		for(auto Player : PlayersWhoEnteredSwatZone)
		{
			BeenInsideSwatTrigger[Player] = true;
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		if(bLeftArm)
			Dentist.bSwatLeftHand = false;
		else
			Dentist.bSwatRightHand = false;

		for(auto Player : Game::Players)
		{
			if(!BeenInsideSwatTrigger[Player])
				continue;

			if(HasBeenSwatted[Player])
				continue;

			SwatAwayPlayer(Player);
		}
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(ActiveDuration < SwatDelay)
			return;
		
		for(auto Player : Game::Players)
		{
			if(!BeenInsideSwatTrigger[Player])
				continue;

			if(Dentist.HasSwatAmnesty[Player])
				continue;

			float TimeSinceLastSwatted = Time::GetGameTimeSince(LastTimeSwatted[Player]);
			if(TimeSinceLastSwatted < SwattingCooldown)
				continue;

			if(HasBeenSwatted[Player])
				continue;

			SwatAwayPlayer(Player);

		}
	}

	void SwatAwayPlayer(AHazePlayerCharacter Player)
	{
		Player.ActorVelocity = FVector::ZeroVector;
			
		FVector DirToZone = (SwatTrigger.WorldLocation - Player.ActorLocation).ConstrainToPlane(FVector::UpVector).GetSafeNormal();
		FVector Impulse = -DirToZone * SwattingImpulseSize;
		Impulse += FVector::UpVector * 1000.0;

		auto ResponseComp = UDentistToothImpulseResponseComponent::Get(Player);

		FDentistToothApplyRagdollSettings RagdollSettings;
		ResponseComp.OnImpulseFromObstacle.Broadcast(Dentist, Impulse, RagdollSettings);

		LastTimeSwatted[Player] = Time::GameTimeSeconds;
		HasBeenSwatted[Player] = true;

		FDentistBossEffectHandlerOnPlayerSwatAwayParams Params;
		Params.Player = Player;
		UDentistBossEffectHandler::Trigger_OnPlayerSwatAway(Dentist, Params);
	}
};