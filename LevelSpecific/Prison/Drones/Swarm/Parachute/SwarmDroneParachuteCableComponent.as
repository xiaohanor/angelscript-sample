class USwarmDroneParachuteCableComponent : UHazeTEMPCableComponent
{
	default CableWidth = 3.0;
	default NumSegments = 8;

	default bEnableCollision = false;
	default bEnableStiffness = true;
	default bSkipCableUpdateWhenNotOwnerRecentlyRendered = true;

	default SolverIterations = 5;

	//default bUseSubstepping = true;
	default SubstepTime = 0.005;

	// Start disabled
	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SetHiddenInGame(true);
		SetComponentTickEnabled(false);

		StartLocation = FVector::ZeroVector;
	}
}