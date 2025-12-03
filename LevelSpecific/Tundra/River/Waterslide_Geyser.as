event void FOnPlayerLaunched();

class UTundraWaterslideGeyserEffectHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent)
	void OnOtterStartSliding() {}

	UFUNCTION(BlueprintEvent)
	void OnGeyserClose() {}

	UFUNCTION(BlueprintEvent)
	void OnGeyserOpen() {}

	UFUNCTION(BlueprintEvent)
	void OnGeyserLaunch() {}
}

UCLASS(Abstract)
class AWaterslide_Geyser : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UHazeSkeletalMeshComponentBase LeftRootsMesh;
#if EDITOR
	default LeftRootsMesh.bUpdateAnimationInEditor = true;
#endif

	UPROPERTY(DefaultComponent, Attach = Root)
	UHazeSkeletalMeshComponentBase RightRootsMesh;
#if EDITOR
	default RightRootsMesh.bUpdateAnimationInEditor = true;
#endif

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent LeftVineRoot;
	default LeftVineRoot.RelativeLocation = FVector(448.051847, -511.804370, 86.226618);

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent LeftVineTargetRoot;
	default LeftVineTargetRoot.RelativeLocation = FVector(444.533345, -222.714042, 89.763288);

	UPROPERTY(DefaultComponent, Attach = LeftVineRoot)
	USceneComponent LeftShakeRoot;

	UPROPERTY(DefaultComponent, Attach = LeftVineRoot)
	UStaticMeshComponent LeftVineMeshComp;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent RightVineRoot;
	default RightVineRoot.RelativeLocation = FVector(579.058467, 315.507870, 138.174637);

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent RightVineTargetRoot;
	default RightVineTargetRoot.RelativeLocation = FVector(717.708851, 29.676606, 199.070673);

	UPROPERTY(DefaultComponent, Attach = RightVineRoot)
	USceneComponent RightShakeRoot;

	UPROPERTY(DefaultComponent, Attach = RightVineRoot)
	UStaticMeshComponent RightVineMeshComp;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent WaterWheelRotationRoot;

	UPROPERTY(DefaultComponent, Attach = WaterWheelRotationRoot)
	UStaticMeshComponent WaterWheelMesh;

	UPROPERTY(DefaultComponent, Attach = Root)
	UBoxComponent LaunchZone;

	UPROPERTY(DefaultComponent, Attach = Root)
	UNiagaraComponent GeyserEffect;

	UPROPERTY(DefaultComponent, Attach = Root)
	UNiagaraComponent GeyserBubblingEffect;

	UPROPERTY(EditInstanceOnly)
	FVector LeftRootWorldOffset;

	UPROPERTY(EditInstanceOnly)
	FVector RightRootWorldOffset;
	
	UPROPERTY(EditInstanceOnly)
	AActor GeyserSpoutActor;

	UNiagaraComponent GeyserSpoutEffect;

	UPROPERTY(EditDefaultsOnly)
	UForceFeedbackEffect GeyserFF;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<UCameraShakeBase> GeyserCamShake;

#if EDITOR
	UPROPERTY(EditInstanceOnly, Category = "Editor")
	TSoftObjectPtr<AActor> LeftRoot;

	UPROPERTY(EditInstanceOnly, Category = "Editor")
	TSoftObjectPtr<AActor> RightRoot;

	UPROPERTY(EditInstanceOnly, Category = "Editor")
	bool bPreviewTargetInEditor = false;

	UPROPERTY(EditInstanceOnly, Category = "Editor", Meta = (EditCondition = "!bPreviewTargetInEditor", EditConditionHides, ClampMin = "0", ClampMax = "1"))
	float PreviewAlpha = 0.0;

	UPROPERTY(EditInstanceOnly, Category = "Editor", Meta = (EditCondition = "!bPreviewTargetInEditor", EditConditionHides))
	bool bAnimatePreviewAlpha = true;
