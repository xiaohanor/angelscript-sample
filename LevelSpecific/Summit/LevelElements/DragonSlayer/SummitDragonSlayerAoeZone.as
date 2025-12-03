class ASummitDragonSlayerAoeZone : AHazeActor
{

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent DangerZoneRoot;

	UPROPERTY(DefaultComponent, Attach = DangerZoneRoot)
	UHazeDecalComponent DangerZoneDecal;

	UPROPERTY(DefaultComponent, Attach = DangerZoneRoot)
	UTelegraphDecalComponent TelegraphDecal;

	UPROPERTY(DefaultComponent, Attach = "Root")
	USceneComponent BaseComp;

	UPROPERTY(DefaultComponent, Attach = "Root")
	USceneComponent MovableComp;

	UPROPERTY(DefaultComponent)
	UCapsuleComponent DeathCollision;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent DestinationComp;
	
	UPROPERTY()
	UNiagaraSystem Effect;

	UPROPERTY(EditAnywhere)
	float Damage = 1;

	UPROPERTY()
	TSubclassOf<UDamageEffect> DamageEffect;

	UPROPERTY()
	TSubclassOf<UDeathEffect> DeathEffect;

	UPROPERTY(EditAnywhere)
	float TelegraphDuration = 6;

	UPROPERTY(EditAnywhere)
	float ActiveDuration = 0.00001;

	bool bIsActive = true;
	bool bCanKillPlayer = false;

	FHazeTimeLike MoveAnimation;	
	default MoveAnimation.Duration = 0.34;
	default MoveAnimation.UseLinearCurveZeroToOne();

	FTransform StartingTransform;
	FQuat StartingRotation;
	FVector StartingPosition;
	FTransform EndingTransform;
	FQuat EndingRotation;
	UPROPERTY()
	FVector EndingPosition;

	UPROPERTY()
	FVector SpawnVFXLocation;

	bool bMioOn;
	bool bZoeOn;
	bool bHasBeenActivated;
	bool bIsDisabled;



	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		StartingTransform = MovableComp.GetWorldTransform();
		StartingPosition = StartingTransform.GetLocation();
		StartingRotation = StartingTransform.GetRotation();

		EndingTransform = DestinationComp.GetWorldTransform();
		EndingPosition = EndingTransform.GetLocation();
		EndingRotation = EndingTransform.GetRotation();

		SpawnVFXLocation = Root.GetWorldLocation();

		MoveAnimation.BindUpdate(this, n"OnUpdate");
		MoveAnimation.BindFinished(this, n"OnFinished");

		DeathCollision.OnComponentBeginOverlap.AddUFunction(this, n"OnOverlap");
		DeathCollision.OnComponentEndOverlap.AddUFunction(this, n"OnEndOverlap");
		BaseComp.SetHiddenInGame(true, true);

		TelegraphDecal.SetVisibility(true);
		TelegraphDecal.HideTelegraph();

		// DangerZoneDecal.SetVisibility(true);
	}

	UFUNCTION()
	void ActivateAoeZone()
	{
		if (bIsDisabled)
			return;

		bIsActive = true;
		// DangerZoneDecal.SetVisibility(true);
		TelegraphDecal.ShowTelegraph();
		// Timer::SetTimer(this, n"OnActivatingAoeZone", TelegraphDuration);
		USummitDragonSlayerAoeZoneEventHandler::Trigger_OnStartTelegraph(this);
		OnUpdate(0);
		BP_OnTelegraph();
	}

	
	UFUNCTION()
	void ActivateAttack()
	{
		if (bIsDisabled)
			return;

		MoveAnimation.PlayFromStart();
	}

	UFUNCTION()
	void OnActivatingAoeZone()
	{
		if (bIsDisabled)
			return;

		bCanKillPlayer = true;
		TelegraphDecal.HideTelegraph();
		BP_OnActivate();

		if (bMioOn)
			Game::GetMio().DamagePlayerHealth(Damage, FPlayerDeathDamageParams(), DamageEffect, DeathEffect);

		if (bZoeOn)
			Game::GetZoe().DamagePlayerHealth(Damage, FPlayerDeathDamageParams(), DamageEffect, DeathEffect);

		SmashObstacles();

		Timer::SetTimer(this, n"OnDeactivatingAoeZone", ActiveDuration + MoveAnimation.Duration);

	}

	UFUNCTION()
	void DisableZone()
	{
		bIsDisabled = true;
		bCanKillPlayer = false;
		bIsActive = false;
		BP_OnDeactivate();
	}

	UFUNCTION()
	void OnDeactivatingAoeZone()
	{
		bCanKillPlayer = false;
		bIsActive = false;
		BP_OnDeactivate();
	}

	UFUNCTION()
	private void OnOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor,
	                       UPrimitiveComponent OtherComp, int OtherBodyIndex, bool bFromSweep,
	                       const FHitResult&in SweepResult)
	{	
		if (bIsDisabled)
			return;

		auto Player = Cast<AHazePlayerCharacter>(OtherActor);
		if (Player == nullptr)
			return;

		if (Player == Game::GetMio())
		 bMioOn = true;

		if (Player == Game::GetZoe())
		 bZoeOn = true;

		if(bCanKillPlayer)
		{
			Player.DamagePlayerHealth(Damage, FPlayerDeathDamageParams(), DamageEffect, DeathEffect);
			SmashObstacles();
		}

	}

	UFUNCTION()
	private void OnEndOverlap(
        UPrimitiveComponent OverlappedComponent, AActor OtherActor,
        UPrimitiveComponent OtherComponent, int OtherBodyIndex)
	{	
		if (bIsDisabled)
			return;

		auto Player = Cast<AHazePlayerCharacter>(OtherActor);
		if (Player == nullptr)
			return;

		if (Player == Game::GetMio())
		 bMioOn = false;

		if (Player == Game::GetZoe())
		 bZoeOn = false;
	}

	UFUNCTION()
	void OnUpdate(float Alpha)
	{
		MovableComp.SetWorldLocation(Math::Lerp(StartingPosition, EndingPosition, Alpha));
	}

	UFUNCTION()
	void OnFinished()
	{
		OnActivatingAoeZone();
	}
	
	UFUNCTION(BlueprintEvent)
	void BP_OnActivate() {}

	UFUNCTION(BlueprintEvent)
	void BP_OnDeactivate() {}

	UFUNCTION(BlueprintEvent)
	void BP_OnTelegraph() {}

	void SmashObstacles()
	{
		if (!HasControl())
			return;
		TArray<ASummitKnightAreaDenialZone> Zones = TListedActors<ASummitKnightAreaDenialZone>().Array;
		for (ASummitKnightAreaDenialZone Zone : Zones)
		{
			if (!Zone.HasActiveObstacle())
				continue;
			if (!Zone.ActorLocation.IsWithinDist2D(ActorLocation, DeathCollision.CapsuleRadius + 150.0))
				continue;
			Zone.CrumbSmashObstacle();
		}		
	}
}

UCLASS(Abstract)
class USummitDragonSlayerAoeZoneEventHandler : UHazeEffectEventHandler
{

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStartTelegraph() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStartAttack() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStopAttack() {}

}
