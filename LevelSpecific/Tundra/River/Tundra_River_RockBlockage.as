event void FRockBlockageEvent();

class ATundra_River_RockBlockage : AHazeActor
{
	UPROPERTY()
	FRockBlockageEvent OnRockMoved;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent RockRoot;

	UPROPERTY(DefaultComponent, Attach = RockRoot)
	UStaticMeshComponent RockMeshComp;
	default RockMeshComp.bHiddenInGame = true;

	UPROPERTY(DefaultComponent, Attach = RockRoot)
	UStaticMeshComponent RockVisualMeshComp;
	default RockVisualMeshComp.CollisionEnabled = ECollisionEnabled::NoCollision;

	UPROPERTY(DefaultComponent, Attach = Root)
	UFauxPhysicsTranslateComponent FPTranslateComp;
	default FPTranslateComp.ForceScalar = 2;
	default FPTranslateComp.Friction = 6;
	default FPTranslateComp.bConstrainX = true;
	default FPTranslateComp.bConstrainY = true;
	default FPTranslateComp.bConstrainZ = true;
	default FPTranslateComp.MinZ = -450;
	default FPTranslateComp.SpringStrength = 4;

	UPROPERTY(DefaultComponent, Attach = FPTranslateComp)
	USceneComponent ClimbRoot;

	UPROPERTY(DefaultComponent, Attach = ClimbRoot)
	UStaticMeshComponent ClimbMeshComp;

	UPROPERTY(DefaultComponent, Attach = ClimbMeshComp)
	UTundraPlayerSnowMonkeyCeilingClimbSelectorComponent ClimbSelectComp;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent LifeGiveRoot;

	UPROPERTY(DefaultComponent, Attach = LifeGiveRoot)
	UStaticMeshComponent LifeGiveMeshComp;

	UPROPERTY(DefaultComponent, Attach = LifeGiveRoot)
	UTundraTreeGuardianRangedInteractionTargetableComponent LifeTargetComp;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent RootsRoot;

	UPROPERTY(DefaultComponent, Attach = RootsRoot)
	UStaticMeshComponent RootsBlockerComp;

	UPROPERTY(DefaultComponent, Attach = RootsRoot)
	UStaticMeshComponent RootsMeshComp;

	UPROPERTY(DefaultComponent)
	UTundraPlayerSnowMonkeyCeilingClimbComponent ClimbComp;

	UPROPERTY(DefaultComponent)
	UTundraLifeReceivingComponent LifeComp;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<UCameraShakeBase> RockMoveCamShake;
	
	UPROPERTY(EditDefaultsOnly)
	FHazeTimeLike RockMoveTimeLike;
	default RockMoveTimeLike.Duration = 0.15;
	default RockMoveTimeLike.Curve.AddDefaultKey(0,0);
	default RockMoveTimeLike.Curve.AddDefaultKey(0.15,1);

	UPROPERTY(EditAnywhere)
	AStaticCameraActor CameraActor;

	UPROPERTY(EditAnywhere, Meta = (MakeEditWidget))
	FVector EndPosition;

	UPROPERTY(EditAnywhere)
	float ClimbRockDistance = 150;

	UPROPERTY(EditAnywhere)
	float TimeUntilRockPushed = 1;

	UPROPERTY(DefaultComponent)
	UHazeCrumbSyncedFloatComponent Input;

