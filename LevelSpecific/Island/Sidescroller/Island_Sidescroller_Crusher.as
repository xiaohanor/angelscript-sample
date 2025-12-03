event void FAIsland_Sidescroller_CrusherSignature();

UCLASS(Abstract)
class AIsland_Sidescroller_Crusher : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	USceneComponent Crusher;

	UPROPERTY(DefaultComponent, Attach = Crusher)
	UBoxComponent DeathCollision;

	UPROPERTY(DefaultComponent)
	USceneComponent Indicator;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent IndicationLocation;

	UPROPERTY(DefaultComponent, Attach = IndicationLocation)
	UBillboardComponent IndicationBillboard;

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 10000.0;

	UPROPERTY(DefaultComponent, Attach = Crusher)
	UCameraShakeForceFeedbackComponent CamShakeFFComp;

	UPROPERTY(EditInstanceOnly)
	float IndicationDelay = 0;

	UPROPERTY(EditInstanceOnly)
	bool bDebug = false;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<UDeathEffect> DeathEffect;

	bool bActive;
	bool bIndicated;
	bool bAttacking = false;
	FVector OriginalLocation;
	FVector AttackLocation;
	FVector TelegraphLocation;
	FHazeAcceleratedVector AccLocation;

	float AttackDuration = 0.4;
	float AttackDistance = 1010;
	float TelegraphDistance = 150;
	float AttackDelay = 2;
	float ActivationTime;

	UPROPERTY()
	FAIsland_Sidescroller_CrusherSignature OnAttackStarted;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		OriginalLocation = Crusher.WorldLocation;
		Indicator.SetVisibility(false, true);

		DeathCollision.OnComponentBeginOverlap.AddUFunction(this, n"DeathCollisionOverlap");

		Initialize();
	}

	UFUNCTION()
	private void DeathCollisionOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor,
	                                   UPrimitiveComponent OtherComp, int OtherBodyIndex, bool bFromSweep,
	                                   const FHitResult&in SweepResult)
	{
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);

		if(Player == nullptr)
			return;

		if(!bAttacking)
			return;

		Player.KillPlayer(DeathEffect = DeathEffect);
	}

	void Initialize()
	{
		AttackLocation = ActorLocation + ActorForwardVector * AttackDistance;
		TelegraphLocation = ActorLocation + ActorForwardVector * TelegraphDistance;
		AccLocation.SnapTo(ActorLocation);
	}

	void Indicate()
	{
		UIslandSidescrollerCrusherEffectHandler::Trigger_OnIndicate(this);
		// Indicator.SetVisibility(true, true);
	}

	void Deindicate()
	{
		UIslandSidescrollerCrusherEffectHandler::Trigger_OnImpact(this);
		// Indicator.SetVisibility(false, true);
	}

	UFUNCTION(BlueprintCallable)
	void Activate()
	{
		bIndicated = false;
		bActive = true;
		ActivationTime = Time::GetGameTimeSeconds();
	}

	void Deactivate()
	{
		bActive = false;
		Deindicate();
		CamShakeFFComp.ActivateCameraShakeAndForceFeedback();
	}
	
	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(!bActive)
			return;

		if(Time::GetGameTimeSince(ActivationTime) < IndicationDelay)
			return;

		if(!bIndicated)
		{
			Indicate();
			bIndicated = true;
		}

		if(Time::GetGameTimeSince(ActivationTime) < IndicationDelay + AttackDelay)
		{
			AccLocation.AccelerateTo(TelegraphLocation, AttackDelay / 2, DeltaSeconds);
			Crusher.WorldLocation = AccLocation.Value;
			return;
		}

		if(bActive && Time::GetGameTimeSince(ActivationTime) < IndicationDelay + AttackDelay + AttackDuration)
		{
			if(!bAttacking)
			{
				bAttacking = true;
				DeathCollision.SetCollisionEnabled(ECollisionEnabled::QueryOnly);
				OnAttackStarted.Broadcast();
				UIslandSidescrollerCrusherEffectHandler::Trigger_OnStartMoving(this);
			}
			AccLocation.ThrustTo(AttackLocation, 12000, DeltaSeconds);
			// AccLocation.AccelerateToWithStop(AttackLocation, AttackDuration, DeltaSeconds, 0.01);
			// AccLocation.AccelerateTo(AttackLocation, AttackDuration, DeltaSeconds);
		}
		else
		{
			Deactivate();
		}
		
		Crusher.WorldLocation = AccLocation.Value;
	}
}

UCLASS(Abstract)
class UIslandSidescrollerCrusherEffectHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnIndicate() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStartMoving() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnImpact() {}
};
