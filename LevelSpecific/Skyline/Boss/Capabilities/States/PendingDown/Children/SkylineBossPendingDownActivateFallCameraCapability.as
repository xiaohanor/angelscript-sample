struct FSkylineBossPendingDownActivateFallCameraActivateParams
{
	ASkylineBossSplineHub FallDownHub;
};

class USkylineBossPendingDownActivateFallCameraCapability : USkylineBossChildCapability
{
	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FSkylineBossPendingDownActivateFallCameraActivateParams& Params) const
	{
		if(Boss.MovementQueue.Num() == 0)
			return false;

		if(Boss.MovementQueue[0].ToHub.ActorLocation.DistXY(Boss.ActorLocation) > SkylineBoss::Fall::ActivateCameraDistanceThreshold)
			return false;

		Params.FallDownHub = Boss.GetNextHub();
		
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FSkylineBossPendingDownActivateFallCameraActivateParams Params)
	{
		Boss.OnBeginFall.Broadcast(Params.FallDownHub);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
	}
};