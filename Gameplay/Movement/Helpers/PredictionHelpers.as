namespace NetworkPrediction
{
	/**
	 * If we predict the player's crumb trail position forward in time, where do we think the player is after the specified time?
	 */
	void GetPredictedCrumbSyncedLocation(UPlayerMovementComponent MovementComponent, FVector& OutWorldLocation, FVector& OutWorldVelocity, FRotator& OutWorldRotation, float PredictForwardTime = 0.0)
	{
		float CrumbTrailTime;
		FHazeSyncedActorPosition SyncedActorData = MovementComponent.GetLatestAvailableSyncedPosition(CrumbTrailTime);

		float TrailOffset = Time::OtherSideCrumbTrailSendTimePrediction - CrumbTrailTime;

		OutWorldLocation = SyncedActorData.WorldLocation;
		OutWorldVelocity = SyncedActorData.WorldVelocity;
		OutWorldLocation += SyncedActorData.WorldVelocity * (PredictForwardTime + TrailOffset);
		OutWorldRotation = SyncedActorData.WorldRotation;
	}
}