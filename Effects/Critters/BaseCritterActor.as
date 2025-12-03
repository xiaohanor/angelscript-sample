
/**
 * Common actor for Sphere constrained Frogs and Rats. Since they have to sync up.
 */

 UCLASS(Abstract)
 class ABaseCritterActor : AHazeActor
 {
	// our critter actor will start mirroring this critter actor if this variable is set
	UPROPERTY(EditAnywhere)
	ABaseCritterActor LinkedCritter;

	// we'll refer to this in situations when code can't determine who should be in control.
	UPROPERTY(EditAnywhere, Meta = (EditConditionHides = "CritterLeader != nullptr"))
	bool bLinkedCritterLeader = false;

	// random range for the mesh size
	UPROPERTY(EditAnywhere, meta = (ClampMin = 0.0001))
	FFloatInterval RandomMeshSizeScaler;
	default RandomMeshSizeScaler.Min = 0.8;
	default RandomMeshSizeScaler.Max = 1.2;

	/**
	  	Use this to control the random RandomMeshSizeScaler distrubtion. 

		Bias = 1 will give you no bias towards MAX nor MIN.

		Bias = 0.001 ... 0.999 gives a bias towards MAX. The lower the number the more likely it'll be closer to MAX. 

		Bias = 1.001 .... 16 gives a bias towards MIN. 
	 */
	UPROPERTY(EditAnywhere, meta = (ClampMin = 0.0))
	float RandomMeshSizeRangeBias = 1.0;

	TArray<UBaseCritterComponent> Critters;

	// center of mass for all rats
	FVector COM = FVector::ZeroVector;

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		ApplyLinkedCritterScaleDeferred();
		UpdateCenterOfMass();
	}

	bool bApplyLinkedCritterScale = false;

	void ApplyLinkedCritterScaleDeferred()
	{
		if(bApplyLinkedCritterScale == false)
			return;

		// make sure that all the critters have spawned
		if(Critters.Num() != LinkedCritter.Critters.Num())
			return;

		for(int i = 0; i < Critters.Num(); ++i)
			Critters[i].RelativeScale3D *= LinkedCritter.Critters[i].AssignedRandomSizeScaler;

		// done
		bApplyLinkedCritterScale = false;
	}

 #if EDITOR
	UFUNCTION(BlueprintOverride)
	void OnActorModifiedInEditor()
	{
		if(LinkedCritter == nullptr)
			return;

		if(LinkedCritter.LinkedCritter == this)
			return;

		LinkedCritter.LinkedCritter = this;
		LinkedCritter.MarkPackageDirty();
	}
