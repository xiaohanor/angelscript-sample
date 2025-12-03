class UIslandFallingPlatformsPlayerMovePlatformCapability : UInteractionCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::Gameplay;

	AIslandFallingPlatformsManager Manager;
	UPlayerMovementComponent MoveComp;

	const float InputCooldown = 0.3;

	bool bLastHeldInput = false;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		Manager = TListedActors<AIslandFallingPlatformsManager>().Single;
		MoveComp = UPlayerMovementComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FInteractionCapabilityParams Params)
	{
		Super::OnActivated(Params);
		Manager.InteractingPlayer = Player;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		Manager.InteractingPlayer = nullptr;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(!HasControl())
			return;

		HandleMovementInput();
		HandleRotateInput();
		HandleSpeedUpInput();

		FVector Input = MoveComp.MovementInput;
		bool bCurrentlyInputting = Input.Size() > 0.3;
		bLastHeldInput = bCurrentlyInputting;
	}

	void HandleMovementInput()
	{
		FVector Input = MoveComp.MovementInput;
		bool bCurrentlyInputting = Input.Size() > 0.3;

		if(!bCurrentlyInputting)
			return;

		if(bLastHeldInput)
			return;

		float RightInput = Input.DotProduct(Manager.ActorRightVector);
		float ForwardInput = Input.DotProduct(Manager.ActorForwardVector);

		FVector2D Direction;
		if(Math::Abs(ForwardInput) > Math::Abs(RightInput))
		{
			Direction = FVector2D(Math::Sign(ForwardInput), 0.0);
		}
		else
		{
			Direction = FVector2D(0.0, Math::Sign(RightInput));
		}

		Manager.TryMove(Direction);
	}

	void HandleRotateInput()
	{
		bool bClockwiseAction = WasActionStarted(ActionNames::PrimaryLevelAbility);
		bool bCounterClockwiseAction = WasActionStarted(ActionNames::SecondaryLevelAbility);

		if(bClockwiseAction == bCounterClockwiseAction)
			return;

		Manager.TryRotate(bClockwiseAction);
	}

	void HandleSpeedUpInput()
	{
		Manager.CurrentPlatform.bShouldSpeedUp = IsActioning(ActionNames::MovementJump);
	}
}