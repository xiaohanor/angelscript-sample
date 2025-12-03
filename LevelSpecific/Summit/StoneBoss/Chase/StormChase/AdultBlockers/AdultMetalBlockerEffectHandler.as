struct FAdultMetalBlockerOnAcidHitParams
{
	UPROPERTY()
	FVector Location;

	FAdultMetalBlockerOnAcidHitParams(FVector NewLocation)
	{
		Location = NewLocation;
	}
}

UCLASS(Abstract)
class UAdultMetalBlockerEffectHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnAcidHit(FAdultMetalBlockerOnAcidHitParams Params) {}
};