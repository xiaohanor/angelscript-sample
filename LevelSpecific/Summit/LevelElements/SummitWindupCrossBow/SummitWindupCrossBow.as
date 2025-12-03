event void FOnSummitCrossbowFired(bool bWasZoeOnCrossbow);

UCLASS(Abstract)
class ASummitWindupCrossBow : AHazeActor
{
	UPROPERTY()
	FOnSummitCrossbowFired OnSummitCrossbowFired;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent LeftRoot;
	default LeftRoot.RelativeLocation = FVector(-300, 0, 0);
	
	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent RightRoot;
	default RightRoot.RelativeLocation = FVector(300, 0, 0);

	UPROPERTY(DefaultComponent, Attach = BasketRoot)
	UHazeTEMPCableComponent LeftCable;
	default LeftCable.bVisible = false;

	UPROPERTY(DefaultComponent, Attach = BasketRoot)
	UHazeTEMPCableComponent RightCable;
	default RightCable.bVisible = false;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent BasketRoot;
	default RightRoot.RelativeLocation = FVector(0, -300, 0);

	UPROPERTY(DefaultComponent)
	UInteractionComponent InteractComp;
	default InteractComp.UsableByPlayers = EHazeSelectPlayer::Zoe;
	default InteractComp.InteractionCapability = n"SummitWindupCrossBowWindupCapability";
	default InteractComp.MovementSettings.Type = EMoveToType::NoMovement;
	default InteractComp.ActionShape.BoxExtents = FVector(500, 500, 500);
	default InteractComp.FocusShape.SphereRadius = 900;

	UPROPERTY(DefaultComponent)
	USphereComponent WindupReleaseBoarder;
	default WindupReleaseBoarder.SphereRadius = 1000;
	default WindupReleaseBoarder.RelativeLocation = FVector(-200, 0, 0);
	default WindupReleaseBoarder.bGenerateOverlapEvents = true;
	default WindupReleaseBoarder.SetCollisionProfileName(n"Trigger");

	UPROPERTY(DefaultComponent)
	UHazeCrumbSyncedFloatComponent SyncedWindupAmount;

	UPROPERTY(EditAnywhere)
	AHazeTargetPoint ShootTowardsTarget;

	UPROPERTY(EditAnywhere)
	float ReleaseSpeed = 10000;

	UPROPERTY(EditAnywhere)
	float WindupOffset = 800;

	UPROPERTY(EditAnywhere)
	float WindupTime = 3.0;

	bool bIsZoeOnCrossbow;

	bool bHasBeenReleased = false;
	TPerPlayer<bool> bPlayerIsInActionArea;
	
	private float InternalWindupAmount = 0.0;
	private float DefaultBasketRootX = 0;
		
	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SetActorControlSide(Game::GetZoe());

		DefaultBasketRootX = BasketRoot.RelativeLocation.X;

		LeftCable.SetAttachEndTo(this, n"LeftRoot");
		LeftCable.SetVisibility(true);

		RightCable.SetAttachEndTo(this, n"RightRoot");
		RightCable.SetVisibility(true);

		WindupReleaseBoarder.OnComponentBeginOverlap.AddUFunction(this, n"BeginOverlapActionArea");
		WindupReleaseBoarder.OnComponentEndOverlap.AddUFunction(this, n"EndOverlapActionArea");

		InteractComp.OnInteractionStarted.AddUFunction(this, n"OnInteractionStarted");
		InteractComp.OnInteractionStopped.AddUFunction(this, n"OnInteractionStopped");
	}

	UFUNCTION(NotBlueprintCallable)
    private void BeginOverlapActionArea(
        UPrimitiveComponent OverlappedComponent, AActor OtherActor,
        UPrimitiveComponent OtherComponent, int OtherBodyIndex,
        bool bFromSweep, const FHitResult&in Hit)
    {
		auto Player = Cast<AHazePlayerCharacter>(OtherActor);
		if (Player == nullptr)
			return;
		if (OtherComponent != Player.CapsuleComponent)
			return;

		bPlayerIsInActionArea[Player] = true;
    }

    UFUNCTION(NotBlueprintCallable)
    private void EndOverlapActionArea(
        UPrimitiveComponent OverlappedComponent, AActor OtherActor,
        UPrimitiveComponent OtherComponent, int OtherBodyIndex)
    {
		auto Player = Cast<AHazePlayerCharacter>(OtherActor);
		if (Player == nullptr)
			return;
		if (OtherComponent != Player.CapsuleComponent)
			return;

		bPlayerIsInActionArea[Player] = false;
    }


	UFUNCTION()
	private void OnInteractionStarted(UInteractionComponent InteractionComponent,
	                                  AHazePlayerCharacter Player)
	{
		bIsZoeOnCrossbow = true;
	}

	UFUNCTION()
	private void OnInteractionStopped(UInteractionComponent InteractionComponent,
	                                  AHazePlayerCharacter Player)
	{
		bIsZoeOnCrossbow = false;
	}

	FVector AddWindupAmount(float Amount)
	{
		FVector PreLoc = BasketRoot.WorldLocation;
		InternalWindupAmount = Math::Min(InternalWindupAmount + Amount, 1);
		float Alpha = InternalWindupAmount / 1;
		BasketRoot.RelativeLocation = FVector(Math::Lerp(DefaultBasketRootX, DefaultBasketRootX - WindupOffset, Alpha), BasketRoot.RelativeLocation.Y, BasketRoot.RelativeLocation.Z);
		return BasketRoot.WorldLocation - PreLoc;
	}

	float GetWindupAmount() const
	{
		return InternalWindupAmount;
	}

	void Release()
	{
		bHasBeenReleased = true;
		OnSummitCrossbowFired.Broadcast(bIsZoeOnCrossbow);
	}

	void Restore()
	{
		bHasBeenReleased = false;
		InternalWindupAmount = 0;
		BasketRoot.RelativeLocation = FVector(DefaultBasketRootX, BasketRoot.RelativeLocation.Y, BasketRoot.RelativeLocation.Z);
	}

	FVector GetAimWorldLocation() const
	{
		if(ShootTowardsTarget == nullptr)
		{
			devError(f"{this} is missing 'ShootTowardsTarget' param");
			return FVector::ZeroVector;
		}

		return ShootTowardsTarget.ActorLocation;
	}
};