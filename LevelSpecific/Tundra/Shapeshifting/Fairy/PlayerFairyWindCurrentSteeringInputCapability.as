class UTundraPlayerFairyWindCurrentSteeringInputCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(TundraShapeshiftingTags::Fairy);
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(CapabilityTags::StickInput);
	default CapabilityTags.Add(CapabilityTags::MovementInput);

	default BlockExclusionTags.Add(CapabilityTags::MovementInput);
	default BlockExclusionTags.Add(TundraShapeshiftingTags::Fairy);

	default DebugCategory = n"Movement";
	
	default TickGroup = EHazeTickGroup::BeforeMovement;
	default TickGroupOrder = MovementInput::CapabilityTickGroupOrder;

	UPlayerMovementComponent MoveComponent;
	FStickSnapbackDetector SnapbackDetector;
	UTundraPlayerFairyComponent FairyComp;
	UTundraPlayerFairySettings Settings;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MoveComponent = UPlayerMovementComponent::Get(Player);
		FairyComp = UTundraPlayerFairyComponent::Get(Player);
		Settings = UTundraPlayerFairySettings::GetSettings(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!FairyComp.bIsActive)
			return false;

		if(FairyComp.CurrentWindCurrent == nullptr)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(!FairyComp.bIsActive)
			return true;

		if(FairyComp.CurrentWindCurrent == nullptr)
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
		Player.ClearMovementInput(this);
		SnapbackDetector.ClearSnapbackDetection();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		const FRotator ControlRotation = Player.GetControlRotation();
		FVector Forward, Right;

		GetWindCurrentForwardRightVector(ControlRotation, Forward, Right);
	
		FVector2D RawStick = GetAttributeVector2D(AttributeVectorNames::MovementRaw);

		// This math will make the x and y axis more oval, making it easier to make small adjustments,
		// but it will also making the diagonal directions be a bit skewed.
		FVector CurrentInput = 
			(Forward * Math::Pow(RawStick.X, 2.0) * Math::Sign(RawStick.X)) + 
			(Right * Math::Pow(RawStick.Y, 2.0) * Math::Sign(RawStick.Y));
		CurrentInput = CurrentInput.GetSafeNormal() * RawStick.Size();
		
		const FVector StickInput(RawStick.X, RawStick.Y, 0);
		FVector MoveDirWithoutSnap = SnapbackDetector.RemoveStickSnapbackJitter(StickInput, CurrentInput);

		if(Settings.bDebugWindCurrentSteeringInput)
			Debug::DrawDebugLine(Player.ActorLocation, Player.ActorLocation + MoveDirWithoutSnap * 100.0, FLinearColor::Red);

		Player.ApplyMovementInput(MoveDirWithoutSnap, this);
	}

	void GetWindCurrentForwardRightVector(FRotator ControlRotation, FVector&out Forward, FVector&out Right)
	{
		float ClosestDistance = FairyComp.CurrentWindCurrent.Spline.GetClosestSplineDistanceToWorldLocation(Player.ActorCenterLocation);
		FVector SplineNormal = FairyComp.CurrentWindCurrent.Spline.GetWorldRotationAtSplineDistance(ClosestDistance).ForwardVector;

		if(ControlRotation.ForwardVector.DotProduct(SplineNormal) > 0.0)
			SplineNormal = -SplineNormal;

		Forward = ControlRotation.ForwardVector.VectorPlaneProject(SplineNormal).GetSafeNormal();
		FVector AlternateForward = ControlRotation.UpVector.VectorPlaneProject(SplineNormal).GetSafeNormal();
		if(Math::IsNearlyZero(Forward.SizeSquared()) || AlternateForward.DotProduct(Forward) < 0)
			Forward = AlternateForward;

		Right = Forward.CrossProduct(-SplineNormal);
	}
}