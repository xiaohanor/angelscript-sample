
class USanctuaryCompanionAviationInputCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(AviationCapabilityTags::Aviation);
	default CapabilityTags.Add(CapabilityTags::StickInput);
	default CapabilityTags.Add(CapabilityTags::MovementInput);

	default TickGroup = EHazeTickGroup::BeforeMovement;
	default TickGroupOrder = MovementInput::CapabilityTickGroupOrder;

	default DebugCategory = AviationCapabilityTags::Aviation;

	USanctuaryCompanionAviationPlayerComponent AviationComp;
	UPlayerMovementComponent MoveComp;
	FStickSnapbackDetector SnapbackDetector;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		AviationComp = USanctuaryCompanionAviationPlayerComponent::Get(Player);
		MoveComp = UPlayerMovementComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!AviationComp.GetIsAviationActive())
			return false;

		if (!HasControl())
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(!AviationComp.GetIsAviationActive())
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Player.BlockCapabilities(CapabilityTags::MovementInput, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.UnblockCapabilities(CapabilityTags::MovementInput, this);
		Owner.ClearMovementInput(this);
		SnapbackDetector.ClearSnapbackDetection();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		const FVector2D RawStick = GetAttributeVector2D(AttributeVectorNames::MovementRaw);
		float InvertValue = 1;
		if (CompanionAviation::bAviationAllowInvertedFlying)
			InvertValue = Player.IsSteeringPitchInverted() ? -1 : 1;
		const FVector StickInput(RawStick.X * InvertValue, RawStick.Y, 0);
		Player.ApplyMovementInput(StickInput, this, EInstigatePriority::High);

		FHazeFrameForceFeedback FF;
		float Strength = StickInput.Size() * 0.5;
		FF.LeftMotor = Strength;
		FF.RightMotor = Strength;
		FF.LeftTrigger = Strength;
		FF.RightTrigger = Strength;

		Player.SetFrameForceFeedback(FF);
	}
}