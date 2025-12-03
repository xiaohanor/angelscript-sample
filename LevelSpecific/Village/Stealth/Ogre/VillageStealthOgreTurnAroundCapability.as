class UVillageStealthOgreTurnAroundCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::Gameplay;

	AVillageStealthOgre Ogre;
	AHazePlayerCharacter TargetPlayer;

	float TurnAroundDuration = 0.5;
	float TurnedAroundDuration = 2.0;
	float TurnBackDuration = 1.4;
	float CurrentTurnBackTime = 0.0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Ogre = Cast<AVillageStealthOgre>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{	
		if (Ogre.CurrentState != EVillageStealthOgreState::TurningAround)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (CurrentTurnBackTime >= TurnBackDuration)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		CurrentTurnBackTime = 0.0;
		Ogre.CurrentState = EVillageStealthOgreState::TurningAround;

		Ogre.OnHitByThrowable.Broadcast();

		UVillageStealthOgreEffectEventHandler::Trigger_TurnAround(Ogre);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Ogre.bTurnedAround = false;
		Ogre.CurrentState = EVillageStealthOgreState::Idle;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (ActiveDuration >= TurnAroundDuration && !Ogre.bTurnedAround)
		{
			Ogre.bTurnedAround = true;
			Ogre.CurrentState = EVillageStealthOgreState::Idle;
		}

		if (HasControl())
		{
			if (ActiveDuration >= TurnAroundDuration + TurnedAroundDuration)
			{
				if (Ogre.CurrentState != EVillageStealthOgreState::Throwing)
				{
					Crumb_TurnBack();
					CurrentTurnBackTime += DeltaTime;
				}
			}
		}
	}

	UFUNCTION(CrumbFunction)
	void Crumb_TurnBack()
	{
		if (Ogre.CurrentState == EVillageStealthOgreState::TurningBack)
			return;

		Ogre.CurrentState = EVillageStealthOgreState::TurningBack;
		UVillageStealthOgreEffectEventHandler::Trigger_TurnBack(Ogre);
	}
}