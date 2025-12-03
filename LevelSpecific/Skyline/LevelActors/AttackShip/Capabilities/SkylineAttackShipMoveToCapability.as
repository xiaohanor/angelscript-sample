class USkylineAttackShipMoveToCapability : UHazeChildCapability
{
	default CapabilityTags.Add(n"SkylineAttackShipMoveTo");
	default CapabilityTags.Add(n"SkylineAttackShipMovement");

	default CompoundNetworkSupport = EHazeCompoundNetworkSupport::ActivatesOnControlOnly;

	ASkylineAttackShip AttackShip;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		AttackShip = Cast<ASkylineAttackShip>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (AttackShip.MoveToTarget.IsDefaultValue())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (AttackShip.MoveToTarget.IsDefaultValue())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		PrintToScreen("OnActivated MoveTo", 0.1, FLinearColor::Green);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FVector ToTarget = AttackShip.MoveToTarget.Get() - AttackShip.ActorLocation;

		float MovementAcceleration = Math::Min(AttackShip.Settings.MovementSpeed * 3.0 * AttackShip.SpeedScale, ToTarget.Size());

		AttackShip.Acceleration += ToTarget.SafeNormal * MovementAcceleration;
	}
}