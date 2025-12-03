event void FControllableDropShipHitEvent();

class UControllableDropShipShotResponseComponent : UActorComponent
{
	UPROPERTY()
	FControllableDropShipHitEvent OnHit;

	void Hit()
	{
		OnHit.Broadcast();
	}
}