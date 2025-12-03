enum EOneArmedBanditWinState
{
	Win,
	Mid,
	Lose
}

UCLASS(Abstract)
class AOneArmedBandit : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UHazeSkeletalMeshComponentBase SkelMesh;

	UPROPERTY(DefaultComponent, Attach = SkelMesh)
	UStaticMeshComponent Wheel1;

	UPROPERTY(DefaultComponent, Attach = SkelMesh)
	UStaticMeshComponent Wheel2;

	UPROPERTY(DefaultComponent, Attach = SkelMesh)
	UStaticMeshComponent Wheel3;

	UPROPERTY(EditDefaultsOnly)
	FHazePlaySlotAnimationParams RollAnim;

	UPROPERTY(EditDefaultsOnly)
	FHazePlaySlotAnimationParams RollAnimPlayer;

	UPROPERTY(EditDefaultsOnly)
	FHazePlaySlotAnimationParams RollAnimPlayerMonkey;

	UPROPERTY(EditDefaultsOnly)
	FHazePlaySlotAnimationParams RollAnimPlayerTreeGuardian;

	UPROPERTY(EditDefaultsOnly, Category = "Settings")
	FHazeTimeLike WheelRotationTimeLike;

	UPROPERTY(DefaultComponent)
	UTundraShapeshiftingInteractionComponent InteractionComp;
	default InteractionComp.bPlayerCanCancelInteraction = false;
	default InteractionComp.bIsImmediateTrigger = true;

	// The big shapes needs to stand further away, hence the seperate interaction comp
	UPROPERTY(DefaultComponent)
	UTundraShapeshiftingInteractionComponent InteractionCompBigShape;
	default InteractionCompBigShape.bPlayerCanCancelInteraction = false;
	default InteractionCompBigShape.bIsImmediateTrigger = true;

	// Delay from the start of the animation until the wheels should start rolling
	UPROPERTY(EditDefaultsOnly)
	float DelayUntilRollingCasino = 1.92;

	UPROPERTY(EditInstanceOnly)
	AInvisiblePoopThrower PoopThrower;

	float WheelStartRotation1 = 25;
	float WheelStartRotation2 = 25;
	float WheelStartRotation3 = 25;

	AHazePlayerCharacter Player;

	bool bHasRolled = false;
	float InteractionStarted;
	EOneArmedBanditWinState RollState;

	default TickGroup = ETickingGroup::TG_PrePhysics;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		InteractionComp.OnInteractionStarted.AddUFunction(this, n"OnInteractionStarted");
		InteractionCompBigShape.OnInteractionStarted.AddUFunction(this, n"OnInteractionStarted");

		WheelRotationTimeLike.BindUpdate(this, n"OnRollUpdate");
		WheelRotationTimeLike.BindFinished(this, n"OnRollFinished");

		SetActorTickEnabled(false);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		const float TimeSinceInteractionStarted = Time::GameTimeSeconds - InteractionStarted;
		if (TimeSinceInteractionStarted > DelayUntilRollingCasino)
		{
			if (!bHasRolled)
				Roll();

			if (Player != nullptr && Player.Mesh.CanRequestLocomotion())
			{
				auto MoveComp = UPlayerMovementComponent::Get(Player);
				if (MoveComp != nullptr)
					MoveComp.SnapToGround(bLerpVerticalOffset = true);

				Player.RequestLocomotion(n"Movement", this);
			}
		}
	}

	UFUNCTION()
	private void OnInteractionStarted(UInteractionComponent InteractionComponent, AHazePlayerCharacter InPlayer)
	{
		if (Player != nullptr)
			return;

		SetActorTickEnabled(true);
		SetActorControlSide(InPlayer);

		Player = InPlayer;
		InteractionStarted = Time::GameTimeSeconds;

		Player.BlockCapabilities(CapabilityTags::Movement, this);
		Player.BlockCapabilities(CapabilityTags::GameplayAction, this);

		auto ShapeshiftingComp = UTundraPlayerShapeshiftingComponent::Get(Player);

		// Don't allow small shapes
		if (ShapeshiftingComp.IsSmallShape())
			Player.TundraSetPlayerShapeshiftingShape(ETundraShapeshiftShape::Player);

		InteractionComp.Disable(this);
		InteractionCompBigShape.Disable(this);

		SkelMesh.PlaySlotAnimation(RollAnim);

		FHazeAnimationDelegate OnBlendingOut = FHazeAnimationDelegate(this, n"OnPlayerAnimationFinished");
		if (ShapeshiftingComp.IsBigShape())
		{
			UHazeSkeletalMeshComponentBase Mesh = ShapeshiftingComp.GetMeshForShapeType(ETundraShapeshiftShape::Big);
			Mesh.PlaySlotAnimation(FHazeAnimationDelegate(),
								   OnBlendingOut,
								   Player.IsMio() ? RollAnimPlayerMonkey : RollAnimPlayerTreeGuardian);
		}
		else
			Player.PlaySlotAnimation(FHazeAnimationDelegate(), OnBlendingOut, RollAnimPlayer);

		auto MoveComp = UPlayerMovementComponent::Get(Player);
		if (MoveComp != nullptr)
			MoveComp.ClearVerticalLerp();
	}

	UFUNCTION()
	private void OnPlayerAnimationFinished()
	{
		Player.UnblockCapabilities(CapabilityTags::Movement, this);
		Player.UnblockCapabilities(CapabilityTags::GameplayAction, this);

		SetActorTickEnabled(false);
	}

	private void Roll()
	{
		UTundra_River_InteractableCasinoEffectHandler::Trigger_OnPlayerStartCasino(this);
		bHasRolled = true;

		if (!HasControl())
			return;
		
		CrumbRoll(EOneArmedBanditWinState(Math::RandRange(0, 2)));
	}

	UFUNCTION(CrumbFunction)
	void CrumbRoll(EOneArmedBanditWinState NewRollState)
	{
		RollState = NewRollState;
		WheelRotationTimeLike.PlayFromStart();
	}

	UFUNCTION()
	private void OnRollUpdate(float CurveValue)
	{
		Wheel1.RelativeRotation = FRotator(
			Math::Lerp(WheelStartRotation1, GetWheelTargetRotation(1), CurveValue),
			0,
			0);

		Wheel2.RelativeRotation = FRotator(
			Math::Lerp(WheelStartRotation2, GetWheelTargetRotation(2), CurveValue),
			0,
			0);

		Wheel3.RelativeRotation = FRotator(
			Math::Lerp(WheelStartRotation3, GetWheelTargetRotation(3), CurveValue),
			0,
			0);
	}

	UFUNCTION()
	private void OnRollFinished()
	{
		InteractionComp.Enable(this);
		InteractionCompBigShape.Enable(this);
		bHasRolled = false;

		if (RollState == EOneArmedBanditWinState::Win)
			UTundra_River_InteractableCasinoEffectHandler::Trigger_OnWinConditionStarted(this);
		else if (RollState == EOneArmedBanditWinState::Mid)
			UTundra_River_InteractableCasinoEffectHandler::Trigger_OnMidConditionStarted(this);
		else
		{
			if(PoopThrower != nullptr)
				PoopThrower.ThrowPoopAtPlayer(Player);
			UTundra_River_InteractableCasinoEffectHandler::Trigger_OnLoseConditionStarted(this);
		}

		// Update start rotations for the next roll
		const float StartRotation = Math::Wrap(GetWheelTargetRotation(), 0, 360);
		WheelStartRotation1 = StartRotation;
		WheelStartRotation2 = StartRotation;
		WheelStartRotation3 = StartRotation;
		Player = nullptr;
	}

	private float GetWheelTargetRotation(int AdditionalSpins = 0) const
	{
		if (RollState == EOneArmedBanditWinState::Win)
		{
			return -190 - (AdditionalSpins * 360);
		}
		else if (RollState == EOneArmedBanditWinState::Mid)
		{
			return -80 - (AdditionalSpins * 360);
		}

		return -335 - (AdditionalSpins * 360);
	}
};
