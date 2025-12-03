event void FArenaPlatformPlayerLandedEvent(AArenaPlatform Platform, AHazePlayerCharacter Player);

UCLASS(Abstract)
class AArenaPlatform : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UFauxPhysicsTranslateComponent TranslateRoot;

	UPROPERTY(DefaultComponent, Attach = TranslateRoot)
	UFauxPhysicsConeRotateComponent PlatformRoot;

	UPROPERTY(DefaultComponent, Attach = PlatformRoot)
	USceneComponent ImpactTargetComp;

	UPROPERTY(DefaultComponent, Attach = PlatformRoot)
	UStaticMeshComponent PlatformMesh;

	UPROPERTY(DefaultComponent)
	UMovementImpactCallbackComponent MovementImpactCallbackComp;

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedComponent;

	UPROPERTY(BlueprintReadWrite)
	UNiagaraComponent DangerEffectComp;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<UDeathEffect> PlatformAttackDeathEffect;

	UPROPERTY(EditDefaultsOnly)
	FHazeTimeLike MovePlatformTimeLike;

	UPROPERTY(EditAnywhere)
	FVector PlatformOffset;

	UPROPERTY(EditAnywhere)
	UStaticMesh MeshAsset;

	UPROPERTY(EditAnywhere)
	FVector Spread = FVector(0.0, 300.0, 0.0);
	bool bIsSpread = false;

	UPROPERTY(EditInstanceOnly)
	UStaticMesh DestructionMesh;

	UPROPERTY(EditDefaultsOnly)
	FHazeTimeLike DestructionTimeLike;

	UPROPERTY()
	FArenaPlatformPlayerLandedEvent OnPlayerLanded;

	bool bResetting = false;

	FVector StartSpread = FVector::ZeroVector;

	bool bDestroyed = false;

	UPROPERTY(EditAnywhere)
	bool bPreviewSpread = false;

	TArray<AHazePlayerCharacter> PlayersOnPlatform;

	bool bFauxPhysicsAllowed = false;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		if (MeshAsset != nullptr)
			PlatformMesh.SetStaticMesh(MeshAsset);

		TArray<AActor> Actors;
		GetAttachedActors(Actors);
		for (AActor Actor : Actors)
		{
			Actor.AttachToComponent(PlatformRoot, NAME_None, EAttachmentRule::KeepWorld);
		}

		if (bPreviewSpread)
			TranslateRoot.SetRelativeLocation(PlatformOffset + Spread);
		else
			TranslateRoot.SetRelativeLocation(PlatformOffset);

		PlatformMesh.SetRelativeLocation(-PlatformOffset);
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		MovePlatformTimeLike.BindUpdate(this, n"UpdateMovePlatform");
		MovePlatformTimeLike.BindFinished(this, n"FinishMovePlatform");

		MovementImpactCallbackComp.OnGroundImpactedByPlayer.AddUFunction(this, n"PlayerLanded");
		MovementImpactCallbackComp.OnGroundImpactedByPlayerEnded.AddUFunction(this, n"PlayerLeft");

		DestructionTimeLike.BindUpdate(this, n"UpdateDestruction");
		DestructionTimeLike.BindFinished(this, n"FinishDestruction");
	}

	UFUNCTION()
	private void PlayerLanded(AHazePlayerCharacter Player)
	{
		OnPlayerLanded.Broadcast(this, Player);

		if (bIsSpread && bFauxPhysicsAllowed)
		{
			PlatformRoot.ApplyImpulse(Player.ActorLocation, FVector::UpVector * -150.0);
		}

		PlayersOnPlatform.AddUnique(Player);
	}

	UFUNCTION()
	private void PlayerLeft(AHazePlayerCharacter Player)
	{
		PlayersOnPlatform.Remove(Player);
	}

	UFUNCTION(NotBlueprintCallable)
	void UpdateMovePlatform(float CurValue)
	{
		FVector CurSpread = Math::Lerp(StartSpread, PlatformOffset + Spread, CurValue);
		TranslateRoot.SetRelativeLocation(CurSpread);
	}

	UFUNCTION(NotBlueprintCallable)
	void FinishMovePlatform()
	{

	}

	UFUNCTION()
	void UpdateSpread(FVector NewSpread)
	{
		Spread = NewSpread;
	}

	UFUNCTION()
	void SpreadPlatform(bool bEnablePhysics)
	{
		bIsSpread = true;
		bResetting = false;
		bFauxPhysicsAllowed = bEnablePhysics;
		StartSpread = TranslateRoot.RelativeLocation;
		MovePlatformTimeLike.PlayFromStart();
	}

	UFUNCTION()
	void ResetPlatform()
	{
		if (!bIsSpread)
			return;

		bIsSpread = false;
		bResetting = true;
		bFauxPhysicsAllowed = false;
		MovePlatformTimeLike.ReverseFromEnd();
	}

	UFUNCTION()
	void SnapSpread()
	{
		bIsSpread = true;
		bResetting = false;
		StartSpread = TranslateRoot.RelativeLocation;
		TranslateRoot.SetRelativeLocation(PlatformOffset + Spread);
	}

	void PrepareAttack()
	{
		if (bDestroyed)
			return;

		DangerEffectComp.Activate(true);
	}

	void TriggerAttack()
	{
		DangerEffectComp.Deactivate();

		FVector ImpulseLoc = ImpactTargetComp.WorldLocation + (ActorForwardVector.RotateAngleAxis(Math::RandRange(0.0, 360.0), FVector::UpVector) * 500.0);
		PlatformRoot.ApplyImpulse(ImpulseLoc, FVector::UpVector * 800.0);

		for (AHazePlayerCharacter Player : Game::GetPlayers())
		{
			FHazeTraceSettings Trace = Trace::InitChannel(ECollisionChannel::ECC_Visibility);
			Trace.IgnorePlayers();
			Trace.UseCapsuleShape(Player.ScaledCapsuleRadius, Player.ScaledCapsuleHalfHeight);

			FHitResult Hit = Trace.QueryTraceSingle(Player.ActorCenterLocation, Player.ActorCenterLocation - (FVector::UpVector * 500.0));
			if (Hit.bBlockingHit)
			{
				if (Hit.Actor == this)
					Player.KillPlayer(FPlayerDeathDamageParams(FVector::UpVector), PlatformAttackDeathEffect);
			}
		}

		UArenaPlatformEffectEventHandler::Trigger_Attacked(this);
	}

	UFUNCTION()
	void DestroyPlatform()
	{
		if (bDestroyed)
			return;

		SetActorEnableCollision(false);

		TArray<AActor> Actors;
		GetAttachedActors(Actors);
		for (AActor Actor : Actors)
		{
			Actor.SetActorHiddenInGame(true);
			Actor.SetActorEnableCollision(false);
		}

		TriggerAttack();

		Timer::SetTimer(this, n"DelayedDestroy", 5.0);

		UArenaPlatformEffectEventHandler::Trigger_Destroyed(this);

		PlatformMesh.SetStaticMesh(DestructionMesh);
		DestructionTimeLike.PlayFromStart();
	}

	UFUNCTION()
	private void UpdateDestruction(float CurValue)
	{
		PlatformMesh.SetScalarParameterValueOnMaterials(n"VAT_DisplayTime", CurValue);
	}

	UFUNCTION()
	private void FinishDestruction()
	{
		PlatformMesh.SetHiddenInGame(true);
	}


	UFUNCTION()
	void DelayedDestroy()
	{
		SetDestroyed();
	}

	void SetDestroyed()
	{
		if (bDestroyed)
			return;

		bDestroyed = true;
		AddActorDisable(this);
		TArray<AActor> Actors;
		GetAttachedActors(Actors);
		for (AActor Actor : Actors)
		{
			Actor.AddActorDisable(this);
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (bIsSpread && bFauxPhysicsAllowed)
		{
			for (AHazePlayerCharacter Player : PlayersOnPlatform)
				PlatformRoot.ApplyForce(Player.ActorLocation, FVector::UpVector * -150.0);
		}
	}
}

class AArenaPlatformFrontRoot : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;
}

class UArenaPlatformEffectEventHandler : UHazeEffectEventHandler
{
	UPROPERTY(BlueprintReadOnly)
	AArenaPlatform Platform;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Platform = Cast<AArenaPlatform>(Owner);
	}

	UFUNCTION(BlueprintEvent)
	void Attacked() {}
	UFUNCTION(BlueprintEvent)
	void Destroyed() {}
}