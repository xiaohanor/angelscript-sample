
UCLASS(Abstract)
class UGameplay_Vehicle_NPC_OilRigDropShip_SoundDef : USoundDefBase
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	/* END OF AUTO-GENERATED CODE */

	AOilRigDropShip DropShip;

	UFUNCTION(BlueprintOverride)
	void ParentSetup()
	{
		DropShip = Cast<AOilRigDropShip>(HazeOwner);	
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		return DropShip.bFollowingSpline && !DropShip.IsHidden();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return DropShip.IsHidden();
	}
}