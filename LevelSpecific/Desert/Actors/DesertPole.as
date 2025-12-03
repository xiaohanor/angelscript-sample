class ADesertPole : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent Scene;

	UPROPERTY(DefaultComponent, Attach = Scene)
	UFauxPhysicsConeRotateComponent AxisRotateComp;

	UPROPERTY(EditAnywhere)
	APoleClimbActor Pole;

	UPROPERTY(EditAnywhere)
	ADesertPole AlignToDesertPole;

	UFauxPhysicsWeightComponent PlayerWeightComp;

	UPROPERTY(DefaultComponent, Attach = Root)
	UDesertSandHeightSampleComponent DesertSandHeightSampleComp;

	TPerPlayer<bool> IsPlayerClimbing;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		if (Pole != nullptr)
			Pole.AttachToComponent(AxisRotateComp);
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Pole.OnStartPoleClimb.AddUFunction(this,n"StartPoleClimb");
		Pole.OnStopPoleClimb.AddUFunction(this,n"StopPoleClimb");
	}

	UFUNCTION()
	private void StartPoleClimb(AHazePlayerCharacter Player, APoleClimbActor PoleClimbActor)
	{
		IsPlayerClimbing[Player] = true;
	}

	UFUNCTION()
	private void StopPoleClimb(AHazePlayerCharacter Player, APoleClimbActor PoleClimbActor)
	{
		IsPlayerClimbing[Player] = false;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		for(auto Player : Game::Players)
		{
			if(!IsPlayerClimbing[Player])
				continue;

			FVector PlayerPos = Player.ActorLocation;
			PlayerPos.Z = AxisRotateComp.WorldLocation.Z;

			FVector Force = ActorLocation - Player.ActorLocation;
			Force.Z = Force.Size();
			Force.Z /= Pole.Height;
			Force.Z *= -50;

			AxisRotateComp.ApplyForce(PlayerPos, Force);				
		}

		if(AlignToDesertPole != nullptr)
			LookAt(AlignToDesertPole.ActorLocation, DeltaSeconds);

	}

	UFUNCTION(BlueprintEvent)
	void LookAt(FVector Target, float DeltaSeconds) {	}
};