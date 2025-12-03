struct FSoftSplitPerchSplineHit
{
	UPROPERTY()
	FVector HitLocation_Scifi;
	UPROPERTY()
	FVector HitLocation_Fantasy;
}

class USoftSplitPerchSplineReceiverEffectHandler : UHazeEffectEventHandler
{
	// Opened for receiving the perch spline
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void Opened()
	{
	}

	// Closed for receiving the perch spline
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void Closed()
	{
	}

	// Hit by the perch spline projectile with correct timing
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void PerchSplineHitSuccess(FSoftSplitPerchSplineHit Hit)
	{
	}

	// Hit by the perch spline projectile with incorrect timing
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void PerchSplineHitFail(FSoftSplitPerchSplineHit Hit)
	{
	}
}

class USoftSplitPerchSplineTurretEffectHandler : UHazeEffectEventHandler
{
	// The turret files a projectile
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void FireProjectile()
	{
	}
}

class USoftSplitPerchSplineProjectileEffectHandler : UHazeEffectEventHandler
{
	// The projectile is fired
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void Fired()
	{
	}

	// The projectile hits something it succesfully attached to
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void HitSuccess(FSoftSplitPerchSplineHit Hit)
	{
	}

	// The projectile hits something it cannot attached to
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void HitFail(FSoftSplitPerchSplineHit Hit)
	{
	}
}