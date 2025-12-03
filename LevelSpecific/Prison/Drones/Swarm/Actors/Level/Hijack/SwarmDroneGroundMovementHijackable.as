

class ASwarmDroneGroundMovementHijackable : ASwarmDroneHijackable
{
	default CapabilityComponent.InitialStoppedSheets.Add(SwarmDroneMovementHijackSheets::GroundMovement);

	UPROPERTY(DefaultComponent, EditAnywhere)
	UHazeMovementComponent MovementComponent;

	UPROPERTY(DefaultComponent, EditAnywhere)
	UCapsuleComponent CollisionCapsule;
	default CollisionCapsule.SetCapsuleSize(50.0, 120.0);
	default CollisionCapsule.SetCollisionProfileName(n"PlayerCharacter");

	UPROPERTY(EditAnywhere)
	FSwarmDroneGroundMovementHijackSettings MovementSettings;

	// UPROPERTY(EditAnywhere)
	// FHazeShapeSettings CollisionShapeSettings;

	void OnHijackStart(FSwarmDroneHijackParams HijackParams) override
	{
		Super::OnHijackStart(HijackParams);
		StartCapabilitySheet(SwarmDroneMovementHijackSheets::GroundMovement, this);
	}

	void OnHijackStop() override
	{
		Super::OnHijackStop();
		StopCapabilitySheet(SwarmDroneMovementHijackSheets::GroundMovement, this);
	}

}



