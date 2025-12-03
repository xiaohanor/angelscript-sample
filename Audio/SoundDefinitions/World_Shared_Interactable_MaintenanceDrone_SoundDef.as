
UCLASS(Abstract)
class UWorld_Shared_Interactable_MaintenanceDrone_SoundDef : USoundDefBase
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	/* END OF AUTO-GENERATED CODE */

	URemoteHackingResponseComponent HackingResponseComp;
	UHazeMovementComponent PlayerMoveComp;

	private bool bIsHacked = false;	

	UFUNCTION(BlueprintOverride)
	void ParentSetup()
	{
		HackingResponseComp = URemoteHackingResponseComponent::Get(HazeOwner);

		HackingResponseComp.OnHackingStarted.AddUFunction(this, n"OnDroneHackingStartedInternal");
		HackingResponseComp.OnHackingStopped.AddUFunction(this, n"OnDroneHackingStoppedInternal");

		PlayerMoveComp = UHazeMovementComponent::Get(Game::GetMio());
	}	

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason EndPlayReason)
	{
		HackingResponseComp.OnHackingStarted.UnbindObject(this);
		HackingResponseComp.OnHackingStopped.UnbindObject(this);
	}

	UPROPERTY(Category = "Propulsion")
	bool bStartWithPassivePropulsion = true;

	UPROPERTY(Category = "Propulsion")
	UHazeAudioActorMixer PropulsionActorMixer = nullptr;

	UPROPERTY(Category = "Propulsion")
	UHazeAudioEvent PropulsionPassiveLoopEvent = nullptr;

	UPROPERTY(Category = "Propulsion")
	UHazeAudioEvent PropulsionActiveLoopEvent = nullptr;

	UPROPERTY(Category = "Propulsion")
	UHazeAudioEvent PropulsionMovementStartEvent = nullptr;

	UPROPERTY(Category = "Propulsion")
	UHazeAudioEvent PropulsionMovementStopEvent = nullptr;

	UPROPERTY(Category = "Propulsion", Meta = (ForceUnits = "cm"))
	float MaxInputMovementSpeed = 500;

	UPROPERTY(Category = "Propulsion", Meta = (ForceUnits = "cm"))
	float MaxAngularVelocity = 5.0;

	UPROPERTY(Category = "Servo Movement")
	UHazeAudioActorMixer ServoActorMixer = nullptr;
	
	UPROPERTY(Category = "Servo Movement")
	UHazeAudioEvent ServoShortEvent = nullptr;

	UPROPERTY(Category = "Servo Movement")
	UHazeAudioEvent ServoLongEvent = nullptr; 

	UPROPERTY(Category = "Vocalizations")
	bool bAutoActivateVocalizations = false;

	UPROPERTY(Category = "Vocalizations")
	UHazeAudioActorMixer VocalizationsActorMixer = nullptr;

	UPROPERTY(Category = "Vocalizations", Meta = (ForceUnits = "cents"))
	float VocalizationsPitch = 0.0;

	UPROPERTY(Category = "Vocalizations")
	UHazeAudioEvent VocalizationsShortEvent = nullptr;

	UPROPERTY(Category = "Vocalizations")
	UHazeAudioEvent VocalizationsLongEvent = nullptr;

	UPROPERTY(Category = "Logic")
	float AttenuationScaling = 3000;

	private float DroneInputInterped = 0.0;
	private float DroneInput = 0.0;

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaSeconds)
	{
		if(bIsHacked)
		{
			FVector Input = PlayerMoveComp.GetSyncedMovementInputForAnimationOnly();

			DroneInput = Input.Size();
			DroneInputInterped = Math::FInterpConstantTo(DroneInputInterped, DroneInput, DeltaSeconds, 2.0);
			TickOnHacked(DeltaSeconds);
		}
	}

	UFUNCTION(NotBlueprintCallable)
	void OnDroneHackingStartedInternal()
	{
		bIsHacked = true;
		OnDroneHackingStarted();
	}

	UFUNCTION(NotBlueprintCallable)
	void OnDroneHackingStoppedInternal()
	{
		bIsHacked = false;
		OnDroneHackingStopped();
	}

	UFUNCTION(BlueprintEvent)
	void OnDroneHackingStarted() {}

	UFUNCTION(BlueprintEvent)
	void OnDroneHackingStopped() {}

	UFUNCTION(BlueprintEvent)
	void TickOnHacked(float DeltaSeconds) {}

	UFUNCTION(BlueprintPure)
	float GetDroneInputMovementSpeedNormalized()
	{
		return DroneInputInterped;
	}

	UFUNCTION(BlueprintPure)
	float GetDroneInputRaw()
	{
		return DroneInput;
	}
}