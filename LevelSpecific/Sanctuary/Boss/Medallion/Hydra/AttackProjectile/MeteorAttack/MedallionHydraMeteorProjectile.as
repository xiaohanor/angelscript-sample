class AMedallionHydraMeteorProjectile : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent TelegraphRoot;

	UPROPERTY(DefaultComponent)
	UHazeActionQueueComponent QueueComp;

	UPROPERTY()
	UMaterialInstance OverlayMat;

	FVector StartLocation;
	FVector HoverLocation;
	FVector HoverWithWobbleLocation;

	// AHazePlayerCharacter TargetPlayer;
	ABallistaHydraSplinePlatform TargetPlatform;
	FVector LastTargetLocation;

	FVector TargetPlatformOffset;

	const float HoverDistance = 3000.0;
	const float DamageHeight = 400.0;
	float RandomOffset;

	UPROPERTY()
	ASanctuaryBossMedallionHydra Hydra;

	TArray<UActorComponent> PlatformMeshComps;

	UMedallionPlayerReferencesComponent MedallionRefsComp;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		RandomOffset = Math::RandRange(0.0, PI);
		StartLocation = ActorLocation;
		HoverLocation = ActorLocation + ActorForwardVector * HoverDistance;

		MedallionRefsComp = UMedallionPlayerReferencesComponent::GetOrCreate(Game::Mio);

		TelegraphRoot.SetHiddenInGame(true, true);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		HoverWithWobbleLocation = HoverLocation + (FVector::UpVector * Math::Sin((Time::GameTimeSeconds + RandomOffset) * 3.0) * 150.0);
	}

	void QueueHover()
	{
		QueueComp.Duration(1.0, this, n"GoToHoverUpdate");
	}

	void QueueMeteor()
	{
		QueueComp.Event(this, n"StartTelegraph");
		QueueComp.Duration(2.0, this, n"MeteorFloatUpdate");
		QueueComp.Event(this, n"StartMeteor");
		QueueComp.Duration(0.5, this, n"MeteorUpdate");
		QueueComp.Event(this, n"Explode");
	}

	

	UFUNCTION()
	private void StartTelegraph()
	{
		FHazeTraceSettings Trace = Trace::InitProfile(n"PlayerCharacter");
		auto HitResult = Trace.QueryTraceSingle(
			TargetPlatform.ActorLocation + FVector::UpVector * 1000.0, 
			TargetPlatform.ActorLocation + FVector::UpVector * -1000.0);
		
		if (HitResult.bBlockingHit)
		{
			TargetPlatformOffset = TargetPlatform.ActorTransform.InverseTransformPositionNoScale(HitResult.Location);
		}
		
		TargetPlatform.GetAllComponents(UStaticMeshComponent, PlatformMeshComps);

		for (auto PlatformMeshComp : PlatformMeshComps)
		{
			auto StaticMesh = Cast<UStaticMeshComponent>(PlatformMeshComp);
			if (StaticMesh != nullptr)
				StaticMesh.SetOverlayMaterial(OverlayMat);
		}

		TelegraphRoot.SetWorldLocationAndRotation(TargetPlatform.ActorTransform.TransformPositionNoScale(TargetPlatformOffset), TargetPlatform.ActorRotation);
		TelegraphRoot.AttachToComponent(TargetPlatform.FloatingComp, NAME_None, EAttachmentRule::KeepWorld);
		TelegraphRoot.SetHiddenInGame(false, true);
	}

	UFUNCTION()
	private void GoToHoverUpdate(float Alpha)
	{
		float CurrentValue = Math::EaseOut(0.0, 1.0, Alpha, 2.0);
		FVector Location = Math::Lerp(StartLocation, HoverWithWobbleLocation, CurrentValue);
		SetActorLocation(Location);
	}

	UFUNCTION()
	private void StartMeteor()
	{
		FSanctuaryBossMedallionManagerEventProjectileData Params;
		Params.Projectile = this;
		Params.ProjectileType = EMedallionHydraProjectileType::Meteor;
		Params.StartLocation = ActorLocation;

		UMedallionHydraAttackManagerEventHandler::Trigger_OnShootProjectile(MedallionRefsComp.Refs.HydraAttackManager, Params);
		BP_StartMeteor();
	}

	UFUNCTION()
	private void MeteorFloatUpdate(float Alpha)
	{
		SetActorLocation(HoverWithWobbleLocation);
	}

	UFUNCTION(BlueprintEvent)
	private void BP_StartMeteor(){}

	UFUNCTION()
	private void MeteorUpdate(float Alpha)
	{
		float CurrentValue = Math::EaseIn(0.0, 1.0, Alpha, 1.0);
		if (TargetPlatform != nullptr)
		{
			FVector Location = Math::Lerp(HoverWithWobbleLocation, TelegraphRoot.WorldLocation, CurrentValue);
			LastTargetLocation = TelegraphRoot.WorldLocation;
			SetActorLocation(Location);
		}
		else
		{
			FVector Location = Math::Lerp(HoverWithWobbleLocation, LastTargetLocation, CurrentValue);
			SetActorLocation(Location);
		}
	}

	UFUNCTION()
	private void Explode()
	{
		BP_Explode();
		FVector ImpulseDirection = (TelegraphRoot.WorldLocation - HoverLocation).GetSafeNormal();
		TargetPlatform.TranslateCompZ.ApplyImpulse(TelegraphRoot.WorldLocation, ImpulseDirection * 2000.0);
		TargetPlatform.ConeRotateComp.ApplyImpulse(TelegraphRoot.WorldLocation, ImpulseDirection * 2000.0);

		for (auto Player : Game::Players)
		{
			auto Trace = Trace::InitProfile(n"PlayerCharacter");
			auto HitResult = Trace.QueryTraceSingle(Player.ActorCenterLocation, Player.ActorCenterLocation - FVector::UpVector * DamageHeight);

			if (HitResult.bBlockingHit)
			{
				if (HitResult.Actor == TargetPlatform)
					KnockPlayer(Player, ImpulseDirection);
			}

		}

		for (auto PlatformMeshComp : PlatformMeshComps)
		{
			auto StaticMesh = Cast<UStaticMeshComponent>(PlatformMeshComp);
			if (StaticMesh != nullptr)
				StaticMesh.SetOverlayMaterial(nullptr);
		}

		FSanctuaryBossMedallionManagerEventProjectileData Params;
		Params.Projectile = this;
		Params.ProjectileType = EMedallionHydraProjectileType::Meteor;
		Params.StartLocation = ActorLocation;

		UMedallionHydraAttackManagerEventHandler::Trigger_OnProjectileImpact(MedallionRefsComp.Refs.HydraAttackManager, Params);
		DestroyActor();
	}

	private void KnockPlayer(AHazePlayerCharacter Player, FVector ImpulseDirection)
	{
		Player.DamagePlayerHealth(0.5);

		FVector KnockbackMove = FRotator::MakeFromZX(FVector::UpVector, ImpulseDirection).ForwardVector * 3000.0 +
							FVector::UpVector * 2000.0;

		Player.ApplyKnockdown(KnockbackMove, 2.5);
	}

	UFUNCTION(BlueprintEvent)
	private void BP_Explode(){}
};