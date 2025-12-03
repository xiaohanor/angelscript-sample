class AAcidFireSprayContraption : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = Root)
	UBoxComponent SprayBounds;
	default SprayBounds.SetCollisionResponseToAllChannels(ECollisionResponse::ECR_Block);

	UPROPERTY(DefaultComponent, Attach = Root)
	UNiagaraComponent FlameThrower;
	default FlameThrower.SetAutoActivate(false);

	UPROPERTY(DefaultComponent, Attach = Root)
	UInteractionComponent InteractComp;
	default InteractComp.UsableByPlayers = EHazeSelectPlayer::Zoe;

	UPROPERTY(DefaultComponent, Attach = SprayBounds)
	UAcidResponseComponent ResponseComp;

	UPROPERTY(DefaultComponent)
	UAcidSprayContraptionResponseComponent CurrentSprayResponseComp;

	TArray<UAcidSprayContraptionResponseComponent> FoundResponseComps;	

	float SprayTime;
	float SprayDelayComplete = 1.1;
	float SprayDistance;
	float MaxSprayDistance = 3500.0;
	float SprayDistanceAcceleration = 1600.0;

	bool bIsActive;

	//ATeenDragon AttachedDragon;
	AHazePlayerCharacter ActivePlayer;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		ResponseComp.OnAcidHit.AddUFunction(this, n"OnAcidHit");
		InteractComp.OnInteractionStarted.AddUFunction(this, n"OnInteractionStarted");
		InteractComp.OnInteractionStopped.AddUFunction(this, n"OnInteractionStopped");
		CurrentSprayResponseComp.OnAcidSprayIgnite.AddUFunction(this, n"OnAcidSprayIgnite");
	}


	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		// PrintToScreen("bIsActive: " + bIsActive);

		if (Time::GameTimeSeconds < SprayTime)
		{
			if (!bIsActive)
			{
				FlameThrower.Activate();
				bIsActive = true;
			}

			FHazeTraceDebugSettings Debug;
			Debug.TraceColor = FLinearColor::Red;
			Debug.Thickness = 10.0;

			float BoundingExtent = 320.0;
			FHazeTraceSettings TraceSettings = Trace::InitChannel(ECollisionChannel::ECC_WorldDynamic);
			TraceSettings.UseBoxShape(FVector(BoundingExtent, BoundingExtent, BoundingExtent), ActorForwardVector.ToOrientationQuat());
			TraceSettings.IgnoreActor(this);
			//TraceSettings.IgnoreActor(AttachedDragon);
			// TraceSettings.DebugDraw(Debug);

			SprayDistance = Math::FInterpConstantTo(SprayDistance, MaxSprayDistance, DeltaSeconds, SprayDistanceAcceleration);

			FHitResultArray HitResults = TraceSettings.QueryTraceMulti(SprayBounds.WorldLocation, SprayBounds.WorldLocation + ActorForwardVector * SprayDistance);

			for (FHitResult Hit : HitResults)
			{
				UAcidSprayContraptionResponseComponent SprayResponseComp = UAcidSprayContraptionResponseComponent::Get(Hit.Actor);

				if (SprayResponseComp != nullptr)
				{
					if (FoundResponseComps.Contains(SprayResponseComp))
						continue;

					FoundResponseComps.AddUnique(SprayResponseComp);
					SprayResponseComp.BroadcastSprayIgnite();
				}
			}
		}
		else
		{
			if (bIsActive)
			{
				bIsActive = false;
				FlameThrower.Deactivate();
				SprayDistance = 0.0;
				FoundResponseComps.Empty();
			}
		}

		if (ActivePlayer != nullptr)
		{	
			ActorLocation = UPlayerTeenDragonComponent::Get(ActivePlayer).DragonMesh.GetSocketLocation(n"Jaw");
			ActorLocation -= FVector(0.0, 0.0, 50.0);
			ActorRotation = ActivePlayer.ActorRotation;
		}
	}


	UFUNCTION()
	private void OnAcidSprayIgnite()
	{
		SprayTime = Time::GameTimeSeconds + SprayDelayComplete;
	}

	UFUNCTION()
	private void OnAcidHit(FAcidHit Hit)
	{
		if (Hit.HitComponent != nullptr)
			Print("WE HIT: " + Hit.HitComponent.Owner.Name);
		else	
			Print("WE HIT NO COMPONENT");

		if (Hit.HitComponent == SprayBounds)
			SprayTime = Time::GameTimeSeconds + SprayDelayComplete;
	}
	
	UFUNCTION()
	private void OnInteractionStarted(UInteractionComponent Interaction, AHazePlayerCharacter Player)
	{
		ActivePlayer = Player;
		// UPlayerTeenDragonComponent DragonComp = UPlayerTeenDragonComponent::Get(Player);
		// AttachedDragon = DragonComp.TeenDragon;
	}
	
	UFUNCTION()
	private void OnInteractionStopped(UInteractionComponent Interaction, AHazePlayerCharacter Player)
	{
		ActorLocation = ActivePlayer.ActorLocation;
		ActorLocation += ActivePlayer.ActorForwardVector * 200.0;
		ActivePlayer = nullptr;
	}
	
	// UFUNCTION()
	// private void OnComponentBeginOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor,
	//                                      UPrimitiveComponent OtherComp, int OtherBodyIndex,
	//                                      bool bFromSweep, const FHitResult&in SweepResult)
	// {
	// 	UAcidSprayContraptionResponseComponent SprayResponseComp = UAcidSprayContraptionResponseComponent::Get(OtherActor);

	// 	if (SprayResponseComp != nullptr)
	// 		SprayResponseComp.BroadcastSprayIgnite();
	// }
}