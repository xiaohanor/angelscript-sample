

/**
 * Rat Critters constrained to a circle with no-go zones
 * 
 * Prototype in AngelScript using components, then ported to Niagara 
 * 
 */

class ACritterRats : ABaseCritterActor
{
	UPROPERTY(EditAnywhere)
	int NumRats = 10;

	int GetNumCrittersToSpawn() override
	{
		return NumRats;
	}

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, ShowOnActor)
	UCritterRatComponent RatMesh;
	default RatMesh.CollisionProfileName = FName("NoCollision");
	default RatMesh.CollisionEnabled = ECollisionEnabled::NoCollision;
	default RatMesh.RelativeScale3D = FVector(0.2);
	default RatMesh.TickGroup = ETickingGroup::TG_PrePhysics;

	UPROPERTY(EditAnywhere, Category="Audio")
	FSoundDefReference SoundDefRef;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		// Find all the no-go-zones, if any.
		TArray<USphereComponent>FoundSpheres;
		GetComponentsByClass(USphereComponent, FoundSpheres);
		RatMesh.NoGoZones = FoundSpheres;
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		// Find all the no-go-zones, if any.
		TArray<USphereComponent>FoundSpheres;
		GetComponentsByClass(USphereComponent, FoundSpheres);
		RatMesh.NoGoZones = FoundSpheres;

		int NumRatsToSpawn = NumRats;
		if(bLinkedCritterLeader == false && LinkedCritter != nullptr)
		{
			bApplyLinkedCritterScale = true;
			NumRatsToSpawn = LinkedCritter.GetNumCrittersToSpawn();
		}

		RatMesh.CachedJumpCurveAverage = CalculateJumpCurveAverage(RatMesh.JumpCurve);
		RatMesh.CachedAnimationDuration = RatMesh.GetAnimationTextureDuration();

		// +1 because we have the default mesh on the actor
		Critters.Empty(NumRatsToSpawn+1);
		Critters.Add(RatMesh);

		// +1 because we have the default mesh on the actor
		int SpawnRatCounter = NumRatsToSpawn-1;
		while(SpawnRatCounter > 0)
		{
			auto NewRatMesh = CreateComponent(UCritterRatComponent, FName("Rat"+SpawnRatCounter));
			NewRatMesh.CopyScriptPropertiesFrom(RatMesh);
			NewRatMesh.NoGoZones = RatMesh.NoGoZones;
			NewRatMesh.StaticMesh = RatMesh.StaticMesh;
			NewRatMesh.CollisionProfileName = FName("NoCollision");
			NewRatMesh.CollisionEnabled = ECollisionEnabled::NoCollision;
			NewRatMesh.TickGroup = ETickingGroup::TG_PrePhysics;
			NewRatMesh.RelativeScale3D = RatMesh.RelativeScale3D;

			NewRatMesh.CachedAnimationDuration = RatMesh.CachedAnimationDuration;
			NewRatMesh.CachedJumpCurveAverage = RatMesh.CachedJumpCurveAverage;

			if(bApplyLinkedCritterScale == false)
			{
				float RngScaler = RandomMeshSizeScaler.Min;
				float A = RandomMeshSizeScaler.Max - RandomMeshSizeScaler.Min; 
				float B = Math::Pow(Math::RandRange(0.0, 1.0), RandomMeshSizeRangeBias);
				RngScaler += (A*B);
				NewRatMesh.AssignedRandomSizeScaler = RngScaler;
				NewRatMesh.RelativeScale3D *= RngScaler;
				devCheck(Math::IsWithinInclusive(
					RngScaler,
					RandomMeshSizeScaler.Min,
					RandomMeshSizeScaler.Max
				));
			}

			NewRatMesh.CritterIndex = Critters.Num();

			Critters.Add(NewRatMesh);

			--SpawnRatCounter;

			// Print("Crit Index: " + NewRatMesh.CritterIndex);
		}

		if (SoundDefRef.IsValid())
		{
			SoundDefRef.SpawnSoundDefAttached(this);
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		Super::Tick(DeltaSeconds);
		UpdateDebug();
	}

	void UpdateDebug()
	{
		if(RatMesh.bDebug == false)
			return;

		Debug::DrawDebugPoint(COM + FVector(0,0, 50), 15, FLinearColor::Green);
		Debug::DrawDebugCircle(GetActorLocation(), RatMesh.SphereConstraintRadius, 32, FLinearColor::Red);

		if(RatMesh.NoGoZones.Num() <= 0)
			return;

		for(auto IterNoGoZone : RatMesh.NoGoZones)
		{
			if(IterNoGoZone == nullptr)
				continue;

			Debug::DrawDebugCircle(
				IterNoGoZone.GetWorldLocation(),
				IterNoGoZone.GetScaledSphereRadius(),
				32,
				FLinearColor::Yellow
			);
		}

	}

}

