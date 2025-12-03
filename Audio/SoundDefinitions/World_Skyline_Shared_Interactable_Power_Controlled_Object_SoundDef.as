
UCLASS(Abstract)
class UWorld_Skyline_Shared_Interactable_Power_Controlled_Object_SoundDef : USoundDefBase
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	UFUNCTION(BlueprintEvent)
	void OnInteractionStart(float Intensity){}

	UFUNCTION(BlueprintEvent)
	void OnInteractionStop(){}

	/* END OF AUTO-GENERATED CODE */

	UPROPERTY(EditAnywhere)
	bool bStartActivated = false;

	UPROPERTY(EditInstanceOnly, Category = "Emitter")
	UMeshComponent PlaneMesh = nullptr;

	UPROPERTY(Category = "Emitter")
	TPerPlayer<bool> PlayerTrackEmitterPositions;

	UPROPERTY(Category = "Events")
	UHazeAudioEvent OnActivatedEvent;

	UPROPERTY(Category = "Events")
	UHazeAudioEvent OnPowerUpEvent;

	UPROPERTY(Category = "Events")
	UHazeAudioEvent OnPowerDownEvent;

	UPROPERTY(Category = "Events")
	UHazeAudioEvent PlayerInteractionStartEvent;

	UPROPERTY(Category = "Events")
	UHazeAudioEvent PlayerInteractionStopEvent;	

	UPROPERTY(Category = "Events")
	UHazeAudioEvent PulsePrePowerDownEvent;	

	UPROPERTY(Category = "Events", Meta = (EditCondition = "PulsePrePowerDownEvent != nullptr"))
	float PowerDownLookaheadTime = 0;	

	UPROPERTY(Category = "Interaction")
	UHazeAudioActorMixer InteractionActorMixer;

	UPROPERTY(Category = "Interaction", Meta = (ForceUnits = "db"))
	float MinInteractionGain = -24;

	UPROPERTY(Category = "Interaction", Meta = (ForceUnits = "db"))
	float MaxInteractionGain = 0;

	private USkylineInterfaceComponent InterfaceComp;
	private bool bIsActive = false;
	private bool bHasMesh = false;
	
	UPROPERTY()
	bool bHasPrePowerDownEvent = false;

	UFUNCTION(BlueprintOverride)
	void ParentSetup()
	{
		InterfaceComp = USkylineInterfaceComponent::Get(HazeOwner);
		devCheck(InterfaceComp != nullptr, f"No SkylineInterfaceComponent found on {HazeOwner} - SoundDef: {GetName()} will not work!");

		if(InterfaceComp != nullptr)
		{
			InterfaceComp.OnActivated.AddUFunction(this, n"OnInterfaceActivated");
			InterfaceComp.OnDeactivated.AddUFunction(this, n"OnInterfaceDeactivated");
		}

		bHasMesh = PlaneMesh != nullptr;
		bIsActive = bStartActivated;

		bHasPrePowerDownEvent = PulsePrePowerDownEvent != nullptr;	
	}

	UFUNCTION()
	void OnInterfaceActivated(AActor Caller)
	{
		bIsActive = true;
		OnPowerUp();
	}

	UFUNCTION()
	void OnInterfaceDeactivated(AActor Caller)
	{
		bIsActive = false;
		OnPowerDown();
	}

	UFUNCTION(BlueprintEvent)
	void OnPowerUp() {}

	UFUNCTION(BlueprintEvent)
	void OnPowerDown() {}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaSeconds)
	{
		if(!bIsActive)
			return;

		if(bHasMesh)
		{
			TArray<FAkSoundPosition> SoundPositions;

			for(auto Player : Game::GetPlayers())
			{
				if(!PlayerTrackEmitterPositions[Player])
					continue;

				FVector ClosestPlayerPos;
				const float Dist = PlaneMesh.GetClosestPointOnCollision(Player.ActorLocation, ClosestPlayerPos);
				if(Dist < 0)
					ClosestPlayerPos = PlaneMesh.WorldLocation;

				SoundPositions.Add(FAkSoundPosition(ClosestPlayerPos));
			}

			DefaultEmitter.AudioComponent.SetMultipleSoundPositions(SoundPositions);
		}
	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason EndPlayReason)
	{
		InterfaceComp.OnActivated.UnbindObject(this);
		InterfaceComp.OnDeactivated.UnbindObject(this);
	}

	UFUNCTION(BlueprintPure, Meta = (CompactNodeTitle = "Active Duration"))
	float GetActiveDuration()
	{
		auto ElectricBoxController = Cast<ASkylineBrokenElectricBox>(InterfaceComp.ListenToActors[0]);
		if(ElectricBoxController == nullptr)
			return -1;

		return ElectricBoxController.ActivationDuration;
	}

}