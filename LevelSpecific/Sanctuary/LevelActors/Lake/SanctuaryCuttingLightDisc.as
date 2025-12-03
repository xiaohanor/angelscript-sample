class ASanctuaryCuttingLightDisc : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent DiscMeshComp;
	default DiscMeshComp.SetHiddenInGame(true);
	default DiscMeshComp.SetCollisionEnabled(ECollisionEnabled::QueryAndPhysics);

	UPROPERTY(DefaultComponent, Attach = Root)
	UHazeSphereComponent HazeSphereComp;

	UPROPERTY(DefaultComponent)
	ULightBirdResponseComponent LightBirdResponseComponent;

	UPROPERTY(DefaultComponent)
	ULightBirdChargeComponent LightBirdChargeComp;

	// draw bridge golf special case
	ASanctuaryLightBirdSocket Socket;
	FVector OriginalLocation;
	float LastGolfDistance;
	bool bHasBeenGolfedAway = false;
	bool bTriedSpinning = false;

	UPROPERTY()
	FHazeTimeLike SpinnyTimeLike;

	UPROPERTY(EditInstanceOnly)
	TArray<ASanctuaryCutableDrawBridgeChain> ChainArray;

	UPROPERTY(EditAnywhere)
	float MeshScaleMultiplier = 15.0;

	UPROPERTY(EditAnywhere)
	float MaxDiscSize = 500.0;
	float DiscSize;
	
	UPROPERTY(EditAnywhere)
	float MaxSpinSpeed = 1000.0;
	float SpinSpeed = 0.0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		if (AttachParentActor != nullptr)
		{
			Socket = Cast<ASanctuaryLightBirdSocket>(AttachParentActor);
			LightBirdResponseComponent.AddListenToResponseActor(AttachParentActor);
			OriginalLocation = ActorLocation;
		}
		else
			PrintToScreen("Cutting disc is missing parent", 5.0, FLinearColor::Red);

		SpinnyTimeLike.BindUpdate(this, n"SpinnyTimeLikeUpdate");
		SpinnyTimeLike.BindFinished(this, n"SpinnyTimeLikeFinished");
		LightBirdChargeComp.OnFullyCharged.AddUFunction(this, n"HandleFullyCharged");
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		bool bSpinning = SpinSpeed > KINDA_SMALL_NUMBER;

		if (bSpinning)
			AddActorLocalRotation(FRotator(0.0, SpinSpeed * DeltaSeconds, 0.0));

		const float GolfTreshold = 150.0;
		const float GolfedDistance = OriginalLocation.Distance(ActorLocation);
		const bool bIsGolfed = GolfedDistance > GolfTreshold;
		const bool bReturnedToOriginalLocation = bHasBeenGolfedAway && !bIsGolfed;

		//Debug::DrawDebugString(ActorLocation, "" + GolfedDistance);

		bool bSendFailCutEvent = false;
		if (bReturnedToOriginalLocation && bTriedSpinning)
			bSendFailCutEvent = true;
		bHasBeenGolfedAway = bIsGolfed;

		if (!bHasBeenGolfedAway)
			bTriedSpinning = false;
		
		float ChargeFraction = LightBirdChargeComp.GetChargeFraction();
		HazeSphereComp.SetTemperature(ChargeFraction, 0.0, ChargeFraction * 30000.0);

		for (auto Chain : ChainArray)
		{
			if (bSpinning && ActorLocation.Distance(Chain.UpperChainRootComp.WorldLocation) < DiscSize)
				Chain.Cut();
			if (bSendFailCutEvent)
				Chain.MissCut();
		}
	}

	UFUNCTION()
	private void HandleFullyCharged()
	{
		SpinnyTimeLike.PlayFromStart();
		DiscMeshComp.SetHiddenInGame(false);
		DiscMeshComp.SetCollisionEnabled(ECollisionEnabled::QueryAndPhysics);
		Game::Mio.ConsumeButtonInputsRelatedTo(n"SecondaryLevelAbility");
		BP_FullyCharged();
	}

	UFUNCTION()
	private void SpinnyTimeLikeUpdate(float CurrentValue)
	{
		bTriedSpinning = true;
		SpinSpeed = CurrentValue * MaxSpinSpeed;
		DiscMeshComp.SetRelativeScale3D(FVector(CurrentValue * MeshScaleMultiplier));
		DiscSize = CurrentValue * MaxDiscSize;
	}

	UFUNCTION()
	private void SpinnyTimeLikeFinished()
	{
		DiscMeshComp.SetHiddenInGame(true);
		DiscMeshComp.SetCollisionEnabled(ECollisionEnabled::NoCollision);
	}	

	UFUNCTION(BlueprintEvent)
	private void BP_FullyCharged(){}
};