
UCLASS(Abstract)
class UGameplay_Character_Boss_Coast_WingsuitBoss_Movement_SoundDef : USoundDefBase
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	UFUNCTION(BlueprintEvent)
	void OnShootMachineGunBullet(FWingsuitShootMachineGunBulletEffectParams Params){}

	UFUNCTION(BlueprintEvent)
	void OnMachineGunBulletImpact(FWingsuitMachineGunBulletImpactEffectParams Params){}

	/* END OF AUTO-GENERATED CODE */

	FVector LastVelocity;
	AWingsuitBoss Boss;

	UPROPERTY()
	float SideVelocity = 0;

	UFUNCTION(BlueprintOverride)
	void ParentSetup()
	{
		Boss = Cast<AWingsuitBoss>(HazeOwner);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaSeconds)
	{
		if(Boss == nullptr)
			return;

		if (Boss.TargetCart == nullptr)
			return;

		auto Offset = Boss.TargetCart.ActorLocation - Boss.ActorLocation;
		auto Delta = (Offset - LastVelocity) / DeltaSeconds;
		SideVelocity = Delta.Size();
		LastVelocity = Offset;
	}

}