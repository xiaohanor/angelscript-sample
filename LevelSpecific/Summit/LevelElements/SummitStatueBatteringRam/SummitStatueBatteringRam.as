struct FSummitStatueBatteringRamHitEventParams
{
	UPROPERTY()
	FVector HitLocation;

	UPROPERTY()
	AActor HitActor;
}

event void ESummitStatueBatteringRamHitEvent(FSummitStatueBatteringRamHitEventParams Params);

class ASummitStatueBatteringRam : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	USummitStatueBatteringRamRotationRootComponent RotateRoot;

	UPROPERTY(DefaultComponent, Attach = RotateRoot)
	USceneComponent NoRotateRoot;
	default NoRotateRoot.bAbsoluteRotation = true;

	UPROPERTY(DefaultComponent, Attach = NoRotateRoot)
	UStaticMeshComponent MeshComp;

	UPROPERTY(DefaultComponent, Attach = NoRotateRoot)
	USceneComponent LowerBottomLeftChainAttach;

	UPROPERTY(DefaultComponent, Attach = NoRotateRoot)
	USceneComponent LowerBottomRightChainAttach;

	UPROPERTY(DefaultComponent, Attach = NoRotateRoot)
	USceneComponent LowerTopLeftChainAttach;

	UPROPERTY(DefaultComponent, Attach = NoRotateRoot)
	USceneComponent LowerTopRightChainAttach;

	UPROPERTY(DefaultComponent, Attach = NoRotateRoot)
	UStaticMeshComponent RollHitCollisionComp;
	default RollHitCollisionComp.SetHiddenInGame(true);
	
	UPROPERTY(DefaultComponent, Attach = RollHitCollisionComp)
	UTeenDragonTailAttackResponseComponent ResponseComp;
	default ResponseComp.bIsPrimitiveParentExclusive = true;

	UPROPERTY(DefaultComponent, Attach = MeshComp)
	USceneComponent FeetTraceRoot;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent BottomPillarMeshComp;

	UPROPERTY(DefaultComponent, Attach = BottomPillarMeshComp)
	USceneComponent UpperBottomLeftChainAttach;

	UPROPERTY(DefaultComponent, Attach = BottomPillarMeshComp)
	USceneComponent UpperBottomRightChainAttach;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent TopPillarMeshComp;

	UPROPERTY(DefaultComponent, Attach = TopPillarMeshComp)
	USceneComponent UpperTopLeftChainAttach;

	UPROPERTY(DefaultComponent, Attach = TopPillarMeshComp)
	USceneComponent UpperTopRightChainAttach;

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 50000.0;

	UPROPERTY(DefaultComponent)
	UTemporalLogTransformLoggerComponent TempLogTransformComp;

	UPROPERTY(DefaultComponent)
	UHazeCrumbSyncedRotatorComponent SyncedPendulumRotation;
	default SyncedPendulumRotation.SyncRate = EHazeCrumbSyncRate::PlayerSynced;

	UPROPERTY(EditAnywhere, Category = "Settings")
	float RollImpulse = 100.0;

	UPROPERTY(EditAnywhere, Category = "Settings")
	float PendulumGravityPerDegreeRotation = 2.0;

	UPROPERTY(EditAnywhere, Category = "Settings")
	float PendulumFriction = 0.7;

	UPROPERTY(EditAnywhere, Category = "Settings")
	float BounceRestitution = 0.2;

	UPROPERTY(EditAnywhere, Category = "Settings")
	TSubclassOf<UCameraShakeBase> TailImpactCameraShake;

	UPROPERTY(EditAnywhere, Category = "Settings")
	UForceFeedbackEffect RumbleOnTailHit;

	UPROPERTY()
	ESummitStatueBatteringRamHitEvent OnStatueHitTarget;

	TArray<AActor> TargetsHit;

	float PendulumSpeed;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		ResponseComp.OnHitByRoll.AddUFunction(this, n"OnHitByRoll");
	}

	UFUNCTION()
	private void OnHitByRoll(FRollParams Params)
	{
		PendulumSpeed += RollImpulse;
		FSummitStatueBatteringRamOnHitByRollParams EventParams;
		EventParams.HitLocation = Params.HitLocation;
		USummitStatueBatteringRamEventHandler::Trigger_OnHitByRoll(this, EventParams);

		Params.PlayerInstigator.PlayCameraShake(TailImpactCameraShake, this);
		Params.PlayerInstigator.PlayForceFeedback(RumbleOnTailHit, false, true, this);
	}

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		FRotator NewRotation = ActorRotation;
		NewRotation.Pitch = 0.0;
		NewRotation.Roll = 0.0;
		NoRotateRoot.WorldRotation = NewRotation;

		RotateChainsTowardsAttach();
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(HasControl())
		{
			PendulumSpeed -= RotateRoot.RelativeRotation.Pitch * PendulumGravityPerDegreeRotation * DeltaSeconds;
			PendulumSpeed = Math::FInterpTo(PendulumSpeed, 0, DeltaSeconds, PendulumFriction);
			RotateRoot.RelativeRotation += FRotator(PendulumSpeed * DeltaSeconds, 0, 0);
			SyncedPendulumRotation.SetValue(RotateRoot.RelativeRotation);

			TraceForObstacles();
		}
		else
		{
			RotateRoot.RelativeRotation = SyncedPendulumRotation.Value;
		}

		RotateChainsTowardsAttach();
	}

	void TraceForObstacles()
	{
		FHazeTraceSettings Trace;
		Trace.TraceWithChannel(ECollisionChannel::ECC_WorldDynamic);

		FHazeTraceShape TraceShape = FHazeTraceShape::MakeSphere(200);
		Trace.UseShape(TraceShape);
		Trace.IgnoreActor(this);
		Trace.IgnoreActors(TargetsHit);
		FVector Start = FeetTraceRoot.WorldLocation;
		FVector End = Start + FeetTraceRoot.ForwardVector * 50.0;
		auto Hit = Trace.QueryTraceSingle(Start, End);
		TEMPORAL_LOG(this)
			.HitResults("Target Trace", Hit, TraceShape)
		;
		if(Hit.bBlockingHit)
		{
			auto TargetComp = USummitStatueBatteringRamTargetComponent::Get(Hit.Actor);
			if(TargetComp != nullptr)
			{
				CrumbSendHitEvent(Hit);
				PendulumSpeed *= -1;
				PendulumSpeed *= BounceRestitution;
				TargetsHit.AddUnique(Hit.Actor);
			}
		}
	}

	UFUNCTION(CrumbFunction, NotBlueprintCallable)
	private void CrumbSendHitEvent(FHitResult HitResult)
	{
		FSummitStatueBatteringRamHitEventParams HitParams;
		HitParams.HitActor = HitResult.Actor;
		HitParams.HitLocation = HitResult.ImpactPoint;

		OnStatueHitTarget.Broadcast(HitParams);

		FSummitStatueBatteringRamOnHitPillarParams EventParams;
		EventParams.PillarHitLocation = HitResult.ImpactPoint;

		USummitStatueBatteringRamEventHandler::Trigger_OnHitPillar(this, EventParams);
	}
	
	void RotateChainsTowardsAttach()
	{
		FRotator NewRotation = FRotator::MakeFromZY(UpperBottomLeftChainAttach.WorldLocation - LowerBottomLeftChainAttach.WorldLocation, ActorRightVector);
		LowerBottomLeftChainAttach.SetWorldRotation(NewRotation);
		
		NewRotation = FRotator::MakeFromZY(UpperBottomRightChainAttach.WorldLocation - LowerBottomRightChainAttach.WorldLocation, ActorRightVector);
		LowerBottomRightChainAttach.SetWorldRotation(NewRotation);
		
		NewRotation = FRotator::MakeFromZY(UpperTopLeftChainAttach.WorldLocation - LowerTopLeftChainAttach.WorldLocation, ActorRightVector);
		LowerTopLeftChainAttach.SetWorldRotation(NewRotation);
		
		NewRotation = FRotator::MakeFromZY(UpperTopRightChainAttach.WorldLocation - LowerTopRightChainAttach.WorldLocation, ActorRightVector);
		LowerTopRightChainAttach.SetWorldRotation(NewRotation);
	}

	FVector GetTopChainAttachLocation(USceneComponent ChainBottomAttach) const
	{
		FVector ChainTopAttachLocation;
		ChainTopAttachLocation = ChainBottomAttach.WorldLocation;
		ChainTopAttachLocation += RotateRoot.UpVector * (RotateRoot.RelativeLocation.Z - ChainBottomAttach.RelativeLocation.Z);
		return ChainTopAttachLocation;
	}

