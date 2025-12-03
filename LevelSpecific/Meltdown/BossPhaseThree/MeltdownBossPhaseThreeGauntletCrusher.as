class AMeltdownBossPhaseThreeGauntletCrusher : AHazeCharacter
{

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent PortalMesh;

	// Whether to destroy the actor or disable it when it expires
	UPROPERTY()
	bool bDestroyOnExpire = true;

	private AHazePlayerCharacter TargetPlayer;
	private bool bLaunched = false;
	private bool bJumped = false;
	private bool bJumpingOut = false;
	private float Timer = 0.0;
	private FVector OriginalLaunchDirection;
	private FVector StartLocation;
	private FVector TargetLocation;
	private FVector StartVelocity;
	private float JumpDuration;

	UPROPERTY()
	FHazeTimeLike Portal;
	default Portal.Duration = 1;
	default Portal.UseSmoothCurveZeroToOne();

	FVector StartScale;
	FTransform OriginalTransform;

	UPROPERTY()
	FVector EndScale;

	UPROPERTY(EditAnywhere)
	TSubclassOf<AMeltdownBossPhaseThreeTelegraph> TelegraphClass;

	UPROPERTY()
	float JumpAtTime = 2.5;
	UPROPERTY()
	float Gravity = 8000;
	UPROPERTY()
	float Height = 2000;
	AMeltdownBossPhaseThreeTelegraph Telegraph;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		AddActorDisable(this);

		Portal.BindFinished(this, n"PortalOpen");
		Portal.BindUpdate(this, n"PortalOpening");
		OriginalTransform = ActorTransform;

		SetActorHiddenInGame(true);
	}

	
	UFUNCTION(DevFunction)
	void Launch(AHazePlayerCharacter Target)
	{
		ActorTransform = OriginalTransform;
		bLaunched = true;
		bJumped = false;
		bJumpingOut = false;
		TargetPlayer = Target;
		Timer = 0.0;

		OriginalLaunchDirection = (Target.ActorLocation - ActorLocation).GetSafeNormal();
		ActorRotation = FRotator::MakeFromZX(FVector::UpVector, OriginalLaunchDirection);

		Telegraph = MeltdownBossPhaseThree::SpawnTelegraph(TelegraphClass, ActorLocation, 380.0);

		SetActorHiddenInGame(false);
		SetActorTickEnabled(false);
		Mesh.SetHiddenInGame(true);
		RemoveActorDisable(this);
		Portal.PlayFromStart();
	}

	UFUNCTION(BlueprintEvent)
	void StartAnim() {}

	UFUNCTION(BlueprintEvent)
	void Landed() {}

	UFUNCTION()
	private void PortalOpening(float CurrentValue)
	{
		PortalMesh.SetRelativeScale3D(Math::Lerp(StartScale,EndScale,CurrentValue));
	}

	UFUNCTION()
	private void PortalOpen()
	{
		if (Portal.IsReversed())
			return;

		Mesh.SetHiddenInGame(false);
		SetActorTickEnabled(true);
		StartAnim();
		PortalMesh.DetachFromComponent(EDetachmentRule::KeepWorld);
		Portal.ReverseFromEnd();
	}
	

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (!bLaunched)
			return;

		Timer += DeltaSeconds;
		if (!bJumped)
		{
			TargetLocation = TargetPlayer.ActorLocation;
			TargetLocation.Z = ActorLocation.Z;
			Telegraph.ActorLocation = TargetLocation;

			ActorRotation = FRotator::MakeFromZX(FVector::UpVector, TargetLocation - ActorLocation);
			if (Timer >= JumpAtTime)
			{
				bJumped = true;
				StartLocation = ActorLocation;

				Trajectory::FOutCalculateVelocity Trajectory = Trajectory::CalculateParamsForPathWithHeight(
					ActorLocation, TargetLocation,
					Gravity, Height
				);
				StartVelocity = Trajectory.Velocity;
				JumpDuration = Trajectory.Time;
			}
		}
		else
		{
			float JumpTime = Math::Clamp(Timer - JumpAtTime, 0.0, JumpDuration);
			FVector PrevLocation = ActorLocation;
			ActorLocation = StartLocation + StartVelocity * JumpTime + FVector::DownVector * Gravity * 0.5 * Math::Square(JumpTime);
			if (JumpTime > 0)
				ActorRotation = FRotator::MakeFromX(ActorLocation - PrevLocation);

			if (JumpTime >= JumpDuration)
			{
				if (bJumpingOut)
				{
					AddActorDisable(this);
				}
				else
				{
					Timer = JumpAtTime;
					StartLocation = ActorLocation;
					TargetLocation = ActorLocation + (ActorForwardVector.GetSafeNormal2D() * 5000.0);
					Landed();

					Trajectory::FOutCalculateVelocity Trajectory = Trajectory::CalculateParamsForPathWithHeight(
						ActorLocation, TargetLocation,
						Gravity, Height
					);

					StartVelocity = Trajectory.Velocity;
					JumpDuration = Trajectory.Time;
					bJumpingOut = true;

					if (Telegraph != nullptr)
					{
						Telegraph.HideAndDestroy();
						Telegraph = nullptr;
					}
				}
			}
		}
	}
};