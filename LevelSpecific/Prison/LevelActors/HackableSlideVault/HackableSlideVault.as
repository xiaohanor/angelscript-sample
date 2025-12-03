UCLASS(Abstract)
class AHackableSlideVault : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent DoorComp;

	UPROPERTY()
	FSwarmHijackStartEvent OnHackingStarted;
	UPROPERTY()
	FSwarmHijackStopEvent OnHackingStopped;

	UPROPERTY(DefaultComponent, Attach = DoorComp)
	USceneComponent SpinningRoot;

	UPROPERTY(DefaultComponent, Attach = SpinningRoot)
	USceneComponent RotationRoot;

	UPROPERTY(DefaultComponent, Attach = DoorComp)
	USceneComponent HackableRoot;

	UPROPERTY(DefaultComponent, Attach = HackableRoot)
	USwarmDroneHijackTargetableComponent HijackTargetableComp;

	UFUNCTION(BlueprintPure)
	float GetNormalizedSpinningSpeed() const
	{
		return Math::NormalizeToRange(Math::Abs(RotationSpeed), 0, MaximumRotationSpeed);
	}

	UFUNCTION(BlueprintPure)
	float GetRotationAngle() const
	{
		return FRotator::ClampAxis(TotalRotation);
	}

	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComp;
	default CapabilityComp.DefaultCapabilities.Add(n"HackableSlideVaultCapability");

	UPROPERTY(DefaultComponent)
	UDroneMagneticSurfaceComponent MagneticSurfaceComp;

	UPROPERTY(DefaultComponent)
	UHazeCrumbSyncedRotatorComponent SyncedRotation;
	default SyncedRotation.SyncRate = EHazeCrumbSyncRate::Low;

	UPROPERTY(EditAnywhere, Category = "Spinning Fan")
	bool bAllowSpinClockwise = true;

	UPROPERTY(EditAnywhere, Category = "Spinning Fan")
	bool bAllowSpinCounterClockwise = true;

	// Minimum speed to rotate while spinning the stick (degrees/second)
	UPROPERTY(EditAnywhere, Category = "Spinning Fan")
	float MinimumRotationSpeed = 50.0;

	// Maximum speed to rotate while spinning the stick (degrees/second)
	UPROPERTY(EditAnywhere, Category = "Spinning Fan")
	float MaximumRotationSpeed = 100.0;

	// Acceleration of the rotation speed (degrees/second^2)
	UPROPERTY(EditAnywhere, Category = "Spinning Fan")
	float RotationSpeedAcceleration = 100.0;

	// How many times per second must the player spin to get the minimum speed
	UPROPERTY(EditAnywhere, Category = "Spinning Fan")
	float SpinsForMinimumSpeed = 0.2;

	// How many times per second must the player spin to get the maximum speed
	UPROPERTY(EditAnywhere, Category = "Spinning Fan")
	float SpinsForMaximumSpeed = 2.0;

	// Whether the spin speed should be constant no matter how much the player is spinning
	UPROPERTY(EditAnywhere, Category = "Spinning Fan")
	bool bConstantSpinSpeed = false;

	float TotalRotation = 0.0;

	float RotationSpeed = 0.0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SetActorControlSide(Game::Mio);

		HijackTargetableComp.OnHijackStartEvent.AddUFunction(this, n"HackingStarted");
		HijackTargetableComp.OnHijackStopEvent.AddUFunction(this, n"HackingStopped");

		TotalRotation = -RotationRoot.RelativeRotation.Pitch;
	}

	UFUNCTION(NotBlueprintCallable)
	private void HackingStarted(FSwarmDroneHijackParams HijackParams)
	{
		OnHackingStarted.Broadcast(HijackParams);
	}

	UFUNCTION(NotBlueprintCallable)
	private void HackingStopped()
	{
		OnHackingStopped.Broadcast();
	}
};

class UHackableSlideVaultCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default TickGroup = EHazeTickGroup::BeforeMovement;
	default TickGroupOrder = 5;

	AHackableSlideVault SlideVault;
	AHazePlayerCharacter Player;

	bool bWasActivelySpinning;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		SlideVault = Cast<AHackableSlideVault>(Owner);
		Player = Drone::GetSwarmDronePlayer();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!SlideVault.HijackTargetableComp.IsHijacked())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!SlideVault.HijackTargetableComp.IsHijacked())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		FStickSpinSettings Settings;
		Settings.bAllowPlayerCancel = false;
		Settings.bAllowSpinClockwise = SlideVault.bAllowSpinClockwise;
		Settings.bAllowSpinCounterClockwise = SlideVault.bAllowSpinCounterClockwise;

		Player.StartStickSpin(Settings, this);

		SlideVault.SyncedRotation.OverrideSyncRate(EHazeCrumbSyncRate::High);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.StopStickSpin(this);

		SlideVault.SyncedRotation.OverrideSyncRate(EHazeCrumbSyncRate::Low);
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
				SlideVault.RotationRoot.SetRelativeRotation(SlideVault.SyncedRotation.Value);
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
			if (Math::Abs(State.SpinVelocity) > SlideVault.SpinsForMinimumSpeed)
			{
				// Determine the rotation speed from the spin speed
				WantedRotationSpeed = Math::GetMappedRangeValueClamped(
					FVector2D(SlideVault.SpinsForMinimumSpeed, SlideVault.SpinsForMaximumSpeed),
					FVector2D(SlideVault.MinimumRotationSpeed, SlideVault.MaximumRotationSpeed),
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
			SlideVault.RotationRoot.SetRelativeRotation(SlideVault.SyncedRotation.Value);
		}
	}

	private void UpdateFanRotation(float WantedRotationSpeed, bool bIsActivelySpinning, float DeltaTime)
	{
			const bool bWasSpinning = Math::Abs(SlideVault.RotationSpeed) > KINDA_SMALL_NUMBER;
		const float PreviousRotationSpeed = SlideVault.RotationSpeed;

		// Lerp the rotation speed to what we want
		SlideVault.RotationSpeed = Math::FInterpConstantTo(SlideVault.RotationSpeed, WantedRotationSpeed, DeltaTime, SlideVault.RotationSpeedAcceleration);

		const bool bIsSpinning = Math::Abs(SlideVault.RotationSpeed) > KINDA_SMALL_NUMBER || bIsActivelySpinning;

		if(bWasSpinning && bIsSpinning)
		{
			if(Math::Sign(PreviousRotationSpeed) != Math::Sign(SlideVault.RotationSpeed))
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

		SlideVault.TotalRotation += SlideVault.RotationSpeed * DeltaTime;

		FQuat CurrentRotation = FQuat(FVector::RightVector, Math::DegreesToRadians(SlideVault.TotalRotation));
		SlideVault.RotationRoot.SetRelativeRotation(CurrentRotation.Rotator());

		SlideVault.SyncedRotation.SetValue(SlideVault.RotationRoot.RelativeRotation);
	}
}