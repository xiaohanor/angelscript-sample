

class USkylineRappellerMovementCapability : UBasicAIMovementCapability
{	
	default CapabilityTags.Add(n"Rappelling");	

	USkylineRappellerComponent RappellerComp;
	USkylineRappellerRopeCollisionComponent RopeCollision;
	UCableComponent CableComp;
	USimpleMovementData SlidingMovement;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		RappellerComp = USkylineRappellerComponent::GetOrCreate(Owner);
		CableComp = UCableComponent::Get(Owner);
		RopeCollision = USkylineRappellerRopeCollisionComponent::Get(Owner);
		SlidingMovement = Cast<USimpleMovementData>(Movement);
	}

	UBaseMovementData SetupMovementData() override
	{
		return MoveComp.SetupSimpleMovementData();
	} 

	bool PrepareMove() override
	{
		return MoveComp.PrepareMove(SlidingMovement);
	}

	void ComposeMovement(float DeltaTime) override
	{	
		FVector Velocity = MoveComp.Velocity;
		
		if (!RopeCollision.bIsCut)
		{
			// Rope tensile acceleration
			FVector RopeStart = CableComp.WorldLocation;
			FVector RopeEnd;
			if(RappellerComp.AnchorComponent != nullptr) // Rope is attached to something that might move
				RopeEnd = RappellerComp.AnchorComponent.WorldTransform.TransformPosition(RappellerComp.AnchorOffset);
			else // Rope is "attached" to its world spawn position
				RopeEnd = Owner.ActorTransform.TransformPosition(CableComp.EndLocation);

			if (!RopeStart.IsWithinDist(RopeEnd, CableComp.CableLength))
			{
				float Tension = (RopeStart.DistSquared(RopeEnd) / Math::Square(CableComp.CableLength));
				Velocity += (RopeEnd - RopeStart).GetSafeNormal() * Tension * 1200.0 * DeltaTime;
			}
		}

		// Gravity
		Movement.AddGravityAcceleration();

		// Apply friction
		Velocity -= Velocity * MoveSettings.AirFriction * DeltaTime;
		Movement.AddVelocity(Velocity);

		CustomVelocity += DestinationComp.CustomAcceleration * DeltaTime;
		CustomVelocity -= CustomVelocity * MoveSettings.AirFriction * DeltaTime;
		Movement.AddVelocity(CustomVelocity);

		// Turn towards focus or direction of move
		if (DestinationComp.Focus.IsValid())
			MoveComp.RotateTowardsDirection(DestinationComp.Focus.GetFocusLocation() - Owner.FocusLocation, MoveSettings.TurnDuration, DeltaTime, Movement);
		else  
			MoveComp.StopRotating(MoveSettings.StopTurningDamping, DeltaTime, Movement);

		Movement.AddPendingImpulses();
	}
}
