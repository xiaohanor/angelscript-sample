UCLASS(Abstract)
class UWindJavelinProjectileEventHandler : UHazeEffectEventHandler
{
    
	AHazePlayerCharacter Player = nullptr;
	AWindJavelin WindJavelin = nullptr;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Player = WindJavelin::GetPlayer();
		WindJavelin = Cast<AWindJavelin>(Owner);
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void Spawned() { }

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void Destroyed() { }

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void Throw(FWindJavelinThrowEventData ThrowData) { }

    UFUNCTION(BlueprintPure)
    AHazePlayerCharacter GetPlayer() const
    {
        return Player;
    }

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void HitValid(FWindJavelinHitEventData HitData) { }

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void HitInvalid(FWindJavelinHitEventData HitData) { }
}

struct FWindJavelinHitEventData
{
	UPROPERTY()
	bool bHitValidSurface;

	UPROPERTY()
	UPrimitiveComponent Component;

	UPROPERTY()
	FVector ImpactNormal;

    UPROPERTY()
	FVector ImpactPoint;
}