#endif

	UPROPERTY(EditInstanceOnly)
	AActor LifeGivingActor;

	UPROPERTY(EditInstanceOnly)
	AActor LandingSpotActor;

	UPROPERTY(EditInstanceOnly)
	AHazeCameraVolume SlidingCameraVolume;

	UPROPERTY(EditAnywhere)
	const float CooldownDuration = 0.1;

	UPROPERTY(EditAnywhere)
	const float ChargeDuration = 0.75;
	
	UPROPERTY(EditAnywhere)
	const float ActiveDuration = 0.75;

	UPROPERTY(EditAnywhere)
	bool bShouldZeroVelocity = false;

	bool bPlayerInside = false;
	bool bInteractHeld = false;
	bool bGeyserActive = false;
	bool bGeyserReady = true;
	bool bShouldRotate = true;
	AHazePlayerCharacter PlayerInVolume;
	float CooldownTimer = -1;
	float CurrentCharge = 0;
	float GeyserActivationTime;
	float CurrentWheelSpeed = -40;
	FVector RightRootCurrentPoint;
	FVector LeftRootCurrentPoint;
	// float RootMoveAlpha;

	
	UPROPERTY()
	FOnPlayerLaunched OnPlayerLaunched;

	UPROPERTY()
	UTundraLifeReceivingComponent LifeComp;

#if EDITOR
	// UFUNCTION(CallInEditor)
	// void SnapRootsToRootActors()
	// {
	// 	if(LeftRoot == nullptr)
	// 		return;

	// 	if(RightRoot == nullptr)
	// 		return;

	// 	LeftRootsMesh.WorldTransform = LeftRoot.Get().ActorTransform;
	// 	RightRootsMesh.WorldTransform = RightRoot.Get().ActorTransform;

	// 	//LeftRootsMesh.WorldRotation = FRotator::MakeFromXZ(LeftRootsMesh.ForwardVector.RotateAngleAxis(25.0, FVector::UpVector), FVector::UpVector);
	// 	//RightRootsMesh.WorldRotation = FRotator::MakeFromXZ(RightRootsMesh.ForwardVector.RotateAngleAxis(25.0, FVector::UpVector), FVector::UpVector);

	// 	LeftRoot.Get().SetActorHiddenInGame(true);
	// 	RightRoot.Get().SetActorHiddenInGame(true);
	// }

	// UFUNCTION(CallInEditor)
	// void SnapTipPointsToBones()
	// {
	// 	FVector NewLeft = LeftRootsMesh.GetSocketLocation(n"Branch15");
	// 	FVector NewRight = RightRootsMesh.GetSocketLocation(n"Branch13");
	// 	LeftRootWorldOffset += LeftVineRoot.WorldLocation - NewLeft;
	// 	RightRootWorldOffset += RightVineRoot.WorldLocation - NewRight;
	// 	LeftVineRoot.WorldLocation = NewLeft;
	// 	RightVineRoot.WorldLocation = NewRight;
	// }

	UFUNCTION(CallInEditor, DisplayName = "Select Right Root Mesh")
	void ASelectRightRootMesh()
	{
		Editor::SelectComponent(RightRootsMesh);
	}

	UFUNCTION(CallInEditor, DisplayName = "Select Left Root Mesh")
	void BSelectLeftRootMesh()
	{
		Editor::SelectComponent(LeftRootsMesh);
	}

	UFUNCTION(CallInEditor, DisplayName = "Select Right Root Start Point")
	void CSelectRightRootStartPoint()
	{
		Editor::SelectComponent(RightVineRoot);
	}

	UFUNCTION(CallInEditor, DisplayName = "Select Left Root Start Point")
	void DSelectLeftRootStartPoint()
	{
		Editor::SelectComponent(LeftVineRoot);
	}

	UFUNCTION(CallInEditor, DisplayName = "Select Right Root End Point")
	void ESelectRightRootEndPoint()
	{
		Editor::SelectComponent(RightVineTargetRoot);
	}

	UFUNCTION(CallInEditor, DisplayName = "Select Left Root End Point")
	void FSelectLeftRootEndPoint()
	{
		Editor::SelectComponent(LeftVineTargetRoot);
	}
