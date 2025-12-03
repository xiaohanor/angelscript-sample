event void FVillageOgreStartedRunningEvent(AVillageOgreBase Ogre);
event void FVillageOgreReachedEndOfSplineEvent(AVillageOgreBase Ogre);

class AVillageOgreBase : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UCapsuleComponent CollisionComp;
	default CollisionComp.RelativeLocation = FVector(0.0, 0.0, 220.0);
	default CollisionComp.CapsuleHalfHeight = 220.0;
	default CollisionComp.CapsuleRadius = 100.0;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UHazeSkeletalMeshComponentBase SkelMeshComp;
	default SkelMeshComp.SetCollisionEnabled(ECollisionEnabled::NoCollision);

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedActorComp;

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 10000.0;

	UPROPERTY(EditInstanceOnly, Category = "Spline")
	AActor FollowSplineActor;
	UHazeSplineComponent FollowSplineComp;

	UPROPERTY(EditAnywhere, Category = "Rush")
	FHazeTimeLike RushTimeLike;
	UHazeSplineComponent RushSplineComp;

	UPROPERTY(EditAnywhere, Category = "Rush")
	bool bRotateOnRush = false;

	UPROPERTY(EditAnywhere)
	bool bAngry = false;

	UPROPERTY(EditAnywhere, Category = "Kill")
	bool bKillPlayerOnImpact = false;
	UPROPERTY(EditAnywhere, Category = "Kill", Meta = (EditCondition = "bKillPlayerOnImpact", EditConditionHides))
	float KillRadius = 300.0;
	UPROPERTY(EditAnywhere, Category = "Kill", Meta = (EditCondition = "bKillPlayerOnImpact", EditConditionHides))
	float KillTriggerOffset = 0.0;
	UPROPERTY(EditAnywhere, Category = "Kill", Meta = (EditCondition = "bKillPlayerOnImpact", EditConditionHides))
	bool bPlayKillAnimation = true;
	UPROPERTY(EditAnywhere, Category = "Kill", Meta = (EditCondition = "bKillPlayerOnImpact && bPlayKillAnimation", EditConditionHides))
	UAnimSequence KillAnim;

	UPROPERTY(EditDefaultsOnly)
	TArray<UAnimSequence> AngryAnimations;
	UAnimSequence AngryAnimation;

	UPROPERTY(EditInstanceOnly, Meta = (EditCondition = "bAngry", EditConditionHides))
	UAnimSequence SpecificAngryAnimation;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<UDeathEffect> DeathEffect;

	bool bFollowingSpline = false;
	FSplinePosition SplinePos;

	// UPROPERTY(EditAnywhere, Category = "Spline")
	// float SplineFollowSpeed = 500.0;

	UPROPERTY()
	FVillageOgreStartedRunningEvent OnStartedRunning;

	UPROPERTY()
	FVillageOgreReachedEndOfSplineEvent OnReachedEndOfSpline;

	UPROPERTY(EditAnywhere)
	float RunSpeed = 600.0;
	bool bRunning = false;

	float ChaseJumpHeightOffset = 0.0;

	UPROPERTY(EditDefaultsOnly)
	FHazeTimeLike ChaseJumpTimeLike;
	default ChaseJumpTimeLike.Duration = 1.0;
	default ChaseJumpTimeLike.bCurveUseNormalizedTime = true;

	// Anim parameters

	UPROPERTY(EditAnywhere)
	ULocomotionFeatureOgreMovement AnimFeature;

	UPROPERTY(BlueprintReadOnly)
	bool bBreakingWall = false;
	UPROPERTY(BlueprintReadOnly)
	bool bChasing = false;
	UPROPERTY(BlueprintReadOnly)
	bool bJumping = false;
	UPROPERTY(BlueprintReadOnly)
	float MoveSpeed = 500.0;

	UPROPERTY(EditAnywhere)
	FVector2D ChaseSpeedDistanceRange = FVector2D(300.0, 1400.0);

	UPROPERTY(EditDefaultsOnly)
	UNiagaraSystem JumpLandingEffect;

	TArray<AHazePlayerCharacter> PlayersInKillRange;

	UPROPERTY(EditAnywhere)
	bool bInterpMovement = true;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		if (bKillPlayerOnImpact)
		{
			UHazeMovablePlayerTriggerComponent DeathTriggerComp = UHazeMovablePlayerTriggerComponent::Create(this);
			DeathTriggerComp.AttachToComponent(SkelMeshComp, n"Hips");
			DeathTriggerComp.SetRelativeLocation(FVector(0.0, 0.0, KillTriggerOffset));
			FHazeShapeSettings ShapeSettings;
			float HalfHeight = Math::Clamp(KillRadius, 220.0, KillRadius);
			ShapeSettings.InitializeAsCapsule(KillRadius, HalfHeight);
			DeathTriggerComp.Shape = ShapeSettings;
		}

