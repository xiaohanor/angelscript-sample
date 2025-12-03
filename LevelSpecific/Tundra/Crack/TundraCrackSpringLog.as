UCLASS(Abstract)
class ATundraCrackSpringLog : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UHazeSkeletalMeshComponentBase Roots;
#if EDITOR
	default Roots.bUpdateAnimationInEditor = true;
#endif

	UPROPERTY(DefaultComponent, Attach=Root)
	UFauxPhysicsTranslateComponent FauxHangerComp;
	default FauxHangerComp.ConstrainBounce = 0.0;
	default FauxHangerComp.NetworkMode = EFauxPhysicsTranslateNetworkMode::SyncedFromActorControl;
	default FauxHangerComp.bConstrainX = true;
	default FauxHangerComp.bConstrainY = true;
	default FauxHangerComp.bConstrainZ = true;

	UPROPERTY(DefaultComponent, Attach=FauxHangerComp)
	UFauxPhysicsTranslateComponent FauxTranslateComp;
	default FauxTranslateComp.NetworkMode = EFauxPhysicsTranslateNetworkMode::SyncedFromActorControl;

	UPROPERTY(DefaultComponent, Attach=FauxTranslateComp)
	UStaticMeshComponent Mesh;
	default Mesh.CollisionProfileName = CollisionProfile::NoCollision;

	UPROPERTY(DefaultComponent, Attach=FauxTranslateComp)
	UHazeSkeletalMeshComponentBase NyparnAttachPoint;
	default NyparnAttachPoint.bHiddenInGame = true;
	default NyparnAttachPoint.CollisionProfileName = CollisionProfile::NoCollision;

	UPROPERTY(DefaultComponent, Attach=Mesh)
	UBoxComponent Collision;
	default Collision.CollisionProfileName = CollisionProfile::BlockAllDynamic;

	UPROPERTY(DefaultComponent, Attach=Mesh)
	UDeathTriggerComponent PlayerKillTrigger;

	UPROPERTY(DefaultComponent)
	UTundraPlayerSnowMonkeyCeilingClimbComponent CeilingClimbComp;

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 15000.0;

#if EDITOR
	UPROPERTY(DefaultComponent)
	UTundraCrackSpringLogVisualizerComponent VisualizerComp;
