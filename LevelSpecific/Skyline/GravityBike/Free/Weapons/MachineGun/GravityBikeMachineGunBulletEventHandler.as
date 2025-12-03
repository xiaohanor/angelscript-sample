struct FGravityBikeMachineGunBulletImpactEventData
{
	UPROPERTY()
	FVector ImpactPoint;

	UPROPERTY()
	FVector ImpactNormal;
}

UCLASS(Abstract)
class UGravityBikeMachineGunBulletEventHandler : UHazeEffectEventHandler
{
	UPROPERTY(BlueprintReadOnly, NotEditable)
	AGravityBikeMachineGunBullet MachineGunBullet;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MachineGunBullet = Cast<AGravityBikeMachineGunBullet>(Owner);
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnImpact(FGravityBikeMachineGunBulletImpactEventData EventData)
	{
	}
};