UCLASS(Abstract)
class AFlyingPigPlatform : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent PlatformRoot;

	UPROPERTY(DefaultComponent, Attach = PlatformRoot)
	UPlayerInheritMovementComponent InheritMovementComp;

	UPROPERTY(DefaultComponent)
	UMovementImpactCallbackComponent MovementImpactCallBackComp;

	UPROPERTY(EditInstanceOnly)
	APlayerTrigger BelowBasketTrigger;

	AFlyingPig ParentPig = nullptr;

	float CurrentWeight = 0.0;

	UPROPERTY(EditAnywhere)
	float WeightPerPlayer = 400.0;

	UPROPERTY(EditAnywhere)
	float MaxOffset = -700.0;

	UPROPERTY(EditAnywhere)
	float InterpolationTimeUpwards = 4.0;

	UPROPERTY(EditAnywhere)
	float InterpolationTimeDownwards = 2.0;

	TArray<AHazePlayerCharacter> PlayersOnPlatform;

	float VerticalStart;
	float VerticalTarget;
	float InterpolationProgress;

	int StretchyTimesInBasket = 0;
	int StretchyTimesBelowBasket = 0;
	bool bZoeIsBelowBasket = false;

	bool bBoundStretchy = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		ParentPig = Cast<AFlyingPig>(GetAttachParentActor());
		AttachToComponent(ParentPig.PigRoot, NAME_None, EAttachmentRule::KeepWorld, EAttachmentRule::KeepWorld, EAttachmentRule::KeepWorld, false);

		MovementImpactCallBackComp.OnGroundImpactedByPlayer.AddUFunction(this, n"PlayerLanded");
		MovementImpactCallBackComp.OnGroundImpactedByPlayerEnded.AddUFunction(this, n"PlayerLeft");

		if (BelowBasketTrigger != nullptr)
		{
			BelowBasketTrigger.OnActorBeginOverlap.AddUFunction(this, n"PlayerEnterBelowTrigger");
			BelowBasketTrigger.OnActorEndOverlap.AddUFunction(this, n"PlayerLeaveBelowTrigger");
		}
	}

	UFUNCTION()
	private void PlayerEnter(UPrimitiveComponent OverlappedComponent, AActor OtherActor, UPrimitiveComponent OtherComp, int OtherBodyIndex, bool bFromSweep, const FHitResult&in SweepResult)
	{
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);
		if (Player == nullptr)
			return;
		

		ModifyCurrentWeight(WeightPerPlayer);
	}

	UFUNCTION()
	private void PlayerLeave(UPrimitiveComponent OverlappedComponent, AActor OtherActor, UPrimitiveComponent OtherComp, int OtherBodyIndex)
	{
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);
		if (Player == nullptr)
			return;

		ModifyCurrentWeight(-WeightPerPlayer);
	}

	UFUNCTION()
	private void PlayerLanded(AHazePlayerCharacter Player)
	{
		if (PlayersOnPlatform.Contains(Player))
			return;

		PlayersOnPlatform.Add(Player);

		ModifyCurrentWeight(WeightPerPlayer);
		FIsInBasketEventHandlerParams Params;
		Params.Player = Player;
		UFlyingPigPlatformEventHandler::Trigger_IsInBasket(this, Params);
	}

	UFUNCTION()
	private void PlayerLeft(AHazePlayerCharacter Player)
	{
		if (!PlayersOnPlatform.Contains(Player))
			return;

		PlayersOnPlatform.Remove(Player);

		ModifyCurrentWeight(-WeightPerPlayer);
	}

	private void ModifyCurrentWeight(float Weight)
	{
		CurrentWeight += Weight;
		VerticalStart = ParentPig.VerticalOffset;
		VerticalTarget = -CurrentWeight;
		InterpolationProgress = 0.0;
	}

	private float GetInterpolationTime() const
	{
		if (VerticalTarget > VerticalStart)
			return InterpolationTimeUpwards;
		return InterpolationTimeDownwards;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (!bBoundStretchy) // stretchy legs gets added post begin play
		{
			UPlayerPigStretchyLegsComponent StretchyLegsComponent = UPlayerPigStretchyLegsComponent::Get(Game::GetZoe());
			if (StretchyLegsComponent != nullptr)
			{
				StretchyLegsComponent.OnPigStretched.AddUFunction(this, n"OnPiggyStretched");
				bBoundStretchy = true;
			}
		}

		float InterpolationTime = GetInterpolationTime();
		if (InterpolationTime > 0.0)
			InterpolationProgress = Math::Clamp(InterpolationProgress + (DeltaTime / InterpolationTime), 0.0, 1.0);

		ParentPig.VerticalOffset = Math::Clamp(Math::EaseOut(VerticalStart, VerticalTarget, InterpolationProgress, 2.0), MaxOffset, 0.0);
	}

	UFUNCTION()
	private void PlayerEnterBelowTrigger(AActor OverlappedActor, AActor OtherActor)
	{
		if (OtherActor == Game::Zoe)
		{
			bZoeIsBelowBasket = true;
			StretchyTimesBelowBasket = 0;
		}
	}

	UFUNCTION()
	private void PlayerLeaveBelowTrigger(AActor OverlappedActor, AActor OtherActor)
	{
		if (OtherActor == Game::Zoe)
		{
			bZoeIsBelowBasket = false;
		}
	}

	UFUNCTION()
	private void OnPiggyStretched()
	{
		if (PlayersOnPlatform.Num() == 2)
		{
			FStretchingBasketEventHandlerParams Params;
			++StretchyTimesInBasket;
			Params.StretchyTimes = StretchyTimesInBasket;
			UFlyingPigPlatformEventHandler::Trigger_StretchingWhileBothInBasket(this, Params);
		}
		else if (PlayersOnPlatform.Num() == 0 && bZoeIsBelowBasket)
		{
			FStretchingBasketEventHandlerParams Params;
			++StretchyTimesBelowBasket;
			Params.StretchyTimes = StretchyTimesBelowBasket;
			UFlyingPigPlatformEventHandler::Trigger_StretchBelowBasketMioNotInBasket(this, Params);
		}
	}
}