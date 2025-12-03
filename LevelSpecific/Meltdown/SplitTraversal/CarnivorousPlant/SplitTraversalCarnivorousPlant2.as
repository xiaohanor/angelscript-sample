event void FCarniPlantHasTargetSignature();

UCLASS(Abstract)
class USplitTraversalCarnivorousPlantEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnWakeUp() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnActivatorInteractionStart() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnActivatorInteractionStop() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStartAttack() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStartRetract() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnLostTarget() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnActivateBitePlayerHit() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnRespawnZoeAfterKilledByCarnivorousPlant() {}
}

class ASplitTraversalCarnivorousPlant2 : AWorldLinkDoubleActor
{
	UPROPERTY(DefaultComponent, Attach = FantasyRoot)
	USceneComponent RotateRoot;

	UPROPERTY(DefaultComponent, Attach = RotateRoot)
	UHazeSkeletalMeshComponentBase CarnivorousPlantMesh;

	UPROPERTY(DefaultComponent, Attach = RotateRoot)
	USceneComponent LowerBodyRoot;

	UPROPERTY(DefaultComponent, Attach = RotateRoot)
	USceneComponent StartLocationComp;

	UPROPERTY(DefaultComponent, Attach = RotateRoot)
	USceneComponent HeadRoot;

	UPROPERTY(DefaultComponent, Attach = HeadRoot)
	USceneComponent UpperJawRoot;

	UPROPERTY(DefaultComponent, Attach = HeadRoot)
	USceneComponent LowerJawRoot;

	UPROPERTY(DefaultComponent, Attach = ScifiRoot)
	USceneComponent RotateRootSciFi;

	UPROPERTY(DefaultComponent, Attach = RotateRootSciFi)
	UHazeSkeletalMeshComponentBase RobotArmMesh;

	UPROPERTY(DefaultComponent, Attach = RobotArmMesh, AttachSocket = Head)
	USceneComponent CaptureRoot;

	UPROPERTY(DefaultComponent, Attach = RobotArmMesh, AttachSocket = Arm3)
	USceneCaptureComponent2D CaptureComp;

	UPROPERTY(DefaultComponent, Attach = RotateRootSciFi)
	USceneComponent LowerBodyRootSciFi;

	UPROPERTY(DefaultComponent, Attach = RotateRootSciFi)
	USceneComponent StartLocationCompSciFi;

	UPROPERTY(DefaultComponent, Attach = RotateRootSciFi)
	USceneComponent HeadRootSciFi;

	UPROPERTY(DefaultComponent, Attach = HeadRootSciFi)
	USceneComponent UpperJawRootSciFi;

	UPROPERTY(DefaultComponent, Attach = HeadRootSciFi)
	USceneComponent LowerJawRootSciFi;

	UPROPERTY(EditDefaultsOnly, Category = "DeathEffects")
	TSubclassOf<UDamageEffect> BiteDamageEffect;
	UPROPERTY(EditDefaultsOnly, Category = "DeathEffects")
	TSubclassOf<UDeathEffect> BiteDeathEffect;

	UPROPERTY(EditDefaultsOnly)
	UForceFeedbackEffect ForceFeedback;

	UPROPERTY(DefaultComponent)
	UHazeActionQueueComponent ActionQueueComp;

	UPROPERTY()
	TSubclassOf<ASplitTraversalCarnivorousPlantImpactActor> ImpactActorClass;

	UPROPERTY()
	FCarniPlantHasTargetSignature OnHasTarget;

	UPROPERTY()
	FCarniPlantHasTargetSignature OnTargetLost;

	UPROPERTY()
	FCarniPlantHasTargetSignature OnTargetFound;

	UPROPERTY()
	FCarniPlantHasTargetSignature OnRetract;

	UPROPERTY(EditInstanceOnly)
	TArray<ASplitTraversalCarnivorousPlantTarget> Targets;

	UPROPERTY(EditAnywhere, Category = "CameraShake")
	TSubclassOf<UCameraShakeBase> CameraShake;

	UPROPERTY(EditAnywhere)
	FName HeadSocket = n"HeadSocket";

	UPROPERTY()
	float Reach = 1000.0;

	UPROPERTY()
	float MaxTargetVisibleRange = 2700.0;

	UPROPERTY()
	float HeadRadius = 100.0;

	UPROPERTY()
	float KnockdownDistance = 800.0;

	UPROPERTY()
	float KnockdownDuration = 2.0;

	UPROPERTY()
	float AttackCooldown = 3.0;