#endif

	UPROPERTY(EditAnywhere)
	FVector AxisToTranslate = -FVector::ForwardVector;

	/* This acceleration will be applied to the force applied to pull back the log */
	UPROPERTY(EditAnywhere)
	float MaxForceAcceleration = 200000.0;

	UPROPERTY(EditAnywhere)
	FRuntimeFloatCurve AccelerationCurve;
	default AccelerationCurve.AddDefaultKey(0.0, 1.0);
	default AccelerationCurve.AddDefaultKey(1.0, 0.0);

	UPROPERTY(EditAnywhere)
	float MaxForce = 200000.0;

	UPROPERTY(EditAnywhere)
	float ForceWhenMonkeyHanging = 2000.0;

	UPROPERTY(EditAnywhere)
	float SpringBackForce = 2000.0;

	UPROPERTY(EditAnywhere)
	FVector RootsRelativeRootOffset = FVector(0.0, -20.0, -50.0);

	UPROPERTY(EditAnywhere)
	FVector RootsAttachPivotLocation = FVector(90.0, 140.0, 315.0);

	UPROPERTY(EditAnywhere)
	FRotator RootsRelativeRotationOffsets = FRotator(0.0, -90.0, -90.0);

	UPROPERTY(EditAnywhere)
	UForceFeedbackEffect LoweredToBottomFF;

	float CurrentForce = 0.0;

	bool bHasLoweredToBottom = false;

	private bool bNyparnAttached = false;
	private bool bLaunched = false;
	FHazeAcceleratedRotator RotationOffset;
	FHazeAcceleratedFloat AcceleratedHangerForce;
	FRotator InitialRotation;
	bool bMonkeyAttached = false;
	bool bKillTriggerEnabled = false;
	FVector AnimPosition;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		PlayerKillTrigger.DisableDeathTrigger(this);
		AcceleratedHangerForce.SnapTo(ForceWhenMonkeyHanging);
		InitialRotation = Mesh.RelativeRotation;
		SetActorControlSide(Game::Zoe);
		CeilingClimbComp.OnAttach.AddUFunction(this, n"OnMonkeyAttach");
		CeilingClimbComp.OnDeatch.AddUFunction(this, n"OnMonkeyDetach");
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(bMonkeyAttached)
			AcceleratedHangerForce.AccelerateTo(100.0, 4.5, DeltaSeconds);

		float Velocity = FauxTranslateComp.GetVelocity().DotProduct(AxisToTranslate);
		if(Velocity > 2000.0)
		{
			TryEnableDeathTrigger();
		}
		else
		{
			TryDisableDeathTrigger();
		}

		HandleBigCrackBirdHit(DeltaSeconds);
		HandleLifeGiving();
		HandleFauxTranslateForce();
		RotationOffset.SpringTo(FRotator::ZeroRotator, 30.0, 0.2, DeltaSeconds);
		Mesh.RelativeRotation = InitialRotation + RotationOffset.Value;

		if(!bHasLoweredToBottom && IsLoweredToBottom())
		{
			bHasLoweredToBottom = true;
			ForceFeedback::PlayWorldForceFeedback(LoweredToBottomFF, Mesh.WorldLocation, true, this, 400, 1600);
		}
	}

	void TryEnableDeathTrigger()
	{
		if(bKillTriggerEnabled)
			return;

		PlayerKillTrigger.EnableDeathTrigger(this);
		bKillTriggerEnabled = true;
	}

	void TryDisableDeathTrigger()
	{
		if(!bKillTriggerEnabled)
			return;

		PlayerKillTrigger.DisableDeathTrigger(this);
		bKillTriggerEnabled = false;
	}

	private void HandleBigCrackBirdHit(float DeltaTime)
	{
		if(bLaunched)
			return;

		if(bNyparnAttached)
			return;

		FVector Velocity = FauxTranslateComp.GetVelocity();
		FVector Delta = Velocity * DeltaTime;
		if(Delta.Equals(FVector::ZeroVector))
			return;

		FHazeTraceSettings Trace = Trace::InitFromPrimitiveComponent(Collision);
		Trace.IgnoreActor(this);
		Trace.IgnorePlayers();
		FHitResultArray Hits = Trace.QueryTraceMulti(Collision.WorldLocation, Collision.WorldLocation + Delta);

		ABigCrackBird BigCrackBird;
		for(FHitResult Hit : Hits.BlockHits)
		{
			BigCrackBird = Cast<ABigCrackBird>(Hit.Actor);
			if(BigCrackBird != nullptr && !BigCrackBird.bIsHit)
			{
				FauxTranslateComp.ApplyImpulse(FauxTranslateComp.WorldLocation, -FauxTranslateComp.GetVelocity() * 0.7);
				//FVector BirdImpulse = Velocity * 1.5;

				// Clamp any speed above 5000 to 10000 and ignore speeds lower than 5000. This makes it more robust.
				// if(BirdImpulse.Size() > 5000.0)
				// {
				// 	BirdImpulse = BirdImpulse.GetSafeNormal() * 10000.0;
				// }
				// else
				// {
				// 	return;
				// }

				BigCrackBird.CrumbHitWithLog();
				bLaunched = true;
				return;
			}
		}
	}

	UFUNCTION()
	private void OnMonkeyAttach()
	{
		if(!bMonkeyAttached)
			AcceleratedHangerForce.SnapTo(ForceWhenMonkeyHanging);

		bMonkeyAttached = true;
	}

	UFUNCTION()
	private void OnMonkeyDetach()
	{
		//bMonkeyAttached = false;
	}

	private void HandleLifeGiving()
	{
		if(!bNyparnAttached)
			return;

		FauxTranslateComp.ApplyForce(FauxTranslateComp.WorldLocation, AxisToTranslate * CurrentForce);
	}

	private void HandleFauxTranslateForce()
	{
		float Force = 0.0;

		if(bMonkeyAttached || bNyparnAttached)
			Force -= AcceleratedHangerForce.Value;
		else
			Force += SpringBackForce;

		FauxHangerComp.ApplyForce(FauxTranslateComp.WorldLocation, FVector::UpVector * Force);
	}

	void OnNyparnInteract(ATundraCrackSpringLogNyparn Nyparn)
	{
		bNyparnAttached = true;

		FTundraCrackSpringLogEffectParams Params;
		Params.Nyparn = Nyparn;
		UTundraCrackSpringLogEffectHandler::Trigger_OnGrab(this, Params);
	}

	void OnNyparnStopInteract(ATundraCrackSpringLogNyparn Nyparn)
	{
		bNyparnAttached = false;
		float Force = (1.0 - Math::NormalizeToRange(CurrentForce, 0.0, -MaxForce)) * 50.0;
		CurrentForce = 0.0;
		RotationOffset.SnapTo(RotationOffset.Value, FRotator(0.0, Force * (Math::RandBool() ? -1.0 : 1.0), Force));

		FTundraCrackSpringLogEffectParams Params;
		Params.Nyparn = Nyparn;
		UTundraCrackSpringLogEffectHandler::Trigger_OnRelease(this, Params);
	}

	void UpdateRawHorizontalInput(float RawHorizontalInput)
	{
		// if(RawHorizontalInput >= 0.0)
		// 	return;

		float Value = Math::Abs(CurrentForce / MaxForce);
        if(RawHorizontalInput >= 0.0)
            Value = 1.0 - Value;

		float CurrentAcceleration = AccelerationCurve.GetFloatValue(Value) * MaxForceAcceleration;
		CurrentForce += RawHorizontalInput * CurrentAcceleration * Time::GetActorDeltaSeconds(this);
		CurrentForce = Math::Clamp(CurrentForce, -MaxForce, 0);
		PrintToScreen(""+CurrentForce);
	}

	bool IsLoweredToBottom() const
	{
		return Math::IsNearlyEqual(FauxHangerComp.RelativeLocation.Z, FauxHangerComp.MinZ, 2.0);
	}

	FTransform GetLogicalMeshTransform() const property
	{
		return FTransform(FRotator::MakeFromXZ(-Mesh.UpVector, -Mesh.RightVector), Mesh.WorldLocation);
	}
}

#if EDITOR
UCLASS(NotPlaceable, NotBlueprintable)
class UTundraCrackSpringLogVisualizerComponent : UActorComponent
{
	default bIsEditorOnly = true;
}

class UTundraCrackSpringLogVisualizer : UHazeScriptComponentVisualizer
{
	default VisualizedClass = UTundraCrackSpringLogVisualizerComponent;

	UFUNCTION(BlueprintOverride)
	void VisualizeComponent(const UActorComponent Component)
	{
		auto SpringLog = Cast<ATundraCrackSpringLog>(Component.Owner);
		DrawPoint(SpringLog.LogicalMeshTransform.TransformPosition(SpringLog.RootsAttachPivotLocation), FLinearColor::Red, 30.0);
	}
}
#endif