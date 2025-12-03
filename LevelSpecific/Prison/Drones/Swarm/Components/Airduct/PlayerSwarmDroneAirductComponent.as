event void FOnSwarmDroneAirductIntakeInRange(USwarmDroneAirductComponent AirductIntakeComponent);
event void FOnSwarmDroneAirductSucked(USwarmDroneAirductComponent AirductIntakeComponent);
event void FOnSwarmDroneAirductExpelled(USwarmDroneAirductComponent AirductIntakeComponent);

class UPlayerSwarmDroneAirductComponent : UActorComponent
{
	UPROPERTY()
	FOnSwarmDroneAirductIntakeInRange OnSwarmDroneAirductIntakeInRangeEvent;

	UPROPERTY()
	FOnSwarmDroneAirductSucked OnSwarmDroneAirductSuckedEvent;

	UPROPERTY()
	FOnSwarmDroneAirductExpelled OnSwarmDroneAirductExpelledEvent;

	UPROPERTY(BlueprintReadOnly)
	USwarmDroneAirductComponent CurrentAirductComponent;

	access AirductCapability = private, USwarmDroneAirductIntakeCapability, USwarmDroneAirductTravelCapability, USwarmDroneAirductExhaustCapability;
	access : AirductCapability
	bool bInAirduct;

	access : AirductCapability
	bool bBeingExpelled;

	access : AirductCapability
	bool bWasJustExpelled;

	UFUNCTION()
	bool InAirduct() const
	{
		return bInAirduct;
	}

	UFUNCTION()
	bool BeingExpelled() const
	{
		return bBeingExpelled;
	}

	bool WasJustExpelled() const
	{
		return bWasJustExpelled;
	}
}