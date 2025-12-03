class ASummitTopDownBossLineAttack : AHazeActor
{

    UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

    UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent Actor1;

    UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent Actor2;

    UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent Actor3;

    UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent Actor4;

    UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent Actor5;

    UPROPERTY(EditAnywhere, meta = (ClampMin="1", ClampMax="2"))
    int Type = 1;

    UPROPERTY()
    TSubclassOf<ASummitTopDownBossGemPart> GemActor;

    UPROPERTY()
    TSubclassOf<ANightQueenMetalSpike> MetalActor;

    float SpawnDelay = 0.8;
    float SpawnDelayTimer;
    bool bFinished;
    int DelayCount = 1;

    UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
        SpawnDelayTimer = SpawnDelay;
    }

    UFUNCTION(BlueprintOverride)
    void Tick(float DeltaSeconds)
    {
        if (bFinished)
            return;

        if (Type == 1 && DelayCount != 6)
        {
            SpawnDelayTimer = SpawnDelayTimer - DeltaSeconds;
            if (SpawnDelayTimer <= 0)
            {
                SpawnDelayTimer = SpawnDelay;
                if (DelayCount == 1)
                {
                    DelayCount = 2;
                    AActor SpawnedActor1 = SpawnActor(GemActor, Actor1.WorldLocation, Actor1.WorldRotation);
                    SpawnedActor1.AttachToComponent(Actor1);
                    return;
                    
                }
                if (DelayCount == 2)
                {
                    DelayCount = 3;
                    AActor SpawnedActor2 = SpawnActor(GemActor, Actor2.WorldLocation, Actor2.WorldRotation);
                    SpawnedActor2.AttachToComponent(Actor2);
                    return;
                }
                if (DelayCount == 3)
                {
                    DelayCount = 4;
                    AActor SpawnedActor3 = SpawnActor(GemActor, Actor3.WorldLocation, Actor3.WorldRotation);
                    SpawnedActor3.AttachToComponent(Actor3);
                    return;
                }
                if (DelayCount == 4)
                {
                    DelayCount = 5;
                    AActor SpawnedActor4 = SpawnActor(GemActor, Actor4.WorldLocation, Actor4.WorldRotation);
                    SpawnedActor4.AttachToComponent(Actor4);
                    return;
                }
                if (DelayCount == 5)
                {
                    DelayCount = 6;
                    AActor SpawnedActor5 = SpawnActor(GemActor, Actor5.WorldLocation, Actor5.WorldRotation);
                    SpawnedActor5.AttachToComponent(Actor5);
                    bFinished = true;
                    return;
                }
            }

        }

        // if (Type == 2 && DelayCount != 6)
        // {
        //     SpawnDelayTimer = SpawnDelayTimer - DeltaSeconds;
        //     if (SpawnDelayTimer <= 0)
        //     {
        //         SpawnDelayTimer = SpawnDelay;
        //         if (DelayCount == 1)
        //         {
        //             DelayCount = 2;
        //             AActor SpawnedMetalActor1 = SpawnActor(MetalActor, Actor1.WorldLocation, Actor1.WorldRotation);
        //             SpawnedMetalActor1.AttachToComponent(Actor1);
        //             return;
                    
        //         }
        //         if (DelayCount == 2)
        //         {
        //             DelayCount = 3;
        //             AActor SpawnedMetalActor2 = SpawnActor(MetalActor, Actor2.WorldLocation, Actor2.WorldRotation);
        //             SpawnedMetalActor2.AttachToComponent(Actor2);
        //             return;
        //         }
        //         if (DelayCount == 3)
        //         {
        //             DelayCount = 4;
        //             AActor SpawnedMetalActor3 = SpawnActor(MetalActor, Actor3.WorldLocation, Actor3.WorldRotation);
        //             SpawnedMetalActor3.AttachToComponent(Actor3);
        //             return;
        //         }
        //         if (DelayCount == 4)
        //         {
        //             DelayCount = 5;
        //             AActor SpawnedMetalActor4 = SpawnActor(MetalActor, Actor4.WorldLocation, Actor4.WorldRotation);
        //             SpawnedMetalActor4.AttachToComponent(Actor4);
        //             return;
        //         }
        //         if (DelayCount == 5)
        //         {
        //             DelayCount = 6;
        //             AActor SpawnedMetalActor5 = SpawnActor(MetalActor, Actor5.WorldLocation, Actor5.WorldRotation);
        //             SpawnedMetalActor5.AttachToComponent(Actor5);
        //             bFinished = true;
        //             return;
        //         }
        //     }
        // }

    }
}