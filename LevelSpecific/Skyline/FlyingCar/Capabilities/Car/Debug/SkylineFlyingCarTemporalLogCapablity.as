class USkylineFlyingCarTemporalLogCapability : UHazeCapability
{
	default TickGroup = EHazeTickGroup::AfterPhysics;

	ASkylineFlyingCar FlyingCar;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		FlyingCar = Cast<ASkylineFlyingCar>(Owner);

#if EDITOR
		UMovementInstigatorLogComponent::GetOrCreate(Owner);
#endif

#if !RELEASE
		UHazeMeshPoseDebugComponent MeshPoseDebugComponent = UHazeMeshPoseDebugComponent::GetOrCreate(Owner);
		if (MeshPoseDebugComponent != nullptr)
			MeshPoseDebugComponent.AddSkelMeshComponent(FlyingCar.Mesh);
#endif
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
#if !RELEASE
		FTemporalLog TemporalLog = TEMPORAL_LOG(Owner);

		FTemporalLog PositionSection = TemporalLog.Page("Position");

		PositionSection.Section("World")
			.Transform("Transform", Owner.ActorTransform)
			.Sphere("Sphere",
				FlyingCar.SphereCollision.WorldLocation,
				FlyingCar.SphereCollision.SphereRadius,
				FLinearColor::Blue)
			.Transform("Mesh Transform", FlyingCar.Mesh.WorldTransform);
#endif
	}
}