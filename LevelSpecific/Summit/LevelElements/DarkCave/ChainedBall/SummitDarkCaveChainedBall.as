asset SummitDarkCaveChainedBallGravitySettings of UMovementGravitySettings
{
	GravityAmount = 4000.0;
}

struct FSummitChainedBallChainData
{
	float ChainLength;
	FVector StartRight;
	FVector StartForward;
}

class ASummitDarkCaveChainedBall : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;
	
	UPROPERTY(EditDefaultsOnly)
	UNiagaraSystem ResetEffectSystem;

	UPROPERTY(DefaultComponent)
	UHazeSphereCollisionComponent SphereComp;
	default SphereComp.SetCollisionProfileName(n"BlockAllDynamic");
	default SphereComp.SphereRadius = 750.0;

	UPROPERTY(DefaultComponent)
	USceneComponent MeshRotateRoot;

	UPROPERTY(DefaultComponent, Attach = MeshRotateRoot)
	USquishTriggerBoxComponent SquishComp;

	UPROPERTY(DefaultComponent)
	UMovementImpactCallbackComponent ImpactComp;

	UPROPERTY(DefaultComponent, Attach = MeshRotateRoot)
	UStaticMeshComponent MeshComp;

	UPROPERTY(DefaultComponent)
	UHazeMovementComponent MoveComp;

	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComp;
	default CapabilityComp.DefaultCapabilityClasses.Add(USummitDarkCaveChainedBallMovementCapability);
	default CapabilityComp.DefaultCapabilityClasses.Add(USummitDarkCaveChainedBallRotationCapability);
	default CapabilityComp.DefaultCapabilityClasses.Add(USummitDarkCaveChainedBallLandInGoalCapability);

	UPROPERTY(DefaultComponent)
	UTeenDragonTailAttackResponseComponent RollResponseComp;

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 50000.0;

	UPROPERTY(DefaultComponent)
	UHazeCrumbSyncedActorPositionComponent SyncedActorComp;
	default SyncedActorComp.SyncRate = EHazeCrumbSyncRate::PlayerSynced;
	default SyncedActorComp.SyncDetailLevel = EHazeActorPositionSyncDetailLevel::Character;

	UPROPERTY(DefaultComponent)
	UHazeCrumbSyncedRotatorComponent SyncedBallRotationComp;
	default SyncedBallRotationComp.SyncRate = EHazeCrumbSyncRate::PlayerSynced;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<UCameraShakeBase> CameraShake;

	UPROPERTY(EditDefaultsOnly)
	UForceFeedbackEffect Rumble;

	UPROPERTY(EditInstanceOnly, Category = "Setup")
	ANightQueenChain Chain;

	UPROPERTY(EditInstanceOnly, Category = "Setup")
	TArray<ANightQueenChain> AttachedChains;

	UPROPERTY(EditInstanceOnly, Category = "Setup")
	bool bStartDisabled = false;

	UPROPERTY(EditInstanceOnly, Category = "Setup")
	ASplineActor LockSpline;

	UPROPERTY(EditInstanceOnly, Category = "Setup|Chain Placement")
	bool bConstrainChainPlacement = false;

	UPROPERTY(EditInstanceOnly, Category = "Setup|Chain Placement", Meta = (EditCondition = "bConstrainChainPlacement", EditConditionHides))
	float ChainDistanceHorizontally = 600.0;

	UPROPERTY(EditInstanceOnly, Category = "Setup|Chain Placement", Meta = (EditCondition = "bConstrainChainPlacement", EditConditionHides))
	float ChainDistanceVertically = 1000.0;

	UPROPERTY(EditAnywhere, Category = "Settings|Roll Impact")
	float RollImpactMinSpeed = 1500.0;

	UPROPERTY(EditAnywhere, Category = "Settings|Roll Impact")
	float HorizontalSpeedGroundDeceleration = 1.0;

	UPROPERTY(EditAnywhere, Category = "Settings|Roll Impact")
	float RollImpactHorizontalImpulseScale = 0.75;

	UPROPERTY(EditAnywhere, Category = "Settings|Roll Impact")
	float RollImpactVerticalImpulseScale = 0.07;

	UPROPERTY(EditAnywhere, Category = "Settings|Roll Impact")
	float RollImpactAngularVelocityMultiplier = 1.5;

	UPROPERTY(EditAnywhere)
	ASummitDarkCaveChainedBallGoal Goal;

	FVector AngularVelocity;
	bool bIsChained = true;
	bool bLandedInGoal;

	FVector ResetLocation;
	FRotator ResetRotation;

	TMap<ANightQueenChain, FSummitChainedBallChainData> ChainData;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		if(AttachedChains.Num() > 0)
		{
			if(bConstrainChainPlacement)
			{
				float AnglePerChain = 360.0 / float(AttachedChains.Num());
				for(int i = 0; i < AttachedChains.Num(); i++)
				{
					auto PlacementChain = AttachedChains[i];
					FVector StartForward = ActorForwardVector;

					FVector ChainForward = StartForward.RotateAngleAxis(AnglePerChain * i, ActorUpVector);
					PlacementChain.ActorLocation = ActorLocation 
						+ ChainForward * ChainDistanceHorizontally
						+ ActorUpVector * ChainDistanceVertically;
				}
			}
			RotateChainsTowardsCenter(ActorLocation);
		}
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		ResetLocation = ActorLocation;
		ResetRotation = ActorRotation;
		
		SetActorControlSide(Game::Zoe);

		ApplyDefaultSettings(SummitDarkCaveChainedBallGravitySettings);

		if(Chain != nullptr)
			Chain.OnNightQueenMetalMelted.AddUFunction(this, n"OnChainMelted");
		else
			bIsChained = false;

		RollResponseComp.OnHitByRoll.AddUFunction(this, n"OnHitByRoll");

		if (bStartDisabled)
			AddActorDisable(this);
		
		for(auto AttachedChain : AttachedChains)
		{
			if(AttachedChain == nullptr)
				continue;

			AttachedChain.OnChainMelted.AddUFunction(this, n"OnAttachedChainMelted");
			FVector ChainToBallDelta = ActorLocation - AttachedChain.ActorLocation;
			float ChainDistance = ChainToBallDelta.Size();

			FSummitChainedBallChainData NewChainData;
			NewChainData.ChainLength = ChainDistance;
			NewChainData.StartRight = AttachedChain.ActorRightVector;
			NewChainData.StartForward = AttachedChain.ActorForwardVector;
			ChainData.Add(AttachedChain, NewChainData);

			MoveComp.AddMovementIgnoresActor(this, AttachedChain);
		}
		RotateChainsTowardsCenter(ActorLocation);
		MeshComp.AddTag(n"Walkable");

		if(LockSpline != nullptr)
		{
			TArray<ASplineActor> LockSplines;
			LockSplines.Add(LockSpline);
			MoveComp.ApplySplineCollision(LockSplines, this, ESplineCollisionWorldUp::MovementWorldUp);
		}
	}
	
	UFUNCTION()
	private void OnAttachedChainMelted(ANightQueenChain MeltedChain)
	{
		AttachedChains.RemoveSingleSwap(MeltedChain);
	}

	UFUNCTION()
	private void OnChainMelted()
	{
		bIsChained = false;
	}

	UFUNCTION()
	private void OnHitByRoll(FRollParams Params)
	{
		if(bIsChained)
			return;

		FVector DirFromPlayer = (ActorLocation - Params.PlayerInstigator.ActorCenterLocation).GetSafeNormal(); 
		float SpeedAtHit = Math::Max(Params.SpeedAtHit, RollImpactMinSpeed);

		FVector Impulse = DirFromPlayer * SpeedAtHit * RollImpactHorizontalImpulseScale
			+ FVector::UpVector * SpeedAtHit * RollImpactVerticalImpulseScale;

		TEMPORAL_LOG(this).DirectionalArrow("Impulse", ActorLocation, Impulse, 20, 4000, FLinearColor::Red);

		if(AttachedChains.IsEmpty())
		{
			AngularVelocity += Impulse.CrossProduct(FVector::UpVector) * RollImpactAngularVelocityMultiplier;
			MoveComp.AddPendingImpulse(Impulse);
		}

		FSummitDarkCaveChainedBallImpactedByRollParams EventParams;
		EventParams.RollImpactLocation = Params.HitLocation;
		EventParams.LaunchDir = Impulse.GetSafeNormal();
		EventParams.LaunchSpeed = Impulse.Size();
		USummitDarkCaveChainedBallEventHandler::Trigger_OnBallImpactedByRoll(this, EventParams);

		PlayFeedback();
	}

	void ResetBall()
	{
		MoveComp.Reset();
		Niagara::SpawnOneShotNiagaraSystemAtLocation(ResetEffectSystem, ActorLocation);
		Niagara::SpawnOneShotNiagaraSystemAtLocation(ResetEffectSystem, ResetLocation);
		USummitDarkCaveChainedBallEventHandler::Trigger_OnBallReset(this, FSummitDarkCaveResetParams(ActorLocation, ResetLocation));
		ActorLocation = ResetLocation;
	}

	UFUNCTION()
	void RemoveActorStartDisabled()
	{
		RemoveActorDisable(this);
	}

	UFUNCTION()
	void ActivateAppearanceEffect()
	{
		Niagara::SpawnOneShotNiagaraSystemAtLocation(ResetEffectSystem, ActorLocation);
	}

	void SetNewRelocation(FVector NewLocation)
	{
		ResetLocation = NewLocation;
	}

	void RotateChainsTowardsCenter(FVector CenterLocation)
	{
		for(auto AttachedChain : AttachedChains)
		{
			if(AttachedChain == nullptr)
				continue;
			
			FVector AttachLocation = CenterLocation;
			FVector ChainToBallDir = (AttachLocation - AttachedChain.ActorLocation).GetSafeNormal(); 
#if EDITOR
			if(!Editor::IsPlaying())
			{
				AttachedChain.SetActorRotation(FQuat::MakeFromZ(-ChainToBallDir));
				continue;
			}
#endif
			if(!ChainData.Contains(AttachedChain))
				continue;

			auto AttachedChainData = ChainData[AttachedChain];
			AttachedChain.SetActorRotation(FQuat::MakeFromZX(-ChainToBallDir, AttachedChainData.StartForward));
		}
	}

	UFUNCTION()
	void SetEndState()
	{
		ActorLocation = Goal.BallTargetLocation.WorldLocation;

		for(auto AttachedChain : AttachedChains)
		{
			AttachedChain.AddActorDisable(this);
		}

		bLandedInGoal = true;
	}

	void PlayFeedback()
	{
		for (AHazePlayerCharacter Player : Game::Players)
		{
			Player.PlayWorldCameraShake(CameraShake, this, ActorLocation, 500.0, 4000.0);
			float Intensity = (Player.ActorLocation - ActorLocation).Size() / 3000.0;
			Player.PlayForceFeedback(Rumble, false, false, this, Intensity);
		}
	}
};