class UCritterRatComponent : UBaseCritterComponent
{
	UPROPERTY(EditAnywhere)
	float PlayerProximityRadius = 1000;

	UPROPERTY(EditAnywhere)
	float SphereConstraintRadius = 1000;

	UPROPERTY(EditAnywhere)
	bool bDebug = false;

	UPROPERTY(EditAnywhere)
	FRuntimeFloatCurve JumpCurve;

	UPROPERTY(EditAnywhere)
	UTexture2D Animation0;

	UPROPERTY(EditAnywhere)
	UTexture2D Animation1;

	// Fallback (random) duration range if no texture has been supplied
	UPROPERTY(EditAnywhere)
	float FallbackLoopDuration= 0.5;

	// Settings
	//////////////////////////////////////////////7
	// Transient variables

	FHazeAcceleratedVector Move;
	FVector StartLocation = FVector::ZeroVector;
	FVector PrevJumpDirection = FVector::ForwardVector;
	FQuat PrevJumpQuat = FQuat::Identity;
	FHazeAcceleratedFloat AccTimeScale;
	FQuat JumpQuat = FQuat::Identity;
	FVector JumpDirection = FVector::ForwardVector;
	float CurrentLoopPauseTime = 0;
	float AnimationAlpha = 0;
	float SlowDown = 0.0;
	int LoopCount = 0;

	// Fallback duration is no texture has been given
	float AssignedAnimDuration = 0;

	float Random_RatToCenter = 0.0;
	float Random_AwayFromCOM = 0.0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();

		StartLocation = GetWorldLocation();

		Move.SnapTo(StartLocation);
		AccTimeScale.SnapTo(0);
		
		float LowRange = FallbackLoopDuration*0.5;
		float HighRange = FallbackLoopDuration*1.0;
		AssignedAnimDuration = Math::RandRange(LowRange, HighRange);

