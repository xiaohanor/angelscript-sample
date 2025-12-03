class ASummitTopDownBoss : AHazeActor
{

    UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

    UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent BossRoot;

    UPROPERTY(DefaultComponent, Attach = BossRoot)
	USceneComponent BossMesh;

    UPROPERTY(DefaultComponent, Attach = BossMesh)
	UHazeSkeletalMeshComponentBase SkelMesh;

    UPROPERTY(DefaultComponent, Attach = BossRoot)
	USceneComponent BossVechile;

    UPROPERTY(DefaultComponent, Attach = BossRoot)
	USceneComponent BossShield;

    UPROPERTY(DefaultComponent, Attach = BossRoot)
	USceneComponent LaserPivot;

    UPROPERTY(DefaultComponent, Attach = LaserPivot)
	USceneComponent Laser1;

    UPROPERTY(DefaultComponent, Attach = LaserPivot)
	USceneComponent Laser2;

    UPROPERTY(DefaultComponent, Attach = LaserPivot)
	USceneComponent Laser3;

    UPROPERTY(DefaultComponent, Attach = LaserPivot)
	USceneComponent Laser4;

    UPROPERTY(Category = "Animation Settings")
	UAnimSequence ThrowAnim;
	UPROPERTY(Category = "Animation Settings")
	UAnimSequence Idle;
	UPROPERTY(Category = "Animation Settings")
	UAnimSequence ChargeAnim;

    UPROPERTY(Category = "Begin Settings")
    float PhaseSwitchCoolDown = 3;
    float PhaseSwitchTimer = PhaseSwitchCoolDown;

    UPROPERTY(EditAnywhere, Category = "Phase 1 Settings")
    TArray<ASummitTopDownBossPlatform> Platforms;
    UPROPERTY(BlueprintReadOnly)
    int PlaftormCount;
    UPROPERTY(BlueprintReadWrite)
    bool bPhaseCompleted;
    UPROPERTY(BlueprintReadWrite)
    int PlatformX = 0;

    UPROPERTY(EditAnywhere, Category = "Phase 1 Settings")
    float PhaseOneAttackCoolDown = 1; 
    float PhaseOneAttackCoolDownTimer; 

    UPROPERTY(EditAnywhere, Category = "Phase 1 Settings")
	TSubclassOf<ASummitMagicTrajectoryProjectile> ProjectileClass;

    UPROPERTY(Category = "Phase 2 Settings")
    float PhaseTwoDuration = 10;
    float PhaseTwoTimer;

    UPROPERTY(Category = "Phase 2 Settings")
    float LaserSpeed = 0.15;

    UPROPERTY(Category = "Phase 2 Settings")
    TSubclassOf<ASummitTopDownBossLineAttack> LineGemAttack;
    UPROPERTY(Category = "Phase 2 Settings")
    TSubclassOf<ASummitTopDownBossLineAttack> LineMetalAttack;

    AActor LineAttackActor;
    AActor LineAttackActor2;
    AActor LineAttackActor3;
    AActor LineAttackActor4;

    int Phase = 0;
    int NextPhase = 1;
    int Attack = 1;
    bool bPhaseActivated;

    UPROPERTY(BlueprintReadWrite)
    bool bActivated;

    UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
        PlaftormCount = Platforms.Num();
        PhaseOneAttackCoolDownTimer = PhaseOneAttackCoolDown;
        PhaseTwoTimer = PhaseTwoDuration;
        // Activate();
    }

    UFUNCTION(BlueprintOverride)
    void Tick(float DeltaSeconds)
    {
        if (!bActivated)
            return;

        // PrintToScreen("Phase: " + Phase + "", 0.1);
        // BossShield.AddRelativeRotation(FRotator(0, 0.1, 0));

        if (Phase == 0)
        {
            PhaseSwitchTimer = PhaseSwitchTimer - DeltaSeconds;
            
            if (PhaseSwitchTimer <= 0)
            {
                BP_PhaseSwitch();
                ActivatePhase(NextPhase);
                PhaseSwitchTimer = PhaseSwitchCoolDown;
                return;
            }
        }

        if (!bPhaseActivated)
            return;

        if (Phase == 1)
        {

            PhaseOneAttackCoolDownTimer = PhaseOneAttackCoolDownTimer - DeltaSeconds;

            if (PhaseOneAttackCoolDownTimer <= 0) 
            {
                PhaseOneAttackCoolDownTimer = PhaseOneAttackCoolDown;
                if (!bPhaseCompleted)
                {

                    if (PlatformX < PlaftormCount) {

                        FRotator RotTarget = (Platforms[PlatformX].ActorLocation - BossShield.WorldLocation).Rotation();

                        ASummitMagicTrajectoryProjectile Proj = SpawnActor(ProjectileClass, BossShield.WorldLocation, RotTarget, bDeferredSpawn = true);
                        Proj.IgnoreActors.Add(this);
                        Proj.TargetLocation = Platforms[PlatformX].ActorLocation;
                        Proj.Speed = 8100.0;
                        Proj.Gravity = 2200.0;
                        FinishSpawningActor(Proj);

                        BP_PhaseOne();
                        PlayThrowAnimation();

                    } 
                    else
                    {
                        DeactivatePhase(1);
                    }

                }
            }
        }

        if (Phase == 2)
        {
            if (bPhaseCompleted)
            {
                Phase = 0;
                NextPhase = 3;
            }

            // LaserPivot.AddRelativeRotation(FRotator(0, LaserSpeed, 0));
            // BossVechile.AddRelativeRotation(FRotator(0, LaserSpeed, 0));
            // BossMesh.AddRelativeRotation(FRotator(0, (LaserSpeed / 2) * -1, 0));

            PhaseTwoTimer = PhaseTwoTimer - DeltaSeconds;
            if (PhaseTwoTimer <= 0)
            {
                DeactivatePhase(2);
            }
        }

        if (Phase == 3)
        {
            BossMesh.AddRelativeRotation(FRotator(0, (LaserSpeed / 2) * -1, 0));

            for (auto Platform : Platforms)
		    {
                if (!Platform.bIsActive)
                    Platform.Reverse();
		    }

            bPhaseCompleted = true;
            Phase = 0;
            NextPhase = 1;
            bPhaseActivated = false;

        }
    }

    UFUNCTION()
    void Activate()
    {
        bActivated = true;
        BP_Activate();
        PlayIdleAnimation();
    }

    UFUNCTION()
    void ActivatePhase(int PhaseToActivate)
    {
        Phase = PhaseToActivate;

        if (Phase == 1)
        {
        }

        if (Phase == 2)
        {
            LineAttackActor = SpawnActor(LineGemAttack, Laser1.WorldLocation, Laser1.WorldRotation);
            // LineAttackActor2 = SpawnActor(LineGemAttack, Laser2.WorldLocation, Laser2.WorldRotation);
            // LineAttackActor3 = SpawnActor(LineMetalAttack, Laser3.WorldLocation, Laser3.WorldRotation);
            // LineAttackActor4 = SpawnActor(LineMetalAttack, Laser4.WorldLocation, Laser4.WorldRotation);

            LineAttackActor.AttachToComponent(Laser1);
            // LineAttackActor2.AttachToComponent(Laser2);
            // LineAttackActor3.AttachToComponent(Laser3);
            // LineAttackActor4.AttachToComponent(Laser4);

            PhaseTwoTimer = PhaseTwoDuration;
            PlayThrowAnimation();
        }

        if (Phase == 3)
        {

            PlayThrowAnimation();
            
            
        }

        bPhaseActivated = true;
        bPhaseCompleted = false;
        
    }

    UFUNCTION()
    void DeactivatePhase(int PhaseToDeactivate)
    {
        bPhaseActivated = false;

        if (PhaseToDeactivate == 1)
        {
            bPhaseCompleted = true;
            Phase = 0;
            NextPhase = 2;
            PlatformX = 0;
        }

        if (PhaseToDeactivate == 2)
        {
            bPhaseCompleted = true;
            Phase = 0;
            NextPhase = 3;
            if (LineAttackActor != nullptr)
                LineAttackActor.DestroyActor();
            if (LineAttackActor2 != nullptr)
                LineAttackActor2.DestroyActor();
            if (LineAttackActor3 != nullptr)
                LineAttackActor3.DestroyActor();
            if (LineAttackActor4 != nullptr)
                LineAttackActor4.DestroyActor();
            
            BP_DeactivatePhaseTwo();
            PhaseTwoTimer = PhaseTwoDuration;
        }
    }

    void PlayIdleAnimation()
	{
		FHazePlaySlotAnimationParams Params;
		Params.Animation = Idle;
		Params.BlendTime = 0.5;
		Params.bLoop = true;
		SkelMesh.PlaySlotAnimation(FHazeAnimationDelegate(), FHazeAnimationDelegate(), Params);	
	}

	void PlayThrowAnimation()
	{
		FHazePlaySlotAnimationParams Params;
		Params.Animation = ThrowAnim;
		Params.BlendTime = 0.25;
		FHazeAnimationDelegate EndThrowAnimation;
		// EndThrowAnimation.BindUFunction(this, n"EndThrowAnimation");
		SkelMesh.PlaySlotAnimation(FHazeAnimationDelegate(), EndThrowAnimation, Params);
		// Timer::SetTimer(this, n"EndThrowAnimation", 0.5, false);
	}

	void PlayRunChargeAnimation()
	{
		FHazePlaySlotAnimationParams Params;
		Params.Animation = ChargeAnim;
		Params.BlendTime = 0.5;
		Params.bLoop = true;
		SkelMesh.PlaySlotAnimation(FHazeAnimationDelegate(), FHazeAnimationDelegate(), Params);			
	}


    UFUNCTION(BlueprintEvent)
    void BP_Activate() {}
    UFUNCTION(BlueprintEvent)
    void BP_PhaseSwitch() {}
    UFUNCTION(BlueprintEvent)
    void BP_PhaseOne() {}
    UFUNCTION(BlueprintEvent)
    void BP_DeactivatePhaseTwo() {}

}