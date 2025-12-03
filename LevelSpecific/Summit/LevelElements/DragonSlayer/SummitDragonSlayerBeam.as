class ASummitDragonSlayerBeam : AHazeActor
{

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent DangerZoneRoot;

	UPROPERTY(DefaultComponent, Attach = DangerZoneRoot)
	UHazeDecalComponent DangerZoneDecal;

	UPROPERTY(DefaultComponent, Attach = "Root")
	USceneComponent BaseComp;

	UPROPERTY(DefaultComponent)
	UCapsuleComponent DeathCollision;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent DestinationComp;
	
	UPROPERTY()
	UNiagaraSystem Effect;

	UPROPERTY(EditAnywhere)
	float Damage = 0.5;

	UPROPERTY(EditAnywhere)
	float TelegraphDuration = 3;

	UPROPERTY(EditAnywhere)
	float ActiveDuration = 20;

	bool bIsActive = true;
	bool bCanKillPlayer = false;

	FHazeTimeLike MoveAnimation;	
	default MoveAnimation.Duration = 1;
	default MoveAnimation.UseLinearCurveZeroToOne();

	FTransform StartingTransform;
	FQuat StartingRotation;
	UPROPERTY()
	FVector StartingPosition;
	FTransform EndingTransform;
	FQuat EndingRotation;
	FVector EndingPosition;

	bool bMioOn;
	bool bZoeOn;
	bool bHasBeenActivated;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		StartingTransform = BaseComp.GetWorldTransform();
		StartingPosition = StartingTransform.GetLocation();
		StartingRotation = StartingTransform.GetRotation();

		EndingTransform = DestinationComp.GetWorldTransform();
		EndingPosition = EndingTransform.GetLocation();
		EndingRotation = EndingTransform.GetRotation();

		MoveAnimation.BindUpdate(this, n"OnUpdate");
		MoveAnimation.BindFinished(this, n"OnFinished");

		DeathCollision.OnComponentBeginOverlap.AddUFunction(this, n"OnOverlap");
		DeathCollision.OnComponentEndOverlap.AddUFunction(this, n"OnEndOverlap");
		BaseComp.SetHiddenInGame(true, true);

		DangerZoneDecal.SetVisibility(true);
	}

	UFUNCTION()
	void ActivateAoeZone()
	{
		bIsActive = true;
		DangerZoneDecal.SetVisibility(true);
		Timer::SetTimer(this, n"OnActivatingAoeZone", TelegraphDuration);
		USummitDragonSlayerBeamEventHandler::Trigger_OnStartTelegraph(this);
		BP_OnTelegraph();
	}

	UFUNCTION()
	void OnActivatingAoeZone()
	{

		bCanKillPlayer = true;
		BP_OnActivate();

		if (bMioOn)
			Game::GetMio().DamagePlayerHealth(Damage);

		if (bZoeOn)
			Game::GetZoe().DamagePlayerHealth(Damage);

		Timer::SetTimer(this, n"OnDeactivatingAoeZone", ActiveDuration);

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

		auto Player = Cast<AHazePlayerCharacter>(OtherActor);
		if (Player == nullptr)
			return;

		if (Player == Game::GetMio())
		 bMioOn = true;

		if (Player == Game::GetZoe())
		 bZoeOn = true;

		if(bCanKillPlayer)
			Player.DamagePlayerHealth(Damage);

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
			Game::GetMio().DamagePlayerHealth(Damage);

		if (bZoeOn)
			Game::GetZoe().DamagePlayerHealth(Damage);

	}
	
	UFUNCTION(BlueprintEvent)
	void BP_OnActivate() {}

	UFUNCTION(BlueprintEvent)
	void BP_OnDeactivate() {}

	UFUNCTION(BlueprintEvent)
	void BP_OnTelegraph() {}

}

UCLASS(Abstract)
class USummitDragonSlayerBeamEventHandler : UHazeEffectEventHandler
{

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStartTelegraph() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStartAttack() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStopAttack() {}

}