		Random_RatToCenter = Math::RandRange(5.0, 10.0);
		Random_AwayFromCOM = Math::RandRange(0.1, 0.2);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		UpdatePlayerProximity(DeltaSeconds, PlayerProximityRadius);
		UpdateMovement(DeltaSeconds);
	}

	FVector CalculateNextJumpDirection() const
	{
		FVector NextDir = FVector::ZeroVector;

		// Define base direction. Random in the direction we are 
		// currently heading in OR away from the player

		const FVector Up = GetWorldRotation().UpVector;

		const bool bChasedByPlayer = ClosestProximity.DistanceAlpha > 0;
		if(bChasedByPlayer)
		{
			FVector AwayFromPlayer = ClosestProximity.AwayFromPlayerDelta;
			AwayFromPlayer.Normalize();

			const FVector AwayFromPlayerOrthogonal = AwayFromPlayer.CrossProduct(Up);
			const FVector AwayFromPlayerDiagonal = AwayFromPlayer + AwayFromPlayerOrthogonal;
			FVector AwayFromPlayerComposed = AwayFromPlayerDiagonal.SlerpTowards(
				AwayFromPlayerOrthogonal, 
				Math::Pow(ClosestProximity.DistanceAlpha, 10)
			);
			AwayFromPlayerComposed = Math::GetRandomConeDirection( AwayFromPlayerComposed, Math::DegreesToRadians(35));

			NextDir = AwayFromPlayerComposed;
		}
		else if(JumpDirection == FVector::ZeroVector)
		{
			NextDir = Math::GetRandomPointInCircle_XY();
		}
		else
		{
			NextDir  = Math::GetRandomConeDirection(JumpDirection, Math::DegreesToRadians(10));
		}

		// Various Avoidance slerps
		FVector SlerpedDirection = NextDir;

		// inwards towards the center when approaching the sphere edge
		float EdgeProximityAlpha = 0;
		const FVector DeltaFromRatToCenter = StartLocation - GetWorldLocation();

		float DistanceFromSphereCenter = DeltaFromRatToCenter.Size();

		// project an esstimate of how far we are gonna jump and check if this is to far
		DistanceFromSphereCenter += GetEstimatedJumpLength();

		const FVector RatToCenterNormalized = DeltaFromRatToCenter.GetSafeNormal();
		const float EdgeDistanceThreshold = SphereConstraintRadius * 0.8;
		const float EdgeBlendDistance = SphereConstraintRadius * 0.2;
		if(DistanceFromSphereCenter > EdgeDistanceThreshold)
		{
			float CrossedDistance = DistanceFromSphereCenter - EdgeDistanceThreshold;
			EdgeProximityAlpha = CrossedDistance / EdgeBlendDistance;
			EdgeProximityAlpha = Math::Saturate(EdgeProximityAlpha);
		}

		if(EdgeProximityAlpha > 0)
		{
			const FVector RatToCenterOrthogonal = RatToCenterNormalized.CrossProduct(Up);
			const FVector RatToCenterDiagonal = RatToCenterNormalized + RatToCenterOrthogonal;

			FVector RatToCenterComposed = RatToCenterOrthogonal.SlerpTowards( RatToCenterDiagonal, Math::Pow(EdgeProximityAlpha, 10));

			// const float TimeBasedRamp = ClosestProximity.TimeSpentInProximity;
			// const float RampedPlayerProximityAlpha = Math::Pow(ClosestProximity.DistanceAlpha, TimeBasedRamp);
			// RatToCenterComposed = RatToCenterNormalized.SlerpTowards(RatToCenterComposed, RampedPlayerProximityAlpha);
			RatToCenterComposed = RatToCenterNormalized.SlerpTowards(RatToCenterComposed, ClosestProximity.DistanceAlpha);

			// time based override to prevent clusters.
			const float TimebasedAlpha = Math::Saturate(ClosestProximity.TimeSpentInProximity * 0.5);
			if(TimebasedAlpha > 0.0)
			{
				// RatToCenterComposed = RatToCenterOrthogonal.SlerpTowards(RatToCenterComposed, TimebasedAlpha);
				const FVector TimeBasedTarget = RatToCenterOrthogonal.SlerpTowards(RatToCenterNormalized, EdgeProximityAlpha);
				// const FVector TimeBasedTarget = EdgeProximityAlpha >= 1.0 ? RatToCenterNormalized : RatToCenterOrthogonal;
				RatToCenterComposed = RatToCenterComposed.SlerpTowards(TimeBasedTarget, TimebasedAlpha);
			}

			// if(ClosestProximity.DistanceAlpha > 0)
			// 	Debug::DrawDebugPoint(GetWorldLocation(), 30.0 * ClosestProximity.DistanceAlpha, FLinearColor::Yellow);
			// Debug::DrawDebugLine( GetWorldLocation(), GetWorldLocation() + RatToCenterComposed*1000.0);

			SlerpedDirection = SlerpedDirection.SlerpTowards(RatToCenterComposed, EdgeProximityAlpha);
		}

		// away from no-go-zones
		FVector NoGoToRatNormalized = FVector::ZeroVector; float NoGoToRatProximityAlpha = 0;
		FindClosestNoGoZoneParams(NoGoToRatNormalized, NoGoToRatProximityAlpha);
		if(NoGoToRatProximityAlpha > 0)
		{
			FVector Constrained_NoGoZoneToRat = NoGoToRatNormalized.CrossProduct(Up);
			SlerpedDirection = SlerpedDirection.SlerpTowards(Constrained_NoGoZoneToRat, NoGoToRatProximityAlpha);
		}

		// Away from Center of mass
		const FVector AwayFromCOM = GetWorldLocation() - CritterOwner.COM;
		const float AwayFromCOMThreshold = SphereConstraintRadius * 0.1; 
		const float AwayFromCOMAlpha = 1.0 - Math::Saturate(AwayFromCOM.Size() / AwayFromCOMThreshold);
		if(AwayFromCOMAlpha > 0)
		{
			const FVector Constrained_AwayFromCOM = AwayFromCOM.ClampInsideCone(SlerpedDirection,180.0);
			SlerpedDirection = SlerpedDirection.SlerpTowards(Constrained_AwayFromCOM, AwayFromCOMAlpha);
		}

		NextDir = SlerpedDirection;
		NextDir = NextDir.VectorPlaneProject(FVector::UpVector);
		NextDir.Normalize();

		return NextDir;
	}
	
	void CurveMovement(const float DeltaTime) override
	{
		float Time = Time::GetGameTimeSeconds();
		const float TextureAnimationDuration = CachedAnimationDuration;

		if(TextureAnimationDuration <= 0)
			return;

		if(ClosestProximity.DistanceAlpha > 0)
		{
			// Speed up
			AccTimeScale.AccelerateTo(DeltaTime*0.5, 1.0, DeltaTime);
		}
		else
		{
			// Speed down
			AccTimeScale.AccelerateTo(-DeltaTime*0.5, 1.0, DeltaTime);
		}

		SlowDown += AccTimeScale.Value;

		SetScalarParameterValueOnMaterials(FName("RuntimeOffset"), -SlowDown);

		Time += SlowDown;
		Time = Math::Max(0, Time);

		const float AnimationDuration = TextureAnimationDuration;
		float CurrentAnimationTime = Time % AnimationDuration;
		float NewAnimationAlpha = Math::Frac(CurrentAnimationTime / AnimationDuration);

		float RotationAlpha = 0.0;

		bool bHasPassedAlphaMarker = false;
		if(AnimationAlpha <= NewAnimationAlpha)
		{
			// normal case, no wrap around.
			bHasPassedAlphaMarker = (LoopAlphaMarker >= AnimationAlpha && LoopAlphaMarker < NewAnimationAlpha);
		}
		else
		{
			// wrap-around case
			bHasPassedAlphaMarker = (LoopAlphaMarker >= AnimationAlpha || LoopAlphaMarker <= NewAnimationAlpha);
		}

		// prevAge > age
		if(bHasPassedAlphaMarker)
		{
			// then we have loop
			LoopCount += 1;

			// JumpDirection = NextJumpDirection;
			// JumpQuat = FQuat::MakeFromXZ(JumpDirection, FVector::UpVector);

			// NextJumpDirection = CalculateNextJumpDirection();
			// NextJumpQuat = FQuat::MakeFromXZ(NextJumpDirection, FVector::UpVector);

			PrevJumpDirection = JumpDirection;
			// PrevJumpQuat = JumpQuat;
			PrevJumpQuat = GetComponentQuat();
			JumpDirection = CalculateNextJumpDirection();
			JumpQuat = FQuat::MakeFromXZ(JumpDirection, FVector::UpVector);

			PreviousJumpDistance = 0.0;
			TimeStampLoop = Time;
			RotationAlpha = 0.0;
		}
		else
		{
			// note that this takes into account the 'slowdown' that we have a few lines up
			float ElapsedTimeSinceLoop = Time - TimeStampLoop;
			RotationAlpha = Math::Saturate(ElapsedTimeSinceLoop / RotationBlendTime);
		}

		AnimationAlpha = NewAnimationAlpha;

		float MeshScale = GetWorldScale().Size();
		float CurveAlpha = JumpCurve.GetFloatValue(AnimationAlpha);
		const float ProximityScaler = Math::Max(ClosestProximity.DistanceAlpha, 0.1);

		const float UpScale = Math::Lerp(
			MovementScalerUp*MovementPlayerProximityScaler.Min,
			MovementScalerUp*MovementPlayerProximityScaler.Max,
			ClosestProximity.DistanceAlpha
		);

		const float ForwardScale = Math::Lerp(
			MovementScalerForwards*MovementPlayerProximityScaler.Min,
			MovementScalerForwards*MovementPlayerProximityScaler.Max,
			ClosestProximity.DistanceAlpha
		);

		float Delta_XY = CurveAlpha;
		Delta_XY *= MeshScale;
		Delta_XY *= ForwardScale; 
		Delta_XY *= DeltaTime;

		// keep a record of how far we've traversed this jump
		PreviousJumpDistance += Delta_XY;

		Move.Value += (JumpDirection * Delta_XY);

		float Delta_Z = CurveAlpha;
		Delta_Z *= MeshScale;
		Delta_Z *= UpScale;

		Move.Value.Z = StartLocation.Z;
		Move.Value.Z += Delta_Z;

  		FQuat NewRot = FQuat::Slerp(PrevJumpQuat, JumpQuat, RotationAlpha);
		// FQuat NewRot = FQuat::Slerp(JumpQuat, NextJumpQuat, RotationAlpha);
		NewRot *= FRotator().Quaternion();

		// animate the rat by rolling a bit
		const float Angle = 20;
		const float Period = 20;
		NewRot *= Math::RotatorFromAxisAndAngle(FVector::ForwardVector, Math::Sin(Time*Period-SlowDown)*Angle*ProximityScaler).Quaternion();

		SetWorldLocation(Move.Value);
		SetComponentQuat(NewRot);

		if(bDebug)
		{
			// PrintToScreen("Slowdown " + SlowDown);
			// PrintToScreen("Time " + Time);
			// PrintToScreen("CurrentAnimationTime " + CurrentAnimationTime);
			// PrintToScreen("ProximityScaler " + ProximityScaler );
			// PrintToScreen("CurveAlpha: " + CurveAlpha);
			// PrintToScreen("" + Move.Value);
			// PrintToScreen("NewRot" + NewRot);
			// PrintToScreen("RotationAlpha" + RotationAlpha);
			// PrintToScreen("New Animation Alpha " + NewAnimationAlpha);
			// PrintToScreen("Current Animation Time " + CurrentAnimationTime);
			// FVector O = GetWorldLocation();
			// Debug::DrawDebugArrow( O, O + JumpDirection * 1000, 1000, FLinearColor::Green);
			// Debug::DrawDebugArrow( O, O + NextJumpDirection * 1000, 1000, FLinearColor::Red);
			// PrintToScreen("World Z " + O.Z);
		}
	}

	void MirroredMovement(const float Dt) override
	{
		UBaseCritterComponent OtherCritter = CritterOwner.LinkedCritter.Critters[CritterIndex];
		FVector TargetPos = OtherCritter.GetWorldLocation();
		TargetPos -= CritterOwner.LinkedCritter.GetActorLocation();

		// the z offset needs to be normalized to our maximum range. 
		// first we normalize the relativePos.z then multiple it with our max.
		TargetPos.Z /= OtherCritter.MovementScalerUp;
		// devCheck(TargetPos.Z <= 1.0);
		TargetPos.Z *= MovementScalerUp;

		FVector RelativeDelta = FVector(TargetPos.X, TargetPos.Y, 0.0);

		TargetPos += CritterOwner.GetActorLocation();
		SetWorldLocation(TargetPos);

		FQuat TargetQuat = OtherCritter.GetComponentQuat();

		float OtherCritterSpeed = OtherCritter.GetEstimatedJumpLength() / Dt;
		float SpeedFrac = Math::Saturate(OtherCritterSpeed * 0.0001); 
		SpeedFrac = Math::Pow(SpeedFrac, 0.5);
		

		const float Angle = 20;
		const float Period = 20;
		float Time = Time::GetGameTimeSeconds();
		Time += SlowDown;
		Time = Math::Max(0, Time);
		TargetQuat *= Math::RotatorFromAxisAndAngle(FVector::ForwardVector, Math::Sin(Time*Period)*Angle*SpeedFrac).Quaternion();

		SetComponentQuat(TargetQuat);

	}

	float GetAnimationTextureDuration() const
	{
		// use assigned anim duration if we don't have any texture 
		float Duration = AssignedAnimDuration;
		
		if(Animation0 != nullptr)
		{
			float DurationAnimation0 = float(Animation0.Blueprint_GetSizeY()) / 30.0;

			if(bDebug)
			{
				// PrintToScreen("Animation 0 Duration from texture: " + DurationAnimation0);
			}

			Duration += DurationAnimation0;
		}

		if(Animation1 != nullptr)
		{
			float DurationAnimation1 = float(Animation1.Blueprint_GetSizeY()) / 30.0;

			if(bDebug)
			{
				// PrintToScreen("Animation 1 Duration from texture: " + DurationAnimation1);
			}

			Duration += DurationAnimation1;
		}

		if(bDebug)
		{
			// PrintToScreen("Total Duration from texture: " + Duration);
		}

		return Duration;
	}

}

