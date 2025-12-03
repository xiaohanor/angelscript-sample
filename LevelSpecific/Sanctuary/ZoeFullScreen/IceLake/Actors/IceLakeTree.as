UCLASS(Abstract)
class AIceLakeTree : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;
	default Root.Mobility = EComponentMobility::Movable;

	UPROPERTY(DefaultComponent, Attach = "Root")
	UStaticMeshComponent Mesh;
	default Mesh.CollisionEnabled = ECollisionEnabled::NoCollision;

	UPROPERTY(DefaultComponent, Attach = "Mesh")
	USceneComponent PoleParent;

	UPROPERTY(DefaultComponent)
	UWindDirectionResponseComponent WindDirectionResponseComp;

	UPROPERTY(EditAnywhere, Category = "Ice Lake Tree")
	float BendStiffness = 10;

	UPROPERTY(EditAnywhere, Category = "Ice Lake Tree")
	float BendDamping = 0.6;

	UPROPERTY(EditAnywhere, Category = "Ice Lake Tree")
	float BendAmount = 50.0;

	UPROPERTY(EditAnywhere, Category = "Ice Lake Tree|Pole Climb")
	TSubclassOf<APoleClimbActor> PoleClimbActorClass;
	APoleClimbActor PoleClimbActor;

	UPROPERTY(EditAnywhere, Category = "Ice Lake Tree|Pole Climb")
	float ClimbableHeight = 1000.0;

	FHazeAcceleratedVector AccBend;
	FVector TargetBend;

	FRotator StartRotation;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		WindDirectionResponseComp.OnWindDirectionChanged.AddUFunction(this, n"OnWindDirectionChanged");

		PoleClimbActor = SpawnActor(PoleClimbActorClass, PoleParent.WorldLocation, PoleParent.WorldRotation, NAME_None, true);
		PoleClimbActor.AttachToComponent(PoleParent);
		PoleClimbActor.bShouldValidatePlayerPoleWorldUp = false;
		PoleClimbActor.Height = ClimbableHeight;
		PoleClimbActor.SetActorHiddenInGame(true);
		FinishSpawningActor(PoleClimbActor);

		StartRotation = ActorRotation;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		AccBend.SpringTo(TargetBend, BendStiffness, BendDamping, DeltaSeconds);

		FRotator Rotation = FRotator(AccBend.Value.X * -BendAmount, 0.0, AccBend.Value.Y * BendAmount);
		SetActorRotation(StartRotation.Compose(Rotation));
	}

	UFUNCTION()
	void OnWindDirectionChanged(FVector WindDirection, FVector Location)
	{
		TargetBend = WindDirection;
	}
};