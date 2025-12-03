
UCLASS(Abstract)
class UWorld_Prison_Containment_Interactable_LaserShaft_WeldingBot_SoundDef : USoundDefBase
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	/* END OF AUTO-GENERATED CODE */

	UPROPERTY(BlueprintReadOnly)
	ARemoteHackableWinch Winch;

	float VerticalProgression;
	float LastVerticalProgression;
	float AccumelatedVerticalDelta;

	UPROPERTY(BlueprintReadWrite)
	FHazeAudioPostEventInstance VerticalMovingEventInstance;

	UPROPERTY(BlueprintReadWrite)
	FHazeAudioPostEventInstance HorizontalMovingEventInstance;

	UPROPERTY(BlueprintReadWrite)
	FHazeAudioPostEventInstance MetalStressEventInstance;

	const float MAX_WINCH_SPEED_COMBINED_RANGE = 30.0;
	const float LASER_SHAFT_LENGTH_SQUARED = 333157036;
	const float VERTICAL_DELTA_INCREMENT_AMOUNT = 0.0007;

	FVector LastWinchInput;
	FVector LastWinchLocation;

	float VerticalSpeed;
	float HorizontalSpeed;
	float CurrVerticalDirection = 0.0;

	bool bMovingHorizontal = false;
	bool bMovingVertical = false;

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!Winch.HackingComp.bHacked)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(Winch.HackingComp.bHacked)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	void ParentSetup()
	{
		Winch = Cast<ARemoteHackableWinch>(HazeOwner);

		Winch.HackingComp.OnHackingStarted.AddUFunction(this, n"OnHackingStarted");		
		Winch.HackingComp.OnHackingStopped.AddUFunction(this, n"OnHackingStopped");		

		UPlayerHealthComponent::Get(Game::GetZoe()).OnDeathTriggered.AddUFunction(this, n"OnPlayerDied");
	}

	UFUNCTION()
	void OnPlayerDied()
	{
		VerticalMovingEventInstance.Stop(0);
		MetalStressEventInstance.Stop(0);
		HorizontalMovingEventInstance.Stop(0);
	}

	UFUNCTION(BlueprintEvent)
	void OnHackingStarted() {};
	
	UFUNCTION(BlueprintEvent)
	void OnHackingStopped() {};	

	UFUNCTION(BlueprintEvent)
	void OnStartMovingVertical(bool IsDownwards) {};	

	UFUNCTION(BlueprintEvent)
	void OnStopMovingVertical() {};	

	UFUNCTION(BlueprintEvent)
	void OnStartMovingHorizontal() {};	

	UFUNCTION(BlueprintEvent)
	void OnStopMovingHorizontal() {};	

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaSeconds)
	{
		VerticalProgression = Winch.RootComp.GetWorldLocation().DistSquared(Game::GetZoe().GetActorLocation()) / LASER_SHAFT_LENGTH_SQUARED;

		if(VerticalProgression > LastVerticalProgression)
		{
			AccumelatedVerticalDelta += VERTICAL_DELTA_INCREMENT_AMOUNT;
		}		
		else if(VerticalProgression < LastVerticalProgression)
		{
			AccumelatedVerticalDelta -= VERTICAL_DELTA_INCREMENT_AMOUNT;
		}
		else
		{
			AccumelatedVerticalDelta = 0;
		}

		QueryMovement(DeltaSeconds);

		LastVerticalProgression = VerticalProgression;

		// PrintToScreenScaled(f"Shaft progression: {GetVerticalProgression()}");
	}

	private void QueryMovement(float DeltaSeconds)
	{
		const float CurrHeight = Winch.SyncedCurrentHeight.GetValue();

		const FVector WinchLocation = Winch.GetActorCenterLocation();
		const FVector WinchVelo = WinchLocation - LastWinchLocation;

		const FVector WinchInput = Winch.GetWinchInput();

		if(WinchInput.Z != 0)
		{
			if(!bMovingVertical)
			{
				const bool bIsMovingDownwards = WinchInput.Z < 0;
				OnStartMovingVertical(bIsMovingDownwards);
			}

			bMovingVertical = true;
		}
		else
		{
			if(bMovingVertical)
			{
				OnStopMovingVertical();
			}

			bMovingVertical = false;
		}		

		if(HasHorizontalInput())
		{
			if(!bMovingHorizontal)
			{
				OnStartMovingHorizontal();			
			}

			bMovingHorizontal = true;
		}
		else
		{	
			if(bMovingHorizontal)		
				OnStopMovingHorizontal();

			bMovingHorizontal = false;
		}

		FVector HorizVelo = WinchVelo;
		HorizVelo.Z = 0;

		HorizontalSpeed = HorizVelo.Size() / DeltaSeconds;

		FVector VerticalVelo = WinchVelo;
		VerticalVelo.X = 0;
		VerticalVelo.Y = 0;	

		VerticalSpeed = VerticalVelo.Size() / DeltaSeconds;		

		if((WinchLocation - LastWinchLocation).IsNearlyZero())
			CurrVerticalDirection = 0.0;
		else
		{
			CurrVerticalDirection = Math::Sign(LastWinchLocation.Z - WinchLocation.Z);
		}

		LastWinchLocation = WinchLocation;
	}	

	UFUNCTION(BlueprintPure)
	void GetVerticalMovement(float&out Speed, float&out Direction)
	{
		Speed = VerticalSpeed;
		Direction = CurrVerticalDirection;
	}	

	UFUNCTION(BlueprintPure)
	void GetHorizontalMovement(float&out Speed, float&out Direction)
	{
		Speed = HorizontalSpeed;

		const FVector Input = Winch.GetWinchInput();	
	
		if(Math::Abs(Input.X) < Math::Abs(Input.Y))
			Direction = Input.X;
		else
			Direction = Input.Y;
	}	

	UFUNCTION(BlueprintPure)
	float GetVerticalProgression()
	{
		return VerticalProgression;
	}
	
	UFUNCTION(BlueprintPure)
	float GetAccumulatedVerticalDelta()
	{
		return AccumelatedVerticalDelta;
	}

	private bool HasHorizontalInput()
	{
		const FVector Input = Winch.GetWinchInput();
		return Input.X != 0 || Input.Y != 0;
	}

	private bool MovingInstanceIsPlaying(const FHazeAudioPostEventInstance& InInstance)
	{
		if(InInstance.IsPlaying())
			return !InInstance.bIsBeingStopped;

		return false;
	}

}