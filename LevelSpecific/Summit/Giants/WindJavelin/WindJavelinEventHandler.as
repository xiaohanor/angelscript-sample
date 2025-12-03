UCLASS(Abstract)
class UWindJavelinEventHandler : UHazeEffectEventHandler
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
	void StartAiming() { }

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void StopAiming() { }

    UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void StartCharging() { }

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void Spawned() { }

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void Throw(FWindJavelinThrowEventData ThrowData) { }

    UFUNCTION(BlueprintPure)
    AHazePlayerCharacter GetPlayer() const
    {
        return Player;
    }
}

struct FWindJavelinThrowEventData
{
	UPROPERTY()
	FVector ThrowImpulse;
}