#if EDITOR
		if (bAngry && SpecificAngryAnimation != nullptr)
			SkelMeshComp.EditorPreviewAnim = SpecificAngryAnimation;
#endif
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		RushTimeLike.BindUpdate(this, n"UpdateRush");
		RushTimeLike.BindFinished(this, n"FinishRush");

		if (bAngry)
		{
			if (SpecificAngryAnimation != nullptr)
				AngryAnimation = SpecificAngryAnimation;
			else
				AngryAnimation = AngryAnimations[Math::RandRange(0, AngryAnimations.Num() - 1)];
			PlaySlotAnimation(Animation = AngryAnimation, bLoop = true, StartTime = Math::RandRange(0.0, AngryAnimation.SequenceLength));
		}

		if (bKillPlayerOnImpact)
		{
			UHazeMovablePlayerTriggerComponent DeathTriggerComp = UHazeMovablePlayerTriggerComponent::Get(this);
			if (DeathTriggerComp != nullptr)
			{
				DeathTriggerComp.OnPlayerEnter.AddUFunction(this, n"PlayerEnterDeathTrigger");
			}
		}
	}

	UFUNCTION()
	void MakeAngry(bool bRandomStartTime = true)
	{
		if (SpecificAngryAnimation != nullptr)
			AngryAnimation = SpecificAngryAnimation;
		else
			AngryAnimation = AngryAnimations[Math::RandRange(0, AngryAnimations.Num() - 1)];
		
		float AnimStartTime = bRandomStartTime ? Math::RandRange(0.0, AngryAnimation.SequenceLength) : 0.0;
		PlaySlotAnimation(Animation = AngryAnimation, bLoop = true, StartTime = AnimStartTime);
	}

	UFUNCTION()
	private void PlayerEnterDeathTrigger(AHazePlayerCharacter Player)
	{
		if (!IsPlayingAnimAsSlotAnimation(KillAnim))
		{
			FHazePlaySlotAnimationParams AnimParams;
			AnimParams.Animation = KillAnim;
			SkelMeshComp.PlaySlotAnimation(AnimParams);
		}

		if (bPlayKillAnimation)
		{
			PlayersInKillRange.Add(Player);
			Timer::SetTimer(this, n"KillPlayerOnImpact", 0.3);
		}
		else
		{
			FVector DeathDir = (Player.ActorLocation - ActorLocation).ConstrainToPlane(FVector::UpVector).GetSafeNormal();
			Player.KillPlayer(FPlayerDeathDamageParams(DeathDir), DeathEffect);
		}
	}

	UFUNCTION()
	private void KillPlayerOnImpact()
	{
		for (AHazePlayerCharacter Player : PlayersInKillRange)
		{
			FVector DeathDir = (Player.ActorLocation - ActorLocation).ConstrainToPlane(FVector::UpVector).GetSafeNormal();
			Player.KillPlayer(FPlayerDeathDamageParams(DeathDir), DeathEffect);
		}

		PlayersInKillRange.Empty();
	}

	UFUNCTION()
	void Run(ASplineActor Spline = nullptr, bool bStopAnimations = true)
	{
		if (bStopAnimations)
			StopSlotAnimation();

		if (Spline != nullptr)
			FollowSplineActor = Spline;

		FollowSplineComp = UHazeSplineComponent::Get(FollowSplineActor);

		float SplineDist = FollowSplineComp.GetClosestSplineDistanceToWorldLocation(ActorLocation);
		SplinePos = FSplinePosition(FollowSplineComp, SplineDist, true);

		bRunning = true;
		bFollowingSpline = true;

		OnStartedRunning.Broadcast(this);
	}

	UFUNCTION()
	void StopRunning()
	{
		bRunning = false;
		bFollowingSpline = false;
	}

	UFUNCTION()
	void Rush(ASplineActor Spline = nullptr)
	{
		if (Spline != nullptr)
			FollowSplineActor = Spline;

		RushSplineComp = UHazeSplineComponent::Get(FollowSplineActor);

		RushTimeLike.PlayFromStart();

		bBreakingWall = true;
	}

	UFUNCTION(NotBlueprintCallable)
	void UpdateRush(float CurValue)
	{
		FVector Loc = RushSplineComp.GetWorldLocationAtSplineFraction(CurValue);
		SetActorLocation(Loc);

		if (bRotateOnRush)
		{
			FRotator Rot = RushSplineComp.GetWorldRotationAtSplineDistance(RushSplineComp.SplineLength * CurValue).Rotator();
			Rot.Pitch = 0.0;
			Rot.Roll = 0.0;
			SetActorRotation(Rot);
		}
	}

	UFUNCTION(NotBlueprintCallable)
	void FinishRush()
	{
		if (bJumping)
			Niagara::SpawnOneShotNiagaraSystemAtLocation(JumpLandingEffect, ActorLocation);

		bBreakingWall = false;
		bJumping = false;
		OnReachedEndOfSpline.Broadcast(this);
	}

	UFUNCTION()
	void Jump(ASplineActor Spline = nullptr)
	{
		if (Spline != nullptr)
			FollowSplineActor = Spline;

		RushSplineComp = UHazeSplineComponent::Get(FollowSplineActor);

		RushTimeLike.PlayFromStart();

		StopSlotAnimation();

		bJumping = true;
	}

	UFUNCTION()
	void StartChasing(AActor Spline = nullptr, bool bForward = true)
	{
		if (Spline != nullptr)
			FollowSplineActor = Spline;

		FollowSplineComp = UHazeSplineComponent::Get(FollowSplineActor);

		float SplineDist = FollowSplineComp.GetClosestSplineDistanceToWorldLocation(ActorLocation);
		SplinePos = FSplinePosition(FollowSplineComp, SplineDist, bForward);

		bChasing = true;
		bFollowingSpline = true;

		OnStartedRunning.Broadcast(this);
	}

	UFUNCTION()
	void TriggerChaseJump()
	{
		bJumping = true;

		ChaseJumpTimeLike.BindUpdate(this, n"UpdateChaseJump");
		ChaseJumpTimeLike.BindFinished(this, n"FinishChaseJump");
		ChaseJumpTimeLike.PlayFromStart();
	}

	UFUNCTION()
	private void UpdateChaseJump(float CurValue)
	{
		ChaseJumpHeightOffset = Math::Lerp(0.0, 250.0, CurValue);
	}

	UFUNCTION()
	private void FinishChaseJump()
	{
		bJumping = false;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (bFollowingSpline && !RushTimeLike.IsPlaying())
		{	
			if (bChasing)
			{
				float DistToClosestPlayer = GetDistanceTo(Game::Mio);
				if (DistToClosestPlayer > GetDistanceTo(Game::Zoe))
					DistToClosestPlayer = GetDistanceTo(Game::Zoe);

				float SpeedAlpha = Math::GetMappedRangeValueClamped(ChaseSpeedDistanceRange, FVector2D(0.0, 1.0), DistToClosestPlayer);
				MoveSpeed = Math::Lerp(500.0, 1000.0, SpeedAlpha);
			}
			else
				MoveSpeed = RunSpeed;


			SplinePos.Move(MoveSpeed * DeltaTime);

			FVector Loc;
			FRotator Rot;
			if (bInterpMovement)
			{
				Loc = Math::VInterpTo(ActorLocation, SplinePos.WorldLocation, DeltaTime, 2.0);
				Rot = Math::RInterpTo(ActorRotation, SplinePos.WorldRotation.Rotator(), DeltaTime, 2.0);
			}
			else
			{
				Loc = SplinePos.WorldLocation;
				Rot = SplinePos.WorldRotation.Rotator();
			}

			Loc.Z += ChaseJumpHeightOffset;

			SetActorLocationAndRotation(Loc, Rot);

			if ((SplinePos.CurrentSplineDistance >= SplinePos.CurrentSpline.SplineLength && Loc.Equals(SplinePos.WorldLocation, 20.0)) || (SplinePos.CurrentSplineDistance <= 0.0 && !SplinePos.IsForwardOnSpline()))
			{
				MoveSpeed = 0.0;
				bFollowingSpline = false;
				bChasing = false;
				bRunning = false;
				OnReachedEndOfSpline.Broadcast(this);
			}
		}
	}
}