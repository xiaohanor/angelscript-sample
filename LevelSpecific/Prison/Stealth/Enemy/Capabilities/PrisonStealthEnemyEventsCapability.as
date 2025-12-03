enum EPrisonStealthEnemyEventState
{
	Idle,
	Spotted,
	Detected,
};

class UPrisonStealthEnemyEventsCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Local;

	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::AfterGameplay;

	APrisonStealthEnemy Enemy;
	
	EPrisonStealthEnemyEventState CurrentState;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Enemy = Cast<APrisonStealthEnemy>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!HasControl())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		SetState(EPrisonStealthEnemyEventState::Idle);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		EPrisonStealthEnemyEventState NewState = DecideState();
		SetState(NewState);
	}

	EPrisonStealthEnemyEventState DecideState() const
	{
		if(Enemy.HasDetectedAnyPlayer())
			return EPrisonStealthEnemyEventState::Detected;

		if(Enemy.HasSpottedAnyPlayer())
			return EPrisonStealthEnemyEventState::Spotted;

		return EPrisonStealthEnemyEventState::Idle;
	}

	void SetState(EPrisonStealthEnemyEventState NewState)
	{
		if(CurrentState == NewState)
			return;

		CrumbSetState(NewState);
	}

	UFUNCTION(CrumbFunction)
	void CrumbSetState(EPrisonStealthEnemyEventState NewState)
	{
		if(HasAnyPlayersInSight(CurrentState) && !HasAnyPlayersInSight(NewState))
		{
			// We lost both players
			if(Enemy.IsA(APrisonStealthCamera))
			{
				UPrisonStealthCameraEventHandler::Trigger_OnPlayerLost(Enemy);
			}
			else if(Enemy.IsA(APrisonStealthGuard))
			{
				UPrisonStealthGuardEventHandler::Trigger_OnPlayerLost(Enemy);
			}
		}

		switch(NewState)
		{
			case EPrisonStealthEnemyEventState::Idle:
				break;

			case EPrisonStealthEnemyEventState::Spotted:
			{
				if(Enemy.IsA(APrisonStealthCamera))
				{
					UPrisonStealthCameraEventHandler::Trigger_OnPlayerSpotted(Enemy);
				}
				else if(Enemy.IsA(APrisonStealthGuard))
				{
					UPrisonStealthGuardEventHandler::Trigger_OnPlayerSpotted(Enemy);
				}
				break;
			}
			case EPrisonStealthEnemyEventState::Detected:
				UPrisonStealthEnemyEventHandler::Trigger_OnPlayerDetected(Enemy);
				break;
		}

		CurrentState = NewState;
	}

	bool HasAnyPlayersInSight(EPrisonStealthEnemyEventState State) const
	{
		switch(State)
		{
			case EPrisonStealthEnemyEventState::Idle:
				return false;
			case EPrisonStealthEnemyEventState::Spotted:
				return true;
			case EPrisonStealthEnemyEventState::Detected:
				return true;
		}
	}
};