
UCLASS(Abstract)
class UGameplay_Vehicle_Player_WaterSki_SoundDef : USoundDefBase
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	UFUNCTION(BlueprintEvent)
	void OnStartWaterskiing(FCoastWaterskiGeneralParams Params){}

	UFUNCTION(BlueprintEvent)
	void OnStopWaterskiing(FCoastWaterskiGeneralParams Params){}

	UFUNCTION(BlueprintEvent)
	void OnHitWaterSurface(FCoastWaterskiOnHitWaterSurfaceParams Params){}

	UFUNCTION(BlueprintEvent)
	void OnLeaveWaterSurface(FCoastWaterskiGeneralParams Params){}

	UFUNCTION(BlueprintEvent)
	void OnActivateWaterskiRope(){}

	UFUNCTION(BlueprintEvent)
	void OnDeactivateWaterskiRope(){}

	UFUNCTION(BlueprintEvent)
	void OnCollided(FCoastWaterskiOnCollidedParams Params){}

	UFUNCTION(BlueprintEvent)
	void OnJump(){}

	UFUNCTION(BlueprintEvent)
	void OnHitGround(FCoastWaterskiOnHitGroundParams Params){}

	/* END OF AUTO-GENERATED CODE */

	UPROPERTY()
	UCoastWaterskiPlayerComponent WaterskiComponent;

	UPROPERTY()
	UHazeMovementComponent MoveComp;

	UFUNCTION(BlueprintOverride)
	void ParentSetup()
	{
		WaterskiComponent = UCoastWaterskiPlayerComponent::Get(PlayerOwner);
		MoveComp = UHazeMovementComponent::Get(PlayerOwner);
	}

	UFUNCTION(BlueprintPure)
	float GetHorizontalStickInput()
	{
		return MoveComp.GetSyncedMovementInputForAnimationOnly().X;
	}

	UFUNCTION(BlueprintPure)
	bool IsAirborne()
	{
		return WaterskiComponent.IsAirborne();
	}

	// Will return true when player is under water or on the surface
	UFUNCTION(BlueprintPure)
	bool IsInWater() const
	{
		return WaterskiComponent.IsInWater();
	}

	UFUNCTION(BlueprintPure)
	bool IsOnWaterSurface()
	{
		return WaterskiComponent.IsOnWaterSurface();
	}

	UFUNCTION(BlueprintPure)
	bool IsWaterskiing()
	{
		return WaterskiComponent.IsWaterskiing();
	}

	UFUNCTION(BlueprintPure)
	bool IsBuoyancyBlocked()
	{
		return WaterskiComponent.IsBuoyancyBlocked();
	}

	UFUNCTION(BlueprintPure)
	bool IsWaterskiRopeBlocked()
	{
		return WaterskiComponent.IsWaterskiRopeBlocked();
	}

}