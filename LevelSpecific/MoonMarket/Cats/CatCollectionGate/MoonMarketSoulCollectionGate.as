event void FOnMoonMarketSoulGateOpened();

class AMoonMarketSoulCollectionGate : AHazeActor
{
	UPROPERTY()
	FOnMoonMarketSoulGateOpened OnMoonMarketSoulGateOpened;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UBoxComponent CatGateCheck;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent RRoot;
	
	UPROPERTY(DefaultComponent, Attach = RRoot)
	UStaticMeshComponent RGate;

	UPROPERTY(DefaultComponent, Attach = RRoot)
	UStaticMeshComponent RKeyMesh;
	default RKeyMesh.SetCollisionEnabled(ECollisionEnabled::NoCollision);
	default RKeyMesh.SetHiddenInGame(true);
	
	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent LRoot;

	UPROPERTY(DefaultComponent, Attach = LRoot)
	UStaticMeshComponent LGate;

	UPROPERTY(DefaultComponent, Attach = LRoot)
	UStaticMeshComponent LKeyMesh;
	default LKeyMesh.SetCollisionEnabled(ECollisionEnabled::NoCollision);
	default LKeyMesh.SetHiddenInGame(true);

	UPROPERTY(DefaultComponent)
	UMoonMarketCatProgressComponent CatProgressComp;

	UPROPERTY(EditInstanceOnly)
	ADoubleInteractionActor DoubleInteract;

	UPROPERTY(EditInstanceOnly)
	AHazeCameraActor Camera;

	UPROPERTY(EditInstanceOnly)
	float RadiusCatCheck = 1000.0;

	UPROPERTY()
	FRuntimeFloatCurve DoorOpenCurve;

	TArray<AMoonGateCatHead> CatHeads;
	int CurrentNum;
	bool bCompleted;

	float Alpha;
	float Speed = 0.5;

	float RotateAmount = 90.0; 

	TArray<AMoonMarketCat> CatsDelivered;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		TArray<AActor> AttachedActors;
		GetAttachedActors(AttachedActors);
		for (AActor Actor : AttachedActors)
		{
			auto CatHead = Cast<AMoonGateCatHead>(Actor);
			if (CatHead != nullptr)
			{
				CatHeads.AddUnique(CatHead);
			}
		}
		int Num = CatHeads.Num();

		DoubleInteract.OnPlayerStartedInteracting.AddUFunction(this, n"OnStartInteracting");
		DoubleInteract.OnDoubleInteractionCompleted.AddUFunction(this, n"OnDoubleInteractionCompleted");
		DoubleInteract.AddActorDisable(this);
		CatGateCheck.OnComponentBeginOverlap.AddUFunction(this, n"OnComponentBeginOverlap");
		SetActorTickEnabled(false);

		CatProgressComp.OnProgressionActivated.AddUFunction(this, n"OnProgressionActivated");
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		Alpha += Speed * DeltaSeconds;
		Alpha = Math::Clamp(Alpha, 0, 1);
		float Curve = DoorOpenCurve.GetFloatValue(Alpha);
		RRoot.RelativeRotation = FRotator(0, RotateAmount * Alpha, 0.0);
		LRoot.RelativeRotation = FRotator(0, -RotateAmount * Alpha, 0.0);

