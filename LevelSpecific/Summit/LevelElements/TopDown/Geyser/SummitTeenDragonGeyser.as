class USummitTeenDragonGeyserComponent : USceneComponent
{

}

class ASummitTeenDragonGeyser : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UHazeSphereCollisionComponent OverlapSphere;

	UPROPERTY(DefaultComponent, Attach = OverlapSphere)
	USummitTeenDragonGeyserComponent LaunchDirection;

    UPROPERTY(EditAnywhere, Category = "Settings")
    float ImpulseForce = 5000;

	UPROPERTY(EditAnywhere, Category = "Settings")
	float LaunchCooldown = 3.0;

	/** If it should force the tail dragon to keep rolling until they hit a wall */
	UPROPERTY(EditAnywhere, Category = "Settings")
	bool bForceRollingUntilImpact = true;

	UPROPERTY(EditAnywhere, Category = "Visualizer Settings")
	float VisualizeDuration = 3.0;

	UPROPERTY(EditAnywhere, Category = "Visualizer Settings")
	float DragonGravityMagnitude = 6750.0;

	float TimeLastLaunched = -MAX_flt;

	UPROPERTY()
	bool bHasBeenActivated;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		OverlapSphere.OnComponentBeginOverlap.AddUFunction(this, n"OnBeginOverlap");

		SetActorControlSide(Game::GetZoe());
	}

	UFUNCTION()
	private void OnBeginOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor,
	                                     UPrimitiveComponent OtherComp, int OtherBodyIndex,
	                                     bool bFromSweep, const FHitResult&in SweepResult)
	{
		if(Time::GetGameTimeSince(TimeLastLaunched) < LaunchCooldown)
			return;

		AHazePlayerCharacter PlayerOverlapping = Cast<AHazePlayerCharacter>(OtherActor);

		// Overlapped with non player character
		if(PlayerOverlapping == nullptr)
			return;

		UTeenDragonRollComponent RollComp = UTeenDragonRollComponent::Get(PlayerOverlapping);
		// Overlapped with a player without roll comp (probably the acid dragon)
		if(RollComp == nullptr)
			return;

		if(!RollComp.IsRolling())
			return;
		
		if(HasControl())
			CrumbLaunchPlayer(PlayerOverlapping, RollComp);
	}	

	UFUNCTION(NotBlueprintCallable, CrumbFunction)
	private void CrumbLaunchPlayer(AHazePlayerCharacter PlayerToLaunch, UTeenDragonRollComponent RollComp)
	{
		if (bHasBeenActivated)
			return;

		PlayerToLaunch.SetActorVelocity(FVector::ZeroVector);
		FVector Impulse;
		Impulse += LaunchDirection.ForwardVector * ImpulseForce;
		PlayerToLaunch.AddMovementImpulse(Impulse, TeenDragonCapabilityTags::TeenDragonRollImpulseBlockAirControl);
		bHasBeenActivated = true;
		BP_OnPlayerLaunched();

		if(bForceRollingUntilImpact)
			RollComp.RollUntilImpactInstigators.AddUnique(this);

		TimeLastLaunched = Time::GetGameTimeSeconds();

		USummitTeenDragonGeyserEventHandler::Trigger_OnExploded(this);
	}

	UFUNCTION()
	void StartRegrow()
	{
		bHasBeenActivated = false;
		BP_StartRegrow();
	}

	UFUNCTION(BlueprintEvent)
	void BP_OnPlayerLaunched()
	{}

	UFUNCTION(BlueprintEvent)
	void BP_StartRegrow()
	{}

	UFUNCTION(BlueprintCallable)
	void OnRegrowStarted()
	{
		USummitTeenDragonGeyserEventHandler::Trigger_OnRegrowStart(this);
	}

	UFUNCTION(BlueprintCallable)
	void OnRegrowEnd()
	{
		USummitTeenDragonGeyserEventHandler::Trigger_OnRegrowEnd(this);
	}
}

#if EDITOR
class USummitTeenDragonGeyserComponentVisualizer : UHazeScriptComponentVisualizer
{
	default VisualizedClass = USummitTeenDragonGeyserComponent;

	const float DragonCapsuleRadius = 130.0;

	FVector SimulatedLocation;
	FVector SimulatedVelocity;  
	float LastTimeStamp;
	float ElapsedTime;

	UFUNCTION(BlueprintOverride)
	void VisualizeComponent(const UActorComponent Component)
	{
		auto Comp = Cast<USummitTeenDragonGeyserComponent>(Component);
		auto Geyser = Cast<ASummitTeenDragonGeyser>(Component.Owner);
		if(!ensure((Comp != nullptr) && (Geyser != nullptr)))
			return;
		
		VisualizeLaunchDirection(Geyser);
		VisualizeLaunch(Geyser);
	}

	void VisualizeLaunchDirection(ASummitTeenDragonGeyser Geyser)
	{
		DrawArrow(Geyser.LaunchDirection.WorldLocation, Geyser.LaunchDirection.WorldLocation + Geyser.LaunchDirection.ForwardVector * Geyser.ImpulseForce, FLinearColor::Red, 80, 40, false);
	}

	void VisualizeLaunch(ASummitTeenDragonGeyser Geyser)
	{
		float TimeStamp = Time::GameTimeSeconds;
		float DeltaTime = TimeStamp - LastTimeStamp;
		LastTimeStamp = TimeStamp;

		ElapsedTime += DeltaTime;

		if(ElapsedTime > Geyser.VisualizeDuration)
			RestartSimulation(Geyser);

		SimulatedVelocity += FVector::DownVector * Geyser.DragonGravityMagnitude * DeltaTime;
		SimulatedLocation += SimulatedVelocity * DeltaTime;

		DrawWireSphere(SimulatedLocation, DragonCapsuleRadius, FLinearColor::Green, 10, 12, false);
	}

	void RestartSimulation(ASummitTeenDragonGeyser Geyser)
	{
		ElapsedTime = 0.0;
		SimulatedLocation = Geyser.LaunchDirection.WorldLocation;
		SimulatedVelocity = Geyser.LaunchDirection.ForwardVector * Geyser.ImpulseForce;
	}
}
#endif