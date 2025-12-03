class AMeltdownWorldSpinFauxPhysicsActor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
    UFauxPhysicsConeRotateComponent FauxConeRotateComp;
	default FauxConeRotateComp.NetworkMode = EFauxPhysicsConeRotateNetworkMode::SyncedFromZoeControl;

	UPROPERTY(DefaultComponent, Attach = "FauxConeRotateComp")
    UFauxPhysicsWeightComponent FauxWeightComp;
	default FauxWeightComp.RelativeLocation = FVector(0, 0, -500);

	UPROPERTY(DefaultComponent)
    UMeltdownWorldSpinFauxPhysicsResponseComponent ResponseComp;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		FRotator Rotation = GetActorRotation();
		Rotation.Pitch = 0.0;
		Rotation.Roll = 0.0;
		SetActorRotation(Rotation);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		float Distance = Game::Zoe.GetDistanceTo(this);
		if (Distance < 5000.0)
			FauxConeRotateComp.OverrideNetworkSyncRate(EHazeCrumbSyncRate::PlayerSynced);
		else
			FauxConeRotateComp.OverrideNetworkSyncRate(EHazeCrumbSyncRate::Standard);
	}
}