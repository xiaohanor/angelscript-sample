event void SummitMeltableCounterWeightEvent(AMeltableCounterWeight CounterWeight); 

class AMeltableCounterWeight : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UFauxPhysicsConeRotateComponent ConeRotateComp;

	UPROPERTY(DefaultComponent, Attach = ConeRotateComp)
	UFauxPhysicsTranslateComponent TranslateComp;
	default TranslateComp.bConstrainX = true;
	default TranslateComp.bConstrainY = true;
	default TranslateComp.bConstrainZ = true;
	default TranslateComp.ConstrainBounce = 0.25;

	UPROPERTY(DefaultComponent, Attach = TranslateComp)
	UFauxPhysicsForceComponent ForceComp;
	default ForceComp.Force = FVector(0,0, -15000);

	UPROPERTY(DefaultComponent, Attach = ForceComp)
	UStaticMeshComponent WeightMeshComp;

	UPROPERTY(DefaultComponent, Attach = WeightMeshComp)
	USceneComponent ChainAttachRoot;

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 60000.0;

	UPROPERTY(EditAnywhere, Category = "Setup")
	bool bUseLinkedChain = true;

	UPROPERTY(EditAnywhere, Category = "Setup")
	TSubclassOf<ANightQueenChain> ChainClass;

	UPROPERTY(EditAnywhere, Category = "Setup", Meta = (EditCondition = "!bUseLinkedChain", EditConditionHides))
	ANightQueenChain Chain;

	UPROPERTY(EditAnywhere, Category = "Setup")
	TSubclassOf<ASummitLinkedChain> LinkedChainClass;

	UPROPERTY(EditAnywhere, Category = "Setup", Meta = (EditCondition = "bUseLinkedChain", EditConditionHides))
	ASummitLinkedChain LinkedChain;

	UPROPERTY(EditAnywhere, Category = "Setup", Meta = (EditCondition = "bUseLinkedChain", EditConditionHides))
	float ChainLength = 4000.0;

	UPROPERTY(EditAnywhere, Category = "Setup", Meta = (EditCondition = "bUseLinkedChain", EditConditionHides))
	float LinkScale = 0.75;

	UPROPERTY(EditAnywhere, Category = "Settings", Meta = (EditCondition = "bUseLinkedChain", EditConditionHides))
	bool bMoveChainUpAfterMelted = true;

	UPROPERTY(EditAnywhere, Category = "Settings", Meta = (EditCondition = "bUseLinkedChain", EditConditionHides))
	bool bDisableLinkedChainAfterMelted = true; 

	UPROPERTY(EditAnywhere, Category = "Settings", Meta = (EditCondition = "bUseLinkedChain && bDisableLinkedChainAfterMelted", EditConditionHides))
	float DisableLinkedChainDuration = 5.0;

	UPROPERTY(EditAnywhere, Category = "Settings", Meta = (EditCondition = "bUseLinkedChain && bMoveChainUpAfterMelted", EditConditionHides))
	float ChainMoveUpDistance = 4000.0;

	UPROPERTY(EditAnywhere, Category = "Settings", Meta = (EditCondition = "bUseLinkedChain && bMoveChainUpAfterMelted", EditConditionHides))
	float ChainMoveUpAcceleration = 4000.0;

	UPROPERTY(EditAnywhere, Category = "Setup")
	bool bStartRaised = false;

	UPROPERTY(EditAnywhere, Category = "Setup")
	TSubclassOf<UCameraShakeBase> CameraShake;

	UPROPERTY(EditAnywhere, Category = "Setup")
	UForceFeedbackEffect Rumble;

	UPROPERTY(EditAnywhere, Category = "Setup", meta = (EditCondition = "bStartRaised", EditConditionHides))
	float RaisedZOffset = 4500.0;

	UPROPERTY(EditAnywhere, Category = "Setup", meta = (EditCondition = "bStartRaised", EditConditionHides))
	float DropSpeedTarget = 3500.0;

	UPROPERTY(EditAnywhere, Category = "Setup", meta = (EditCondition = "bStartRaised", EditConditionHides))
	float DropSpeedStart = 1000.0;

	float DropSpeed;

	float PitchSwingForce;
	float StartingPitchSwingForce = 15.0;

	UPROPERTY(EditAnywhere, Category = "Settings")
	float FallRange = 4000.0;

	UPROPERTY(EditAnywhere, Category = "Settings")
	float FallForce = 20000.0;

	float TimeStartedDropping = -MAX_flt;

	UPROPERTY()
	SummitMeltableCounterWeightEvent OnWeightStartsFalling;
	
	FVector StartLocation;
	FVector EndLocation;
	bool bCanDropCounterWeight;

	bool bWeightHasDropped = false;

	FHazeAcceleratedVector AccChainMoveUpLocation;
	FVector ChainLastLinkStartLocation;
	FVector ChainLastLinkEndLocation;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		if(Chain != nullptr)
		{
			Chain.OnNightQueenMetalMelted.AddUFunction(this, n"OnChainMelted");
			Chain.AttachToComponent(TranslateComp, NAME_None, EAttachmentRule::KeepWorld);
		}
		else if(LinkedChain != nullptr)
		{
			for(auto Link : LinkedChain.Links)
			{
				Link.OnNightQueenMetalMelted.AddUFunction(this, n"OnChainLinkMelted");
			}
			ChainLastLinkStartLocation = LinkedChain.Links.Last().ActorLocation;
			ChainLastLinkEndLocation = ChainLastLinkStartLocation - ChainAttachRoot.UpVector * ChainMoveUpDistance;
			AccChainMoveUpLocation.SnapTo(ChainLastLinkStartLocation);
		}

		ForceComp.AddDisabler(this);
		SetActorControlSide(Game::Mio);

		if (bStartRaised)
		{
			StartLocation = TranslateComp.RelativeLocation;
			EndLocation = TranslateComp.RelativeLocation - FVector::UpVector * RaisedZOffset;
			ActivateDropCounterWeight();
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (bStartRaised)
		{
			if (bCanDropCounterWeight)
			{
				DropSpeed = Math::FInterpConstantTo(DropSpeed, DropSpeedTarget, DeltaSeconds, DropSpeedTarget);
				TranslateComp.RelativeLocation = Math::VInterpConstantTo(TranslateComp.RelativeLocation, EndLocation, DeltaSeconds, DropSpeed);
			}

			if ((TranslateComp.RelativeLocation - EndLocation).Size() < 10.0 && bCanDropCounterWeight)
			{
				bCanDropCounterWeight = false;
				ConeRotateComp.ApplyImpulse(TranslateComp.RelativeLocation, ActorRightVector * 300.0);	
				UMeltableCounterWeightEventHandler::Trigger_OnStoppedWeightDrop(this, FMeltableCounterWeightParams(TranslateComp.WorldLocation));
			}
		}

		if(bUseLinkedChain)
		{
			if(bWeightHasDropped)
			{
				if(bMoveChainUpAfterMelted)
				{
					AccChainMoveUpLocation.ThrustTo(ChainLastLinkEndLocation, ChainMoveUpAcceleration, DeltaSeconds);
					LinkedChain.Links.Last().ActorLocation = AccChainMoveUpLocation.Value;
				}
				if(bDisableLinkedChainAfterMelted)
				{
					float TimeSinceStartedDropping = Time::GetGameTimeSince(TimeStartedDropping);
					if(TimeSinceStartedDropping >= DisableLinkedChainDuration)
					{
						LinkedChain.AddActorDisable(this);
					}
				}
			}
		}
	}

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		TranslateComp.MinZ = -FallRange;
		ForceComp.Force = FVector(0, 0, -FallForce);
	}

	UFUNCTION(NotBlueprintCallable)
	private void OnChainMelted()
	{
		Chain.DetachFromActor(EDetachmentRule::KeepWorld);
		
		StartDroppingWeight();
	}

	UFUNCTION()
	private void OnChainLinkMelted()
	{
		if(bWeightHasDropped)
			return;

		StartDroppingWeight();
	}

	private void StartDroppingWeight()
	{
		ForceComp.RemoveDisabler(this);

		UMeltableCounterWeightEventHandler::Trigger_OnStartedFalling(this);

		for (AHazePlayerCharacter Player : Game::Players)
		{
			Player.PlayWorldCameraShake(CameraShake, this, ActorLocation, 8000.0, 25000.0);
			if ((Player.ActorLocation - ActorLocation).Size() < 25000.0)
				Player.PlayForceFeedback(Rumble, false, true, this);
		}
		
		OnWeightStartsFalling.Broadcast(this);

		bWeightHasDropped = true;
		TimeStartedDropping = Time::GetGameTimeSeconds();
	}

	UFUNCTION()
	void ActivateDropCounterWeight()
	{
		if (!bStartRaised)
			return;

		bCanDropCounterWeight = true;
		PitchSwingForce = StartingPitchSwingForce;
		DropSpeed = DropSpeedStart;

		UMeltableCounterWeightEventHandler::Trigger_OnStartedWeightDrop(this, FMeltableCounterWeightParams(TranslateComp.WorldLocation));
	}

	UFUNCTION(CallInEditor, Category = "Setup")
	void CreateChain()
	{
		if(!bUseLinkedChain)
		{
			CleanUpChains();

			auto ChainActor = SpawnActor(ChainClass, Name = n"CounterWeightChain");
			Chain = Cast<ANightQueenChain>(ChainActor);
			Chain.AttachToComponent(ChainAttachRoot, NAME_None, EAttachmentRule::SnapToTarget, EAttachmentRule::SnapToTarget, EAttachmentRule::SnapToTarget, true);
		}
		else
		{
			CleanUpChains();

			LinkedChain = SpawnActor(LinkedChainClass, ChainAttachRoot. WorldLocation, ChainAttachRoot.WorldRotation);
			LinkedChain.AttachToComponent(ChainAttachRoot, NAME_None, EAttachmentRule::SnapToTarget, EAttachmentRule::SnapToTarget, EAttachmentRule::KeepWorld, true);
			
			LinkedChain.Spline.SplinePoints[0].RelativeLocation = FVector::ZeroVector;
			LinkedChain.Spline.SplinePoints[1].RelativeLocation = -FVector::UpVector * ChainLength;
			LinkedChain.Spline.UpdateSpline();
			LinkedChain.bFirstLinkIsLocked = true;
			LinkedChain.FirstLinkAttachActor = this;
			LinkedChain.FirstLinkAttachComponentName = ChainAttachRoot.Name;
			LinkedChain.bLastLinkIsLocked = true;
			LinkedChain.LinkScale = LinkScale;

			LinkedChain.CreateLinks();
		}
	}

	private void CleanUpChains()
	{
		if(Chain != nullptr)
			Chain.DestroyActor();

		if(LinkedChain != nullptr)
		{
			LinkedChain.RemoveAllLinks();
			LinkedChain.DestroyActor();
		}
	}

