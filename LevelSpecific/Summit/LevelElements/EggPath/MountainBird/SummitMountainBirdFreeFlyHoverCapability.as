class USummitMountainBirdFreeFlyHoverCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::Gameplay;

	AAISummitMountainBird MountainBird;	
	
	UFUNCTION(BlueprintOverride)
	void Setup()
	{		
		MountainBird = Cast<AAISummitMountainBird>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (MountainBird.CurrentState != ESummitMountainBirdFlightState::Hover)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{		
		if (MountainBird.CurrentState != ESummitMountainBirdFlightState::Hover)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		SummitMountainBird::Animations::PlayFlapAnimation(MountainBird);
		ForwardTimer = 5.0;
		USummitMountainBirdEventHandler::Trigger_OnHoveringStart(Owner);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{		
		MountainBird.SetCurrentState(ESummitMountainBirdFlightState::Land);
	}

	float ForwardTimer = 5.0;
	float TurnTimer = 10.0;
	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		float Speed = 1000.0;
		FVector NewLocation = Owner.ActorLocation + Owner.ActorForwardVector * Speed * DeltaTime;
		ForwardTimer -= DeltaTime;
		if (ForwardTimer < 0.0)
		{
			// Turn
			TurnTimer -= DeltaTime;
			FVector NewRotation = Owner.ActorForwardVector.RotateTowards(MountainBird.EscapeLocation.ActorLocation - Owner.ActorLocation, 45 * DeltaTime);
			Owner.SetActorRotation(NewRotation.ToOrientationRotator());
			if (TurnTimer < 0.0) // enough turning, switch to forward movement
			{				
				//ForwardTimer = 2.0;
				TurnTimer = 2.0;
			}
		}

		Owner.SetActorLocation(NewLocation);
	}

};