		if (Alpha == 1)
			SetActorTickEnabled(false);
	}

	UFUNCTION()
	private void OnStartInteracting(AHazePlayerCharacter Player, ADoubleInteractionActor Interaction,
	                                UInteractionComponent InteractionComponent)
	{
		if(Player.HasControl())
			UMoonMarketPlayerInteractionComponent::Get(Player).CrumbStopAllInteractions();
	}

	UFUNCTION()
	private void OnDoubleInteractionCompleted()
	{
		Timer::SetTimer(this, n"OnDoubleInteractionAnimationCompleted", 2);
		LKeyMesh.AttachToComponent(Game::Mio.Mesh, n"Align", EAttachmentRule::KeepWorld);
		RKeyMesh.AttachToComponent(Game::Zoe.Mesh, n"Align", EAttachmentRule::KeepWorld);
	}

	UFUNCTION()
	void OnDoubleInteractionAnimationCompleted()
	{
		OpenGate();
		DoubleInteract.AddActorDisable(this);
		LKeyMesh.DetachFromParent(true);
		RKeyMesh.DetachFromParent(true);
		LKeyMesh.SetHiddenInGame(true);
		RKeyMesh.SetHiddenInGame(true);
		OnMoonMarketSoulGateOpened.Broadcast();

		for (AHazePlayerCharacter Player : Game::Players)
		{
			UPolymorphResponseComponent::Get(Player).DesiredMorphClass = nullptr;
		}
	}

	UFUNCTION()	
	void ActivateGate()
	{
		DoubleInteract.RemoveActorDisable(this);
		LKeyMesh.SetHiddenInGame(false);
		RKeyMesh.SetHiddenInGame(false);
		UMoonMarketSoulCollectionGateEventHandler::Trigger_OnKeysRevealed(this, FMoonMarketSoulCollectionGateParams(LKeyMesh.WorldLocation));
		UMoonMarketSoulCollectionGateEventHandler::Trigger_OnKeysRevealed(this, FMoonMarketSoulCollectionGateParams(RKeyMesh.WorldLocation));
	}

	UFUNCTION(DevFunction)
	void DevActivateGate()
	{
		ActivateGate();
	}

	void OpenGate()
	{	
		SetActorTickEnabled(true);
	}
	
	UFUNCTION()
	private void OnComponentBeginOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor,
	                                     UPrimitiveComponent OtherComp, int OtherBodyIndex,
	                                     bool bFromSweep, const FHitResult&in SweepResult)
	{
		if (!HasControl())
			return;

		if (bCompleted)
			return;

		if (CatHeads.Num() == 0)
			return;

		AMoonMarketCat Cat = Cast<AMoonMarketCat>(OtherActor);

		if (Cat == nullptr)
			return;

		if (CatsDelivered.Contains(Cat))
			return;
		
		TEMPORAL_LOG(this).Event(f"Collected Cat {Cat}");
		CatsDelivered.AddUnique(Cat);
		CrumbCatDelivered(Cat);
	}

	UFUNCTION(CrumbFunction)
	void CrumbCatDelivered(AMoonMarketCat Cat)
	{
		Cat.StartSoulDeliverance();
		Cat.OnMoonCatFinishDelivering.AddUFunction(this, n"OnMoonCatFinishDelivering");
		Cat.SoulTargetPlayer.ActivateCamera(Camera, 2.0, this);
		
		CurrentNum++;
		TEMPORAL_LOG(this).PersistentValue("Numbers Collected", CurrentNum);
		TEMPORAL_LOG(this).PersistentValue(f"Cat Collected {Cat.GetCatName()}", true);

		if (CurrentNum >= CatHeads.Num())
			bCompleted = true;
	}

	UFUNCTION()
	private void OnMoonCatFinishDelivering(AHazePlayerCharacter Player, AMoonMarketCat Cat)
	{
		Player.DeactivateCameraByInstigator(this, 2.0);
		if (CurrentNum >= CatHeads.Num())
		{
			Timer::SetTimer(this, n"ActivateGate", 1.25, false);
		}
	}
	
	UFUNCTION()
	private void OnProgressionActivated()
	{
		CurrentNum++;

		if (CurrentNum >= CatHeads.Num())
		{
			DoubleInteract.RemoveActorDisable(this);
			LKeyMesh.SetHiddenInGame(false);
			RKeyMesh.SetHiddenInGame(false);
			bCompleted = true;
		}
	}

	UFUNCTION()
	void SetOpenState()
	{
		DoubleInteract.AddActorDisable(this);
		LKeyMesh.SetHiddenInGame(true);
		RKeyMesh.SetHiddenInGame(true);		
		RRoot.RelativeRotation = FRotator(0, RotateAmount, 0.0);
		LRoot.RelativeRotation = FRotator(0, -RotateAmount, 0.0);
		bCompleted = true;
	}

	UFUNCTION(BlueprintCallable)
	void BlockRelaxIdle(bool bBlock)
	{
		for (auto Player : Game::Players)
		{
			auto FloorComp = UPlayerFloorMotionComponent::Get(Player);
			if (FloorComp != nullptr)
			{
				if (bBlock)
					FloorComp.AddRelaxIdleBlocker(this);
				else
					FloorComp.ClearRelaxIdleBlocker(this);
			}
		}
	}
};