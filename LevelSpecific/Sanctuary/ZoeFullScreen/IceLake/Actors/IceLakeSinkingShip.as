UCLASS(Abstract)
class AIceLakeSinkingShip : AHazeActor
{
    UPROPERTY(DefaultComponent, RootComponent)
    USceneComponent Root;

    UPROPERTY(DefaultComponent, Attach = "Root")
    UStaticMeshComponent ShipMesh;

    UPROPERTY(DefaultComponent, Attach = "ShipMesh")
    UStaticMeshComponent MastMesh;

    UPROPERTY(DefaultComponent, Attach = "MastMesh")
    USceneComponent PoleParent;

    UPROPERTY(DefaultComponent)
    UWindDirectionResponseComponent WindDirectionResponseComp;

    UPROPERTY(EditDefaultsOnly, Category = "Ice Lake Sinking Ship|Pole Climb")
	TSubclassOf<APoleClimbActor> PoleClimbActorClass;
	APoleClimbActor PoleClimbActor;

    UPROPERTY(EditDefaultsOnly, Category = "Ice Lake Sinking Ship|Pole Climb")
	float ClimbableHeight = 1000;

    bool bIsSinking = false;
    bool bIsClimbingPole = false;

    UPROPERTY(EditInstanceOnly)
    TArray<AHazeActor> OtherSinkingActors;

    UPROPERTY(EditDefaultsOnly, Category = "Ice Lake Sinking Ship")
    UNiagaraSystem SinkingSplash_Sys;
    UNiagaraComponent SplashingComp;

    UPROPERTY(EditDefaultsOnly, Category = "Ice Lake Sinking Ship")
    float StartSinkSpeed = 1.0 / 60.0;

    UPROPERTY(EditDefaultsOnly, Category = "Ice Lake Sinking Ship")
    float PoleSinkSpeed = 1.0 / 20.0;

    FHazeAcceleratedFloat AccSinking;

    FVector TargetBend;
    FHazeAcceleratedVector AccBend;

    UPROPERTY(EditDefaultsOnly, Category = "Ice Lake Sinking Ship")
	float BendStiffness = 10;

	UPROPERTY(EditDefaultsOnly, Category = "Ice Lake Sinking Ship")
	float BendDamping = 0.6;

	UPROPERTY(EditDefaultsOnly, Category = "Ice Lake Sinking Ship")
	float BendAmount = 50.0;

    UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
        PoleClimbActor = SpawnActor(PoleClimbActorClass, PoleParent.WorldLocation, PoleParent.WorldRotation, NAME_None, true);
		PoleClimbActor.AttachToComponent(PoleParent);
		PoleClimbActor.bShouldValidatePlayerPoleWorldUp = false;
        PoleClimbActor.bAllowPerchOnTop = true;
		PoleClimbActor.Height = ClimbableHeight;
		PoleClimbActor.SetActorHiddenInGame(true);
		FinishSpawningActor(PoleClimbActor);

        WindDirectionResponseComp.OnWindDirectionChanged.AddUFunction(this, n"OnWindDirectionChanged");
        PoleClimbActor.OnStartPoleClimb.AddUFunction(this, n"OnStartClimbingMast");
    }

    UFUNCTION(BlueprintOverride)
    void Tick(float DeltaSeconds)
    {
		AccBend.SpringTo(TargetBend, BendStiffness, BendDamping, DeltaSeconds);

		FRotator Rotation = FRotator(AccBend.Value.X * -BendAmount, 0.0, AccBend.Value.Y * BendAmount);
        Rotation = ActorTransform.InverseTransformRotation(Rotation.Quaternion()).Rotator();
        ShipMesh.SetRelativeRotation(Rotation);

        if(!bIsSinking)
            return;

        float SinkDuration = (bIsClimbingPole ? PoleSinkSpeed : StartSinkSpeed) / 100.0;
        AccSinking.AccelerateTo(-1200, 1.0 / SinkDuration, DeltaSeconds);
        FVector SinkDelta = FVector(0, 0, AccSinking.Velocity * DeltaSeconds);

        AddActorWorldOffset(SinkDelta);
        for(auto Actor : OtherSinkingActors)
            Actor.AddActorWorldOffset(SinkDelta);
    }

    UFUNCTION(BlueprintCallable)
    void StartSinking()
    {
        if(bIsSinking)
            return;

        bIsSinking = true;
        SplashingComp = Niagara::SpawnLoopingNiagaraSystemAttached(SinkingSplash_Sys, Root);

        Timer::SetTimer(this, n"StopSinking", 60);
    }

    UFUNCTION(NotBlueprintCallable)
    void StopSinking()
    {
        if(SplashingComp != nullptr)
            SplashingComp.Deactivate();
    }

    UFUNCTION(NotBlueprintCallable)
    void OnStartClimbingMast(AHazePlayerCharacter Player, APoleClimbActor PoleActor)
    {
        bIsClimbingPole = true;
    }

    UFUNCTION()
    void OnWindDirectionChanged(FVector InWindDirection, FVector InLocation)
    {
        TargetBend = InWindDirection;
    }
}