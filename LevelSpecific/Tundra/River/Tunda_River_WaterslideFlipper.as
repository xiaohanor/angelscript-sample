event void FWaterSlideFlipperEvent();

class ATunda_River_WaterslideFlipper : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent RotationRoot;

	UPROPERTY(DefaultComponent, Attach = RotationRoot)
	USceneComponent FlipperRoot;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent ArriveMeshComp;

	UPROPERTY(DefaultComponent, Attach = FlipperRoot)
	UStaticMeshComponent FlipperMeshComp;

	UPROPERTY(DefaultComponent, Attach = FlipperRoot)
	USceneComponent Flipper1Root;
	
	UPROPERTY(DefaultComponent, Attach = Flipper1Root)
	USceneComponent Flipper2Root;

	UPROPERTY(DefaultComponent, Attach = Flipper2Root)
	USceneComponent Flipper3Root;

	UPROPERTY(DefaultComponent, Attach = Flipper2Root)
	USceneComponent Flipper2ShakeRoot;

	UPROPERTY(DefaultComponent, Attach = Flipper3Root)
	USceneComponent Flipper3ShakeRoot;

	UPROPERTY(DefaultComponent, Attach = Flipper1Root)
	UStaticMeshComponent FlipperMesh1Comp;

	UPROPERTY(DefaultComponent, Attach = Flipper2ShakeRoot)
	UStaticMeshComponent FlipperMesh2Comp;

	UPROPERTY(DefaultComponent, Attach = Flipper3ShakeRoot)
	UStaticMeshComponent FlipperMesh3Comp;

	UPROPERTY(DefaultComponent, Attach = FlipperRoot)
	UStaticMeshComponent FlipperMeshCollisionComp;

	UPROPERTY(DefaultComponent, Attach = FlipperRoot)
	USceneComponent SplashEffectLocation;

	UPROPERTY(DefaultComponent, Attach = Root)
	UBoxComponent LaunchTrigger;

	UPROPERTY(DefaultComponent, Attach = Root)
	UArrowComponent LaunchDirectionArrow;
	default LaunchDirectionArrow.RelativeLocation = FVector(900, 0, 250);
	default LaunchDirectionArrow.RelativeRotation = FRotator(60, 0, 0);
	default LaunchDirectionArrow.ArrowSize = 4;

	UPROPERTY(EditAnywhere, Category = "Flipper Settings", Meta = (MakeEditWidget))
	TArray<FVector> SplashLocations;

	UPROPERTY(EditDefaultsOnly, Category = "Flipper Settings")
	FHazeTimeLike FlipperReleaseTimeLike;
	default FlipperReleaseTimeLike.Duration = 0.15;
	default FlipperReleaseTimeLike.Curve.AddDefaultKey(0,0);
	default FlipperReleaseTimeLike.Curve.AddDefaultKey(0.15,1);

	UPROPERTY(EditDefaultsOnly, Category = "Flipper Settings")
	UNiagaraSystem SplashEffect;

	UPROPERTY(EditInstanceOnly, Category = "Flipper Settings")
	AActor LifeGivingActor;

	UPROPERTY(EditAnywhere, Category = "Flipper Settings")
	float MaxRotateAngle = -10;

	UPROPERTY(EditAnywhere, Category = "Flipper Settings")
	float PullbackSpeed = 10;

	UPROPERTY(EditAnywhere, Category = "Flipper Settings")
	float CooldownTime = 1;

	UPROPERTY(EditAnywhere, Category = "Flipper Settings")
	float LaunchForce = 2000;

	UPROPERTY(EditAnywhere, Category = "Flipper Settings")
	bool bShouldZeroVelocity = true;

	UPROPERTY(DefaultComponent)
	UHazeCrumbSyncedFloatComponent CurrentPitch;
	
	UTundraLifeReceivingComponent LifeComp;

	FWaterSlideFlipperEvent OnFlipperPulledBack;
	FWaterSlideFlipperEvent OnFlipperReleased;

	bool bPlayerInside = false;
	bool bReachedEnd = false;
	bool bLaunching = false;
	float Input;
	float CooldownTimer = 0;

	AHazePlayerCharacter PlayerOnFlipper;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SetActorControlSide(Game::Zoe);
	
		if(LifeGivingActor != nullptr)
			LifeComp = UTundraLifeReceivingComponent::Get(LifeGivingActor);
	
		LaunchTrigger.OnComponentBeginOverlap.AddUFunction(this, n"PlayerEntered");
		LaunchTrigger.OnComponentEndOverlap.AddUFunction(this, n"PlayerLeft");
		OnFlipperPulledBack.AddUFunction(this, n"FlipperPulledBack");
		OnFlipperReleased.AddUFunction(this, n"CrumbFlippedReleased");
		FlipperReleaseTimeLike.BindUpdate(this, n"FlipperReleaseTimeLikeUpdate");
		FlipperReleaseTimeLike.BindFinished(this, n"FlipperReleaseTimeLikeFinished");
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(HasControl())
		{
			if(CooldownTimer > 0)
			{
				CooldownTimer -= DeltaSeconds;
			}

			if(LifeComp != nullptr)
			{
				if(LifeComp.IsCurrentlyLifeGiving())
				{
					if(CooldownTimer <= 0)
					{
						Input = LifeComp.RawVerticalInput;
					}
					else
					{
						Input = 0;
					}

					if(bReachedEnd && !bLaunching)
					{
						FHazeFrameForceFeedback Feedback;
						Feedback.LeftMotor = 0.5;
						Feedback.RightMotor = 0.5;
						Game::GetZoe().SetFrameForceFeedback(Feedback);
						CrumbShakeFlipperVisual(false);
					}

					if(bReachedEnd && Input == 0 && !bLaunching)
					{
						OnFlipperReleased.Broadcast();
					}
				}
				else
				{
					Input = 0;
				}

				if(!bLaunching)
				{
					RotateRamp(DeltaSeconds);
				}
			}
		}
		else
		{
			SetFlipperAngle();
		}
	}

	UFUNCTION()
	private void FlipperReleaseTimeLikeFinished()
	{
		bReachedEnd = false;
		bLaunching = false;
	}

	UFUNCTION()
	private void FlipperReleaseTimeLikeUpdate(float CurrentValue)
	{
		float DesiredRotation = Math::Lerp(MaxRotateAngle, 0, CurrentValue);
		RotationRoot.RelativeRotation = FRotator(DesiredRotation,0 , 0);
		Flipper1Root.RelativeRotation = FRotator(Math::Clamp(DesiredRotation, 0, 1), 0, 0);
		Flipper2Root.RelativeRotation = FRotator(Math::Clamp(DesiredRotation, 0, 1), 0, 0);
		Flipper3Root.RelativeRotation = FRotator(Math::Clamp(DesiredRotation, 0, 1), 0, 0);
	}

	UFUNCTION(CrumbFunction)
	private void CrumbFlippedReleased()
	{
		CrumbShakeFlipperVisual(true);
		bLaunching = true;
		FlipperReleaseTimeLike.PlayFromStart();
		if(!Network::IsGameNetworked() || !HasControl())
		{
			LaunchPlayer();
		}
		CooldownTimer = CooldownTime;

		for(int i = 0; i < SplashLocations.Num(); i++)
		{
			FVector SpawnLoc = Root.WorldTransform.TransformPosition(SplashLocations[i]);
			Niagara::SpawnOneShotNiagaraSystemAtLocation(SplashEffect, SpawnLoc, WorldScale = FVector(1,1,1));

		}
	}

	UFUNCTION()
	private void FlipperPulledBack()
	{
	}

	UFUNCTION()
	private void PlayerEntered(UPrimitiveComponent OverlappedComponent, AActor OtherActor,
	                           UPrimitiveComponent OtherComp, int OtherBodyIndex, bool bFromSweep,
	                           const FHitResult&in SweepResult)
	{
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);

		if(Player == nullptr)
			return;

		bPlayerInside = true;
		PlayerOnFlipper = Player;
	}
	
	UFUNCTION()
	private void PlayerLeft(UPrimitiveComponent OverlappedComponent, AActor OtherActor,
	                        UPrimitiveComponent OtherComp, int OtherBodyIndex)
	{
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);

		if(Player == nullptr)
			return;

		bPlayerInside = false;
		PlayerOnFlipper = nullptr;
	}

	UFUNCTION(BlueprintCallable)
	void RotateRamp(float DeltaSeconds)
	{
		if(bReachedEnd)
			return;

		float InternalInput = 0;

		if(Input == 0)
		{
			InternalInput = 1;
		}
		else
		{
			InternalInput = Input;
		}

		float TargetPitch = InternalInput < 0 ? MaxRotateAngle : 0;

		float ToTargetRotationDelta = (TargetPitch - RotationRoot.RelativeRotation.Pitch);
		float TargetRotationDirection = ToTargetRotationDelta < 0 ? -1 : 1;

		float RotationDelta = TargetRotationDirection * PullbackSpeed * DeltaSeconds;

		if(Math::Abs(RotationDelta) > Math::Abs(ToTargetRotationDelta))
		{
			RotationDelta = ToTargetRotationDelta;

			if(TargetPitch == MaxRotateAngle)
			{
				bReachedEnd = true;
				OnFlipperPulledBack.Broadcast();
			}
		}

		CurrentPitch.Value = RotationRoot.RelativeRotation.Pitch + RotationDelta;
		
		SetFlipperAngle();
	}

	private void SetFlipperAngle()
	{
		RotationRoot.RelativeRotation = FRotator(CurrentPitch.Value,0 , 0);
		Flipper1Root.RelativeRotation = FRotator(CurrentPitch.Value * 0.1,0 , 0);
		Flipper2Root.RelativeRotation = FRotator(CurrentPitch.Value * 3,0 , 0);
		Flipper3Root.RelativeRotation = FRotator(CurrentPitch.Value * 2,0 , 0);
	}

	private void LaunchPlayer()
	{
		if(PlayerOnFlipper == nullptr)
			return;

		UTundra_River_WaterslideLaunch_PlayerComponent LaunchPlayerComp = UTundra_River_WaterslideLaunch_PlayerComponent::Get(PlayerOnFlipper);
		LaunchPlayerComp.OnNewLaunchTriggered();
		
		if(bShouldZeroVelocity)
		{
			PlayerOnFlipper.SetActorHorizontalAndVerticalVelocity(FVector::ZeroVector, FVector::ZeroVector);
		}
		
		PlayerOnFlipper.AddMovementImpulse(LaunchDirectionArrow.ForwardVector * LaunchForce);
	}

	UFUNCTION(CrumbFunction)
	private void CrumbShakeFlipperVisual(bool bReset)
	{
		if(bReset)
		{
			Flipper2ShakeRoot.SetRelativeRotation(FRotator(0, 0, 0));
			Flipper3ShakeRoot.SetRelativeRotation(FRotator(0, 0, 0));
			return;
		}

		float RandomPitchRotation = Math::RandRange(-2, 1);
		Flipper2ShakeRoot.SetRelativeRotation(FRotator(RandomPitchRotation, 0, 0));
		Flipper3ShakeRoot.SetRelativeRotation(FRotator(RandomPitchRotation, 0, 0));
	}
};