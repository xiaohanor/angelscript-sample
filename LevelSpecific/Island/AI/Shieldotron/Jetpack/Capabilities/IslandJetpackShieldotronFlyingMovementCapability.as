const FStatID StatAIFlyingMovement(n"StatAIFlyingMovementCapability");
class UIslandJetpackShieldotronFlyingMovementCapability : UBasicAIMovementCapability
{	
	default CapabilityTags.Add(n"FlyingMovement");	

	USimpleMovementData SlidingMovement;
	UIslandJetpackShieldotronComponent JetpackComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		SlidingMovement = Cast<USimpleMovementData>(Movement);
		JetpackComp = UIslandJetpackShieldotronComponent::Get(Owner);		
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const override
	{
		if (!Super::ShouldActivate())
			return false;
		if (JetpackComp.GetCurrentFlyState() != EIslandJetpackShieldotronFlyState::IsAirBorne)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const override
	{
		if (Super::ShouldDeactivate())
			return true;
		if (JetpackComp.GetCurrentFlyState() == EIslandJetpackShieldotronFlyState::IsGrounded)
			return true;

		return false;
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
#if !RELEASE
		FScopeCycleCounter Counter(StatAIFlyingMovement);
#endif
		FVector OwnLoc = Owner.ActorLocation;
		FVector Velocity = MoveComp.Velocity;
		Velocity -= CustomVelocity;
		float Friction = MoveSettings.AirFriction;

		FVector Destination = GetCurrentDestination();

		FVector ToDest = (Destination - OwnLoc);
		float DestDist = ToDest.Size();
		FVector DestDir = (DestDist > 1.0) ? ToDest / DestDist : Owner.ActorForwardVector;
		if (DestinationComp.HasDestination() && (DestDist > 1.0))
		{
			float Acceleration = DestinationComp.Speed;

			// Accelerate right/left to turn towards destination if we're off
			FVector CurDir = Velocity.IsNearlyZero(10.0) ? Owner.ActorForwardVector : Velocity.GetSafeNormal();
			float DestAccFactor = 1.0;
			if (CurDir.DotProduct(DestDir) < 1.0 - SMALL_NUMBER)
			{
				FVector TurnPlaneNormal = CurDir.CrossProduct(DestDir);
				FVector TurnCross = TurnPlaneNormal.CrossProduct(CurDir);
				Velocity += TurnCross * Acceleration * DeltaTime;
				DestAccFactor = 1.0 - TurnCross.Size();
			}

			// Accelerate directly towards destination with remaining acceleration fraction
			Velocity += DestDir * Acceleration * DestAccFactor * DeltaTime;
		}
		else
		{
			// No destination, let friction slow us to a stop 
			DestinationComp.ReportStopping();
		}

		// Apply friction
		Velocity -= Velocity * Friction * DeltaTime;
	
		Movement.AddVelocity(Velocity);

		CustomVelocity += DestinationComp.CustomAcceleration * DeltaTime;
		CustomVelocity -= CustomVelocity * Friction * DeltaTime;
		Movement.AddVelocity(CustomVelocity);

		// Turn towards focus or direction of move
		if (DestinationComp.Focus.IsValid())
			MoveComp.RotateTowardsDirection(DestinationComp.Focus.GetFocusLocation() - Owner.FocusLocation, MoveSettings.TurnDuration, DeltaTime, Movement);
		else if (DestinationComp.HasDestination() && !OwnLoc.IsWithinDist(Destination, PathingSettings.AtDestinationRange))
			MoveComp.RotateTowardsDirection(DestDir, MoveSettings.TurnDuration, DeltaTime, Movement);
		else  
			MoveComp.StopRotating(MoveSettings.StopTurningDamping, DeltaTime, Movement);

		Movement.AddPendingImpulses();

#if EDITOR
		//Owner.bHazeEditorOnlyDebugBool = true;
		if (Owner.bHazeEditorOnlyDebugBool)
		{
			Debug::DrawDebugLine(Destination, OwnLoc, FLinearColor::LucBlue);		
			Debug::DrawDebugLine(OwnLoc, OwnLoc + Velocity, FLinearColor::Green);		

			float Acc = DestinationComp.Speed;
			FVector DebugVel = Velocity; 
			float dt = 0.05;
			FVector PrevLoc = OwnLoc;
			FVector DebugLoc = OwnLoc;
			FVector StringLoc = FVector(BIG_NUMBER);
			for (float t = 0; t < 10.0 && !DebugLoc.IsWithinDist(Destination, 50.0); t += dt)
			{
				// Accelerate right/left to turn towards destination
				FVector CurDir = DebugVel.IsNearlyZero(10.0) ? Owner.ActorForwardVector : DebugVel.GetSafeNormal();
				float DestAccFactor = 1.0;
				FVector TurnCross = FVector::ZeroVector;
				if (CurDir.DotProduct(DestDir) < 1.0 - SMALL_NUMBER)
				{
					FVector TurnPlaneNormal = CurDir.CrossProduct(DestDir);
					TurnCross = TurnPlaneNormal.CrossProduct(CurDir);
					DebugVel += TurnCross * Acc * dt;
					DestAccFactor = 1.0 - TurnCross.Size();
				}

				// Accelerate directly towards destination
				DebugVel += DestDir * Acc * DestAccFactor * dt;

				DebugVel -= DebugVel * Friction * dt;
				DebugLoc += DebugVel * dt;
				Debug::DrawDebugLine(DebugLoc, DebugLoc + TurnCross * 100, FLinearColor::Yellow, 0.f);	
				Debug::DrawDebugLine(PrevLoc, DebugLoc, FLinearColor::Red);	
				if (!StringLoc.IsWithinDist(DebugLoc, 100.0))
				{
					//Debug::DrawDebugString(DebugLoc + FVector(0,0,20), "" + TurnCross.Size());
					StringLoc = DebugLoc;
				}
				PrevLoc = DebugLoc;		
				DestDir = (Destination - DebugLoc).GetSafeNormal();	
			}
		}
#endif
	}
}
