struct FGravityBikeWeaponPickupOnPickedUpEventData
{
	UPROPERTY()
	AHazePlayerCharacter Player;
};

struct FGravityBikeWeaponPickupOnRespawnedEventData
{
	UPROPERTY()
	AHazePlayerCharacter Player;
};

UCLASS(Abstract)
class UGravityBikeWeaponPickupEventHandler : UHazeEffectEventHandler
{
	UPROPERTY(BlueprintReadOnly, NotEditable)
	AGravityBikeWeaponPickup Pickup;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Pickup = Cast<AGravityBikeWeaponPickup>(Owner);
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnPickedUp(FGravityBikeWeaponPickupOnPickedUpEventData EventData) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnRespawned(FGravityBikeWeaponPickupOnRespawnedEventData EventData) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnExpire() {}
};