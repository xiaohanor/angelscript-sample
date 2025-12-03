class USummitRecoveryBehaviour : UBasicBehaviour
{
	float RecoveryTime;

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Super::ShouldActivate())
			return false;

		if (!TargetComp.HasValidTarget())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Super::ShouldDeactivate())
			return true;
		if (ActiveDuration > BasicSettings.AttackCooldown)
			return true;
		
		return false;
	}
	
	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		// PrintToScreen("MAGE RECOVERY");
		// Debug::DrawDebugSphere(Owner.ActorCenterLocation, 200.0, LineColor = FLinearColor::Green);
	}
}