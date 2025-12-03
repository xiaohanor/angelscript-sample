class USkylineSentryBossAlignMovementCapability : UHazeCapability
{
	default CapabilityTags.Add(n"AlignMovement");
	
	default TickGroup = EHazeTickGroup::Gameplay;
	default TickGroupOrder = 100;

	USkylineSentryBossSphericalMovementComponent SphericalMovementComponent;
	USkylineSentryBossAlignmentComponent AlignmentComp;
	AHazeActor Target;


	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		SphericalMovementComponent = USkylineSentryBossSphericalMovementComponent::Get(Owner);
		AlignmentComp = USkylineSentryBossAlignmentComponent::Get(Owner);

		//SphericalMovementComponent.SetOrigin();
		//Owner.ActorTransform = AlignmentComp.GetAlignment(SphericalMovementComponent.Origin.WorldTransform);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(AlignmentComp.bIsMoving)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(AlignmentComp.bIsMoving)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FVector Direction = Owner.ActorForwardVector;

		if (AlignmentComp.bIsHoming)
		{
			Target = Game::Mio;
			FVector ToTarget = Target.ActorLocation - Owner.ActorLocation;
			Direction = ToTarget.VectorPlaneProject(SphericalMovementComponent.UpVector).SafeNormal;
		}

		FVector Acceleration = Direction * AlignmentComp.Speed * AlignmentComp.Drag
							 - AlignmentComp.Velocity * AlignmentComp.Drag;

		AlignmentComp.Velocity += Acceleration * DeltaTime;
		AlignmentComp.Velocity = AlignmentComp.Velocity.SafeNormal.VectorPlaneProject(SphericalMovementComponent.UpVector).SafeNormal * AlignmentComp.Velocity.Size();


		FTransform NewTransform = SphericalMovementComponent.GetTransformFromDelta(AlignmentComp.Velocity * DeltaTime);

		Owner.SetActorTransform(NewTransform);
	}
}