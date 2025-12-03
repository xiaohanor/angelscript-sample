UCLASS(Abstract)
class AAITundraGnatapult : ABasicAICharacter
{
	default CapabilityComp.DefaultCapabilities.Add(n"TundraGnatMovementCapability"); 
	default CapabilityComp.DefaultCapabilities.Add(n"TundraGnatClimbingMovementCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"TundraGnatBeaverSpearMovementCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"TundraGnatapultBehaviourCompoundCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"TundraGnatSquashedReactionCapability");

	UPROPERTY(DefaultComponent)
	UTundraGnatComponent GnatComp;

	UPROPERTY(DefaultComponent)
	UTundraPlayerSnowMonkeyGroundSlamResponseComponent SquashComp;

	UPROPERTY(DefaultComponent, Attach = "CharacterMesh0")
	UTundraGnatapultProjectileLauncherComponent Launcher;
	default Launcher.RelativeLocation = FVector(150.0, 0.0, 10.0);

	uint HideFrame;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		// Let's see how well the monkey likes someone else flingin poo
		TargetingComponent.SetTarget(Game::Mio);
		RespawnComp.OnPostRespawn.AddUFunction(this, n"OnRespawn");

		// Set control side matching squasher monkey for best fidelity.
		SetActorControlSide(Game::Mio);

		// We can climb anywhere!
		UMovementStandardSettings::SetWalkableSlopeAngle(this, 89.0, this, EHazeSettingsPriority::Defaults);

		// Only use front climb entry points
		UTundraGnatSettings::SetClimbEntryFrontOnly(this, true, this);	

		Super::BeginPlay();
	}

	UFUNCTION(NotBlueprintCallable)
	private void OnRespawn()
	{
		// Always go for the tree man girl
		TargetingComponent.SetTarget(Game::Zoe);

		// Respawning gnat is hidden a few frames since it may be repositioned at most two frames after spawn
		AddActorVisualsBlock(this);
		HideFrame = Time::FrameNumber;
		Timer::SetTimer(this, n"SpawnUnhide", 0.1);
	}

	UFUNCTION(NotBlueprintCallable)
	private void SpawnUnhide()
	{
		if (Time::FrameNumber > HideFrame + 2)
			RemoveActorVisualsBlock(this);
		else
			Timer::SetTimer(this, n"SpawnUnhide", 0.1);
	}
}
