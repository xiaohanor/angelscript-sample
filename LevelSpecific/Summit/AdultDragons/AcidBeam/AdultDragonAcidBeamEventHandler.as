
struct FAdultDragonAcidBeamParams
{
	UPROPERTY()
	FVector BeamStartLocation;
	UPROPERTY()
	FVector BeamEndLocation;
	UPROPERTY()
	bool bBeamHitSomething = false;
};

UCLASS(Abstract)
class UAdultDragonAcidBeamEventHandler : UHazeEffectEventHandler
{

	// UFUNCTION(BlueprintPure)
	// AAdultDragon GetAdultDragon() const
	// {
	// 	auto DragonComp = UPlayerAdultDragonComponent::Get(Owner);
	// 	return DragonComp.AdultDragon;
	// }

	// Started charging the beam, but not actually firing yet
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void BeamChargeStarted() {}
	
	// The beam has started firing from the mouth of the dragon
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void BeamStartedFiring(FAdultDragonAcidBeamParams BeamParams) {}

	// The beam location has updated. Usually called every frame
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void BeamLocationChanged(FAdultDragonAcidBeamParams BeamParams) {}

	// The beam has stopped firing
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void BeamStopped() {}

};