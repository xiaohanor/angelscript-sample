event void EventRemoveHackableWaterGearTutorial();

class AHackableWaterGear : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent)
	USceneComponent SpinningFanRoot;

	UPROPERTY(DefaultComponent, Attach = SpinningFanRoot)
	USceneComponent FanRotationRoot;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent HackableRoot;

	UPROPERTY(DefaultComponent, Attach = HackableRoot)
	USwarmDroneHijackTargetableComponent HijackTargetableComp;

	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComp;
	default CapabilityComp.DefaultCapabilities.Add(n"HackableWaterGearCapability");

	UPROPERTY(DefaultComponent)
	UHazeCrumbSyncedRotatorComponent SyncedRotation;
	default SyncedRotation.SyncRate = EHazeCrumbSyncRate::Low;

	UPROPERTY()
	EventRemoveHackableWaterGearTutorial OnHideTutorial;

	UPROPERTY()
	FSwarmHijackStartEvent OnHackingStarted;
	UPROPERTY()
	FSwarmHijackStopEvent OnHackingStopped;

	UPROPERTY(EditAnywhere)
	TArray<AHackableWaterGearWheel> Wheels;

	UPROPERTY(EditAnywhere, Category = "Spinning Fan")
	bool bAllowSpinClockwise = true;

	UPROPERTY(EditAnywhere, Category = "Spinning Fan")
	bool bAllowSpinCounterClockwise = true;

	// Minimum speed to rotate while spinning the stick (degrees/second)
	UPROPERTY(EditAnywhere, Category = "Spinning Fan")
	float MinimumRotationSpeed = 1000.0;

	// Maximum speed to rotate while spinning the stick (degrees/second)
	UPROPERTY(EditAnywhere, Category = "Spinning Fan")
	float MaximumRotationSpeed = 3000.0;

	// Acceleration of the rotation speed (degrees/second^2)
	UPROPERTY(EditAnywhere, Category = "Spinning Fan")
	float RotationSpeedAcceleration = 4000.0;

	// How many times per second must the player spin to get the minimum speed
	UPROPERTY(EditAnywhere, Category = "Spinning Fan")
	float SpinsForMinimumSpeed = 0.1;

	// How many times per second must the player spin to get the maximum speed
	UPROPERTY(EditAnywhere, Category = "Spinning Fan")
	float SpinsForMaximumSpeed = 1.0;

	// Whether the spin speed should be constant no matter how much the player is spinning
	UPROPERTY(EditAnywhere, Category = "Spinning Fan")
	bool bConstantSpinSpeed = false;

	float TotalRotation = 0.0;

	float RotationSpeed = 0.0;

	UPROPERTY(EditAnywhere, Category = Audio)
	UHazeAudioBusMixer HackingBusMixer;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SetActorControlSide(Game::Mio);

		HijackTargetableComp.OnHijackStartEvent.AddUFunction(this, n"HackingStarted");
		HijackTargetableComp.OnHijackStopEvent.AddUFunction(this, n"HackingStopped");

		SetActorControlSide(Game::Mio);
		TotalRotation = -FanRotationRoot.RelativeRotation.Pitch;
	}

	UFUNCTION(NotBlueprintCallable)
	private void HackingStarted(FSwarmDroneHijackParams HijackParams)
	{
		OnHackingStarted.Broadcast(HijackParams);

		if(HackingBusMixer != nullptr)
		{
			Audio::StartOrUpdateUserStateControlledBusMixer(this, HackingBusMixer, EHazeBusMixerState::FadeIn);
		}
	}

	UFUNCTION(NotBlueprintCallable)
	private void HackingStopped()
	{
		OnHackingStopped.Broadcast();

		if(HackingBusMixer != nullptr)
		{
			Audio::StartOrUpdateUserStateControlledBusMixer(this, HackingBusMixer, EHazeBusMixerState::FadeOut);
		}
	}

	UFUNCTION(BlueprintPure)
	float GetRotationAngle() const
	{
		return FRotator::ClampAxis(TotalRotation);
	}

	UFUNCTION(BlueprintCallable)
	void SetSpinningFanRotationRoot(FRotator NewRot)
	{
		if(HasControl())
		{
			FanRotationRoot.SetRelativeRotation(NewRot);
			for (auto Wheel : Wheels)
			{
				Wheel.SetSpinningFanRotationRoot(NewRot);
			}
		}
		else
		{
			for (auto Wheel : Wheels)
			{
				Wheel.SetSpinningFanRotationRoot(NewRot);
			}
		}
	}
	UFUNCTION(BlueprintCallable)
	void SetSpinningFanRotationSpeed(float Speed)
	{
		RotationSpeed = Speed;
		for (auto Wheel : Wheels)
		{
			Wheel.RotationSpeed = Speed;
		}
	}
	UFUNCTION(BlueprintCallable)
	void SetTotalSpinningFanRotation(float Total)
	{
		TotalRotation = Total;
		for (auto Wheel : Wheels)
		{
			Wheel.SetTotalSpinningFanRotation(Total);
		}
	}
};