	bool bLifeGiveBlocked = true;
	bool bMioClimbing = false;
	float ClimbStartPosZ;
	float ChargeTimer;
	bool bCharging = false;
	bool bRockMoved = false;
	FVector StartPos;
	float MaxRootsScale = 15;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SetActorControlSide(Game::Zoe);
		ClimbComp.OnAttach.AddUFunction(this, n"HandleOnAttach");
		ClimbComp.OnDeatch.AddUFunction(this, n"HandleOnDetach");
		RockMoveTimeLike.BindFinished(this, n"TL_RockMoveFinished");
		RockMoveTimeLike.BindUpdate(this, n"TL_RockMoveUpdate");
		LifeComp.OnInteractStart.AddUFunction(this, n"OnInteractStarted");
		LifeComp.OnInteractStop.AddUFunction(this, n"OnInteractStopped");
		ClimbStartPosZ = FPTranslateComp.RelativeLocation.Z;
		LifeTargetComp.Disable(this);
		StartPos = RockRoot.RelativeLocation;
	}

	UFUNCTION()
	private void OnInteractStopped(bool bForced)
	{
		Game::GetZoe().DeactivateCamera(CameraActor);
	}

	UFUNCTION()
	private void OnInteractStarted(bool bForced)
	{
		Game::GetZoe().ActivateCamera(CameraActor, 2, this);
	}

	UFUNCTION()
	private void TL_RockMoveUpdate(float CurrentValue)
	{
		FVector LerpedLocation = Math::Lerp(StartPos, EndPosition, CurrentValue);
		RockRoot.SetRelativeLocation(LerpedLocation);
		float LerpedRootScale = Math::Lerp(1, MaxRootsScale, CurrentValue);
		RootsRoot.SetRelativeScale3D(FVector(1,LerpedRootScale,1));
	}

	UFUNCTION()
	private void TL_RockMoveFinished()
	{
		Game::GetMio().PlayCameraShake(RockMoveCamShake, this);
		Game::GetZoe().PlayCameraShake(RockMoveCamShake, this);
		OnRockMoved.Broadcast();
	}

	UFUNCTION()
	private void HandleOnDetach()
	{
		bMioClimbing = false;
		Game::GetMio().DeactivateCamera(CameraActor);
	}

	UFUNCTION()
	private void HandleOnAttach()
	{
		bMioClimbing = true;
		Game::GetMio().ActivateCamera(CameraActor, 2, this);
	}

	UFUNCTION()
	private void ScaleRoots(float DeltaSeconds)
	{
		if(!bRockMoved)
			return;

		if(HasControl())
		{
			Input.Value = LifeComp.RawHorizontalInput;
		}
		
		float InternalInput = 0;
		InternalInput = Input.Value;

		if(InternalInput == 0 && LifeComp.IsCurrentlyLifeGiving())
			return;
		
		if(!LifeComp.IsCurrentlyLifeGiving())
			InternalInput = 1;

		float TargetScale = InternalInput > 0 ? 1 : MaxRootsScale;

		float ToTargetDelta = (TargetScale - RootsRoot.RelativeScale3D.Y);
		float ToTargetDirection = ToTargetDelta > 0 ? 1 : -1;

		float ScaleDelta = (ToTargetDirection * 15 * DeltaSeconds * Math::Abs(InternalInput));

		if(Math::Abs(ScaleDelta) > Math::Abs(ToTargetDelta))
		{
			ScaleDelta = ToTargetDelta;
		}

		RootsRoot.SetRelativeScale3D(FVector(1,RootsRoot.RelativeScale3D.Y + ScaleDelta,1));
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(!bRockMoved)
		{
			if(LifeComp.IsCurrentlyLifeGiving())
			{
				if(LifeComp.HorizontalAlpha < -0.25)
				{
					bCharging = true;
					ChargeTimer += DeltaSeconds;

					float SineRotate = Math::Sin(Time::GetGameTimeSeconds() * 50) * 1;
					RockVisualMeshComp.RelativeRotation = FRotator(Math::Sin(Time::GetGameTimeSeconds() * 5), Math::Sin(Time::GetGameTimeSeconds() * 5), Math::Sin(Time::GetGameTimeSeconds() * 5)) * SineRotate;

					if(ChargeTimer > TimeUntilRockPushed)
					{
						RockMoveTimeLike.Play();
						bRockMoved = true;
					}
				}
				else
				{
					bCharging = false;
				}
			}
			else
			{
				bCharging = false;
			}

			if(!bCharging && ChargeTimer > 0)
			{
				ChargeTimer -= DeltaSeconds;
			}
		}
		else
		{
			ScaleRoots(DeltaSeconds);
		}

		if(FPTranslateComp.RelativeLocation.Z < ClimbStartPosZ - ClimbRockDistance)
		{
			if(bLifeGiveBlocked)
			{
				bLifeGiveBlocked = false;
				LifeTargetComp.Enable(this);
			}
		}
		else
		{
			if(!bLifeGiveBlocked)
			{
				bLifeGiveBlocked = true;
				LifeTargetComp.ForceExitInteract();
				LifeTargetComp.Disable(this);
			}
		}

		if(bMioClimbing)
		{
			FauxPhysics::ApplyFauxForceToActorAt(this, Game::GetMio().GetActorLocation(), FVector(0,0,-6000));
		}
	}
};