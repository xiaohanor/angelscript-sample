class ASolarFlareDestructibleCover : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UStaticMeshComponent Cover1;
	default Cover1.SetMobility(EComponentMobility::Movable);

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UStaticMeshComponent Cover2;
	default Cover2.SetMobility(EComponentMobility::Movable);
	default Cover2.SetHiddenInGame(true);

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UStaticMeshComponent Cover3;
	default Cover3.SetMobility(EComponentMobility::Movable);
	default Cover3.SetHiddenInGame(true);

	UPROPERTY(DefaultComponent, Attach = MeshRoot, ShowOnActor)
	USolarFlarePlayerCoverComponent CoverPlayerComp;
	default CoverPlayerComp.Distance = 650.0;

	UPROPERTY(DefaultComponent)
	USolarFlareEffectComponent EffectComp;

	UPROPERTY(DefaultComponent)
	USolarFlareFireWaveReactionComponent WaveReactionComp;

	UPROPERTY(EditAnywhere)
	bool bIsPermaDestroyable = false;

	UPROPERTY(EditAnywhere)
	bool bIsDestroyable = true;

	UPROPERTY(EditAnywhere)
	bool bDebug;

	UPROPERTY(EditAnywhere)
	FRuntimeFloatCurve Curve;
	default Curve.AddDefaultKey(0.0, 0.0);
	default Curve.AddDefaultKey(1.0, 1.0);

	TArray<UStaticMeshComponent> MeshComps;

	int Index = 0;

	bool bIsActive = true;
	bool bIsBreakActive = false;
	bool bHasPermaDestroyed;

	FLinearColor GlassColor;

	UMaterialInstanceDynamic DynamicMat;

	float V = 0.0;
	float TargetV = 125.0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		GetComponentsByClass(MeshComps);
		TArray<USolarFireStaticMesh> FireMeshes;
		GetComponentsByClass(FireMeshes);
		for (USolarFireStaticMesh Fire : FireMeshes)
		{
			if (MeshComps.Contains(Fire))
				MeshComps.Remove(Fire);
		}

		for (int i = 0; i < MeshComps.Num(); i++)
		{
			if (i != 0)
				MeshComps[i].SetHiddenInGame(true);
		}

		WaveReactionComp.OnSolarFlareImpact.AddUFunction(this, n"OnSolarFlareImpact");

		CoverPlayerComp.OnPlayerEnteredCover.AddUFunction(this, n"OnPlayerEnteredCover");

		DynamicMat = Cover2.CreateDynamicMaterialInstance(1);
		Cover2.SetMaterial(1, DynamicMat);
		Cover3.SetMaterial(1, DynamicMat);
		GlassColor = DynamicMat.GetVectorParameterValue(n"Emiss");
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		V = Math::FInterpConstantTo(V, 0.0, DeltaSeconds, TargetV / 4.0);
		float Alpha = Math::Saturate(V / TargetV);
		DynamicMat.SetVectorParameterValue(n"Emiss", GlassColor * Curve.GetFloatValue(Alpha));
	}

	UFUNCTION()
	private void OnPlayerEnteredCover()
	{
		SetBreakActiveState(true);
	}

	UFUNCTION()
	private void OnSolarFlareImpact()
	{
		V = TargetV;

		if (!bIsActive)
			return;

		if (!bIsBreakActive)
		{
			FOnSolarFlareDestructibleCoverGeneralParams Params;
			Params.Location = ActorLocation;
			USolarFlareDestructibleCoverEffectHandler::Trigger_OnCoverImpacted(this, Params);
			return;
		}

		ActivateDestruction();
	}

	UFUNCTION()
	void ActivateDestruction()
	{
		if (Index >= 3)
			return;

		if (!bIsDestroyable)
			return;

		Index++;

		switch (Index)
		{
			case 1:
				Cover1.SetHiddenInGame(true);
				Cover2.SetHiddenInGame(false);
				break;
			case 2:
				Cover2.SetHiddenInGame(true);
				Cover3.SetHiddenInGame(false);
				break;
			case 3:
				if (bIsPermaDestroyable)
					PermaDestroy();
		}

		FOnSolarFlareDestructibleCoverActivatedParams Params;
		Params.Location = ActorLocation;
		Params.Index = Index;
		USolarFlareDestructibleCoverEffectHandler::Trigger_OnDestructionImpact(this, Params);
	}

	void PermaDestroy()
	{
		SetActorEnableCollision(false);
		// CoverOverlapComp.AddDisabler(this);
		SetActiveState(false);

		for (UStaticMeshComponent Mesh : MeshComps)
		{
			Mesh.SetHiddenInGame(true);
			Mesh.SetCollisionEnabled(ECollisionEnabled::NoCollision);
		}

		for (AHazePlayerCharacter Player : Game::Players)
		{
			USolarFlarePlayerComponent PlayerComp = USolarFlarePlayerComponent::Get(Player);
			if (PlayerComp.IsThisCoverInUse(CoverPlayerComp))
				PlayerComp.SetInvincibleForDuration(0.5);
		}

		CoverPlayerComp.Destroyed();

		EffectComp.AddDisabler(this);
		FOnSolarFlareDestructibleCoverGeneralParams Params;
		Params.Location = ActorLocation;
		USolarFlareDestructibleCoverEffectHandler::Trigger_OnCoverPermaDestroyed(this, Params);

		FHazeTraceDebugSettings Debug;
		Debug.Duration = 5.0;
		FHazeTraceSettings TraceSettings = Trace::InitChannel(ECollisionChannel::ECC_Visibility);
		TraceSettings.UseSphereShape(500.0);
		// TraceSettings.DebugDraw(Debug);
		TraceSettings.IgnoreActor(this);

		FHitResultArray HitResults = TraceSettings.QueryTraceMulti(ActorLocation, ActorLocation + ActorForwardVector);

		for (FHitResult Hit : HitResults)
		{
			if (!Hit.bBlockingHit)
				continue;

			auto Player = Cast<AHazePlayerCharacter>(Hit.Actor);

			if (Player == nullptr)
				continue;

			FKnockdown KnockDown;
			FVector Move = -ActorForwardVector * 900.0;
			Move += FVector::UpVector * 500.0;
			KnockDown.Move = Move;
			KnockDown.AirFriction = 1.0;
			KnockDown.Duration = 1.0;
			Player.ApplyKnockdown(KnockDown);
		}
	}

	UFUNCTION()
	void BP_PermaDestroy()
	{
		PermaDestroy();
	}

	void SetBreakActiveState(bool bCanBreak)
	{
		if (!bIsDestroyable)
			return;
		
		bIsBreakActive = bCanBreak;
	}

	void SetActiveState(bool bSetIfActive)
	{
		bIsActive = bSetIfActive;
	}
}