
UCLASS(Abstract)
class UTeenDragonAirGlideEventHandler : UHazeEffectEventHandler
{
	UPROPERTY(BlueprintReadOnly)
	UHazeCharacterSkeletalMeshComponent Mesh;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		auto DragonComp = UPlayerTeenDragonComponent::Get(Owner);
		check(DragonComp != nullptr);
		Mesh = DragonComp.DragonMesh;
	}

	// When the player does the 'double jump' in the air
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void AirGlideActivated() {}

	// When the player starts gliding
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void StartedGliding() {}

	// When the player stops gliding
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void StoppedGliding() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void InitialUpwardsBoostTriggered() {}	

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void BoostRingStarted() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void BoostRingStopped() {}
};