


class UHoverPerchMovementInputCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(CapabilityTags::StickInput);
	default CapabilityTags.Add(CapabilityTags::MovementInput);

	default BlockExclusionTags.Add(CapabilityTags::MovementInput);

	default DebugCategory = n"Movement";
	
	default TickGroup = EHazeTickGroup::BeforeMovement;
	default TickGroupOrder = MovementInput::CapabilityTickGroupOrder;

	AHoverPerchActor PerchActor;
	UHoverPerchMovementComponent MoveComponent;
	AHazePlayerCharacter Player;
	FStickSnapbackDetector SnapbackDetector;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		PerchActor = Cast<AHoverPerchActor>(Owner);
		MoveComponent = UHoverPerchMovementComponent::Get(PerchActor);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FHoverPerchMovementInputActivatedParams& Params) const
	{
		if(PerchActor.PlayerLocker == nullptr)
			return false;

		Params.Player = PerchActor.PlayerLocker;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(PerchActor.PlayerLocker == nullptr)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FHoverPerchMovementInputActivatedParams Params)
	{
		Player = Params.Player;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		MoveComponent.ClearMovementInput(this);
		SnapbackDetector.ClearSnapbackDetection();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		const FVector Up = MoveComponent.GetWorldUp();
		const FRotator ControlRotation = Player.GetControlRotation();
		FVector Forward = MovementInput::FixupMovementForwardVector(ControlRotation, Up);	
		FVector Right = MovementInput::FixupMovementRightVector(ControlRotation, Up, Forward);

		const FVector2D RawStick = GetAttributeVector2D(AttributeVectorNames::MovementRaw);
		FVector CurrentInput = Forward * RawStick.X + Right * RawStick.Y;
			
		const FVector StickInput(RawStick.X, RawStick.Y, 0);
		FVector MoveDirWithoutSnap = SnapbackDetector.RemoveStickSnapbackJitter(StickInput, CurrentInput);
		MoveComponent.ApplyMovementInput(MoveDirWithoutSnap, this);
	}
}

struct FHoverPerchMovementInputActivatedParams
{
	AHazePlayerCharacter Player;
}