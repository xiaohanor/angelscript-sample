event void FSplitTraversalPushableMushroomOnBounced(FSplitTraversalPushableMushroomImpact ImpactData);

UCLASS(Abstract)
class ASplitTraversalPushableMushroom : AWorldLinkDoubleActor
{
	UPROPERTY(DefaultComponent, Attach = ScifiRoot)
	UBoxComponent BoxComp;
	default BoxComp.CollisionProfileName = CollisionProfile::PlayerCharacter;
	default BoxComp.bGenerateOverlapEvents = false;

	UPROPERTY(DefaultComponent, Attach = ScifiRoot)
	UInteractionComponent InteractionComp;

	UPROPERTY(DefaultComponent)
	UHazeMovementComponent MovementComp;
	default MovementComp.bAllowUsingBoxCollisionShape = true;
	default MovementComp.bCanRerunMovement = true;

	UPROPERTY(DefaultComponent, Attach = FantasyRoot)
	USceneComponent MushroomRoot;

	UPROPERTY(DefaultComponent, Attach = ScifiRoot)
	USceneComponent BoxBounceRoot;

	UPROPERTY(DefaultComponent, Attach = FantasyRoot)
	USceneComponent VFXRoot;

	UPROPERTY(DefaultComponent)
	UMovementImpactCallbackComponent ImpactComp;

	UPROPERTY(DefaultComponent, Attach = VFXRoot)
	UNiagaraComponent MushroomPushVFXComp;

	UPROPERTY(DefaultComponent)
	UHazeCrumbSyncedActorPositionComponent SyncedPositionComp;
	default SyncedPositionComp.SyncDetailLevel = EHazeActorPositionSyncDetailLevel::Character;
	default SyncedPositionComp.SyncRate = EHazeCrumbSyncRate::High;

	UPROPERTY(DefaultComponent, Attach = FantasyRoot)
	UCameraShakeForceFeedbackComponent CameraShakeForceFeedbackComponent;

	UPROPERTY()
	FHazeTimeLike BounceTimeLike;
	default BounceTimeLike.UseSmoothCurveZeroToOne();
	default BounceTimeLike.Duration = 1.0;

	UPROPERTY(EditAnywhere)
	float PushForce = 300.0;

	UPROPERTY(EditAnywhere)
	float Friction = 2.4;

	UPROPERTY(EditAnywhere)
	float MinSpeedToBounce = 100;

	UPROPERTY(EditAnywhere)
	float MinTimeBetweenImpacts = 0.5;

	UPROPERTY(EditAnywhere)
	float BounceFactor = 0.5;

	UPROPERTY(EditAnywhere)
	UHazeCameraSpringArmSettingsDataAsset CameraSettings;

	FHazeAcceleratedRotator AccWheelRot;
	FRotator TargetRotation;

	UPROPERTY()
	float WheelPushForce;

	bool bIsMoving = false;
	FVector VelocityOnStoppedMoving;

	float FFProgress = 0.0;

	UPROPERTY()
	FSplitTraversalPushableMushroomOnBounced OnBounced;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();

		MovementComp.OverrideResolver(USplitTraversalPushableMushroomMovementResolver, this);
		BounceTimeLike.BindUpdate(this, n"BounceTimeLikeUpdate");
		ImpactComp.OnGroundImpactedByPlayer.AddUFunction(this, n"HandleGroundImpact");
		InteractionComp.OnInteractionStopped.AddUFunction(this, n"HandleInteractionStopped");
		SetActorControlSide(Game::Mio);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (WheelPushForce > 5.0)
		{
			if (TargetRotation.AngularDistance(AccWheelRot.Value) > 90.0)
				TargetRotation.Yaw += 180.0;

			AccWheelRot.AccelerateTo(TargetRotation, 1.5, DeltaSeconds);
			BP_UpdateWheelRotation(AccWheelRot.Value);
		}

		if (bIsMoving)
		{
			float ForceAlpha = MovementComp.Velocity.Size() * 0.005;

			PrintToScreen("Force = " + ForceAlpha);
			
			float FFFrequency = 20.0;
			float FFIntensity = 0.2;

			FFFrequency *= ForceAlpha;
			FFIntensity *= ForceAlpha;

			FFProgress += FFFrequency * DeltaSeconds;

			FHazeFrameForceFeedback FF;
			FF.LeftMotor = Math::Sin(FFProgress) * FFIntensity;
			FF.RightMotor = Math::Sin(-FFProgress) * FFIntensity;
			Game::Mio.SetFrameForceFeedback(FF);
		}
	}

	UFUNCTION(BlueprintEvent)
	private void BP_UpdateWheelRotation(FRotator Rotation){}

	UFUNCTION()
	private void HandleInteractionStopped(UInteractionComponent InteractionComponent,
	                                      AHazePlayerCharacter Player)
	{
		InteractionComp.Disable(this);
		Timer::SetTimer(this, n"HandleReactivateInteract", 0.5);
	}

	UFUNCTION()
	private void HandleReactivateInteract()
	{
		InteractionComp.Enable(this);
	}

	UFUNCTION()
	private void HandleGroundImpact(AHazePlayerCharacter Player)
	{
		if (Player.IsZoe())
		{
			CameraShakeForceFeedbackComponent.ActivateCameraShakeAndForceFeedback();
			Player.FlagForLaunchAnimations(Player.ActorForwardVector * Player.ActorUpVector * 1000);
			Player.AddMovementImpulse(FVector(0, 0, 2000));
			BounceTimeLike.PlayFromStart();
			BP_GroundImpact();

			USplitTraversalPushableMushroomEventHandler::Trigger_OnBounce(this);
		}
	}

	UFUNCTION(BlueprintEvent)
	private void BP_GroundImpact(){}

	UFUNCTION()
	private void BounceTimeLikeUpdate(float CurrentValue)
	{
		float ScaleMultiplier = Math::Lerp(1.0, 1.2, CurrentValue);
		MushroomRoot.SetRelativeScale3D(FVector(ScaleMultiplier, ScaleMultiplier, 1 / ScaleMultiplier));
	}

	// Called from the resolver
	void OnImpact(FSplitTraversalPushableMushroomImpact ImpactData)
	{
		OnBounced.Broadcast(ImpactData);
		USplitTraversalPushableMushroomEventHandler::Trigger_OnHitConstraint(this, ImpactData);
	}
};