class UCritterRatVisualizer : UHazeScriptComponentVisualizer
{
	default VisualizedClass = UCritterRatComponent;

	UFUNCTION(BlueprintOverride)
	void VisualizeComponent(const UActorComponent InComponent)
	{
		auto SelectableComponent = Cast<UCritterRatComponent>(InComponent);
		if(SelectableComponent == nullptr)
			return;

		FTransform CompTransform = SelectableComponent.WorldTransform;

		// Render the handle in foreground drawing mode so it's in front of stuff
		SetRenderForeground(true);

		const auto& NoGoZones = SelectableComponent.NoGoZones;
		
		for(auto IterNoGoZone : NoGoZones)
		{
			const float Radius = IterNoGoZone.GetScaledSphereRadius();
			FVector O = IterNoGoZone.GetWorldLocation();
			DrawCircle(
				O,
				Radius,
				FLinearColor::Yellow,
				10.0,
				FVector::UpVector,
				64	
			);

			DrawDashedLine(
				O,
				O + FVector::ForwardVector*Radius,
				FLinearColor::Yellow,
			);

			DrawWorldString(
				f"No-go-zone: \n"+ IterNoGoZone,
				O + FVector::ForwardVector*Radius*0.5,
				FLinearColor::Yellow,
				1.0,
				SelectableComponent.SphereConstraintRadius*PI*2,
				true,
				true
			);

		}

		DrawCircle(
			CompTransform.GetLocation(),
			SelectableComponent.SphereConstraintRadius,
			FLinearColor::Blue,
			SelectableComponent.SphereConstraintRadius * 0.01,
			FVector::UpVector,
			64	
		);

		DrawDashedLine(
			CompTransform.GetLocation(),
			CompTransform.GetLocation() + FVector::RightVector*SelectableComponent.SphereConstraintRadius,
			FLinearColor::Blue,
		);

		DrawWorldString(
			f"Constraint Radius: "+SelectableComponent.SphereConstraintRadius,
			CompTransform.GetLocation() + FVector::RightVector*SelectableComponent.SphereConstraintRadius*0.5,
			FLinearColor::Blue,
			1.2,
			SelectableComponent.SphereConstraintRadius*PI*2,
			true,
			true
		);

		// Player bubble
		float PlayerBubbleOffset = SelectableComponent.SphereConstraintRadius*1.2;
		PlayerBubbleOffset += SelectableComponent.PlayerProximityRadius;

		DrawCircle(
			CompTransform.GetLocation() + FVector::RightVector*PlayerBubbleOffset,
			SelectableComponent.PlayerProximityRadius,
			FLinearColor::Purple,
			0.01 * SelectableComponent.PlayerProximityRadius,
			FVector::UpVector,
			64	
		);

		const FVector StartLine = CompTransform.GetLocation() + FVector::RightVector*PlayerBubbleOffset;
		const FVector EndLine = StartLine + FVector::RightVector*SelectableComponent.PlayerProximityRadius;
		DrawDashedLine(
			StartLine,
			EndLine,
			FLinearColor::Purple,
		);

		DrawWorldString(
			// f"Player Proximity (push away) Radius: "+SelectableComponent.PlayerProximityRadius + f"\n IF player was standing in the middle here for example",
			f"Player Proximity (push away) Radius: "+SelectableComponent.PlayerProximityRadius,
			CompTransform.GetLocation() + FVector::RightVector*PlayerBubbleOffset,
			FLinearColor::Purple,
			1.2,
			SelectableComponent.SphereConstraintRadius*PI*2,
			true,
			true
		);

	}

}