event void FHungryDoorOpenEvent();

UCLASS(Abstract)
class AHungryDoor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent DoorRoot;

	UPROPERTY(DefaultComponent, Attach = DoorRoot)
	UHazeSkeletalMeshComponentBase SkelMeshComp;

	UPROPERTY(DefaultComponent, Attach = DoorRoot)
	USceneComponent LeftDoorRoot;

	UPROPERTY(DefaultComponent, Attach = DoorRoot)
	USceneComponent RightDoorRoot;

	UPROPERTY(DefaultComponent, Attach = DoorRoot)
	USceneComponent AppleTargetComp;

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedComponent;

	UPROPERTY()
	FHungryDoorOpenEvent OnDoorOpened;

	UPROPERTY()
	FHungryDoorOpenEvent OnTwoApplesPlaced;

	UPROPERTY(EditInstanceOnly)
	ADoubleInteractionActor DoubleInteractionActor;

	bool bBothPlaced = false;

	bool bDoorOpened = false;

	UPROPERTY(NotVisible)
	AGoldenApple LeftApple;
	UPROPERTY(NotVisible)
	AGoldenApple RightApple;

	UPROPERTY(EditAnywhere)
	bool bRequireTwoApples = true;

	bool bDoubleInteractionCompleted = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		if (DoubleInteractionActor != nullptr)
		{
			DoubleInteractionActor.LeftInteraction.AddInteractionCondition(this, FInteractionCondition(this, n"CanPlayerInteract"));
			DoubleInteractionActor.RightInteraction.AddInteractionCondition(this, FInteractionCondition(this, n"CanPlayerInteract"));

			DoubleInteractionActor.OnDoubleInteractionCompleted.AddUFunction(this, n"DoubleInteractionCompleted");
			DoubleInteractionActor.DisableDoubleInteractionForPlayer(Game::Mio, this);
			DoubleInteractionActor.DisableDoubleInteractionForPlayer(Game::Zoe, this);
		}
	}

	void EnableInteractionForPlayer(AHazePlayerCharacter Player)
	{
		if (DoubleInteractionActor != nullptr)
			DoubleInteractionActor.EnableDoubleInteractionForPlayer(Player, this);
	}

	void DisableInteractionForPlayer(AHazePlayerCharacter Player)
	{
		if (DoubleInteractionActor != nullptr)
			DoubleInteractionActor.DisableDoubleInteractionForPlayer(Player, this);
	}

	UFUNCTION()
	private void DoubleInteractionCompleted()
	{
		if (bDoubleInteractionCompleted)
			return;

		bDoubleInteractionCompleted = true;
		DoubleInteractionActor.DisableDoubleInteraction(Game::Mio);

		if (bRequireTwoApples)
		{
			OpenDoor();
			EatApples();
		}
		else
		{
			OnTwoApplesPlaced.Broadcast();

			UGoldenApplePlayerComponent MioComp = UGoldenApplePlayerComponent::Get(Game::Mio);
			MioComp.CurrentApple = nullptr;

			UGoldenApplePlayerComponent ZoeComp = UGoldenApplePlayerComponent::Get(Game::Zoe);
			ZoeComp.CurrentApple = nullptr;
		}
	}

	void EatApples()
	{
		UGoldenApplePlayerComponent MioComp = UGoldenApplePlayerComponent::Get(Game::Mio);
		LeftApple = MioComp.CurrentApple;
		MioComp.CurrentApple = nullptr;

		UGoldenApplePlayerComponent ZoeComp = UGoldenApplePlayerComponent::Get(Game::Zoe);
		RightApple = ZoeComp.CurrentApple;
		ZoeComp.CurrentApple = nullptr;

		BP_EatApples();
	}

	UFUNCTION(BlueprintEvent)
	void BP_EatApples() {}

	UFUNCTION()
	void OpenDoor()
	{
		if (bDoorOpened)
			return;

		FHazeStopSlotAnimationParams StopAnimParams;
		SkelMeshComp.StopSlotAnimation(StopAnimParams);
		
		bDoorOpened = true;
		BP_OpenDoor();

		OnDoorOpened.Broadcast();

		UHungryDoorEffectEventHandler::Trigger_ReceiveApples(this);
	}

	UFUNCTION(BlueprintEvent)
	void BP_OpenDoor() {}

	UFUNCTION()
	void SnapOpenDoor()
	{
		if (bDoorOpened)
			return;

		DoubleInteractionActor.DisableDoubleInteraction(Game::Mio);

		bDoorOpened = true;
		LeftDoorRoot.SetRelativeRotation(FRotator(0.0, -120.0, 0.0));
		RightDoorRoot.SetRelativeRotation(FRotator(0.0, 120.0, 0.0));
	}

	UFUNCTION(NotBlueprintCallable)
	private EInteractionConditionResult CanPlayerInteract(const UInteractionComponent InteractionComponent, AHazePlayerCharacter Player)
	{
		// Don't allow interaction if player is screwing around
		if (Player.IsAnyCapabilityActive(PigTags::SpecialAbility))
			return EInteractionConditionResult::DisabledVisible;

		// Player needs to be grounded
		if (!Player.IsOnWalkableGround())
			return EInteractionConditionResult::DisabledVisible;

		return EInteractionConditionResult::Enabled;
	}

	UFUNCTION(BlueprintPure)
	bool IsDoorOpened()
	{
		return bDoorOpened;
	}
}