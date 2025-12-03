
UCLASS(Abstract)
class UGameplay_Vehicle_Player_SwarmDrone_Boat_SoundDef : USoundDefBase
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	UFUNCTION(BlueprintEvent)
	void OnWallImpact(FSwarmBoatWallImpactEventParams Params){}

	UFUNCTION(BlueprintEvent)
	void OnMagnetDroneEnter(FSwarmBoatWallImpactEventParams Params){}

	/* END OF AUTO-GENERATED CODE */

	UPlayerSwarmDroneComponent SwarmDroneComp;
	UPlayerSwarmBoatComponent BoatComp;

	UFUNCTION(BlueprintEvent)
	void OnEnterWater(float Speed) {}

	UFUNCTION(BlueprintEvent)
	void OnExitWater() {}

	UFUNCTION(BlueprintEvent)
	void OnImpactWall() {}

	private bool bWasInWater = false;
	private bool bHadWallImpact = false;

	UFUNCTION(BlueprintOverride)
	void ParentSetup()
	{
		SwarmDroneComp = UPlayerSwarmDroneComponent::Get(PlayerOwner);
		BoatComp = UPlayerSwarmBoatComponent::Get(PlayerOwner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(PlayerOwner.IsPlayerDead())
			return false;

		if(!BoatComp.IsBoatActive())
			return false;

		return true;		
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(PlayerOwner.IsPlayerDead())
			return true;

		if(!BoatComp.IsBoatActive())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		bWasInWater = false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaSeconds)
	{
		bool bIsInWater = SwarmDroneComp.IsInsideFloatZone();
		if(!bWasInWater && bIsInWater)
		{
			auto Speed = SwarmDroneComp.MoveComp.PreviousVelocity.Size() / 850;
			OnEnterWater(Speed);
		}
		else if(bWasInWater && !bIsInWater)
			OnExitWater();

		bool bHasImpactedWall = SwarmDroneComp.MovementComponent.HasImpactedWall();
		if(!bHadWallImpact && bHasImpactedWall)
			OnImpactWall();

		bWasInWater = bIsInWater;
		bHadWallImpact = bHasImpactedWall;
	}

	UFUNCTION(BlueprintPure, Meta = (CompactNodeTitle = "Stick Input Value"))
	float GetStickInputValue()
	{
		auto StickInput = SwarmDroneComp.MoveComp.GetSyncedMovementInputForAnimationOnly();
		return StickInput.Size();
	}
}