#endif

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		RightRootCurrentPoint = RightVineRoot.WorldLocation;
		LeftRootCurrentPoint = LeftVineRoot.WorldLocation;

		if(LifeGivingActor != nullptr)
		{
			LifeComp = UTundraLifeReceivingComponent::Get(LifeGivingActor);
			LifeComp.OnInteractStart.AddUFunction(this, n"OnLifeGiveStarted");
			LifeComp.OnInteractStop.AddUFunction(this, n"OnLifeGiveStopped");
			LifeComp.OnInteractStartDuringLifeGive.AddUFunction(this, n"OnTreeInteractHeld");
			LifeComp.OnInteractStopDuringLifeGive.AddUFunction(this, n"OnTreeInteractReleased");
		}

		if(GeyserSpoutActor != nullptr)
		{
			GeyserSpoutEffect = UNiagaraComponent::Get(GeyserSpoutActor);
		}

		LaunchZone.OnComponentBeginOverlap.AddUFunction(this, n"OnPlayerEnterTrigger");
		LaunchZone.OnComponentEndOverlap.AddUFunction(this, n"OnPlayerLeaveTrigger");

		if(SlidingCameraVolume != nullptr)
		{
			SlidingCameraVolume.OnVolumeActivated.AddUFunction(this, n"OnOtterStartSliding");
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(CooldownTimer > 0)
		{
			CooldownTimer -= DeltaSeconds;
		}

		if(Time::GetGameTimeSince(GeyserActivationTime) >= ActiveDuration && bGeyserActive)
		{
			bGeyserActive = false;
			LaunchZone.SetCollisionEnabled(ECollisionEnabled::NoCollision);
		}

		MoveRoots(DeltaSeconds);

		CurrentWheelSpeed = Math::GetMappedRangeValueClamped(FVector2D(1, 0), FVector2D(-40, -300), Time::GetGameTimeSince(GeyserActivationTime));

		if(bInteractHeld)
		{
			if(CooldownTimer <= 0/* && CurrentCharge < ChargeDuration*/)
			{
				CurrentCharge += DeltaSeconds;
			}

			FHazeFrameForceFeedback Feedback;
			Feedback.LeftMotor = 0.2;
			//Feedback.RightMotor = 0.2;
			Game::GetZoe().SetFrameForceFeedback(Feedback);

			float SineAlpha = Math::GetMappedRangeValueClamped(FVector2D(0, 3), FVector2D(0.25, 1), CurrentCharge);
			float SineRotate = Math::Sin(Time::GetGameTimeSeconds() * 60);
			//LeftShakeRoot.RelativeRotation = FRotator(-1.1, 0, -4) * SineRotate * SineAlpha;
			//RightShakeRoot.RelativeRotation = FRotator(1.1, 0, 4) * SineRotate * SineAlpha;

			WaterWheelRotationRoot.AddLocalRotation(FRotator(2, 0, 0) * SineRotate * SineAlpha);

			bShouldRotate = false;
		}
		else
		{
			bShouldRotate = true;
		}

		if(bShouldRotate)
		{
			WaterWheelRotationRoot.AddLocalRotation(FRotator(CurrentWheelSpeed * DeltaSeconds, 0, 0));
		}

		// Print("Cooldown: " + CooldownTimer + "  Charge: " + CurrentCharge);
	}

	bool IsGeyserReady()
	{
		return CooldownTimer <= 0 && CurrentCharge >= ChargeDuration;
	}

	UFUNCTION()
	private void OnPlayerEnterTrigger(UPrimitiveComponent OverlappedComponent, AActor OtherActor, UPrimitiveComponent OtherComponent, int OtherBodyIndex, bool bFromSweep, const FHitResult&in HitResult)
	{
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);
		if(Player == nullptr)
			return;

		PlayerInVolume = Player;
		bPlayerInside = true;

		TryLaunchPlayer();
	}

	UFUNCTION()
	void MoveRoots(float DeltaTime)
	{
		float Alpha = Math::Saturate(CurrentCharge / ChargeDuration);
		if(bInteractHeld)
		{
			Alpha = 1;
		}
		FVector LeftTarget = Math::Lerp(LeftVineRoot.WorldLocation, LeftVineTargetRoot.WorldLocation, Alpha);
		FVector RightTarget = Math::Lerp(RightVineRoot.WorldLocation, RightVineTargetRoot.WorldLocation, Alpha);

		float InterpSpeed;
		if(bInteractHeld)
		{
			InterpSpeed = 12;
		}
		else
		{
			InterpSpeed = 12;
		}

		LeftRootCurrentPoint = Math::VInterpTo(LeftRootCurrentPoint, LeftTarget, DeltaTime, InterpSpeed);
		RightRootCurrentPoint =  Math::VInterpTo(RightRootCurrentPoint, RightTarget, DeltaTime, InterpSpeed);
	}

	UFUNCTION()
	private void OnPlayerLeaveTrigger(UPrimitiveComponent OverlappedComponent, AActor OtherActor,
	                                        UPrimitiveComponent OtherComp, int OtherBodyIndex)
	{
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);
		if(Player == nullptr)
			return;

		PlayerInVolume = nullptr;
		bPlayerInside = false;
	}

	bool CheckIsLifeGiving()
	{
		if(LifeComp == nullptr)
			return false;

		if(LifeComp.IsCurrentlyLifeGiving())
			return true;

		return false;
	}

	UFUNCTION()
	private void OnTreeInteractReleased()
	{
		UTundraWaterslideGeyserEffectHandler::Trigger_OnGeyserOpen(this);

		if(!bInteractHeld)
			return;

		GeyserBubblingEffect.Deactivate();
	
		if(GeyserSpoutEffect != nullptr)
			GeyserSpoutEffect.Activate();

		ReleaseGeyser();

		CurrentCharge = 0;

		bInteractHeld = false;
	}

	UFUNCTION()
	private void OnOtterStartSliding(UHazeCameraUserComponent UserComp)
	{
		UTundraWaterslideGeyserEffectHandler::Trigger_OnOtterStartSliding(this);
	}

	void ReleaseGeyser()
	{
		if(!IsGeyserReady())
			return;

		GeyserEffect.ResetSystem();
		
		// TryLaunchPlayer();
		bGeyserActive = true;
		GeyserActivationTime = Time::GetGameTimeSeconds();

		LaunchZone.SetCollisionEnabled(ECollisionEnabled::QueryOnly);

		CooldownTimer = CooldownDuration;

		Game::GetZoe().PlayCameraShake(GeyserCamShake, this);
		Game::GetZoe().PlayForceFeedback(GeyserFF, false, false, this);

		UTundraWaterslideGeyserEffectHandler::Trigger_OnGeyserLaunch(this);
	}

	void TryLaunchPlayer()
	{
		if(PlayerInVolume == nullptr)
			return;
		
		if(bShouldZeroVelocity)
		{
			PlayerInVolume.SetActorHorizontalAndVerticalVelocity(FVector::ZeroVector, FVector::ZeroVector);
		}
		
		// auto PlayerMoveComp = UPlayerMovementComponent::Get(PlayerInVolume);
		// FVector LaunchVelocity = Trajectory::CalculateVelocityForPathWithHeight(PlayerInVolume.ActorLocation, LandingSpotActor.ActorLocation, PlayerMoveComp.GravityForce, 3500, PlayerMoveComp.TerminalVelocity);
		// PlayerInVolume.SetActorVelocity(LaunchVelocity);

		FPlayerLaunchToParameters LaunchParams;
		LaunchParams.LaunchToLocation = LandingSpotActor.ActorLocation;
		LaunchParams.Type = EPlayerLaunchToType::LaunchToPoint;
		LaunchParams.Duration = 3;
		PlayerInVolume.LaunchPlayerTo(this, LaunchParams);

		UTundra_River_WaterslideLaunch_PlayerComponent LaunchPlayerComp = UTundra_River_WaterslideLaunch_PlayerComponent::Get(PlayerInVolume);
		LaunchPlayerComp.OnNewLaunchTriggered();

		OnPlayerLaunched.Broadcast();
	}

	UFUNCTION()
	private void OnTreeInteractHeld()
	{
		if(CooldownTimer > 0)
			return;

		bInteractHeld = true;

		GeyserBubblingEffect.Activate();
		UTundraWaterslideGeyserEffectHandler::Trigger_OnGeyserClose(this);

		if(GeyserSpoutEffect != nullptr)
			GeyserSpoutEffect.Deactivate();
	}

	UFUNCTION()
	private void OnLifeGiveStarted(bool bForce)
	{
		Game::GetZoe().ApplyOtherPlayerIndicatorMode(EOtherPlayerIndicatorMode::AlwaysVisible, this);
	}

	UFUNCTION()
	private void OnLifeGiveStopped(bool bForce)
	{
		Game::GetZoe().ClearOtherPlayerIndicatorMode(this);
	}
};