#if EDITOR
	UFUNCTION(BlueprintOverride)
	void OnActorModifiedInEditor()
	{
		RotateChainsTowardsAttach();
	}

	UFUNCTION(BlueprintOverride)
	void OnVisualizeInEditor() const
	{
		Debug::DrawDebugSphere(LowerBottomLeftChainAttach.WorldLocation, 100, 12, FLinearColor::White);
		Debug::DrawDebugSphere(LowerBottomRightChainAttach.WorldLocation, 100, 12, FLinearColor::White);
		Debug::DrawDebugSphere(LowerTopLeftChainAttach.WorldLocation, 100, 12, FLinearColor::White);
		Debug::DrawDebugSphere(LowerTopRightChainAttach.WorldLocation, 100, 12, FLinearColor::White);

		Debug::DrawDebugSphere(UpperTopLeftChainAttach.WorldLocation, 100, 12, FLinearColor::Black);
		Debug::DrawDebugSphere(UpperTopRightChainAttach.WorldLocation, 100, 12, FLinearColor::Black);
		Debug::DrawDebugSphere(UpperBottomLeftChainAttach.WorldLocation, 100, 12, FLinearColor::Black);
		Debug::DrawDebugSphere(UpperBottomRightChainAttach.WorldLocation, 100, 12, FLinearColor::Black);
	}
#endif
};

class USummitStatueBatteringRamRotationRootComponent : USceneComponent
{
#if EDITOR
	UFUNCTION(BlueprintOverride)
	void OnComponentModifiedInEditor()
	{
		auto Statue = Cast<ASummitStatueBatteringRam>(Owner);
		if(Statue == nullptr)
			return;

		Statue.RotateChainsTowardsAttach();
	}
#endif
}