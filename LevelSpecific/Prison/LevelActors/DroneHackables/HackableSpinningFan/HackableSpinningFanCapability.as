class UHackableSpinningFanCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default TickGroup = EHazeTickGroup::BeforeMovement;
	default TickGroupOrder = 5;

	AHackableSpinningFan SpinningFan;
	AHazePlayerCharacter Player;

	bool bWasActivelySpinning;

	bool bHideTutorial = false;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		SpinningFan = Cast<AHackableSpinningFan>(Owner);
		Player = Drone::GetSwarmDronePlayer();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!SpinningFan.HijackTargetableComp.IsHijacked())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!SpinningFan.HijackTargetableComp.IsHijacked())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		FStickSpinSettings Settings;
		Settings.bAllowPlayerCancel = false;
		Settings.bAllowSpinClockwise = SpinningFan.bAllowSpinClockwise;
		Settings.bAllowSpinCounterClockwise = SpinningFan.bAllowSpinCounterClockwise;
		Settings.bShowStickSpinWidget = false;

		Player.StartStickSpin(Settings, this);

		bHideTutorial = false;

		SpinningFan.SyncedRotation.OverrideSyncRate(EHazeCrumbSyncRate::High);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.StopStickSpin(this);

		SpinningFan.SyncedRotation.OverrideSyncRate(EHazeCrumbSyncRate::Low);
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		if(!IsActive())
		{
			if(HasControl())
			{
				UpdateFanRotation(0, false, DeltaTime);
			}
			else
			{
				SpinningFan.FanRotationRoot.SetRelativeRotation(SpinningFan.SyncedRotation.Value);
			}
		}
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(HasControl())
		{
			FStickSpinState State = Player.GetStickSpinState(this);

			float WantedRotationSpeed = 0.0;
			bool bIsActivelySpinning = false;

			// SpinVelocity indicates how fast the player is spinning the stick, you can also
			// use SpinPosition for how much they've spinned in total, and Direction to get the general direction the spin is happening in
			if (Math::Abs(State.SpinVelocity) > SpinningFan.SpinsForMinimumSpeed)
			{
				// Determine the rotation speed from the spin speed
				WantedRotationSpeed = Math::GetMappedRangeValueClamped(
					FVector2D(SpinningFan.SpinsForMinimumSpeed, SpinningFan.SpinsForMaximumSpeed),
					FVector2D(SpinningFan.MinimumRotationSpeed, SpinningFan.MaximumRotationSpeed),
					Math::Abs(State.SpinVelocity)
				);

				// Rotate in the same direction that we're spinning
				WantedRotationSpeed *= Math::Sign(State.SpinVelocity);

				bIsActivelySpinning = true;

				if(SpinningFan.RotationSpeed > 0)
					Player.SetFrameForceFeedback(0, SpinningFan.RotationSpeed*0.001, 0.0, 0.0);
				else
					Player.SetFrameForceFeedback(Math::Abs(SpinningFan.RotationSpeed*0.001), 0, 0.0, 0.0);
			}

			UpdateFanRotation(WantedRotationSpeed, bIsActivelySpinning, DeltaTime);

			if(!bWasActivelySpinning && bIsActivelySpinning)
			{
				Crumb_PlayerStartedSpinning();
			}
			else if(bWasActivelySpinning && !bIsActivelySpinning)
			{
				Crumb_PlayerStoppedSpinning();
			}

			bWasActivelySpinning = bIsActivelySpinning;
		}
		else
		{
			SpinningFan.FanRotationRoot.SetRelativeRotation(SpinningFan.SyncedRotation.Value);
		}
	}

	private void UpdateFanRotation(float WantedRotationSpeed, bool bIsActivelySpinning, float DeltaTime)
	{
			const bool bWasSpinning = Math::Abs(SpinningFan.RotationSpeed) > KINDA_SMALL_NUMBER;
		const float PreviousRotationSpeed = SpinningFan.RotationSpeed;

		// Lerp the rotation speed to what we want
		SpinningFan.RotationSpeed = Math::FInterpConstantTo(SpinningFan.RotationSpeed, WantedRotationSpeed, DeltaTime, SpinningFan.RotationSpeedAcceleration);

		const bool bIsSpinning = Math::Abs(SpinningFan.RotationSpeed) > KINDA_SMALL_NUMBER || bIsActivelySpinning;

		if(bWasSpinning && bIsSpinning)
		{
			if(Math::Sign(PreviousRotationSpeed) != Math::Sign(SpinningFan.RotationSpeed))
				Crumb_SpinDirectionReversed();
		}
		if(!bWasSpinning && bIsSpinning)
		{
			Crumb_StartSpinningFan();
		}
		else if(bWasSpinning && !bIsSpinning)
		{
			Crumb_StopSpinningFan();
		}

		SpinningFan.TotalRotation += SpinningFan.RotationSpeed * DeltaTime;

		FQuat CurrentRotation = FQuat(FVector::RightVector, Math::DegreesToRadians(SpinningFan.TotalRotation));
		SpinningFan.FanRotationRoot.SetRelativeRotation(CurrentRotation.Rotator());

		SpinningFan.SyncedRotation.SetValue(SpinningFan.FanRotationRoot.RelativeRotation);

		if(!bHideTutorial && Math::Abs(SpinningFan.RotationSpeed) > 25)
		{
			Crumb_HideTutorial();
		}
	}

	UFUNCTION(CrumbFunction)
	private void Crumb_HideTutorial()
	{
		if(bHideTutorial)
			return;

		bHideTutorial = true;
		Timer::SetTimer(this,n"HideTutorial", 1);
	}

	UFUNCTION()
	private void HideTutorial()
	{
		SpinningFan.OnHideTutorial.Broadcast();
	}

	UFUNCTION(CrumbFunction)
	private void Crumb_StartSpinningFan()
	{
		UHackableSpinningFanEventHandler::Trigger_StartSpinningFan(Owner);
	}

	UFUNCTION(CrumbFunction)
	private void Crumb_SpinDirectionReversed()
	{
		UHackableSpinningFanEventHandler::Trigger_SpinDirectionReversed(Owner);
	}

	UFUNCTION(CrumbFunction)
	private void Crumb_StopSpinningFan()
	{
		UHackableSpinningFanEventHandler::Trigger_StopSpinningFan(Owner);
	}

	UFUNCTION(CrumbFunction)
	private void Crumb_PlayerStartedSpinning()
	{
		UHackableSpinningFanEventHandler::Trigger_PlayerStartedSpinning(Owner);
	}

	UFUNCTION(CrumbFunction)
	private void Crumb_PlayerStoppedSpinning()
	{
		UHackableSpinningFanEventHandler::Trigger_PlayerStoppedSpinning(Owner);
	}
}