class ASkylineHighwayFlyingBoxes : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	USceneComponent FixedRoot;

	UPROPERTY(DefaultComponent)
	USceneComponent SimulationRoot;
	TArray<UPrimitiveComponent> SimulatedPrimitives;

	bool bSimulationActive = false;
	bool bActiveForce = false;

	UPROPERTY(EditAnywhere)
	float BoxWeight = 10.0;

	UPROPERTY(EditAnywhere)
	float SimulationDuration = 5.0;
	float ExpireTime = 0.0;

	UPROPERTY(EditAnywhere)
	FVector Force = FVector(11000.0, 0.0, 0.0);

	UPROPERTY(EditAnywhere)
	bool bOnlyFirstBoxHit = true;

	TPerPlayer<bool> bPlayerHit;

	float Distance = 500.0;

	UPROPERTY(DefaultComponent)
	USkylineInterfaceComponent InterfaceComp;

	UPROPERTY(Category = Audio)
	UHazeAudioEvent BoxesFallEvent;

	FHazeAcceleratedFloat AcceleratedFloat;
	private UHazeAudioEmitter BoxesMultiEmitter;
	TArray<FAkSoundPosition> BoxSoundPositions;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		TArray<USceneComponent> Components;
		SimulationRoot.GetChildrenComponentsByClass(UPrimitiveComponent, true, Components);
	
		for (auto Component : Components)
		{
			auto Primitive = Cast<UPrimitiveComponent>(Component);
			if (Primitive != nullptr)
			{
				SimulatedPrimitives.Add(Primitive);
				Primitive.bGenerateOverlapEvents = true;
				Primitive.AddComponentCollisionBlocker(this);
				Primitive.SetMassOverrideInKg(MassInKg = 10.0);
				Primitive.SetCollisionResponseToChannel(ECollisionChannel::PlayerCharacter, ECollisionResponse::ECR_Overlap);
				Primitive.SetCollisionResponseToChannel(ECollisionChannel::ECC_Camera, ECollisionResponse::ECR_Ignore);
				Primitive.SetCollisionResponseToChannel(ECollisionChannel::ECC_Visibility, ECollisionResponse::ECR_Ignore);
				Primitive.OnComponentBeginOverlap.AddUFunction(this, n"HandleBoxPlayerOverlap");
			}
		}

		InterfaceComp.OnActivated.AddUFunction(this, n"HandleActivated");

		FHazeAudioEmitterAttachmentParams PooledEmitterParams;
		PooledEmitterParams.Instigator = this;
		PooledEmitterParams.Owner = this;
		PooledEmitterParams.bCanAttach = true;
		PooledEmitterParams.Attachment = SimulationRoot;

		BoxesMultiEmitter = Audio::GetPooledEmitter(PooledEmitterParams);
		BoxSoundPositions.SetNum(SimulatedPrimitives.Num());
	}

	UFUNCTION()
	private void HandleBoxPlayerOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor, UPrimitiveComponent OtherComp, int OtherBodyIndex, bool bFromSweep, const FHitResult&in SweepResult)
	{
//		OverlappedComponent.OnComponentBeginOverlap.Unbind(this, n"HandleBoxPlayerOverlap");
//		OverlappedComponent.SetCollisionResponseToChannel(ECollisionChannel::PlayerCharacter, ECollisionResponse::ECR_Ignore);
//		OverlappedComponent.bGenerateOverlapEvents = false;

		auto Player = Cast<AHazePlayerCharacter>(OtherActor);
		if (Player == nullptr)
			return;

		if (!bPlayerHit[Player])
		{
			FVector Impulse = (OverlappedComponent.ComponentVelocity * 1.0).VectorPlaneProject(Player.ActorUpVector);
			Impulse += Player.ActorUpVector * 600.0;

			OverlappedComponent.AddImpulse(FVector::UpVector * 800.0, bVelChange = true);

			Player.DamagePlayerHealth(0.1);
			//Player.AddMovementImpulse(Impulse);
			Player.ApplyKnockdown(Impulse, 1.5);
		}

		if (bOnlyFirstBoxHit)
			bPlayerHit[Player] = true;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (bSimulationActive && Time::GameTimeSeconds > ExpireTime)
		{
			for (auto SimulatedPrimitive : SimulatedPrimitives)
				SimulatedPrimitive.DestroyComponent(SimulatedPrimitive);
			
			bSimulationActive = false;
			Audio::ReturnPooledEmitter(this, BoxesMultiEmitter);
		}

		if (bSimulationActive && bActiveForce)
		{
			for(int i = 0; i < SimulatedPrimitives.Num(); ++i)
			{
				auto SimulatedPrimitive = SimulatedPrimitives[i];
				SimulatedPrimitive.AddForce(ActorTransform.TransformVectorNoScale(Force));
				BoxSoundPositions[i].SetPosition(SimulatedPrimitive.GetWorldLocation());
			}
		
			AcceleratedFloat.AccelerateTo(1.0, 5.0, DeltaSeconds);

			FixedRoot.RelativeLocation = FVector::ForwardVector * AcceleratedFloat.Value * Distance;

			BoxesMultiEmitter.AudioComponent.SetMultipleSoundPositions(BoxSoundPositions);
		}
	}

	UFUNCTION()
	private void HandleActivated(AActor Caller)
	{
		SimulatePhysics();
	}

	UFUNCTION(DevFunction)
	void SimulatePhysics()
	{
		ExpireTime = Time::GameTimeSeconds + SimulationDuration;

		bSimulationActive = true;
		bActiveForce = true;

		for (auto SimulatedPrimitive : SimulatedPrimitives)
		{
			SimulatedPrimitive.RemoveComponentCollisionBlocker(this);
			SimulatedPrimitive.SetSimulatePhysics(true);
		}

		BoxesMultiEmitter.SetAttenuationScaling(10000);
		BoxesMultiEmitter.PostEvent(BoxesFallEvent);
	}
};