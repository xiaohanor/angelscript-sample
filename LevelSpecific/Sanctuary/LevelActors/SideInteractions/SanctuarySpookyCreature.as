class ASanctuarySpookyCreature : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UHazeSkeletalMeshComponentBase SkeletalMeshComp;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent LeftEye;
	UPROPERTY(DefaultComponent)
	UStaticMeshComponent RightEye;
	UPROPERTY(DefaultComponent)
	UStaticMeshComponent LeftEar;
	UPROPERTY(DefaultComponent)
	UStaticMeshComponent RightEar;

	UPROPERTY(EditAnywhere)
	UAnimSequence IdleAnim;

	UPROPERTY(EditInstanceOnly)
	APlayerTrigger PlayerEnterVolume;

	UPROPERTY(EditInstanceOnly)
	ASplineActor MoveAwaySpline;
	float SplineDistance = 0.0;

	float Blinking = 1.0;
	float BlinkCooldown = -1.0;
	bool bDoubleBlink = false;

	FVector EyeOGScale;
	bool bBlinking = false;

	bool bHiding = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		LeftEye.AttachToComponent(SkeletalMeshComp, n"LeftEye", EAttachmentRule::KeepWorld);
		RightEye.AttachToComponent(SkeletalMeshComp, n"RightEye", EAttachmentRule::KeepWorld);
		LeftEar.AttachToComponent(SkeletalMeshComp, n"LeftEar", EAttachmentRule::KeepWorld);
		RightEar.AttachToComponent(SkeletalMeshComp, n"RightEar", EAttachmentRule::KeepWorld);

		EyeOGScale = LeftEye.GetWorldScale();

		FHazePlaySlotAnimationParams Params;
		Params.Animation = IdleAnim;
		Params.bLoop = true;
		SkeletalMeshComp.PlaySlotAnimation(Params);

		BlinkCooldown = Math::RandRange(10.0, 30.0);
		PlayerEnterVolume.OnActorBeginOverlap.AddUFunction(this, n"PlayerClosingIn");
	}

	UFUNCTION()
	private void PlayerClosingIn(AActor OverlappedActor, AActor OtherActor)
	{
		if (MoveAwaySpline != nullptr)
		{
			bHiding = true;
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		BlinkCooldown -= DeltaSeconds;
		if (BlinkCooldown < 0.0)
		{
			if (!bDoubleBlink && Math::RandRange(0.0, 1.0) < 0.3)
			{
				BlinkCooldown = 0.3;
				bDoubleBlink = true;
			}
			else
			{
				bDoubleBlink = false;
				BlinkCooldown = Math::RandRange(10.0, 30.0);
			}
			Blinking = 0.0;
			bBlinking = true;
		}

		if (bBlinking)
		{
			const float BlinkDuration = 0.2;
			Blinking = Math::Clamp(Blinking + DeltaSeconds, 0.0, BlinkDuration);
			float Alpha = Blinking / BlinkDuration;
			LeftEye.SetWorldScale3D(Math::EaseOut(FVector::OneVector * KINDA_SMALL_NUMBER * 2.0, EyeOGScale, Alpha, 2.0));
			RightEye.SetWorldScale3D(Math::EaseOut(FVector::OneVector * KINDA_SMALL_NUMBER * 2.0, EyeOGScale, Alpha, 2.0));
			if (Alpha > 1.0 - KINDA_SMALL_NUMBER)
				bBlinking = false;
		}

		if (bHiding)
		{
			const float Speed = 800.0;
			SplineDistance += DeltaSeconds * Speed;
			
			if (SplineDistance > MoveAwaySpline.Spline.SplineLength)
			{
				SetActorHiddenInGame(true);
				SetAutoDestroyWhenFinished(true);
			}
			else
			{
				FTransform NewTransform = MoveAwaySpline.Spline.GetWorldTransformAtSplineDistance(SplineDistance);
				SetActorLocation(NewTransform.Location);
				SetActorRotation(NewTransform.Rotation);
			}
		}
	}
};