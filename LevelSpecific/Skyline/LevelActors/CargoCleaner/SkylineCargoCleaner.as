UCLASS(Abstract)
class USkylineCargoCleanerEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintOverride)
	void Setup()
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnPlayerKilled()
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnScannerStart()
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnScannerReverse()
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnFieldActivate()
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnFieldDeactivate()
	{
	}
};

class ASkylineCargoCleaner : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent Mover;

	UPROPERTY(DefaultComponent, Attach = Mover)
	UBoxComponent Collision;
	default Collision.BoxExtent = FVector(300.0, 25.0, 500.0);
	default Collision.SetCollisionEnabled(ECollisionEnabled::QueryOnly);
	default Collision.bGenerateOverlapEvents = true;
	default Collision.SetCollisionResponseToAllChannels(ECollisionResponse::ECR_Ignore);
	default Collision.SetCollisionResponseToChannel(ECollisionChannel::PlayerCharacter, ECollisionResponse::ECR_Overlap);

	UPROPERTY(DefaultComponent)
	USkylineInterfaceComponent InterfaceComp;

	UPROPERTY(DefaultComponent)
	UHazeActionQueueComponent ActionQueue;

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 10000;

	UPROPERTY(EditAnywhere)
	float Distance = 2800.0;

	UPROPERTY()
	TSubclassOf<UDeathEffect> DeathEffect;

	UPROPERTY(EditAnywhere)
	float FieldActivationSpeed = 0.5;

	UPROPERTY(EditAnywhere)
	float ScanSpeed = 3.0;

	UPROPERTY(EditAnywhere)
	float ReturnSpeed = 1.0;

	UPROPERTY(EditAnywhere)
	UMaterialInterface FieldMaterial;
	UPROPERTY(BlueprintReadOnly)
	UMaterialInstanceDynamic MID;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		InterfaceComp.OnActivated.AddUFunction(this, n"HandleActivated");
		InterfaceComp.OnDeactivated.AddUFunction(this, n"HandleDeactivated");

		Collision.OnComponentBeginOverlap.AddUFunction(this, n"HandleOverlap");

		ActionQueue.SetLooping(true);
		ActionQueue.Event(this, n"StartFieldActivate");
		ActionQueue.Duration(FieldActivationSpeed, this, n"UpdateField");
		ActionQueue.Event(this, n"FinishFieldActivate");
		ActionQueue.Event(this, n"StartScanForward");
		ActionQueue.Duration(ScanSpeed, this, n"UpdateScan");
		ActionQueue.Event(this, n"FinishScanForward");
		ActionQueue.Event(this, n"StartFieldDeactivate");
		ActionQueue.ReverseDuration(FieldActivationSpeed, this, n"UpdateField");
		ActionQueue.Event(this, n"FinishFieldDeactivate");
		ActionQueue.Event(this, n"StartScanReverse");
		ActionQueue.ReverseDuration(ReturnSpeed, this, n"UpdateScan");
		ActionQueue.Event(this, n"FinishScanReverse");

		MID = Material::CreateDynamicMaterialInstance(this, FieldMaterial);
	}

	UFUNCTION()
	private void UpdateScan(float Alpha)
	{
		float Position = Curve::SmoothCurveZeroToOne.GetFloatValue(Alpha);
		Mover.SetRelativeLocation(FVector::RightVector * Position * Distance);
	}

	UFUNCTION()
	private void UpdateField(float Alpha)
	{
		float Position = Curve::SmoothCurveZeroToOne.GetFloatValue(Alpha);
		Position = (1.0 - Position) * 6.0 + 0.75;
		MID.SetScalarParameterValue(n"Main Power Exp", Position);
	}

	UFUNCTION()
	private void StartFieldActivate()
	{
		USkylineCargoCleanerEventHandler::Trigger_OnFieldActivate(this);
	}

	UFUNCTION()
	private void FinishFieldActivate()
	{
		Collision.RemoveComponentCollisionBlocker(this);
		BP_OnStart();
	}

	UFUNCTION()
	private void StartScanForward()
	{
		USkylineCargoCleanerEventHandler::Trigger_OnScannerStart(this);
	}

	UFUNCTION()
	private void FinishScanForward()
	{
	}

	UFUNCTION()
	private void StartFieldDeactivate()
	{
		USkylineCargoCleanerEventHandler::Trigger_OnFieldDeactivate(this);
	}

	UFUNCTION()
	private void FinishFieldDeactivate()
	{
		Collision.AddComponentCollisionBlocker(this);
		BP_OnReverse();
	}

	UFUNCTION()
	private void StartScanReverse()
	{
		USkylineCargoCleanerEventHandler::Trigger_OnScannerReverse(this);
	}

	UFUNCTION()
	private void FinishScanReverse()
	{
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		ActionQueue.ScrubTo(Time::GetPlayerCrumbTrailTime(Game::Mio));
	}

	UFUNCTION()
	private void HandleOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor, UPrimitiveComponent OtherComp, int OtherBodyIndex, bool bFromSweep, const FHitResult&in SweepResult)
	{
		auto Player = Cast<AHazePlayerCharacter>(OtherActor);
		if (Player != nullptr)
		{
			FPlayerDeathDamageParams Params;
			Params.ImpactDirection = ActorRightVector;
			//Params.bIsFallingDeath = true;
			Player.KillPlayer(Params, DeathEffect);
			USkylineCargoCleanerEventHandler::Trigger_OnPlayerKilled(this);
		}
	}

	UFUNCTION()
	private void HandleActivated(AActor Caller)
	{
	}

	UFUNCTION()
	private void HandleDeactivated(AActor Caller)
	{
	}

	UFUNCTION(BlueprintEvent)
	void BP_OnStart() { }

	UFUNCTION(BlueprintEvent)
	void BP_OnReverse() { }
};