class UHackableWaterGearCapability: UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default TickGroup = EHazeTickGroup::BeforeMovement;
	default TickGroupOrder = 5;

	AHackableWaterGear WaterGear;
	AHazePlayerCharacter Player;

	bool bWasActivelySpinning;

	bool bHideTutorial = false;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		WaterGear = Cast<AHackableWaterGear>(Owner);
		Player = Drone::GetSwarmDronePlayer();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!WaterGear.HijackTargetableComp.IsHijacked())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!WaterGear.HijackTargetableComp.IsHijacked())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		FStickSpinSettings Settings;
		Settings.bAllowPlayerCancel = false;
		Settings.bAllowSpinClockwise = WaterGear.bAllowSpinClockwise;
		Settings.bAllowSpinCounterClockwise = WaterGear.bAllowSpinCounterClockwise;
		Settings.bShowStickSpinWidget = false;
		bHideTutorial = false; 
		Player.StartStickSpin(Settings, this);

		WaterGear.SyncedRotation.OverrideSyncRate(EHazeCrumbSyncRate::High);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.StopStickSpin(this);
		WaterGear.SyncedRotation.OverrideSyncRate(EHazeCrumbSyncRate::Low);
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
				WaterGear.FanRotationRoot.SetRelativeRotation(WaterGear.SyncedRotation.Value);
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
			if (Math::Abs(State.SpinVelocity) > WaterGear.SpinsForMinimumSpeed)
			{
				// Determine the rotation speed from the spin speed
				WantedRotationSpeed = Math::GetMappedRangeValueClamped(
					FVector2D(WaterGear.SpinsForMinimumSpeed, WaterGear.SpinsForMaximumSpeed),
					FVector2D(WaterGear.MinimumRotationSpeed, WaterGear.MaximumRotationSpeed),
					Math::Abs(State.SpinVelocity)
				);

				// Rotate in the same direction that we're spinning
				WantedRotationSpeed *= Math::Sign(State.SpinVelocity);

				bIsActivelySpinning = true;
			}

			UpdateFanRotation(WantedRotationSpeed, bIsActivelySpinning, DeltaTime);

			if(!bWasActivelySpinning && bIsActivelySpinning)
			{
				UHackableSpinningFanEventHandler::Trigger_PlayerStartedSpinning(Owner);
			}
			else if(bWasActivelySpinning && !bIsActivelySpinning)
			{
				UHackableSpinningFanEventHandler::Trigger_PlayerStoppedSpinning(Owner);
			}

			bWasActivelySpinning = bIsActivelySpinning;
		}
		else
		{
			WaterGear.FanRotationRoot.SetRelativeRotation(WaterGear.SyncedRotation.Value);
			for ( auto Wheel: WaterGear.Wheels)
			{
				Wheel.SetSpinningFanRotationRoot(WaterGear.SyncedRotation.Value);
			}
		}
	}

	private void UpdateFanRotation(float WantedRotationSpeed, bool bIsActivelySpinning, float DeltaTime)
	{
		const bool bWasSpinning = Math::Abs(WaterGear.RotationSpeed) > KINDA_SMALL_NUMBER;
		const float PreviousRotationSpeed = WaterGear.RotationSpeed;

		// Lerp the rotation speed to what we want
		WaterGear.SetSpinningFanRotationSpeed(Math::FInterpConstantTo(WaterGear.RotationSpeed, WantedRotationSpeed, DeltaTime, WaterGear.RotationSpeedAcceleration));

		const bool bIsSpinning = Math::Abs(WaterGear.RotationSpeed) > KINDA_SMALL_NUMBER || bIsActivelySpinning;

		if(bWasSpinning && bIsSpinning)
		{
			if(Math::Sign(PreviousRotationSpeed) != Math::Sign(WaterGear.RotationSpeed))
				UHackableSpinningFanEventHandler::Trigger_SpinDirectionReversed(Owner);
		}
		if(!bWasSpinning && bIsSpinning)
		{
			UHackableSpinningFanEventHandler::Trigger_StartSpinningFan(Owner);
		}
		else if(bWasSpinning && !bIsSpinning)
		{
			UHackableSpinningFanEventHandler::Trigger_StopSpinningFan(Owner);
		}

		WaterGear.SetTotalSpinningFanRotation(WaterGear.TotalRotation + WaterGear.RotationSpeed * DeltaTime);

		FRotator CurrentRotation = Math::RotatorFromAxisAndAngle(FVector::RightVector, Math::DegreesToRadians(WaterGear.TotalRotation));
		WaterGear.SetSpinningFanRotationRoot(CurrentRotation);

		WaterGear.SyncedRotation.SetValue(WaterGear.FanRotationRoot.RelativeRotation);
		if(!bHideTutorial && Math::Abs(WaterGear.RotationSpeed) > 25)
		{
			bHideTutorial = true;
			Timer::SetTimer(this,n"HideTutorial",1);
		}
	}

	UFUNCTION()
	private void HideTutorial()
	{
		WaterGear.OnHideTutorial.Broadcast();
	}
}