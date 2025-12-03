class UBattlefieldHoverboardSteeringCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(CapabilityTags::StickInput);
	default CapabilityTags.Add(CapabilityTags::MovementInput);
	default CapabilityTags.Add(BattlefieldHoverboardCapabilityTags::Hoverboard);

	default BlockExclusionTags.Add(CapabilityTags::MovementInput);

	default DebugCategory = n"Hoverboard";
	
	default TickGroup = EHazeTickGroup::Input;
	default TickGroupOrder = MovementInput::CapabilityTickGroupOrder;

	UPlayerMovementComponent MoveComponent;
	FStickSnapbackDetector SnapbackDetector;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MoveComponent = UPlayerMovementComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.ClearMovementInput(this);
		SnapbackDetector.ClearSnapbackDetection();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FVector Input;
		if(HasControl())
		{
			FVector2D LeftStickRaw = GetAttributeVector2D(AttributeVectorNames::MovementRaw);
		
			Input.X = LeftStickRaw.X;
			Input.Y = LeftStickRaw.Y;
			
			Player.ApplyMovementInput(Input, this, EInstigatePriority::Normal);
		}
	}
};