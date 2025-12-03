struct FJetskiFloatingDebrisOnHitWaterEventData
{
	UPROPERTY(BlueprintReadOnly)
	FVector Location;

	UPROPERTY(BlueprintReadOnly)
	float ImpactSpeed;
};

struct FJetskiFloatingDebrisOnSurfacedEventData
{
	UPROPERTY(BlueprintReadOnly)
	FVector Location;
};

UCLASS(Abstract)
class UJetskiFloatingDebrisEventHandler : UHazeEffectEventHandler
{
	UPROPERTY(BlueprintReadOnly)
	AJetskiFloatingDebris FloatingDebris;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		FloatingDebris = Cast<AJetskiFloatingDebris>(Owner);
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStartFalling()
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnHitWater(FJetskiFloatingDebrisOnHitWaterEventData EventData)
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnSurfaced(FJetskiFloatingDebrisOnSurfacedEventData EventData)
	{
	}
};