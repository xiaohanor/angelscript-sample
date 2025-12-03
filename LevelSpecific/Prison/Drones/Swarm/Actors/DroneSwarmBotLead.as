class ADroneSwarmBotLead : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UHazeMovementComponent MovementComponent;

	UPROPERTY(DefaultComponent)
	USphereComponent CollisionShape;
	default CollisionShape.SetCollisionProfileName(n"PlayerCharacter");
	default CollisionShape.SetSphereRadius(15.0);

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent Mesh;
	default Mesh.SetCollisionProfileName(n"NoCollision");

	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComponent;
	default CapabilityComponent.DefaultSheets.Add(SwarmDroneBot::LeadBotSheet);


	float Id;

	FVector IdealRelativeLocation;
	const float IdealDistance = 100.0;


	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		MovementComponent.SetupShapeComponent(CollisionShape);

		IdealRelativeLocation = AttachParentActor.ActorForwardVector.RotateAngleAxis((360.0 / SwarmDrone::SwarmBotLeadCount) * Id, FVector::UpVector) * IdealDistance;
		SetActorLocation(GetWorldIdealLocation());
	}

	FVector GetWorldIdealLocation()
	{
		FVector WorldLocation = AttachParentActor.ActorTransform.TransformPosition(IdealRelativeLocation);
		return WorldLocation;
	}
}

namespace SwarmDroneBot
{
	asset LeadBotSheet of UHazeCapabilitySheet
	{
		AddCapability(n"DroneSwarmBotLeadMovementCapability");
	};
}