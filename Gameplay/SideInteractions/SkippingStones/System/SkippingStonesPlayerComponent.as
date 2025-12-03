enum ESkippingStonesState
{
	Pickup,
	Aim,
	Throw,
};

UCLASS(Abstract)
class USkippingStonesPlayerComponent : UActorComponent
{
	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<ASkippingStone> SkippingStoneClass;

	UPROPERTY(EditDefaultsOnly)
	UHazeCameraSettingsDataAsset CameraSettings;

	UPROPERTY(EditDefaultsOnly)
	UForceFeedbackEffect HoldFeedbackStrong;
	
	UPROPERTY(EditDefaultsOnly)
	UForceFeedbackEffect HoldFeedbackWeak;

	UPROPERTY(EditDefaultsOnly)
	UForceFeedbackEffect PickupFeedback;

	UPROPERTY(EditDefaultsOnly)
	UForceFeedbackEffect ThrowFeedback;

	private AHazePlayerCharacter Player;
	ASkippingStones SkippingStonesInteraction;

	ESkippingStonesState State = ESkippingStonesState::Pickup;
	
	// Pickup
	bool bShouldPickUpStone = false;
	ASkippingStone HeldSkippingStone;
	int SpawnedStones = 0;

	// Charging
	bool bIsCharging;
	float ChargeAlpha = 0;

	// Throw
	bool bShouldThrowStone = false;
	FVector ThrowVelocity;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		// if(IsHoldingStone())
		// 	HeldSkippingStone.SetActorRelativeTransform(FTransform(StoneRelativeRotation, StoneRelativeLocation));
	}
	
	void PickupStone()
	{
		if(!ensure(!IsHoldingStone()))
			return;

		if(!ensure(bShouldPickUpStone || !HasControl()))
			return;

		HeldSkippingStone = SpawnActor(SkippingStoneClass, bDeferredSpawn = true);
		HeldSkippingStone.MakeNetworked(this, n"SkippingStone", SpawnedStones);
		SpawnedStones++;
		HeldSkippingStone.SetActorControlSide(Player);
		FinishSpawningActor(HeldSkippingStone);

		HeldSkippingStone.AttachToComponent(Player.Mesh, n"RightAttach", EAttachmentRule::SnapToTarget);
		HeldSkippingStone.SetActorRelativeTransform(FTransform(
			SkippingStones::StoneRelativeRotation,
			SkippingStones::StoneRelativeLocation,
			FVector::OneVector * 0.8
		));

		bShouldPickUpStone = false;

		HeldSkippingStone.OnFinished.AddUFunction(this, n"OnSkippingStoneFinished");
	}

	UFUNCTION()
	private void OnSkippingStoneFinished(ASkippingStone SkippingStone, ESkippingStoneFinishedReason Reason, int Bounces)
	{
		if(Reason == ESkippingStoneFinishedReason::HitPlayer)
		{
			USkippingStonesPlayerEventHandler::Trigger_ThrowHitPlayer(Player);
		}
		else
		{
			if(Bounces > 4)
				USkippingStonesPlayerEventHandler::Trigger_ThrowManyBounces(Player);
			else if (Bounces > 0)
				USkippingStonesPlayerEventHandler::Trigger_ThrowFewBounces(Player);

			if(Reason == ESkippingStoneFinishedReason::Splash)
				USkippingStonesPlayerEventHandler::Trigger_ThrowPladask(Player);
		}
	}

	bool IsHoldingStone() const
	{
		return IsValid(HeldSkippingStone);
	}

	void ThrowStone()
	{
		if(!HasControl())
			return;

		if(!ensure(bShouldThrowStone))
			return;

		CrumbThrowStone(HeldSkippingStone.ActorLocation, ThrowVelocity);
	}

	UFUNCTION(CrumbFunction)
	void CrumbThrowStone(FVector InLocation, FVector InThrowVelocity)
	{
		if(!ensure(IsHoldingStone()))
			return;

		HeldSkippingStone.DetachFromActor(EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld);
		HeldSkippingStone.SetActorLocation(InLocation);
		HeldSkippingStone.Throw(InThrowVelocity, Player);
		HeldSkippingStone = nullptr;

		bShouldThrowStone = false;
	}

	void Reset()
	{
		SkippingStonesInteraction = nullptr;
		State = ESkippingStonesState::Pickup;

		bShouldPickUpStone = false;

		if(IsValid(HeldSkippingStone))
		{
			HeldSkippingStone.DestroyActor();
		}

		HeldSkippingStone = nullptr;

		bIsCharging = false;
		ChargeAlpha = 0;

		bShouldThrowStone = false;
		ThrowVelocity = FVector::ZeroVector;
	}
};