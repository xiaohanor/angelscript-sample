/**
 * Handles syncing the feet transforms
 */
class USkylineBossFeetSyncCapability : USkylineBossChildCapability
{
	default CompoundNetworkSupport = EHazeCompoundNetworkSupport::OnlyCrumbNetwork;
	
	USkylineBossFootMovementComponent MoveComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		MoveComp = USkylineBossFootMovementComponent::Get(Boss);
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
	void TickActive(float DeltaTime)
	{
		if(HasControl())
			TickControl(DeltaTime);
		else
			TickRemote(DeltaTime);
	}

	void TickControl(float DeltaTime)
	{
		for(auto LegComp : Boss.LegComponents)
		{
			FSkylineBossFootSyncedPosition SyncedPosition;

			LegComp.Leg.GetFootAnimationTargetTransform(
				SyncedPosition.Location,
				SyncedPosition.Rotation
			);

			LegComp.Leg.FootSyncedPositionComp.SetCrumbValueStruct(SyncedPosition);

			//Debug::DrawDebugCoordinateSystem(SyncedPosition.Location, SyncedPosition.Rotation, 5000, 100);
		}
	}

	void TickRemote(float DeltaTime)
	{
		for(auto LegComp : Boss.LegComponents)
		{
			FSkylineBossFootSyncedPosition SyncedPosition;
			LegComp.Leg.FootSyncedPositionComp.GetCrumbValueStruct(SyncedPosition);

			LegComp.Leg.SetFootAnimationTargetLocationAndRotation(
				SyncedPosition.Location,
				SyncedPosition.Rotation
			);

			//Debug::DrawDebugCoordinateSystem(SyncedPosition.Location, SyncedPosition.Rotation, 5000, 100);
		}
	}
}