UCLASS(Abstract)
class AWeightPole : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UFauxPhysicsTranslateComponent TranslateComp;
	
	UPROPERTY(DefaultComponent, Attach = TranslateComp)
	UArrowComponent ForceDirection;

	UPROPERTY(EditAnywhere, Category = "Settings | Defaults")
	float Force = 1000;

	UPROPERTY(EditAnywhere, Category = "Settings | Defaults")
	bool bPoleReturn = true;
	
	UPROPERTY(EditAnywhere, Category = "Settings | Pole Actor")
	APoleClimbActor Pole;

	AHazePlayerCharacter Zoe;
	AHazePlayerCharacter Mio;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Pole.OnStartPoleClimb.AddUFunction(this, n"StartPoleClimb");
		Pole.OnStopPoleClimb.AddUFunction(this, n"StopPoleClimb");

		Pole.AttachToComponent(TranslateComp);
	}

	UFUNCTION()
	private void StartPoleClimb(AHazePlayerCharacter Player, APoleClimbActor PoleClimbActor)
	{
		if(Player.IsMio())
		Mio = Player;
		else
		Zoe = Player;
	}

	UFUNCTION()
	private void StopPoleClimb(AHazePlayerCharacter Player, APoleClimbActor PoleClimbActor)
	{
		if(Player.IsMio())
		Mio = nullptr;
		else
		Zoe = nullptr;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(Mio != nullptr || Zoe != nullptr)
			TranslateComp.ApplyForce(ForceDirection.WorldLocation, ForceDirection.ForwardVector*Force);
		else if(bPoleReturn)
			TranslateComp.ApplyForce(ForceDirection.WorldLocation, ForceDirection.ForwardVector*-Force);
	}
};