#endif

	void UpdateCenterOfMass()
	{
		COM = FVector::ZeroVector;
		for(const auto Rat : Critters)
			COM += Rat.GetWorldLocation();
		COM /= Critters.Num();
	}

	int GetNumCrittersToSpawn()
	{
		return 0;
	}

	float CalculateJumpCurveAverage(FRuntimeFloatCurve InCurve) const
	{
		auto NumKeys = InCurve.GetNumKeys();

		if(NumKeys < 2)
		{
			// not enough points
			return 0.0;
		}

		float Timestep = 0.01;

		float CurrentTime = 0.0;
		float NumSamples = 0;
		float Integral = 0.0;

		while(CurrentTime < 1.0)
		{
			Integral += InCurve.GetFloatValue(CurrentTime);
			NumSamples += 1.0;
			CurrentTime += Timestep;
		}

		return (Integral/NumSamples);
	}

 }


 class UBaseCritterComponent : UStaticMeshComponent
 {
	int CritterIndex = 0;
	ABaseCritterActor CritterOwner;

	TPerPlayer<FPlayerProximity> Proximity;
	FPlayerProximity PreviousClosestProximity;
	FPlayerProximity ClosestProximity;

	TArray<USphereComponent>NoGoZones;

	// change when on the curve the loop is triggered and we calculate a new jump direction
	UPROPERTY(EditAnywhere, meta = (UIMin = 0.0, UIMax = 1.0, ClampMin = 0.0, ClampMax = 1.0))
	float LoopAlphaMarker = 0.75;

	// once a new direction has been set we'll blend to it with this time
	UPROPERTY(EditAnywhere, meta = (UIMin = 0.0, UIMax = 1.0, ClampMin = 0.0, ClampMax = 1.0))
	float RotationBlendTime = 0.2;

	UPROPERTY(EditAnywhere)
	float MovementScalerUp = 5;

	UPROPERTY(EditAnywhere)
	float MovementScalerForwards = 1000;

	/**
	 * Interpolates between MIN and MAX depending on how close the player is. 
	 * 
	 * When player is far away then MIN value will multiplied with the set Forwards/Up speed.
	 * When player right on the critter then the MAX value will be used. 
	 */
	UPROPERTY(EditAnywhere, meta = (ClampMin = 0.0, ClampMax = 1.0))
	FFloatInterval MovementPlayerProximityScaler;
	default MovementPlayerProximityScaler.Min = 0.1;
	default MovementPlayerProximityScaler.Max = 1.0;

	float AssignedRandomSizeScaler = 1.0;

	float CachedAnimationDuration = 0.0;
	float CachedJumpCurveAverage = 0.0;

	// distance traversed Previous jump
	float PreviousJumpDistance = 0.0;

	float TimeStampLoop = 0.0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		CritterOwner = Cast<ABaseCritterActor>(Owner);
	}

	void CurveMovement(const float Dt)
	{
		devError("Implement this function in the actor that is inheriting from this");
	}

	// same code for all critters
	void UpdateMovement(const float Dt)
	{
		// normal movement if no critter leader has been set.
		if(CritterOwner.LinkedCritter == nullptr)
		{
			CurveMovement(Dt);
			return;
		}

		if(CritterOwner.LinkedCritter == CritterOwner)
		{
			devError("CritterLeader needs to be a different actor. Set a new linked critter or clear the reference to continue");
			return;
		}

#if EDITOR
		devCheck(CritterOwner.bLinkedCritterLeader != CritterOwner.LinkedCritter.bLinkedCritterLeader,
		 "One of the critters need to be flagged as leader.");
#endif

		if(CritterOwner.bLinkedCritterLeader)
		{
			// Debug::DrawDebugSphere(GetWorldLocation(), 100, 12, FLinearColor::Red);
			CurveMovement(Dt);
		}
		else
		{
			MirroredMovement(Dt);
			// Debug::DrawDebugSphere(GetWorldLocation(), 100, 12, FLinearColor::White);
		}
	}

	void MirroredMovement(const float Dt)
	{
		devError("Implement this function in the actor that is inheriting from this");
	}

	bool FindClosestNoGoZoneParams(FVector& FromToSphereNormalized, float& Alpha) const
	{
		Alpha = 0.0;
		FromToSphereNormalized = FVector::ZeroVector;

		if(NoGoZones.Num() <= 0)
			return false;

		float ClosestDistance = BIG_NUMBER;
		USphereComponent ClosestNoGoZone = nullptr;
		for(auto IterNoGoZone : NoGoZones)
		{
			const FVector SpherePos = IterNoGoZone.GetWorldLocation();
			const float SphereRadius = IterNoGoZone.GetScaledSphereRadius();
			const FVector CritterToSphereDelta = SpherePos - GetWorldLocation();
			const float Dist = CritterToSphereDelta.Size();

			// this will go negative if the Critter is penetrating, but we want to know that
			const float DistToEdge = Dist - SphereRadius;

			if(DistToEdge < ClosestDistance)
			{
				ClosestNoGoZone = IterNoGoZone;
				ClosestDistance = DistToEdge;
			}
		}

		// calculate distance to edge
		float EdgeProximityAlpha = 0;
		const FVector DeltaFromCritterToNoGoCenter = ClosestNoGoZone.GetWorldLocation() - GetWorldLocation();

		float DistanceFromCritterToNoGoCenter = DeltaFromCritterToNoGoCenter.Size();

		// project an estimate of how far we are gonna jump and check if this is to far
		const float JumpLength = GetEstimatedJumpLength();
		DistanceFromCritterToNoGoCenter -= JumpLength;

		const FVector CritterToCenterNormalized = DeltaFromCritterToNoGoCenter.GetSafeNormal();
		const float NoGoRadius = ClosestNoGoZone.GetScaledSphereRadius();

		// We'll inflate the nogozone with this much and start blending 
		// once we enter the inflated area until we reach the visual edge. 
		const float BlendPaddingMultiplier = 0.1;
		float BlendDistance = NoGoRadius * BlendPaddingMultiplier;
		BlendDistance = Math::Max(BlendDistance, JumpLength);
		const float InflatedRadius = NoGoRadius + BlendDistance;

		if(DistanceFromCritterToNoGoCenter < InflatedRadius)
		{
			// How much we've penetrated the inflate radius
			float PenetratedDistance = InflatedRadius - DistanceFromCritterToNoGoCenter;

			// blend 0 to 1 based on how much we've penetrated the 
			// inflated radius until we reach the real radius
			EdgeProximityAlpha = PenetratedDistance / BlendDistance;
			EdgeProximityAlpha = Math::Saturate(EdgeProximityAlpha);
		}

		Alpha = EdgeProximityAlpha;
		FromToSphereNormalized = -CritterToCenterNormalized;

		return Alpha > 0;
	}

	void UpdatePlayerProximity(const float Dt, const float PlayerProxRad)
	{
		AHazePlayerCharacter Mio; AHazePlayerCharacter Zoe;
		Game::GetMioZoe(Mio, Zoe);

		UpdateProximityForPlayer(Mio, Dt, PlayerProxRad);
		UpdateProximityForPlayer(Zoe, Dt, PlayerProxRad);

		// Update closest prox
		if(Proximity[Mio].Distance < Proximity[Zoe].Distance)
		{
			ClosestProximity = Proximity[Mio];
		}
		else
		{
			ClosestProximity = Proximity[Zoe];
		}

		// need to handle circulation dependencies
		PreviousClosestProximity = ClosestProximity;

		// Handle linked actor stuff
		if(CritterOwner.LinkedCritter == nullptr)
			return;

		if(CritterOwner.LinkedCritter.LinkedCritter == nullptr)
			return;

		UBaseCritterComponent OtherCritter = CritterOwner.LinkedCritter.Critters[CritterIndex];

		// who has control will be determined by Player proximity.
		// we'll compare ours to the other critters data and act accordingly
		const float& OurDistAlpha = ClosestProximity.DistanceAlpha;
		const float& OtherDistAlpha = OtherCritter.PreviousClosestProximity.DistanceAlpha;
		if(OurDistAlpha == OtherDistAlpha)
		{
			// do nothing for now
			return;
		}

		// only take the others proximity data if the player is closer to that critter
		if(OtherDistAlpha > OurDistAlpha)
		{
			// we are in control, so we do normal movement
			ClosestProximity = OtherCritter.PreviousClosestProximity;
			// ClosestProximity = OtherCritter.ClosestProximity;
		}
		else
		{
			// Debug::DrawDebugSphere(GetWorldLocation(), 100, 12, FLinearColor::Blue);
		}
	}

	void UpdateProximityForPlayer(AHazePlayerCharacter Player, const float Dt, const float PlayerProxRad)
	{
		auto& ProximityDataForPlayer = Proximity[Player];

		const FVector CritterPos = GetWorldLocation();
		FVector PlayerPos = Player.GetActorLocation();
		const FVector PlayerVelo = Player.GetActorVelocity();
		
		// we want the critters to ignore players that aren't moving...
		if(PlayerVelo.SizeSquared() < 1.0)
			ProximityDataForPlayer.AccStandingStillAlpha.AccelerateTo(1.0, 4.0, Dt);
		else
			ProximityDataForPlayer.AccStandingStillAlpha.AccelerateTo(0.0, 4.0, Dt);

		// cheat by pushing the player pos away, 
		// effectively making them go out of range from the critters 
		const float PlayerCapsuleRadius = 10.0;
		const float StandStillAlpha = ProximityDataForPlayer.AccStandingStillAlpha.Value;
		const float ExtraPushAwayDistance = (PlayerProxRad - PlayerCapsuleRadius) * StandStillAlpha;
		PlayerPos += FVector(0.0, 0.0, ExtraPushAwayDistance);

		const FVector AwayFromPlayerDelta = CritterPos - PlayerPos;
		const float CurrentDistance = AwayFromPlayerDelta.Size();

		ProximityDataForPlayer.PlayerVelocity = PlayerVelo;

		ProximityDataForPlayer.Distance = CurrentDistance;
		ProximityDataForPlayer.AwayFromPlayerDelta = AwayFromPlayerDelta;
		ProximityDataForPlayer.DistanceAlpha  = 1.0 - Math::Saturate(CurrentDistance/PlayerProxRad);

		//if(ProximityDataForPlayer.DistanceAlpha > 0.0)
		//	PrintToScreen("DistAlpha: " + + ProximityDataForPlayer.DistanceAlpha);

		if(ProximityDataForPlayer.DistanceAlpha > 0.0)
		{
			ProximityDataForPlayer.TimeSpentInProximity += Dt;
		}
		else
		{
			ProximityDataForPlayer.TimeSpentInProximity = 0.0;
		}
	}

	float GetEstimatedJumpLength() const
	{
		const float NextJumpDistance = EstimateDistanceTraversedNextJump();
		const float EstJumpLength = Math::Min(NextJumpDistance, PreviousJumpDistance);
		// PrintToScreen("Prev Jump: " + PreviousJumpDistance + " | Next Jump: " + NextJumpDistance , 1.0);
		return EstJumpLength;
	}

	// distance traversed Future jump, estimated.
	float EstimateDistanceTraversedNextJump() const
	{
		float Est = 0.0;

		const float TextureAnimationDuration = CachedAnimationDuration;
		if(TextureAnimationDuration <= 0)
			return Est;

		Est = TextureAnimationDuration;

		float CurveAverage = CachedJumpCurveAverage;

		Est *= CurveAverage;

		float MeshScale = GetWorldScale().Size();

		Est *= MeshScale;

		const float ForwardScale = Math::Lerp(
			MovementScalerForwards*MovementPlayerProximityScaler.Min,
			MovementScalerForwards*MovementPlayerProximityScaler.Max,
			ClosestProximity.DistanceAlpha
		);

		Est *= ForwardScale;

		Est *= 2.0;

		return Est;
	}

 }

struct FPlayerProximity
{
	float DistanceAlpha;
	float Distance;
	FVector AwayFromPlayerDelta;
	FVector	PlayerVelocity;
	float TimeSpentInProximity;
	FHazeAcceleratedFloat AccStandingStillAlpha;
}
