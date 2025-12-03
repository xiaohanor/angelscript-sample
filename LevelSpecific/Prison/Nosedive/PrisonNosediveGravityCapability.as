class UPrisonNosediveGravityCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(n"Example");
	
	default TickGroup = EHazeTickGroup::Gameplay;
	default TickGroupOrder = 100;

	bool bGravityReset = false;
	float WorldUp = -15.0;
	FRotator WorldUpRot = FRotator::ZeroRotator;

	UPrisonNosedivePlayerGravityComponent GravityComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		GravityComp = UPrisonNosedivePlayerGravityComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (bGravityReset)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		WorldUpRot = FRotator(-15.0, 0.0, 0.0);
		Player.OverrideGravityDirection(WorldUpRot.Vector(), this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.ClearGravityDirectionOverride(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (!GravityComp.bResetingGravity)
			return;

		// WorldUp = Math::FInterpConstantTo(WorldUp, 0, DeltaTime, 10.0);
		FVector InverseUp = -FVector::UpVector;
		WorldUpRot = Math::RInterpConstantTo(WorldUpRot, InverseUp.Rotation(), DeltaTime, 30.0);
		// PrintToScreen("" + WorldUpRot);
		Player.OverrideGravityDirection(WorldUpRot.Vector(), this);

		if (Math::IsNearlyEqual(WorldUp, 0.0, 5.5))
			bGravityReset = true;
	}
}

class UPrisonNosedivePlayerGravityComponent : UActorComponent
{
	bool bResetingGravity = false;

	UFUNCTION()
	void ResetGravity()
	{
		bResetingGravity = true;
	}
}