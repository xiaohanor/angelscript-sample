/**
 * Tries to keep the body centered over the legs.
 */
class USkylineBossDownBodyMovementCapability : USkylineBossChildCapability
{
	default CapabilityTags.Add(SkylineBossTags::SkylineBossBodyMovement);

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
	}

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
	void TickActive(float DeltaTime)
	{
		if(HasControl())
		{
			if(Boss.MovementQueue.IsEmpty())
				return;

			AlignWithHub(Boss.CurrentHub, DeltaTime);
		}
		else
		{
			ApplyCrumbSyncedPosition();
		}
	}
}