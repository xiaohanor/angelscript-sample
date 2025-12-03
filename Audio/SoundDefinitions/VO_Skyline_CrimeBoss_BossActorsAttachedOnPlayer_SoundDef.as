
UCLASS(Abstract)
class UVO_Skyline_CrimeBoss_BossActorsAttachedOnPlayer_SoundDef : UHazeVOSoundDef
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	UFUNCTION(BlueprintEvent)
	void SkylineBossTank_OnDie(){}

	UFUNCTION(BlueprintEvent)
	void SkylineBossTank_OnAssemble(){}

	UFUNCTION(BlueprintEvent)
	void SkylineBossTank_OnStunnedStart(){}

	UFUNCTION(BlueprintEvent)
	void SkylineBossTank_OnStunnedEnd(){}

	UFUNCTION(BlueprintEvent)
	void SkylineBossTank_OnSpinningStart(){}

	UFUNCTION(BlueprintEvent)
	void SkylineBossTank_OnSpinningEnd(){}

	UFUNCTION(BlueprintEvent)
	void SkylineBossTank_AttackShipArrive(){}

	UFUNCTION(BlueprintEvent)
	void SkylineBossTank_AttackShipDestroyed(FSkylineBossTankEventData SkylineBossTankEventData){}

	UFUNCTION(BlueprintEvent)
	void SkylineBossTank_DamagingTank(FSkylineBossTankEventData SkylineBossTankEventData){}

	UFUNCTION(BlueprintEvent)
	void SkylineBoss_ShieldImpact(FHitResult HitResult){}

	UFUNCTION(BlueprintEvent)
	void SkylineBoss_OpenHatch(){}

	UFUNCTION(BlueprintEvent)
	void SkylineBoss_CloseHatch(){}

	UFUNCTION(BlueprintEvent)
	void SkylineBoss_CoreDamaged(FSkylineBossCoreDamagedEventData SkylineBossCoreDamagedEventData){}

	UFUNCTION(BlueprintEvent)
	void SkylineBoss_CoreDestroyed(){}

	UFUNCTION(BlueprintEvent)
	void SkylineBoss_PendingDown(){}

	UFUNCTION(BlueprintEvent)
	void SkylineBoss_BeginFall(){}

	UFUNCTION(BlueprintEvent)
	void SkylineBoss_BeamStart(){}

	UFUNCTION(BlueprintEvent)
	void SkylineBoss_BeamStop(){}

	UFUNCTION(BlueprintEvent)
	void SkylineBoss_FootPlacingStart(FSkylineBossFootEventData SkylineBossFootEventData){}

	UFUNCTION(BlueprintEvent)
	void SkylineBoss_FootLifted(FSkylineBossFootEventData SkylineBossFootEventData){}

	UFUNCTION(BlueprintEvent)
	void SkylineBoss_FootPlaced(FSkylineBossFootEventData SkylineBossFootEventData){}

	UFUNCTION(BlueprintEvent)
	void SkylineBoss_LegDamaged(FSkylineBossLegEventData SkylineBossLegEventData){}

	UFUNCTION(BlueprintEvent)
	void SkylineBoss_LegRestored(FSkylineBossLegEventData SkylineBossLegEventData){}

	UFUNCTION(BlueprintEvent)
	void SkylineBoss_ImpactPoolStart(){}

	UFUNCTION(BlueprintEvent)
	void SkylineBoss_RocketBarrageStartShooting(){}

	UFUNCTION(BlueprintEvent)
	void SkylineBoss_RocketBarrageStopShooting(){}

	UFUNCTION(BlueprintEvent)
	void SkylineBoss_DamagingTripod(FSkylineBossDamageEventData SkylineBossDamageEventData){}

	UFUNCTION(BlueprintEvent)
	void SkylineBoss_TripodPhaseOneStart(){}

	UFUNCTION(BlueprintEvent)
	void SkylineBoss_TripodFirstFall(){}

	UFUNCTION(BlueprintEvent)
	void SkylineBoss_TripodRise(){}

	UFUNCTION(BlueprintEvent)
	void SkylineBoss_TripodSecondFall(){}

	UFUNCTION(BlueprintEvent)
	void SkylineBikeTowerEnemyShip_OnExplode(){}

	UFUNCTION(BlueprintEvent)
	void SkylineBossTank_OnExhaustStart(){}

	UFUNCTION(BlueprintEvent)
	void SkylineBossTank_OnExhaustEnd(){}

	UFUNCTION(BlueprintEvent)
	void SkylineBossTankAutoCannonProjectile_OnFire(FSkylineBossTankAutoCannonProjectileOnFireEventData SkylineBossTankAutoCannonProjectileOnFireEventData){}

	UFUNCTION(BlueprintEvent)
	void SkylineBossTankAutoCannonProjectile_OnImpact(FSkylineBossTankAutoCannonProjectileOnImpactEventData SkylineBossTankAutoCannonProjectileOnImpactEventData){}

	UFUNCTION(BlueprintEvent)
	void BasicAIDamage_OnDeath(){}

	UFUNCTION(BlueprintEvent)
	void BasicAIDamage_OnDamage(){}

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