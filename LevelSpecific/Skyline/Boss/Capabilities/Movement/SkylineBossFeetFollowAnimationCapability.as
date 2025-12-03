/**
 * Lerp the feet towards the animation
 */
class USkylineBossFeetFollowAnimationCapability : USkylineBossChildCapability
{
	default CapabilityTags.Add(SkylineBossTags::SkylineBossFootGrounded);

	TArray<USkylineBossLegComponent> LegComponents;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		
		Boss.GetComponentsByClass(LegComponents);
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
		for (USkylineBossLegComponent LegComponent : LegComponents)
		{
			LegComponent.Leg.FootSyncedPositionComp.TransitionSync(this);
		}
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		for (USkylineBossLegComponent LegComponent : LegComponents)
		{
			FVector FootPivotLocation;
			FRotator FootPivotRotation;
			LegComponent.Leg.GetFootLocationAndRotation(FootPivotLocation, FootPivotRotation);

			LegComponent.Leg.SetFootAnimationTargetLocationAndRotation(
				FootPivotLocation,
				FootPivotRotation
			);

			FSkylineBossFootSyncedPosition SyncedPosition;
			SyncedPosition.Location = FootPivotLocation;
			SyncedPosition.Rotation = FootPivotRotation;
			LegComponent.Leg.FootSyncedPositionComp.SetCrumbValueStruct(SyncedPosition);
		}
	}

#if EDITOR
	FTemporalLog GetTemporalLog() const
	{
		return TEMPORAL_LOG(Boss, "Feet Follow Animation");
	}
#endif
}