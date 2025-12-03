class AIceFractalSpawner : AHazeActor
{
    UPROPERTY(DefaultComponent, RootComponent)
    UBillboardComponent Root;

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedComponent;

    float CurrentTime;
    float NextSpawnTime;
    float PlayerDistanceAlpha;

    protected TArray<AIceFractal> FractalPool;

    UPROPERTY(EditInstanceOnly)
    AIceFractal MinIceFractal;

    UPROPERTY(EditInstanceOnly)
    AIceFractal MaxIceFractal;

    UPROPERTY(EditInstanceOnly)
    AIceFractalMovementPlane MovementPlane;

    UPROPERTY(EditDefaultsOnly)
    UIceFractalSettings Settings;

    FVector PlayerPreviousLocationOnPlane;

    UFUNCTION(BlueprintOverride)
    void ConstructionScript()
    {
        if(MinIceFractal != nullptr)
        {
            MinIceFractal.SetActorScale3D(FVector::OneVector);
            MinIceFractal.SetActorLocation(ActorLocation);
        }

        if(MaxIceFractal != nullptr && Settings != nullptr)
        {
            MaxIceFractal.SetActorLocation(ActorLocation + FVector(0.0, 0.0, Settings.MaxHeightOffset));
            MaxIceFractal.SetActorScale3D(FVector(Settings.MaxScale, Settings.MaxScale, 1.0));
        }

        if(MovementPlane != nullptr)
        {
            MovementPlane.Mesh.SetbVisible(Settings.bUseStaticMovementPlane);
            MovementPlane.Mesh.MarkRenderStateDirty();
        }
    }

    UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
        if(Settings == nullptr)
        {
            PrintError("Assign a settings asset to IceFractalSpawner!");
            return;
        }

        CurrentTime = Time::GameTimeSeconds;

        float InitialSpawnTime = 0.0;
        while(InitialSpawnTime < Settings.LifeTime)
        {
            AIceFractal IceFractal = GetPooledIceFractal();
            if(IceFractal != nullptr)
                IceFractal.Initialize(InitialSpawnTime);

            InitialSpawnTime += Settings.SpawnInterval;
        }

        PlayerPreviousLocationOnPlane = FVector(Game::Zoe.ActorLocation.X, Game::Zoe.ActorLocation.Y, 0.0);

        if(MinIceFractal != nullptr)
        {
            MinIceFractal.SetActorScale3D(FVector::OneVector);
            MinIceFractal.SetActorLocation(ActorLocation);
            MinIceFractal.AttachToActor(this, NAME_None, EAttachmentRule::KeepWorld);
        }

        if(MaxIceFractal != nullptr && Settings != nullptr)
        {
            MaxIceFractal.SetActorLocation(ActorLocation + FVector(0.0, 0.0, Settings.MaxHeightOffset));
            MaxIceFractal.SetActorScale3D(FVector(Settings.MaxScale, Settings.MaxScale, 1.0));
            MaxIceFractal.AttachToActor(this, NAME_None, EAttachmentRule::KeepWorld);
        }

        if(MovementPlane != nullptr && !Settings.bUseStaticMovementPlane)
        {
            MovementPlane.DestroyActor();
            MovementPlane = nullptr;
        }
    }

    UFUNCTION(BlueprintOverride)
    void Tick(float DeltaSeconds)
    {
        const FVector SpawnerLocationOnPlane = FVector(ActorLocation.X, ActorLocation.Y, 0.0);
        const FVector PlayerLocationOnPlane = FVector(Game::Zoe.ActorLocation.X, Game::Zoe.ActorLocation.Y, 0.0);

        if(Settings == nullptr)
        {
            PrintError("Assign a settings asset to IceFractalSpawner!", 0.0);
            return;
        }

        if(Settings.bKeepDistanceFromPlayer)
        {
            const FVector PlayerDeltaOnPlane = PlayerLocationOnPlane - PlayerPreviousLocationOnPlane;
            const FVector FromPlayerToSpawner = (SpawnerLocationOnPlane - PlayerLocationOnPlane).GetSafeNormal();
            const FVector DeltaTowardsSpawner = PlayerDeltaOnPlane.ProjectOnToNormal(FromPlayerToSpawner);

            if(SpawnerLocationOnPlane.Distance(PlayerLocationOnPlane) < Settings.KeepDistanceDistance && DeltaTowardsSpawner.DotProduct(FromPlayerToSpawner) > 0.0)
                AddActorWorldOffset(DeltaTowardsSpawner);
        }

        PlayerPreviousLocationOnPlane = PlayerLocationOnPlane;

        if(Settings.bConstantSpeed)
        {
            CurrentTime += Settings.Speed * DeltaSeconds;
        }
        else
        {
            if(Settings.SpeedCurve == nullptr)
            {
                PrintError("Assign a SpeedCurve asset in IceFractalSettings!", 0.0);
                return;
            }

            PlayerDistanceAlpha = 1.0 - Math::Saturate(SpawnerLocationOnPlane.Distance(PlayerLocationOnPlane) / Settings.MaxDistance);
            const float Speed = Math::Lerp(Settings.MinSpeed, Settings.MaxSpeed, Settings.SpeedCurve.GetFloatValue(PlayerDistanceAlpha));
            CurrentTime += Speed * DeltaSeconds;
        }

        while(NextSpawnTime < CurrentTime)
        {
            AIceFractal IceFractal = GetPooledIceFractal();

            if(IceFractal != nullptr)
                IceFractal.Initialize(0.0);

            NextSpawnTime += Settings.SpawnInterval;
        }
    }

    private AIceFractal GetPooledIceFractal()
    {
        if(!Settings.IceFractalClass.IsValid())
        {
            PrintError("Assign a IceFractalClass in IceFractalSpawner!");
            return nullptr;
        }

        if(FractalPool.Num() == 0)
        {
            AIceFractal IceFractal = SpawnActor(Settings.IceFractalClass, ActorLocation, ActorRotation, NAME_None, true);
            IceFractal.Spawner = this;
            IceFractal.AttachToActor(this, NAME_None, EAttachmentRule::KeepWorld);
            FinishSpawningActor(IceFractal);
            return IceFractal;
        }
        
        AIceFractal IceFractal = FractalPool[FractalPool.Num() - 1];
        FractalPool.RemoveAtSwap(FractalPool.Num() - 1);

        IceFractal.RemoveActorTickBlock(this);
        IceFractal.RemoveActorCollisionBlock(this);
        IceFractal.RemoveActorVisualsBlock(this);

        return IceFractal;
    }

    void AddToIceFractalPool(AIceFractal IceFractal)
    {
        check(IceFractal != nullptr);

        IceFractal.AddActorTickBlock(this);
        IceFractal.AddActorCollisionBlock(this);
        IceFractal.AddActorVisualsBlock(this);
        FractalPool.Add(IceFractal);
    }
}