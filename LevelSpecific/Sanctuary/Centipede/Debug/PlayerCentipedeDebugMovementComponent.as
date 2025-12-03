#if !RELEASE
class UPlayerCentipedeDebugMovementComponent : UActorComponent
{
	private bool bPrimaryActive = false;
	private bool bSecondaryActive = false;

	FVector PrimaryMovementInput;
	FVector SecondaryMovementInput;

	bool bPrimaryBiteActionStarted;
	bool bPrimaryBiteActioning;

	bool bSecondaryBiteActionStarted;
	bool bSecondaryBiteActioning;

	AHazePlayerCharacter PlayerOwner;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		PlayerOwner = Cast<AHazePlayerCharacter>(Owner);
	}

	void Activate()
	{
		UPlayerCentipedeDebugMovementComponent OtherPlayerDebugComponent = UPlayerCentipedeDebugMovementComponent::Get(PlayerOwner.OtherPlayer);
		OtherPlayerDebugComponent.bPrimaryActive = false;
		OtherPlayerDebugComponent.bSecondaryActive = true;

		bPrimaryActive = true;
		bSecondaryActive = false;
	}

	void Deactivate()
	{
		UPlayerCentipedeDebugMovementComponent OtherPlayerDebugComponent = UPlayerCentipedeDebugMovementComponent::Get(PlayerOwner.OtherPlayer);
		OtherPlayerDebugComponent.bSecondaryActive = false;

		bPrimaryActive = false;
	}

	bool IsPrimary() const
	{
		return bPrimaryActive;
	}

	bool IsSecondary() const
	{
		return bSecondaryActive;
	}

	bool IsActive()
	{
		return bPrimaryActive || bSecondaryActive;
	}

	FVector GetMovementInput()
	{
		if (IsPrimary())
			return PrimaryMovementInput;

		return UPlayerCentipedeDebugMovementComponent::Get(PlayerOwner.OtherPlayer).SecondaryMovementInput;
	}

	bool GetBitingStarted()
	{
		if (IsPrimary())
			return bPrimaryBiteActionStarted;

		return UPlayerCentipedeDebugMovementComponent::Get(PlayerOwner.OtherPlayer).bSecondaryBiteActionStarted;
	}

	bool GetIsBiting()
	{
		if (IsPrimary())
			return bPrimaryBiteActioning;

		return UPlayerCentipedeDebugMovementComponent::Get(PlayerOwner.OtherPlayer).bSecondaryBiteActioning;
	}
}
#endif