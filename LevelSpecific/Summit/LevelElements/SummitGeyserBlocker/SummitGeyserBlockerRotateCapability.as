class USummitGeyserBlockerRotateCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default TickGroup = EHazeTickGroup::Gameplay;

	default NetworkMode = EHazeCapabilityNetworkMode::Local;

	ASummitGeyserBlocker Blocker;

	FRotator StartRotation;

	bool bHaveBlocked = false;
	ESummitGeyserBlockerDirection PreviousDirection;
	ESummitGeyserBlockerDirection TargetDirection;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Blocker = Cast<ASummitGeyserBlocker>(Owner);
	}

	ESummitGeyserBlockerDirection GetWantedDirection() const
	{
		float Time = Time::PredictedGlobalCrumbTrailTime;
		float CycleDuration = (Blocker.RotateDuration + Blocker.RotateDelay) * 4.0;

		float PctOfCycle = Math::Wrap(Time, 0.0, CycleDuration) / CycleDuration;

		if (Blocker.bRotateClockWise)
			return ESummitGeyserBlockerDirection(Math::Clamp(Math::FloorToInt(PctOfCycle * 4.0), 0, 3));
		else
			return ESummitGeyserBlockerDirection(Math::Clamp(3 - Math::FloorToInt(PctOfCycle * 4.0), 0, 3));
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(GetWantedDirection() != Blocker.BlockerDirection)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(ActiveDuration > Blocker.RotateDuration)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		PreviousDirection = Blocker.BlockerDirection;
		TargetDirection = GetWantedDirection();

		Blocker.BlockerDirection = TargetDirection;

		StartRotation = Blocker.RotateRoot.RelativeRotation;

		bHaveBlocked = false;

		USummitGeyserBlockerEventHandler::Trigger_OnStartedRotating(Blocker);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Blocker.RotateRoot.RelativeRotation = GetTargetRotation();
		USummitGeyserBlockerEventHandler::Trigger_OnStoppedRotating(Blocker);

		if (!bHaveBlocked)
		{
			ToggleBlock(false, PreviousDirection);
			ToggleBlock(true, TargetDirection);
			bHaveBlocked = true;
		}
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		switch(Blocker.BlockerDirection)
		{
			case ESummitGeyserBlockerDirection::Down:
			{
				TEMPORAL_LOG(Blocker).Status("Down", FLinearColor::Green);
				break;				
			}
			case ESummitGeyserBlockerDirection::Left:
			{
				TEMPORAL_LOG(Blocker).Status("Left", FLinearColor::LucBlue);
				break;				
			}
			case ESummitGeyserBlockerDirection::Up:
			{
				TEMPORAL_LOG(Blocker).Status("Up", FLinearColor::DPink);
				break;				
			}
			case ESummitGeyserBlockerDirection::Right:
			{
				TEMPORAL_LOG(Blocker).Status("Right", FLinearColor::Purple);
				break;				
			}
			default:
				break;				
		}

		float Alpha = ActiveDuration / Blocker.RotateDuration;
		if(Alpha >= 0.5
		&& !bHaveBlocked)
		{
			ToggleBlock(false, PreviousDirection);
			ToggleBlock(true, TargetDirection);
			bHaveBlocked = true;
		}

		Alpha = Math::EaseInOut(0.0, 1.0, Alpha, 4);
		FRotator TargetRotation = GetTargetRotation();
		FRotator Rotation = Math::LerpShortestPath(StartRotation, TargetRotation, Alpha);
		Blocker.RotateRoot.RelativeRotation = Rotation;
	}

	FRotator GetTargetRotation() const
	{
		if(Blocker.BlockerDirection == ESummitGeyserBlockerDirection::Down)
			return FRotator(0.0, 0.0, 0.0);
		else if(Blocker.BlockerDirection == ESummitGeyserBlockerDirection::Left)
			return FRotator(0.0, 90, 0.0);
		else if(Blocker.BlockerDirection == ESummitGeyserBlockerDirection::Up)
			return FRotator(0.0, 180, 0.0);
		else 
			return FRotator(0.0, 270, 0.0);
	}

	void ToggleBlock(bool bBlock, ESummitGeyserBlockerDirection BlockDirection)
	{
		switch(BlockDirection)
		{
			case ESummitGeyserBlockerDirection::Down:
			{
				if(bBlock)
				{
					if(Blocker.BottomLeftGeyser != nullptr)
					{
						Blocker.BottomLeftGeyser.DisableEruption(this);
						Blocker.BottomLeftGeyser.OnBecameBlocked.Broadcast();
					}
					if(Blocker.BottomRightGeyser != nullptr)
					{
						Blocker.BottomRightGeyser.DisableEruption(this);
						Blocker.BottomRightGeyser.OnBecameBlocked.Broadcast();
					}
				}
				else
				{
					if(Blocker.BottomLeftGeyser != nullptr)
					{
						Blocker.BottomLeftGeyser.EnableEruption(this);
						Blocker.BottomLeftGeyser.OnBecameUnblocked.Broadcast();
					}
					if(Blocker.BottomRightGeyser != nullptr)
					{
						Blocker.BottomRightGeyser.EnableEruption(this);
						Blocker.BottomRightGeyser.OnBecameUnblocked.Broadcast();
					}
				}
				break;				
			}
			case ESummitGeyserBlockerDirection::Left:
			{
				if(bBlock)
				{
					if(Blocker.BottomLeftGeyser != nullptr)
					{
						Blocker.BottomLeftGeyser.DisableEruption(this);
						Blocker.BottomLeftGeyser.OnBecameBlocked.Broadcast();
					}
					if(Blocker.TopLeftGeyser != nullptr)
					{
						Blocker.TopLeftGeyser.DisableEruption(this);
						Blocker.TopLeftGeyser.OnBecameBlocked.Broadcast();
					}
				}
				else
				{
					if(Blocker.BottomLeftGeyser != nullptr)
					{
						Blocker.BottomLeftGeyser.EnableEruption(this);
						Blocker.BottomLeftGeyser.OnBecameUnblocked.Broadcast();
					}
					if(Blocker.TopLeftGeyser != nullptr)
					{
						Blocker.TopLeftGeyser.EnableEruption(this);
						Blocker.TopLeftGeyser.OnBecameUnblocked.Broadcast();
					}
				}
				break;				
			}
			case ESummitGeyserBlockerDirection::Up:
			{
				if(bBlock)
				{
					if(Blocker.TopRightGeyser != nullptr)
					{
						Blocker.TopRightGeyser.DisableEruption(this);
						Blocker.TopRightGeyser.OnBecameBlocked.Broadcast();
					}
					if(Blocker.TopLeftGeyser != nullptr)
					{
						Blocker.TopLeftGeyser.DisableEruption(this);
						Blocker.TopLeftGeyser.OnBecameBlocked.Broadcast();
					}
				}
				else
				{
					if(Blocker.TopRightGeyser != nullptr)
					{
						Blocker.TopRightGeyser.EnableEruption(this);
						Blocker.TopRightGeyser.OnBecameUnblocked.Broadcast();
					}
					if(Blocker.TopLeftGeyser != nullptr)
					{
						Blocker.TopLeftGeyser.EnableEruption(this);
						Blocker.TopLeftGeyser.OnBecameUnblocked.Broadcast();
					}
				}
				break;				
			}
			case ESummitGeyserBlockerDirection::Right:
			{
				if(bBlock)
				{
					if(Blocker.TopRightGeyser != nullptr)
					{
						Blocker.TopRightGeyser.DisableEruption(this);
						Blocker.TopRightGeyser.OnBecameBlocked.Broadcast();
					}
					if(Blocker.BottomRightGeyser != nullptr)
					{
						Blocker.BottomRightGeyser.DisableEruption(this);
						Blocker.BottomRightGeyser.OnBecameBlocked.Broadcast();
					}
				}
				else
				{
					if(Blocker.TopRightGeyser != nullptr)
					{
						Blocker.TopRightGeyser.EnableEruption(this);
						Blocker.TopRightGeyser.OnBecameUnblocked.Broadcast();
					}
					if(Blocker.BottomRightGeyser != nullptr)
					{
						Blocker.BottomRightGeyser.EnableEruption(this);
						Blocker.BottomRightGeyser.OnBecameUnblocked.Broadcast();
					}
				}
				break;				
			}
			default:
				break;				
		}
	}
};