#if EDITOR
	UFUNCTION(BlueprintOverride)
	void OnVisualizeInEditor() const
	{
		if (bStartRaised)
		{
			FVector Bounds;
			FVector Origin;
			GetActorBounds(true, Origin, Bounds);
			Debug::DrawDebugLine(TranslateComp.WorldLocation, TranslateComp.WorldLocation - FVector::UpVector * RaisedZOffset, FLinearColor::Green, 20.0);
			Debug::DrawDebugCapsule(TranslateComp.WorldLocation - FVector::UpVector * RaisedZOffset, Bounds.Z, Bounds.X, ActorRotation, FLinearColor::Green, 20.0);
		}

		Debug::DrawDebugSphere(ChainAttachRoot.WorldLocation, 100, 12, FLinearColor::LucBlue, 10, 0, true);
		Debug::DrawDebugString(ChainAttachRoot.WorldLocation, "Chain Attach Root", FLinearColor::LucBlue);

		if(bUseLinkedChain)
		{
			FVector Start = ChainAttachRoot.WorldLocation;
			FVector End = Start - ChainAttachRoot.UpVector * ChainLength;
			Debug::DrawDebugLine(Start, End, FLinearColor::White, 10, bDrawInForeground = true);

			Debug::DrawDebugSphere(End, 100, 12, FLinearColor::DPink, 10, 0, true);
			Debug::DrawDebugString(End, "Chain End Location", FLinearColor::DPink);

			if(bMoveChainUpAfterMelted)
			{
				FVector MoveUpStart = End;
				FVector MoveUpEnd = MoveUpStart - ChainAttachRoot.UpVector * ChainMoveUpDistance;

				Debug::DrawDebugLine(MoveUpStart, MoveUpEnd, FLinearColor::Black, 10, bDrawInForeground = true);

				Debug::DrawDebugSphere(MoveUpEnd, 100, 12, FLinearColor::Purple, 10, 0, true);
				Debug::DrawDebugString(MoveUpEnd, "Chain Move Up Max", FLinearColor::Purple);
			}
		}
	}
#endif
};