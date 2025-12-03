struct FMaxSecurityLaserSplineParams
{
	FMaxSecurityLaserSplineParams(FVector InLocation)
	{
		Location = InLocation;
	}

	UPROPERTY()
	FVector Location;
}

struct FMaxSecurityLaserSetupParams
{
	FMaxSecurityLaserSetupParams(AMaxSecurityLaser InLaser)
	{
		Laser = InLaser;
	}

	UPROPERTY()
	AMaxSecurityLaser Laser = nullptr;	
}

class UMaxSecurityLaserEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void SetupLaser(FMaxSecurityLaserSetupParams SetupParams) {};

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnLaserStartMoveOut(FMaxSecurityLaserSetupParams SetupParams) {};

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnLaserStartMoveIn(FMaxSecurityLaserSetupParams SetupParams) {};

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStartOnSpline(FMaxSecurityLaserSplineParams SplineParams) {};

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnReachSplineEnd(FMaxSecurityLaserSplineParams SplineParams) {};
}