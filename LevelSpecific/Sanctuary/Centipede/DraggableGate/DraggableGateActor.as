event void FSanctuaryCentipedeDraggableGateSignature();
event void FSanctuaryCentipedeDraggableGateInteractSignature();

class ADraggableGateActor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComponent;
	default DisableComponent.SetEnableAutoDisable(true);

	UPROPERTY()
	FSanctuaryCentipedeDraggableGateSignature OnGateLocked;

	UPROPERTY()
	FSanctuaryCentipedeDraggableGateInteractSignature OnGateInteractionStarted;

	UPROPERTY()
	FSanctuaryCentipedeDraggableGateInteractSignature OnGateInteractionStopped;

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedyComp;

	UPROPERTY(DefaultComponent)
	UCameraShakeForceFeedbackComponent CameraShakeForceFeedbackComponent;

	//Gate

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent GateRootComp;

	UPROPERTY(DefaultComponent, Attach = GateRootComp)
	UBoxComponent SpikeHurtBox;

	//Chain 1

	UPROPERTY(DefaultComponent, Attach = Root)
	UFauxPhysicsTranslateComponent Chain1TranslateComp;

	UPROPERTY(DefaultComponent, Attach = Chain1TranslateComp)
	UCentipedeDraggableChainComponent Chain1DraggableChainComp;
	bool bChain1Locked = false;

	//Chain 2

	UPROPERTY(DefaultComponent, Attach = Root)
	UFauxPhysicsTranslateComponent Chain2TranslateComp;

	UPROPERTY(DefaultComponent, Attach = Chain2TranslateComp)
	UCentipedeDraggableChainComponent Chain2DraggableChainComp;
	bool bChain2Locked = false;

	bool bGateSocketed = false;

	//Settings

	UPROPERTY(EditAnywhere)
	float GateWeight = 1000.0;

	UPROPERTY(EditAnywhere)
	float PullForce = 300.0;

	UPROPERTY(EditAnywhere)
	float GateHalfWidth = 300.0;

	UPROPERTY(EditAnywhere)
	float GateMaxTilt = 5.0;

	UPROPERTY(EditAnywhere)
	float RequiredDragLength = 800.0;

	private FVector Chain1LastLocation;
	private FVector Chain2LastLocation;

	private float MaxX;

	bool bGateLockedBroadcasted;

	UCentipedeLavaIntoleranceComponent LavaIntoleranceComp;

	UPROPERTY(DefaultComponent)
	USanctuaryLavaApplierComponent LavaComp;
	default LavaComp.bOverlapMesh = false;
	default LavaComp.bOverlapTrigger = true;
	default LavaComp.DamagePerSecond = 5.0;
	default LavaComp.DamageDuration = 0.2;

	UPROPERTY(EditInstanceOnly)
	bool bUglyIsSlopeGate = false;
	UPROPERTY(EditInstanceOnly)
	bool bUglyIsMoleGate = false;

	// hurt players divided by gate lol

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SanctuaryCentipedeDevToggles::Draw::Gate.MakeVisible();
		Chain1DraggableChainComp.RetractingForce = FVector::ForwardVector * GateWeight * -1;
		Chain2DraggableChainComp.RetractingForce = FVector::ForwardVector * GateWeight * -1;
		Chain1DraggableChainComp.OnCentipedeBiteStarted.AddUFunction(this, n"HandleBiteStarted");
		Chain2DraggableChainComp.OnCentipedeBiteStarted.AddUFunction(this, n"HandleBiteStarted");
		Chain1DraggableChainComp.OnCentipedeBiteStopped.AddUFunction(this, n"HandleBiteStopped");
		Chain2DraggableChainComp.OnCentipedeBiteStopped.AddUFunction(this, n"HandleBiteStopped");

		Chain2TranslateComp.OnConstraintHit.AddUFunction(this, n"HandleConstraintHit");
	}

	UFUNCTION(BlueprintCallable)
	void UpdateChainImpossibility(bool bIsImpossible)
	{
		if (bIsImpossible)
		{
			MaxX = Chain1TranslateComp.MaxX;
			Chain1TranslateComp.MaxX = RequiredDragLength * 0.75;
			Chain2TranslateComp.MaxX = RequiredDragLength * 0.75;
		}
		else
		{
			Chain1TranslateComp.MaxX = MaxX;
			Chain2TranslateComp.MaxX = MaxX;
		}

		Chain1DraggableChainComp.bImpossible = bIsImpossible;
		Chain2DraggableChainComp.bImpossible = bIsImpossible;
	}

	UFUNCTION()
	private void HandleBiteStarted(FCentipedeBiteEventParams BiteParams)
	{
		OnGateInteractionStarted.Broadcast();
	}

	UFUNCTION()
	private void HandleBiteStopped(FCentipedeBiteEventParams BiteParams)
	{
		OnGateInteractionStopped.Broadcast();
	}

	UFUNCTION()
	private void HandleConstraintHit(EFauxPhysicsTranslateConstraintEdge Edge, float HitStrength)
	{
		if(HitStrength>100 && !bGateLockedBroadcasted)
			CameraShakeForceFeedbackComponent.ActivateCameraShakeAndForceFeedback();
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{	
		if (LavaIntoleranceComp == nullptr)
		{
			UPlayerCentipedeComponent CentipedeComp = UPlayerCentipedeComponent::Get(Game::Mio);
			if (CentipedeComp != nullptr && CentipedeComp.Centipede != nullptr)
				LavaIntoleranceComp = UCentipedeLavaIntoleranceComponent::Get(CentipedeComp.Centipede);
		}

		MaybeSnapOpen();

		bool bShouldBeDisabled = LavaIntoleranceComp != nullptr && LavaIntoleranceComp.Burns.Num() > 0;
		bool bIsDisabled = Chain1DraggableChainComp.IsDisabled();
		if (bShouldBeDisabled && !bIsDisabled)
		{
			Chain1DraggableChainComp.Disable(this);
			Chain2DraggableChainComp.Disable(this);
		}
		else if (bIsDisabled && !bShouldBeDisabled)
		{
			Chain1DraggableChainComp.Enable(this);
			Chain2DraggableChainComp.Enable(this);
		}

		UpdateGateTransform(DeltaSeconds);

		UpdateDamageSpikes();
	}

	private void UpdateDamageSpikes()
	{
		if (bChain1Locked || bChain2Locked)
		{
			LavaComp.bSpecialCaseDisabled = true;
			return;
		}
		if (Chain1DraggableChainComp.DraggedAlpha > 0.6 || Chain2DraggableChainComp.DraggedAlpha > 0.6 )
		{
			LavaComp.bSpecialCaseDisabled = true;
			return;
		}

		FVector MioRelative = Game::Mio.ActorLocation - SpikeHurtBox.WorldLocation;
		FVector ZoeRelative = Game::Zoe.ActorLocation - SpikeHurtBox.WorldLocation;

		// Debug::DrawDebugLine(Game::Mio.ActorLocation, SpikeHurtBox.WorldLocation, ColorDebug::Ruby, 5.0, bDrawInForeground = true);
		// Debug::DrawDebugLine(Game::Zoe.ActorLocation, SpikeHurtBox.WorldLocation, ColorDebug::Leaf, 5.0, bDrawInForeground = true);
		// Debug::DrawDebugLine(SpikeHurtBox.WorldLocation, SpikeHurtBox.WorldLocation + SpikeHurtBox.ForwardVector * 100, ColorDebug::Cyan, 5.0, bDrawInForeground = true);

		const float Treshold = 10.0;
		bool bPlayerOnForwardSide = SpikeHurtBox.ForwardVector.DotProduct(MioRelative) >= Treshold || SpikeHurtBox.ForwardVector.DotProduct(ZoeRelative) >= Treshold;
		bool bPlayerOnBacksideSide = SpikeHurtBox.ForwardVector.DotProduct(MioRelative) <= Treshold || SpikeHurtBox.ForwardVector.DotProduct(ZoeRelative) <= Treshold;

		if (bPlayerOnForwardSide && bPlayerOnBacksideSide)
			LavaComp.bSpecialCaseDisabled = false;
		else
			LavaComp.bSpecialCaseDisabled = true;
	}

	void UpdateGateTransform(float DeltaSeconds)
	{
		//Calculate gate transform
		FVector Location = FVector::UpVector * (Chain1TranslateComp.RelativeLocation.X + Chain2TranslateComp.RelativeLocation.X) * 0.5;
		
		//Trigonometri
		float V1 = (Math::Acos((Math::Clamp(Chain1TranslateComp.RelativeLocation.X - Chain2TranslateComp.RelativeLocation.X, 0.0, 1000.0)) / GateHalfWidth) * 180.0 / PI) - 90.0;
		float V2 = ((Math::Acos((Math::Clamp(Chain2TranslateComp.RelativeLocation.X - Chain1TranslateComp.RelativeLocation.X, 0.0, 1000.0)) / GateHalfWidth) * 180.0 / PI) - 90.0) * -1;

		float CombinedV = V1 + V2;
		if (CombinedV > GateMaxTilt)
			CombinedV = GateMaxTilt;
		if (CombinedV < -GateMaxTilt)
			CombinedV = -GateMaxTilt;

		FRotator Rotation = FRotator(0.0, 0.0, CombinedV);
		GateRootComp.SetRelativeLocationAndRotation(Location, Rotation);

		Chain1DraggableChainComp.bIsHookable = Chain1TranslateComp.RelativeLocation.X > RequiredDragLength;
		Chain2DraggableChainComp.bIsHookable = Chain2TranslateComp.RelativeLocation.X > RequiredDragLength;
		Chain1DraggableChainComp.bIsCapped = Chain1TranslateComp.RelativeLocation.X >= Chain1TranslateComp.MaxX - 1.0;
		Chain2DraggableChainComp.bIsCapped = Chain2TranslateComp.RelativeLocation.X >= Chain2TranslateComp.MaxX - 1.0;
		Chain1DraggableChainComp.DraggedAlpha = Chain1TranslateComp.RelativeLocation.X / RequiredDragLength;
		if (!bChain1Locked && Chain1DraggableChainComp.DraggedAlpha > 1.0)
		{
			bChain1Locked = true;
			CrumbLockChain1();
		}
		Chain2DraggableChainComp.DraggedAlpha = Chain2TranslateComp.RelativeLocation.X / RequiredDragLength;
		if (!bChain2Locked && Chain2DraggableChainComp.DraggedAlpha > 1.0)
		{
			bChain2Locked = true;
			CrumbLockChain2();
		}

		if (SanctuaryCentipedeDevToggles::Draw::Gate.IsEnabled())
		{
			Debug::DrawDebugString(Chain1DraggableChainComp.WorldLocation, " Dragged " + Chain1DraggableChainComp.DraggedAlpha, ColorDebug::White, 0.0, 5.0);
			Debug::DrawDebugString(Chain2DraggableChainComp.WorldLocation, " Dragged " + Chain2DraggableChainComp.DraggedAlpha, ColorDebug::White, 0.0, 5.0);
		}

		Chain1DraggableChainComp.ChainsDiffLength = Math::Clamp(Chain1TranslateComp.RelativeLocation.X - Chain2TranslateComp.RelativeLocation.X, 0.0, MAX_flt);
		Chain2DraggableChainComp.ChainsDiffLength = Math::Clamp(Chain2TranslateComp.RelativeLocation.X - Chain1TranslateComp.RelativeLocation.X, 0.0, MAX_flt);
		if (SanctuaryCentipedeDevToggles::Draw::Biting.IsEnabled())
		{
			Debug::DrawDebugString(Chain1DraggableChainComp.WorldLocation, "1", ColorDebug::White, 0.0, 5.0);
			Debug::DrawDebugString(Chain2DraggableChainComp.WorldLocation, "2", ColorDebug::White, 0.0, 5.0);
		}

		bool bAnyChainIsDragged = Chain1DraggableChainComp.GetIsDragged() || Chain2DraggableChainComp.GetIsDragged();
		if (!bAnyChainIsDragged && Chain1DraggableChainComp.bIsHookable && Chain2DraggableChainComp.bIsHookable && !bGateSocketed)
		{
			CrumbLockGate();
		}
	}

	private void MaybeSnapOpen()
	{
		if (bChain1Locked || bChain2Locked)
			return;
		USanctuaryUglyProgressionPlayerComponent UglyComp = USanctuaryUglyProgressionPlayerComponent::GetOrCreate(Game::Mio);
		if (UglyComp.bPassedSlopeGateCheckpoint && bUglyIsSlopeGate)
			SnapOpen();
		if (UglyComp.bPassedMoleGateCheckpoint && bUglyIsMoleGate)
			SnapOpen();
	}

	void SnapOpen()
	{
		bChain1Locked = true;
		bChain2Locked = true;
		Chain1TranslateComp.MinX = RequiredDragLength;
		Chain2TranslateComp.MinX = RequiredDragLength;
		Chain1TranslateComp.MaxX = MaxX;
		Chain2TranslateComp.MaxX = MaxX;
		bGateLockedBroadcasted = true;
	}

	UFUNCTION(CrumbFunction, NotBlueprintCallable)
	private void CrumbLockChain1()
	{
		bChain1Locked = true;
		Chain1TranslateComp.MinX = RequiredDragLength;
		BroadcastGateLocked();

	}

	UFUNCTION(CrumbFunction, NotBlueprintCallable)
	private void CrumbLockChain2()
	{
		bChain2Locked = true;
		Chain2TranslateComp.MinX = RequiredDragLength;
		BroadcastGateLocked();
	}

	UFUNCTION(CrumbFunction, NotBlueprintCallable)
	private void CrumbLockGate()
	{
		bGateSocketed = true;

		Chain1TranslateComp.MinX = RequiredDragLength;
		Chain2TranslateComp.MinX = RequiredDragLength;

		// Chain1DraggableChainComp.Disable(this);
		// Chain2DraggableChainComp.Disable(this);
	}

	private void BroadcastGateLocked()
	{
		if (bGateLockedBroadcasted)
			return;

		bGateLockedBroadcasted = true;
		OnGateLocked.Broadcast();
	}
};