	UPROPERTY(Category = AttackSettings)
	FRuntimeFloatCurve AttackCurve;

	UPROPERTY(Category = AttackSettings)
	float AttackDuration = 1.0;

	UPROPERTY(Category = AttackSettings)
	FRuntimeFloatCurve RetractCurve;

	UPROPERTY(Category = AttackSettings)
	float RetractDuration = 1.0;

	FVector HeadStartLocation;
	FVector TargetStartLocation;
	FVector TargetLocation;
	float TargetingAlpha = 0.0;

	float RetractStartJawAlpha = 1.0;
	float JawAlpha;

	FHazeAcceleratedVector AcceleratedTargetLocation;

	ASplitTraversalCarnivorousPlantTarget TargetedTarget;

	bool bActive = false;
	bool bTargeting = true;
	bool bDamagedPlayer = false;


	//Animation Stuff
	float PlayerDistanceFromCenter;
	bool bWakingUp = false;
	bool bAttacking = false;
	bool bAttackingTarget = false;
	bool bRetracting = false;
	bool bLostTarget = false;

#if EDITOR
	UPROPERTY(DefaultComponent)
	UTemporalLogTransformLoggerComponent TransformLogger;
#endif

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();

		HeadStartLocation = HeadRoot.WorldLocation;
		TargetStartLocation = HeadRoot.WorldLocation + HeadRoot.ForwardVector * 2000.0;

		AcceleratedTargetLocation.SnapTo(HeadRoot.WorldLocation + HeadRoot.ForwardVector * 1000.0);

		CaptureComp.HideActorComponents(this);
		CaptureComp.Deactivate();

		SetActorControlSide(Game::Mio);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (bActive)
		{
			if (bTargeting)
			{
				if(IsTargetInRange())
				{
					FVector ZoeLocation = Game::Zoe.ActorLocation;
					ZoeLocation.Z = ActorLocation.Z - 150.0;

					if (TargetingAlpha < 1.0)
					{
						TargetingAlpha += 1.0 * DeltaSeconds;
						TargetingAlpha = Math::Min(TargetingAlpha, 1.0);

						float SmoothAlpha = Curve::SmoothCurveZeroToOne.GetFloatValue(TargetingAlpha);
						TargetLocation = Math::Lerp(TargetStartLocation, ZoeLocation, SmoothAlpha);
					}
					else
					{
						TargetLocation = ZoeLocation;
					}


					//PrintToScreen("Rotation = " + NewRotation);
					//Debug::DrawDebugArrow(CaptureRoot.WorldLocation, AcceleratedTargetLocation.Value + FVector::ForwardVector * 500000.0, 10.0);

					if (StartLocationComp.WorldLocation.Distance(ZoeLocation) > Reach)
						TargetLocation = StartLocationComp.WorldLocation + (TargetLocation - StartLocationComp.WorldLocation).GetSafeNormal() * Reach;
					
					PlayerDistanceFromCenter = AcceleratedTargetLocation.Value.Dist2D(ActorLocation, FVector::UpVector);
				}
				else
				{
					if (HasControl())
						CrumbLostTarget();
				}
			}
			else
			{
				if(bLostTarget)
				{
					if(IsTargetInRange())
						RegainTarget();
				}
				else
				{
					if(!IsTargetInRange() && HasControl())
						CrumbLostTarget();
					else
						CheckPlayerImpact();
				}
			}
			
			SetPlantRotation(DeltaSeconds);
		}
		

