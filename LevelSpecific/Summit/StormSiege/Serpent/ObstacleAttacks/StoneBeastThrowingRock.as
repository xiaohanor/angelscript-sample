//TODO Behaviour for beam link + movement to target + throwing at player
class AStoneBeastThrowingRock : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = Root)
	UNiagaraComponent LightningComp;
	default LightningComp.SetAutoActivate(false);

	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComp;
	default CapabilityComp.DefaultCapabilities.Add(n"StoneBeastThrowingRockMoveCapability");

	UPROPERTY(DefaultComponent)
	UWindTunnelRotationComponent RotationComp;
	default RotationComp.bStartActive = false;
	default RotationComp.RotationPerSecond = FRotator(0.0, 120.0, 0.0);

	UPROPERTY(EditAnywhere)
	ASerpentEventActivator SerpentEvent;

	UPROPERTY(EditAnywhere)
	EHazeSelectPlayer Target;

	UPROPERTY(DefaultComponent)
	UAdultDragonTakeDamageKillComponent DragonKillResponseComp;

	FVector AuraStartingScale;

	AHazePlayerCharacter TargetPlayer;

	ASerpentHead SerpentHead;

	FVector GoToLoc;
	float RandomOffsetAmount = 1000.0;

	bool bRockActive;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SerpentHead = TListedActors<ASerpentHead>().GetSingle();
		SerpentEvent.OnSerpentEventTriggered.AddUFunction(this, n"OnSerpentEventTriggered");
	}

	UFUNCTION()
	private void OnSerpentEventTriggered()
	{
		ActivateThrowingRock();
	}

	UFUNCTION()
	void ActivateThrowingRock()
	{
		if (Target == EHazeSelectPlayer::Mio)
			TargetPlayer = Game::Mio;
		else
			TargetPlayer = Game::Zoe;

		GoToLoc = SerpentHead.ActorLocation;
		GoToLoc += ActorForwardVector * Math::RandRange(-RandomOffsetAmount, RandomOffsetAmount);
		GoToLoc += ActorRightVector * Math::RandRange(-RandomOffsetAmount, RandomOffsetAmount);
		GoToLoc += ActorUpVector * Math::RandRange(-RandomOffsetAmount, RandomOffsetAmount);
		bRockActive = true;
	}

	void UpdateLoopingLighting()
	{
		LightningComp.SetFloatParameter(n"BeamWidth", 1.0);
		LightningComp.SetFloatParameter(n"JitterWidth", 1.0);
		LightningComp.SetNiagaraVariableVec3("End", SerpentHead.ActorLocation);
	}
};