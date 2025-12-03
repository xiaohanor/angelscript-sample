event void FDentistChaseBossUpdatePlayrate(float NewPlayRate);

class ADentistChaseBoss : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UHazeSkeletalMeshComponentBase SkelMesh;

	UPROPERTY(DefaultComponent)
	UTemporalLogTransformLoggerComponent TempLogTransformComp;

	UPROPERTY(DefaultComponent)
	UHazeMeshPoseDebugComponent PoseDebugComp;

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedActorComp;

	UPROPERTY(EditAnywhere, Category = "Animations")
	FHazePlaySlotAnimationParams StartAnimationParams;
	default StartAnimationParams.PlayRate = 0.5;

	UPROPERTY(EditAnywhere, Category = "Animations")
	FHazePlaySlotAnimationParams ChaseAnimationParams;

	UPROPERTY(EditInstanceOnly)
	AHazeActor SplineActor;
	UHazeSplineComponent SplineComp;

	UPROPERTY(EditAnywhere, Category = "Settings")
	float TargetPlayerDist = 2500.0;

	UPROPERTY(EditAnywhere, Category = "Settings")
	FName SocketForLocation = n"Spine6"; //n"HeadLightSocket"; 

	UPROPERTY(EditAnywhere, Category = "Settings")
	float MaxPlayRate = 2.0;

	UPROPERTY(EditAnywhere, Category = "Settings")
	float MinPlayRate = 1.0;

	UPROPERTY(EditAnywhere, Category = "Settings")
	float ExtraDistForMaxPlayRate = 500.0;

	UPROPERTY(EditAnywhere, Category = "Settings")
	float ExtraDistForMinPlayRate = -500.0; 

	bool bActive = false;
	bool bEnterDone = false;

	UPROPERTY(BlueprintReadWrite)
	FDentistChaseBossUpdatePlayrate OnUpdatePlayrate;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SplineComp = UHazeSplineComponent::Get(SplineActor);

		SkelMesh.HideBoneByName(n"LeftLowerArm", EPhysBodyOp::PBO_Term);
		SkelMesh.HideBoneByName(n"RightLowerArm", EPhysBodyOp::PBO_Term);

		AddActorDisable(this);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (!bActive)
			return;

		if(!bEnterDone)
			return;

		auto TempLog = TEMPORAL_LOG(this, "Chase Rubberband");
		
		float LowestPlayerSplineDistance = MAX_flt;
			for (auto Player : Game::GetPlayers())
		{
			if (Player.IsPlayerDead())
				continue;
			float PlayerSplineDist = SplineComp.GetClosestSplineDistanceToWorldLocation(Player.ActorLocation);

			if(PlayerSplineDist < LowestPlayerSplineDistance)
				LowestPlayerSplineDistance = PlayerSplineDist;
		}

		FVector SocketLocation = SkelMesh.GetSocketLocation(SocketForLocation);
		const float CurrentSplineDist =  SplineComp.GetClosestSplineDistanceToWorldLocation(SocketLocation);
		const float TargetSplineDist = LowestPlayerSplineDistance - TargetPlayerDist;
		const float DiffToTarget = TargetSplineDist - CurrentSplineDist;
		
		float AnimPlayRate = 0.0;

		// Further away than should be
		if(DiffToTarget > 0)
		{
			float PlayRateAlpha = DiffToTarget / ExtraDistForMaxPlayRate;
			PlayRateAlpha = Math::Saturate(PlayRateAlpha); 

			AnimPlayRate = Math::Lerp(1.0, MaxPlayRate, PlayRateAlpha);
			TempLog.Value("Play Rate Alpha", PlayRateAlpha);
		}
		// Close than should be
		else
		{
			float PlayRateAlpha = DiffToTarget / ExtraDistForMinPlayRate;
			PlayRateAlpha = Math::Saturate(PlayRateAlpha); 

			AnimPlayRate = Math::Lerp(1.0, MinPlayRate, PlayRateAlpha);
			TempLog.Value("Play Rate Alpha", PlayRateAlpha);
		}

		SkelMesh.SetSlotAnimationPlayRate(ChaseAnimationParams.Animation, AnimPlayRate);
		OnUpdatePlayrate.Broadcast(AnimPlayRate);

		TempLog
			.Value("PlayRate", AnimPlayRate)
			.Value("Diff to Target", DiffToTarget)
			.Value("Current Spline dist", CurrentSplineDist)
			.Value("Target Spline Dist", TargetSplineDist)
		;
	}

	UFUNCTION()
	void Activate()
	{
		if(bActive)
			return;

		RemoveActorDisable(this);

		SkelMesh.PlaySlotAnimation(FHazeAnimationDelegate(this, n"OnStartBlendIn"),FHazeAnimationDelegate(this, n"OnStartBlendOut"), StartAnimationParams);
	}

	UFUNCTION()
	private void OnStartBlendIn()
	{
	}

	UFUNCTION()
	private void OnStartBlendOut()
	{
		SkelMesh.PlaySlotAnimation(ChaseAnimationParams);
		bActive = true;
		bEnterDone = true;
	}
};