		ReplicatePlantMovement();
	}

	private void SetPlantRotation(float DeltaSeconds)
	{
		FRotator TargetRotation = (AcceleratedTargetLocation.Value - RotateRoot.WorldLocation).ConstrainToPlane(FVector::UpVector).GetSafeNormal().Rotation();
		RotateRoot.SetWorldRotation(TargetRotation);
		HeadRoot.SetWorldRotation((AcceleratedTargetLocation.Value - HeadRoot.WorldLocation).GetSafeNormal().Rotation());

		FRotator NewRotation = ((AcceleratedTargetLocation.Value + FVector::ForwardVector * 500000.0) - CaptureRoot.WorldLocation).GetSafeNormal().Rotation();
		//CaptureRoot.SetWorldRotation(NewRotation);
		CaptureComp.SetWorldRotation(NewRotation);

		AcceleratedTargetLocation.AccelerateTo(TargetLocation, 0.5, DeltaSeconds);
	}

	UFUNCTION()
	void Activate()
	{
		if(IsTargetInRange())
			RegainTarget();

		CaptureComp.Activate();
		bActive = true;
		USplitTraversalCarnivorousPlantEventHandler::Trigger_OnWakeUp(this);
		CarnivorousPlantMesh.VisibilityBasedAnimTickOption = EVisibilityBasedAnimTickOption::AlwaysTickPoseAndRefreshBones;
	}

	UFUNCTION()
	void Deactivate()
	{
		bActive = false;
		CarnivorousPlantMesh.VisibilityBasedAnimTickOption = EVisibilityBasedAnimTickOption::OnlyTickMontagesWhenNotRendered;
	}

	void StopControlling()
	{
		CaptureComp.Deactivate();
	}

	void Attack()
	{
		ASplitTraversalCarnivorousPlantTarget PredictedTargetedTarget = nullptr;

		for (auto Target : Targets)
		{
			if (AcceleratedTargetLocation.Value.Distance(Target.FantasyRoot.WorldLocation) < Target.TargetRadius && Game::Zoe.ActorLocation.Distance(Target.FantasyRoot.WorldLocation) < 1000.0)
			{
				if (Target.bBroken)
					continue;

				PredictedTargetedTarget = Target;
			}
		}

		CrumbAttack(PredictedTargetedTarget);
	}

	UFUNCTION(CrumbFunction)
	private void CrumbAttack(ASplitTraversalCarnivorousPlantTarget PredictedTargetedTarget)
	{
		RobotArmMesh.SetAnimTrigger(n"Attack");
		bTargeting = false;
		bDamagedPlayer = false;
		TargetedTarget = nullptr;
		bAttacking = true;

		ActionQueueComp.Duration(AttackDuration, this, n"AttackUpdate");
		ActionQueueComp.Event(this, n"AttackFinished");
		
		if (PredictedTargetedTarget != nullptr)
		{
			TargetLocation = PredictedTargetedTarget.FantasyRoot.WorldLocation;
			TargetedTarget = PredictedTargetedTarget;
			OnHasTarget.Broadcast();
			bAttackingTarget = true;
		}

		USplitTraversalCarnivorousPlantEventHandler::Trigger_OnStartAttack(this);
	}

	UFUNCTION()
	private void AttackUpdate(float Alpha)
	{
		float AttackAlpha = AttackCurve.GetFloatValue(Alpha);
		SetHeadTransform(AttackAlpha);
		SetJawTransform(AttackAlpha);
	}

	UFUNCTION()
	private void AttackFinished()
	{
		bAttacking = false;
		bAttackingTarget = false;

		if (TargetedTarget != nullptr)
		{
			TargetedTarget.Break();
			BP_CableBitten();
			ActionQueueComp.Idle(2.0);
		}

		else
			ActionQueueComp.Idle(0.5);

		SpawnActor(ImpactActorClass, TargetLocation);

		ActionQueueComp.Event(this, n"DelayedRetract");

		ForceFeedback::PlayWorldForceFeedback(ForceFeedback, ScifiRoot.GetWorldLocation(), false, this, 3000, 4000, 1.0, 1, EHazeSelectPlayer::Mio);
		ForceFeedback::PlayWorldForceFeedback(ForceFeedback, FantasyRoot.GetWorldLocation(), false, this, 3000, 4000, 1.0, 1, EHazeSelectPlayer::Zoe);
		Game::Zoe.PlayWorldCameraShake(CameraShake, this, FantasyRoot.GetWorldLocation(), 3000, 4000, 1.0, 1.0, false, EHazeWorldCameraShakeSamplePosition::Player);
	}

	UFUNCTION()
	private void DelayedRetract()
	{
		bRetracting = true;
		ActionQueueComp.Duration(RetractDuration, this, n"RetractUpdate");
		ActionQueueComp.Event(this, n"RetractFinished");
		
		USplitTraversalCarnivorousPlantEventHandler::Trigger_OnStartRetract(this);
	}

	UFUNCTION()
	private void RetractUpdate(float Alpha)
	{
		float RetractAlpha = RetractCurve.GetFloatValue(Alpha);
		SetHeadTransform(RetractAlpha);
		SetJawTransform(RetractAlpha);
	}

	UFUNCTION()
	private void RegainTarget()
	{
		bTargeting = true;
		bLostTarget = false;
		OnTargetFound.Broadcast();
	}

	UFUNCTION()
	void RetractFinished()
	{
		bTargeting = true;
		bRetracting = false;
		OnRetract.Broadcast();
		RetractStartJawAlpha = 1.0;
	}

	UFUNCTION(CrumbFunction)
	void CrumbLostTarget()
	{
		bLostTarget = true;
		bTargeting = false;
		TargetStartLocation = TargetLocation;
		TargetingAlpha = 0.0;
		RetractStartJawAlpha = JawAlpha;

		ActionQueueComp.Empty();
		ActionQueueComp.Idle(1.0);

		if(bAttacking)
		{
			TargetLocation = HeadRoot.WorldLocation;
			ActionQueueComp.Duration(1.0, this, n"RetractUpdate");
			ActionQueueComp.Event(this, n"RetractFinished");
		}
		
		bAttacking = false;
		bAttackingTarget = false;
		AcceleratedTargetLocation.SnapTo(TargetLocation);
		OnTargetLost.Broadcast();

		USplitTraversalCarnivorousPlantEventHandler::Trigger_OnLostTarget(this);
	}

	private void SetHeadTransform(float CurrentValue)
	{
		FVector Location = Math::Lerp(StartLocationComp.WorldLocation, AcceleratedTargetLocation.Value, CurrentValue);
		HeadRoot.SetWorldLocation(Location);
	}

	private void SetJawTransform(float CurrentValue)
	{
		float Alpha = CurrentValue * RetractStartJawAlpha;
		float JawPitch = Math::Lerp(15.0, 0.0, Alpha);

		UpperJawRoot.SetRelativeRotation(FRotator(JawPitch, 0.0, 0.0));
		LowerJawRoot.SetRelativeRotation(FRotator(-JawPitch, 0.0, 0.0));
		LowerBodyRoot.SetRelativeRotation(FRotator(Alpha * -90.0, 0.0, 0.0));

		JawAlpha = Alpha;
	}

	private void ReplicatePlantMovement()
	{
		RotateRootSciFi.WorldRotation = RotateRoot.WorldRotation;
		LowerBodyRootSciFi.RelativeRotation = LowerBodyRoot.RelativeRotation;
		HeadRootSciFi.RelativeLocation = HeadRoot.RelativeLocation;
		HeadRootSciFi.RelativeRotation = HeadRoot.RelativeRotation;
		UpperJawRootSciFi.RelativeRotation = UpperJawRoot.RelativeRotation;
		LowerJawRootSciFi.RelativeRotation = LowerJawRoot.RelativeRotation;
	}

	private void CheckPlayerImpact()
	{
		if (bDamagedPlayer)
			return;

		FVector ClosestShapeLocation;
		AHazePlayerCharacter Player = Game::Zoe;

		FVector SocketLocation = CarnivorousPlantMesh.GetSocketLocation(HeadSocket);

		Player.CapsuleComponent.GetClosestPointOnCollision(SocketLocation, ClosestShapeLocation);
		float DistanceToPlayer = ClosestShapeLocation.Distance(SocketLocation);

		if (DistanceToPlayer <= HeadRadius)
		{
			auto HealthComp = UPlayerHealthComponent::Get(Game::Zoe);
			if (HealthComp.Health.CurrentHealth <= 0.5)
				HealthComp.OnReviveTriggered.AddUFunction(this, n"HandlePlayerRespawned");

			Player.DamagePlayerHealth(0.5,FPlayerDeathDamageParams(),BiteDamageEffect,BiteDeathEffect);

			FVector Impulse = (Player.ActorLocation - CarnivorousPlantMesh.WorldLocation).GetSafeNormal().VectorPlaneProject(FVector::UpVector) * KnockdownDistance;

			Player.ApplyKnockdown(Impulse, KnockdownDuration);
			bDamagedPlayer = true;

			USplitTraversalCarnivorousPlantEventHandler::Trigger_OnActivateBitePlayerHit(this);
		}
	}

	UFUNCTION()
	private void HandlePlayerRespawned()
	{
		auto HealthComp = UPlayerHealthComponent::Get(Game::Zoe);
		HealthComp.OnReviveTriggered.UnbindObject(this);

		USplitTraversalCarnivorousPlantEventHandler::Trigger_OnRespawnZoeAfterKilledByCarnivorousPlant(this);
	}

	bool IsTargetInRange() const
	{
		if(Game::Zoe.IsPlayerDead())
			return false;
		
		return Game::Zoe.ActorLocation.DistSquared(ActorLocation) <= MaxTargetVisibleRange * MaxTargetVisibleRange;
	}

	
	UFUNCTION(BlueprintEvent)
	private void BP_CableBitten(){}
};