class ASkylineVendingMachineActor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;
	
	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent Mesh;
	default DestroyedMesh.bVisible = true;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent DestroyedMesh;
	default DestroyedMesh.bVisible = false;

	UPROPERTY(DefaultComponent, Attach = Root)
	UBillboardComponent Billboard;

	UPROPERTY(DefaultComponent)
	UGravityBladeCombatInteractionResponseComponent BladeInteractionResponseComp;
	
	UPROPERTY(EditInstanceOnly)
	APrefabRoot LitMachine;

	int HitTimes = 0;

	UPROPERTY(EditAnywhere)
	ASplineActor ConstrainRollingCansSpline;

	UPROPERTY(EditAnywhere)
	TSubclassOf<ASkylineRollingTrash> RollingTrashClass;

	UPROPERTY(DefaultComponent)
	UNiagaraComponent BrokenSmokeComp;

	UPROPERTY(EditDefaultsOnly)
	UNiagaraSystem BrokeVFX;

	float SpammingTotalTimer = 0.0;
	float SpammingCooldownTimer = 0.0;
	const float SpammingCooldownTime = 0.15;
	bool bBroken = false;

	int SpawnedObjects = 0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		BladeInteractionResponseComp.OnHit.AddUFunction(this, n"HandleHit");
		SetActorControlSide(Game::Mio);
		DestroyedMesh.SetVisibility(false, true);
	}

	UFUNCTION()
	private void HandleHit(UGravityBladeCombatUserComponent CombatComp, FGravityBladeHitData HitData)
	{
		if (!HasControl())
			return;

		if (bBroken)
			return;

		++HitTimes;
		if (HitTimes > 3)
		{

			if(!bBroken)
				USkylineVendingMachineEventHandler::Trigger_VendingMachineBroken(this);

			SpammingTotalTimer = 3.0;
			SpammingCooldownTimer = SpammingCooldownTime;
			bBroken = true;
			BrokenSmokeComp.Activate();
			Niagara::SpawnOneShotNiagaraSystemAtLocation(BrokeVFX, ActorLocation, ActorRotation);

			Mesh.SetVisibility(false, true);
			DestroyedMesh.SetVisibility(true, true);
			if (LitMachine != nullptr)
				LitMachine.Root.SetVisibility(false, true);

			TArray<USpotLightComponent> Spotlights;
			GetComponentsByClass(Spotlights);
			for (int iLight = 0; iLight < Spotlights.Num(); ++iLight)
			{
				Spotlights[iLight].LightColor = ColorDebug::Ruby;
				Spotlights[iLight].SourceRadius = 0.0;
			}
		}
		else
		{
			USkylineVendingMachineEventHandler::Trigger_HitByKatana(this);
		}

		CrumbSpawnCan(GetRandomImpulse());
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (!HasControl())
			return;

		if (bBroken)
		{
			SpammingTotalTimer -= DeltaSeconds;
			SpammingCooldownTimer -= DeltaSeconds;
			if (SpammingTotalTimer > 0.0 && SpammingCooldownTimer < 0.0)
			{
				SpammingCooldownTimer = SpammingCooldownTime * Math::RandRange(1.0, 1.5);
				CrumbSpawnCan(GetRandomImpulse());
			}
		}
	}

	FVector GetRandomImpulse() const
	{
		FVector RandomImpulse = Math::GetRandomConeDirection(ActorForwardVector, Math::DegreesToRadians(35.0));
		RandomImpulse.Z = 0.5;
		return RandomImpulse.GetSafeNormal() * Math::RandRange(500.0, 1000.0);
	}

	UFUNCTION(CrumbFunction)
	private void CrumbSpawnCan(FVector RandomImpulse)
	{
		if (RollingTrashClass == nullptr)
			return;

		if (ConstrainRollingCansSpline == nullptr)
			return;

		FVector SpawnLocation = ActorLocation + FVector::UpVector * 5.0; // can radius for faux physics

		ASkylineRollingTrash SpawnedActor = SpawnActor(RollingTrashClass, SpawnLocation, FRotator(), NAME_None, true);
		SpawnedActor.MakeNetworked(this, SpawnedObjects);
		SpawnedObjects++;
		SpawnedActor.SetActorControlSide(Game::Zoe);
		SpawnedActor.FauxTranslationComp.OtherSplineActor = ConstrainRollingCansSpline;
		SpawnedActor.FauxTranslationComp.bClockwise = false;
		FQuat NewWorldRot = FQuat::ApplyRelative(FQuat::MakeFromZX(FVector::UpVector, RandomImpulse.GetSafeNormal()), SpawnedActor.FauxRotateComp.RelativeRotation.Quaternion());
		SpawnedActor.FauxRotateComp.SetWorldRotation(NewWorldRot);
		FinishSpawningActor(SpawnedActor);

		FVector Delta = BrokenSmokeComp.WorldLocation - SpawnedActor.FauxTranslationComp.WorldLocation;
		SpawnedActor.FauxTranslationComp.ApplyMovement(SpawnedActor.FauxTranslationComp.WorldLocation, Delta);
		SpawnedActor.FauxTranslationComp.ApplyImpulse(SpawnLocation, RandomImpulse);
		SpawnedActor.FauxRotateComp.ApplyAngularForce(Math::DegreesToRadians(360));
		
		USkylineVendingMachineEventHandler::Trigger_SpawnedCan(this);
	}
};