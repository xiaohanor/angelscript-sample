event void FIslandGrindFireAttackSignature();

class AIslandGrindFireAttack : AHazeActor
{

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = "Root")
	USceneComponent BaseComp;

	UPROPERTY(DefaultComponent, Attach = "Root")
	USceneComponent SpawnBaseComp;

	UPROPERTY(DefaultComponent)
	UCapsuleComponent DeathCollision;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent DestinationComp;

	UPROPERTY(DefaultComponent)
	UCapsuleComponent ActivationCollision;

	UPROPERTY(EditInstanceOnly)
	AIslandWalkerHeadPrototype HeadRef;

	UPROPERTY(EditDefaultsOnly)
	UForceFeedbackEffect ForceFeedback;
	
	UPROPERTY()
	UNiagaraSystem Effect;

	UPROPERTY(EditAnywhere)
	float Damage = 0.5;

	bool bIsActive = true;
	bool bCanKillPlayer = false;

	FHazeTimeLike MoveAnimation;	
	default MoveAnimation.Duration = 1;
	default MoveAnimation.UseLinearCurveZeroToOne();

	FHazeTimeLike SpawnAnimation;	
	default SpawnAnimation.Duration = 0.43;
	default SpawnAnimation.UseSmoothCurveZeroToOne();

	FTransform StartingTransform;
	FQuat StartingRotation;
	FVector StartingPosition;
	FTransform EndingTransform;
	FQuat EndingRotation;
	FVector EndingPosition;

	UPROPERTY(EditAnywhere)
	bool bKillDirectly;

	UPROPERTY(EditAnywhere)
	bool bActivateOnOverlap;

	UPROPERTY(EditDefaultsOnly, Category = "DeathEffect")
	TSubclassOf<UDeathEffect> DeathEffect;

	bool bMioOn;
	bool bZoeOn;
	bool bHasBeenActivated;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		StartingTransform = SpawnBaseComp.GetWorldTransform();
		StartingPosition = StartingTransform.GetLocation();
		StartingRotation = StartingTransform.GetRotation();

		EndingTransform = DestinationComp.GetWorldTransform();
		EndingPosition = EndingTransform.GetLocation();
		EndingRotation = EndingTransform.GetRotation();

		MoveAnimation.BindUpdate(this, n"OnUpdate");
		MoveAnimation.BindFinished(this, n"OnFinished");

		SpawnAnimation.BindUpdate(this, n"OnSpawnUpdate");
		SpawnAnimation.BindFinished(this, n"OnSpawnFinished");

		DeathCollision.OnComponentBeginOverlap.AddUFunction(this, n"OnOverlap");
		DeathCollision.OnComponentEndOverlap.AddUFunction(this, n"OnEndOverlap");
		BaseComp.SetHiddenInGame(true, true);

		SpawnBaseComp.SetHiddenInGame(true, true);

		if (bActivateOnOverlap)
			ActivationCollision.OnComponentBeginOverlap.AddUFunction(this, n"OnActivationOverlap");
	}

	UFUNCTION()
	private void OnOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor,
	                       UPrimitiveComponent OtherComp, int OtherBodyIndex, bool bFromSweep,
	                       const FHitResult&in SweepResult)
	{	
		

		auto Player = Cast<AHazePlayerCharacter>(OtherActor);
		if (Player == nullptr)
			return;

		if (Player == Game::GetMio())
		 bMioOn = true;

		if (Player == Game::GetZoe())
		 bZoeOn = true;

		if (!bCanKillPlayer)
			return;

		// Player.DamagePlayerHealth(Damage);
		Player.KillPlayer(FPlayerDeathDamageParams(ActorForwardVector, 1.0), DeathEffect);

		

	}
	UFUNCTION()
	private void OnEndOverlap(
        UPrimitiveComponent OverlappedComponent, AActor OtherActor,
        UPrimitiveComponent OtherComponent, int OtherBodyIndex)
	{	

		auto Player = Cast<AHazePlayerCharacter>(OtherActor);
		if (Player == nullptr)
			return;

		if (Player == Game::GetMio())
		 bMioOn = false;

		if (Player == Game::GetZoe())
		 bZoeOn = false;

	}

	UFUNCTION()
	private void OnActivationOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor,
	                       UPrimitiveComponent OtherComp, int OtherBodyIndex, bool bFromSweep,
	                       const FHitResult&in SweepResult)
	{	

		if (bHasBeenActivated)
			return;

		auto Player = Cast<AHazePlayerCharacter>(OtherActor);
		if (Player == nullptr)
			return;

		ActivateBeam();
		Player.PlayForceFeedback(ForceFeedback, false, false, this);
		BP_AutomaticDeactivation();

	}

	UFUNCTION()
	void ActivateBeam()
	{
		if (bKillDirectly)
			bCanKillPlayer = true;
		
		bHasBeenActivated = true;
		MoveAnimation.PlayFromStart();
		BP_OnTelegraph();
		UIslandGrindFireAttackEffectHandler::Trigger_OnStartTelegraph(this);
		UIslandGrindFireAttackEffectHandler::Trigger_OnStartShooting(this);
	}

	
	UFUNCTION()
	void DeactivateBeam()
	{
		bHasBeenActivated = false;
		bCanKillPlayer = false;
		BaseComp.SetHiddenInGame(true, true);
		BP_OnDeactivate();
		UIslandGrindFireAttackEffectHandler::Trigger_OnStopShooting(this);
	}

	UFUNCTION()
	void OnUpdate(float Alpha)
	{
	}

	UFUNCTION()
	void OnFinished()
	{
		bCanKillPlayer = true;
		BaseComp.SetHiddenInGame(false, true);
		BP_OnActivate();

		if (bMioOn)
		{
			if (Damage >= 1)
				Game::Mio.KillPlayer();
			else
				Game::GetMio().DamagePlayerHealth(Damage);
		}

		if (bZoeOn)
		{
			if (Damage >= 1)
				Game::Zoe.KillPlayer();
			else
				Game::GetZoe().DamagePlayerHealth(Damage);
		}

	}

	UFUNCTION()
	void SpawnShooter()
	{
		if (HeadRef == nullptr)
			return;

		if(SpawnAnimation.Value == 1.0)
			return;

		if (HeadRef != nullptr)
			StartingTransform = HeadRef.Root.GetWorldTransform();
		
		StartingPosition = StartingTransform.GetLocation();
		StartingRotation = StartingTransform.GetRotation();

		SpawnAnimation.PlayFromStart();
		SpawnBaseComp.SetHiddenInGame(false, true);

	}

	UFUNCTION()
	void OnSpawnUpdate(float Alpha)
	{
		SpawnBaseComp.SetRelativeScale3D(Math::Lerp(FVector(0.1,0.1,0.1), FVector(1,1,1), Alpha));
		SpawnBaseComp.SetWorldLocationAndRotation(Math::Lerp(StartingPosition, EndingPosition, Alpha), FQuat::SlerpFullPath(StartingRotation, EndingRotation, Alpha));
	}

	UFUNCTION()
	void OnSpawnFinished()
	{
		if (Effect != nullptr)
			Niagara::SpawnOneShotNiagaraSystemAtLocation(Effect, EndingPosition);
		
	}

	UFUNCTION(BlueprintEvent)
	void BP_OnActivate() {}

	UFUNCTION(BlueprintEvent)
	void BP_OnDeactivate() {}

	UFUNCTION(BlueprintEvent)
	void BP_OnTelegraph() {}

	UFUNCTION(BlueprintEvent)
	void BP_AutomaticDeactivation() {}

}

UCLASS(Abstract)
class UIslandGrindFireAttackEffectHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStartTelegraph() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStartShooting() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStopShooting() {}

}
