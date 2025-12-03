UCLASS(Abstract)
class USkylineFireTruckLadderClampEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintOverride)
	void Setup()
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnClampOpen()
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnClampClose()
	{
	}
};

class ASkylineFireTruckLadderClamp : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UBoxComponent BlockCollision;
	default BlockCollision.bGenerateOverlapEvents = false;
	default BlockCollision.CollisionResponseToAllChannels = ECollisionResponse::ECR_Ignore;
	default BlockCollision.SetCollisionResponseToChannel(ECollisionChannel::PlayerCharacter, ECollisionResponse::ECR_Block);

	UPROPERTY(DefaultComponent)
	UBoxComponent BlockCollision2;
	default BlockCollision.bGenerateOverlapEvents = false;
	default BlockCollision.CollisionResponseToAllChannels = ECollisionResponse::ECR_Ignore;
	default BlockCollision.SetCollisionResponseToChannel(ECollisionChannel::PlayerCharacter, ECollisionResponse::ECR_Block);

	UPROPERTY(DefaultComponent)
	UBoxComponent KillCollision;
	default KillCollision.bGenerateOverlapEvents = false;
	default KillCollision.CollisionResponseToAllChannels = ECollisionResponse::ECR_Ignore;
	default KillCollision.SetCollisionResponseToChannel(ECollisionChannel::PlayerCharacter, ECollisionResponse::ECR_Overlap);

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 15000.0;

	UPROPERTY(DefaultComponent, Attach = Root)
	UFauxPhysicsAxisRotateComponent RotateComp;
	default RotateComp.NetworkMode = EFauxPhysicsAxisRotateNetworkMode::SyncedFromZoeControl;

	UPROPERTY(DefaultComponent, Attach = RotateComp)
	UFauxPhysicsForceComponent ForceComp;

	UPROPERTY(DefaultComponent, Attach = RotateComp)
	UFauxPhysicsForceComponent OpenForceComp;

	UPROPERTY(DefaultComponent, Attach = RotateComp)
	UGravityWhipTargetComponent WhipTarget;

	UPROPERTY(DefaultComponent, Attach = WhipTarget)
	UTargetableOutlineComponent OutlineComp;

	UPROPERTY(DefaultComponent)
	UGravityWhipResponseComponent ResponseComp;

	UPROPERTY(DefaultComponent)
	UGravityWhipFauxPhysicsComponent WhipFauxComp;

	UPROPERTY(DefaultComponent)
	USkylineInterfaceComponent InterfaceComp;

	UPROPERTY(EditAnywhere, Category = "ForceFeedback")
	UForceFeedbackEffect ZoeForceFeedback;

	UPROPERTY(DefaultComponent)
	UCameraShakeForceFeedbackComponent CameraShakeForceFeedbackComponent;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Enable();

		ResponseComp.OnGrabbed.AddUFunction(this, n"HandleGrabbed");
		ResponseComp.OnReleased.AddUFunction(this, n"HandleReleased");

		RotateComp.OnMinConstraintHit.AddUFunction(this, n"HandleMinConstraintHit");
		RotateComp.OnMaxConstraintHit.AddUFunction(this, n"HandleClampClosed");

		InterfaceComp.OnActivated.AddUFunction(this, n"HandleActivated");
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
//		PrintToScreen("Rotation: " + RotateComp.CurrentRotation, 0.0, FLinearColor::Green);
	}

	UFUNCTION()
	private void HandleActivated(AActor Caller)
	{
		Disable();
	}

	UFUNCTION()
	private void HandleMinConstraintHit(float Strength)
	{
		KillOverlappingPlayers();
		BlockCollision.RemoveComponentCollisionBlocker(this);
		BlockCollision2.RemoveComponentCollisionBlocker(this);
		CameraShakeForceFeedbackComponent.ActivateCameraShakeAndForceFeedback(Game::Mio);
		Game::Zoe.PlayForceFeedback(ZoeForceFeedback, this, 1.0);
	}

	UFUNCTION()
	private void HandleClampClosed(float Strength)
	{
	
	}

	UFUNCTION()
	private void HandleReleased(UGravityWhipUserComponent UserComponent, UGravityWhipTargetComponent TargetComponent, FVector Impulse)
	{
		ForceComp.RemoveDisabler(UserComponent);

		if (Math::IsNearlyEqual(RotateComp.CurrentRotation, 0.0, KINDA_SMALL_NUMBER))
			HandleMinConstraintHit(0.0);

		USkylineFireTruckLadderClampEventHandler::Trigger_OnClampClose(this);		
	}

	UFUNCTION()
	private void HandleGrabbed(UGravityWhipUserComponent UserComponent, UGravityWhipTargetComponent TargetComponent, TArray<UGravityWhipTargetComponent> OtherComponents)
	{
		ForceComp.AddDisabler(UserComponent);
		BlockCollision.AddComponentCollisionBlocker(this);
		BlockCollision2.AddComponentCollisionBlocker(this);

		USkylineFireTruckLadderClampEventHandler::Trigger_OnClampOpen(this);		
	}

	void KillOverlappingPlayers()
	{
		for (auto Player : Game::Players)
		{	
			if (Player.CapsuleComponent.TraceOverlappingComponent(KillCollision))
				Player.KillPlayer();
		}
	}

	void Enable()
	{
		WhipTarget.Enable(this);
		ForceComp.RemoveDisabler(this);
		OpenForceComp.AddDisabler(this);
	}

	UFUNCTION()
	void Disable()
	{
		WhipTarget.Disable(this);
		ForceComp.AddDisabler(this);
		OpenForceComp.RemoveDisabler(this);
		BlockCollision.AddComponentCollisionBlocker(this);
		BlockCollision2.AddComponentCollisionBlocker(this);
		KillCollision.AddComponentCollisionBlocker(this);

		USkylineFireTruckLadderClampEventHandler::Trigger_OnClampOpen(this);		
	}	
};