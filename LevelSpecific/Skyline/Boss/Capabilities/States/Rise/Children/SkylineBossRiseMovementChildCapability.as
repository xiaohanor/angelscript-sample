class USkylineBossRiseMovementChildCapability : USkylineBossChildCapability
{
	default CapabilityTags.Add(SkylineBossTags::SkylineBossRise);

	FVector StartLocation;
	FQuat StartRotation;

	FVector TargetLocation;
	FQuat TargetRotation;

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(Boss.GetPhase() == ESkylineBossPhase::First)
			return false;

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
		for (auto LegComponent : Boss.LegComponents)
		{
			LegComponent.Leg.RestoreLeg();
			LegComponent.SetWorldLocationAndRotation(LegComponent.FootTargetComponent.WorldLocation, LegComponent.FootTargetComponent.WorldRotation);
			LegComponent.bIsGrounded = true;
		}
	}
}