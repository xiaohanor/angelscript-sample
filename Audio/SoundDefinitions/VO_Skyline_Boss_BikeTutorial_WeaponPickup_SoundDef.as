
UCLASS(Abstract)
class UVO_Skyline_Boss_BikeTutorial_WeaponPickup_SoundDef : UHazeVOSoundDef
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	UFUNCTION(BlueprintEvent)
	void GravityBikeWeaponPickup_OnPickedUp(FGravityBikeWeaponPickupOnPickedUpEventData GravityBikeWeaponPickupOnPickedUpEventData){}

	UFUNCTION(BlueprintEvent)
	void GravityBikeWeaponPickup_OnRespawned(FGravityBikeWeaponPickupOnRespawnedEventData GravityBikeWeaponPickupOnRespawnedEventData){}

	UFUNCTION(BlueprintEvent)
	void GravityBikeWeaponPickup_OnExpire(){}

	UFUNCTION(BlueprintEvent)
	void GravityBikeFree_OnMount(){}

	UFUNCTION(BlueprintEvent)
	void GravityBikeFree_OnForwardStart(){}

	UFUNCTION(BlueprintEvent)
	void GravityBikeFree_OnForwardEnd(){}

	UFUNCTION(BlueprintEvent)
	void GravityBikeFree_OnDriftStart(){}

	UFUNCTION(BlueprintEvent)
	void GravityBikeFree_OnDriftEnd(){}

	UFUNCTION(BlueprintEvent)
	void GravityBikeFree_OnBoostStart(){}

	UFUNCTION(BlueprintEvent)
	void GravityBikeFree_OnBoostRefill(){}

	UFUNCTION(BlueprintEvent)
	void GravityBikeFree_OnBoostEnd(){}

	UFUNCTION(BlueprintEvent)
	void GravityBikeFree_OnGroundImpact(FGravityBikeFreeOnGroundImpactEventData GravityBikeFreeOnGroundImpactEventData){}

	UFUNCTION(BlueprintEvent)
	void GravityBikeFree_OnLeaveGround(){}

	UFUNCTION(BlueprintEvent)
	void GravityBikeFree_OnWallImpact(FGravityBikeFreeOnWallImpactEventData GravityBikeFreeOnWallImpactEventData){}

	UFUNCTION(BlueprintEvent)
	void GravityBikeFree_OnThrottleStart(){}

	UFUNCTION(BlueprintEvent)
	void GravityBikeFree_OnThrottleEnd(){}

	UFUNCTION(BlueprintEvent)
	void GravityBikeFree_OnJump(FGravityBikeFreeJumpEventData GravityBikeFreeJumpEventData){}

	UFUNCTION(BlueprintEvent)
	void GravityBikeFree_OnWeaponPickupPickedUp(){}

	UFUNCTION(BlueprintEvent)
	void GravityBikeFree_OnWeaponFire(){}

	UFUNCTION(BlueprintEvent)
	void GravityBikeFree_OnWeaponFireNoCharge(){}

	UFUNCTION(BlueprintEvent)
	void GravityBikeFree_OnInitialDamage(FGravityBikeFreeInitialDamageEventData GravityBikeFreeInitialDamageEventData){}

	UFUNCTION(BlueprintEvent)
	void GravityBikeFree_OnUpdateDamage(FGravityBikeFreeUpdateDamageEventData GravityBikeFreeUpdateDamageEventData){}

	UFUNCTION(BlueprintEvent)
	void GravityBikeFree_OnFullyHealed(){}

	UFUNCTION(BlueprintEvent)
	void GravityBikeFree_OnExplode(){}

	UFUNCTION(BlueprintEvent)
	void GravityBikeFree_PlayBikeFrameFF(){}

	/* END OF AUTO-GENERATED CODE */

	UFUNCTION()
	void LinkTo(AHazeActor TargetActor, AHazeActor EventSourceActor)
	{
		EffectEvent::LinkActorToReceiveEffectEventsFrom(TargetActor, EventSourceActor);
	}
}