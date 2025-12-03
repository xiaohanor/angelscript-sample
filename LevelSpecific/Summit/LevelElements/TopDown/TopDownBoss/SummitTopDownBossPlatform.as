event void FSummitTopDownBossPlatformSignature();

class ASummitTopDownBossPlatform : AHazeActor
{
	
	UPROPERTY(DefaultComponent, RootComponent)
	UBoxComponent Collision;

    UPROPERTY()
	TSubclassOf<ASummitMagicTrajectoryProjectile> ProjectileClass;

	UPROPERTY(DefaultComponent, Attach = Collision)
	USceneComponent MeshRoot;

    UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UStaticMeshComponent Platform;

    UPROPERTY(DefaultComponent, Attach = Collision)
	USceneComponent EndingPosition;
	
    UPROPERTY(EditAnywhere)
	float TravelDuration = 3;

    UPROPERTY(EditAnywhere)
	float DelayFall = 2;
    float DelayFallTimer = DelayFall;

	UPROPERTY()
	FSummitTopDownBossPlatformSignature OnReachedDestination;
	FSummitTopDownBossPlatformSignature OnPlayd;
	FSummitTopDownBossPlatformSignature OnDefeated;

    UPROPERTY(EditAnywhere)
	FHazeTimeLike MoveAnimation;	
	default MoveAnimation.Duration = 1.0;
	default MoveAnimation.Curve.AddDefaultKey(0.0, 0.0);
	default MoveAnimation.Curve.AddDefaultKey(1.0, 1.0);

	UPROPERTY(EditAnywhere)
	float BobHeight = 10.0;

	UPROPERTY(EditAnywhere)
	float BobSpeed = 20;

	UPROPERTY(EditAnywhere)
	float BobOffset = 0.0;
    bool bIsActive;
    FVector PlatformStartLocation;
    FVector PlatformToLocation;

    UPROPERTY(EditAnywhere)
    bool bAutoPlay;

    bool bIsFalling;


	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		PlatformStartLocation = MeshRoot.GetRelativeLocation();
        PlatformToLocation = EndingPosition.GetRelativeLocation();
		OnUpdate(0.0);
		MoveAnimation.BindUpdate(this, n"OnUpdate");
		MoveAnimation.BindFinished(this, n"OnFinished");
		MoveAnimation.SetPlayRate(1.0 / TravelDuration);

        if (bAutoPlay)
            Play();

	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
        if (bIsFalling)
        {
            MeshRoot.SetRelativeLocation(FVector(Math::Sin(Time::GameTimeSeconds * BobSpeed + BobOffset) * BobHeight, Math::Sin(Time::GameTimeSeconds * BobSpeed + BobOffset) * BobHeight, 0));

            // MeshRoot.SetRelativeLocation(FVector::RightVector * Math::Sin((Time::GameTimeSeconds * BobSpeed + BobOffset)) * BobHeight);
            // MeshRoot.SetRelativeLocation(FVector::ForwardVector * Math::Sin((Time::GameTimeSeconds * BobSpeed + BobOffset)) * BobHeight);


            if (bIsActive)
                return;
            
            DelayFallTimer = DelayFallTimer - DeltaTime;

            if (DelayFallTimer <= 0)
            {
                Play();
            }

        }


	}

	UFUNCTION()
	void OnUpdate(float Alpha)
	{
		MeshRoot.SetRelativeLocation(Math::Lerp(FVector(0, 0, PlatformStartLocation.Y), PlatformToLocation, Alpha));
		
	}

    UFUNCTION()
	void OnFinished()
	{
		OnReachedDestination.Broadcast();
        bIsActive = false;
        bIsFalling = false;

        BP_Finished();

	}

	UFUNCTION()
	void Play()
	{
        if (bIsActive)
            return;

        bIsActive = true;
        MoveAnimation.Play();
		
		BP_Play();

	}

    UFUNCTION()
	void BeginFall()
	{
        if (bIsFalling)
            return;

		bIsFalling = true;

	}


	UFUNCTION()
	void Stop()
	{
		MoveAnimation.Stop();
        bIsActive = false;

		BP_Stop();
	}

    UFUNCTION()
	void Reverse()
	{
		MoveAnimation.Reverse();
        bIsActive = true;
	}


    UFUNCTION()
	void Defeated()
	{
		OnDefeated.Broadcast();
	}

    UFUNCTION(BlueprintEvent)
	void BP_Play() {}

    UFUNCTION(BlueprintEvent)
	void BP_Stop() {}

    UFUNCTION(BlueprintEvent)
	void BP_Finished() {}

}