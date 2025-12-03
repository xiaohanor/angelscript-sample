class ASanctuaryWellHydra : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent HydraRevealRoot;

	UPROPERTY(DefaultComponent, Attach = HydraRevealRoot)
	USceneComponent HydraSqueezeRoot;

	UPROPERTY(DefaultComponent, Attach = Root)
	UBillboardComponent BillboardComp;

	UPROPERTY(EditAnywhere, Category = "CameraShake")
	TSubclassOf<UCameraShakeBase> CameraShake;

	UPROPERTY(EditAnywhere, Category = "ForceFeedback")
	UForceFeedbackEffect ForceFeedback;

	UPROPERTY(Category = TimeLikes)
	FHazeTimeLike HydraRevealTimeLike;
	default HydraRevealTimeLike.UseSmoothCurveZeroToOne();
	default HydraRevealTimeLike.Duration = 5.0;

	UPROPERTY(Category = TimeLikes)
	FHazeTimeLike HydraSqueezeTimeLike;
	default HydraSqueezeTimeLike.UseSmoothCurveZeroToOne();
	default HydraSqueezeTimeLike.Duration = 2.0;

	UPROPERTY(Category = TimeLikes)
	FHazeTimeLike HydraIdleTimeLike;
	default HydraIdleTimeLike.UseSmoothCurveZeroToOne();
	default HydraIdleTimeLike.Duration = 3.0;
	default HydraIdleTimeLike.bFlipFlop = true;

	UPROPERTY(Category = Settings)
	float SpiralHeight = 3100;

	UPROPERTY(Category = Settings)
	float IdleTurningDegrees = 20.0;
	float IdleMultiplier;

	UPROPERTY(Category = Settings)
	float SqueezeTurningDegrees = 90.0;
	float SqueezeMultiplier;

	float StartHeight;
	float StartRotation;

	bool bHydraRevealed = false;

	int CrushCounter = 0;
	float HydraRotation = 360;

	UPROPERTY(DefaultComponent, Attach = HydraRevealRoot)
	UHazeSkeletalMeshComponentBase Mesh;

	UPROPERTY(EditAnywhere)
	FHazePlaySlotAnimationParams AnimationParams;


	TArray<AActor> Actors;

	TArray<FInstigator> DisableInstigators;

	#if EDITOR
	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		Mesh.EditorPreviewAnim = AnimationParams.Animation;
		Mesh.EditorPreviewAnimTime = AnimationParams.StartTime;
	}
#endif

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		HydraRevealTimeLike.BindUpdate(this, n"HydraRevealTimeLikeUpdate");
		HydraRevealTimeLike.BindFinished(this, n"HydraRevealTimeLikeFinished");
		HydraSqueezeTimeLike.BindUpdate(this, n"HydraSqueezeTimeLikeUpdate");
		HydraSqueezeTimeLike.BindFinished(this, n"HydraSqueezeTimeLikeFinished");
		HydraIdleTimeLike.BindUpdate(this, n"HydraIdleTimeLikeUpdate");

		IdleMultiplier = IdleTurningDegrees / -360.0;
		SqueezeMultiplier = SqueezeTurningDegrees / 360.0;

		GetAttachedActors(Actors, true, true);

		//AddDisabler(this);

		Mesh.PlaySlotAnimation(AnimationParams);
	}

	UFUNCTION()
	void AddDisabler(FInstigator DisableInstigator)
	{
		if (DisableInstigators.Num() == 0)
		{
			for (auto Actor : Actors)
			{
				Actor.AddActorDisable(this);
				Actor.AddActorCollisionBlock(this);
			}
		}

		DisableInstigators.Add(DisableInstigator);
	}

	UFUNCTION()
	void RemoveDisabler(FInstigator DisableInstigator)
	{
		DisableInstigators.Remove(DisableInstigator);

		if (DisableInstigators.Num() == 0)
		{
			for (auto Actor : Actors)
			{
				Actor.RemoveActorDisable(this);
				Actor.RemoveActorCollisionBlock(this);
			}
		}
	}

	UFUNCTION()
	void RemoveAllDisablers()
	{
		if (DisableInstigators.Num() > 0)
		{
			for (auto Actor : Actors)
			{
				Actor.RemoveActorDisable(this);
				Actor.RemoveActorCollisionBlock(this);
			}
		}

		DisableInstigators.Reset();
	}

	UFUNCTION()
	void RevealHydra()
	{
		if (bHydraRevealed)
			return;

		RemoveDisabler(this);

		bHydraRevealed = true;

		HydraRevealTimeLike.Play();

			
	}

	UFUNCTION()
	private void HydraRevealTimeLikeUpdate(float CurrentValue)
	{
		float ProgressAlpha = CurrentValue;
		FVector Location = FVector::UpVector * SpiralHeight * ProgressAlpha;
		FRotator Rotation = FRotator(0.0, -360.0 * ProgressAlpha, 0.0);

		HydraRevealRoot.SetRelativeLocationAndRotation(Location, Rotation);
	}

	UFUNCTION()
	private void HydraRevealTimeLikeFinished()
	{
		HydraIdleTimeLike.Play();
		StartHeight = HydraRevealRoot.RelativeLocation.Z;
		StartRotation = HydraRevealRoot.RelativeRotation.Yaw;
	}

	UFUNCTION()
	private void HydraIdleTimeLikeUpdate(float CurrentValue)
	{
		float ProgressAlpha = CurrentValue * IdleMultiplier;
		FVector Location = FVector::UpVector * SpiralHeight * ProgressAlpha;
		FRotator Rotation = FRotator(0.0, -360.0 * ProgressAlpha, 0.0);

		HydraSqueezeRoot.SetRelativeLocationAndRotation(Location, Rotation);
	}

	UFUNCTION()
	void HydraCrush()
	{
		CrushCounter++;

		if(CrushCounter==2)
		{
			SpiralHeight = -5900;
			HydraRotation = -360;
		}

		if(CrushCounter==3)
		{
			SpiralHeight = 4100;
			HydraRotation = 360;
		}
		

		HydraIdleTimeLike.StopWithDeceleration(1.0);

		HydraSqueezeTimeLike.PlayFromStart();

		for(auto Player : Game::Players)
		{
			Player.PlayForceFeedback(ForceFeedback, false, false, this, 1.0);
			Player.PlayWorldCameraShake(CameraShake, this, Player.ActorLocation);
		}
	
	}

	UFUNCTION()
	private void HydraSqueezeTimeLikeUpdate(float CurrentValue)
	{
		float ProgressAlpha = CurrentValue * SqueezeMultiplier;
		FVector Location = (FVector::UpVector * SpiralHeight * ProgressAlpha) + (FVector::UpVector * StartHeight);
		FRotator Rotation = FRotator(0.0, StartRotation - HydraRotation * ProgressAlpha, 0.0);

		HydraRevealRoot.SetRelativeLocationAndRotation(Location, Rotation);
	}
	
	UFUNCTION()
	private void HydraSqueezeTimeLikeFinished()
	{
		HydraIdleTimeLike.PlayWithAcceleration(1.0);
		StartHeight = HydraRevealRoot.RelativeLocation.Z;
		StartRotation = HydraRevealRoot.RelativeRotation.Yaw;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(HydraRevealTimeLike.IsPlaying() || HydraSqueezeTimeLike.IsPlaying())
		{
			for(auto Player : Game::Players)
			{	
				FHazeFrameForceFeedback FF;
				FF.LeftMotor = Math::Abs(Math::PerlinNoise1D(Math::Max(0.1, Time::GameTimeSeconds * 150)));
				FF.RightMotor = Math::Abs(Math::PerlinNoise1D(Math::Max(0.1, Time::GameTimeSeconds * 150)));
				Player.PlayWorldCameraShake(CameraShake, this, Player.ActorLocation);
				ForceFeedback::PlayWorldForceFeedbackForFrame(FF, HydraRevealRoot.WorldLocation, 10000, 15000);
			}
				
		}

	
		if(HydraIdleTimeLike.IsPlaying())
		{
			for(auto Player : Game::Players)
			{	
				FHazeFrameForceFeedback FF;
				FF.LeftMotor = Math::Sin(Time::GameTimeSeconds * 15.0) * 0.2;
				FF.RightMotor = Math::Sin(-Time::GameTimeSeconds* 15.0) * 0.2;
				ForceFeedback::PlayWorldForceFeedbackForFrame(FF, HydraRevealRoot.WorldLocation, 10000, 15000);
			}
		}

		PrintToScreen("CRushes: " + CrushCounter);
	}
	UFUNCTION()
	void PlaySlotAnimationLevelBP(FHazePlaySlotAnimationParams AnimParams)
	{
		Mesh.PlaySlotAnimation(AnimParams);
	}
};