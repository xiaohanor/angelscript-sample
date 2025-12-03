
/**
 * Frog Critters constrained to a circle + no go zones
 */

class ACritterFrogs : ABaseCritterActor
{
	UPROPERTY(EditAnywhere)
	int NumFrogs = 50;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, ShowOnActor)
	UCritterFrogComponent FrogMesh;
	default FrogMesh.CollisionProfileName = FName("NoCollision");
	default FrogMesh.CollisionEnabled = ECollisionEnabled::NoCollision;
	default FrogMesh.RelativeScale3D = FVector(0.2);
	default FrogMesh.TickGroup = ETickingGroup::TG_PrePhysics;

	UPROPERTY(EditAnywhere, Category="Audio")
	FSoundDefReference SoundDefRef;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		// Find all the no-go-zones, if any.
		TArray<USphereComponent>FoundSpheres;
		GetComponentsByClass(USphereComponent, FoundSpheres);
		FrogMesh.NoGoZones = FoundSpheres;
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		// Find all the no-go-zones, if any.
		TArray<USphereComponent>FoundSpheres;
		GetComponentsByClass(USphereComponent, FoundSpheres);
		FrogMesh.NoGoZones = FoundSpheres;

		int NumFrogsToSpawn = NumFrogs;
		if(bLinkedCritterLeader == false && LinkedCritter != nullptr)
		{
			bApplyLinkedCritterScale = true;
			NumFrogsToSpawn = LinkedCritter.GetNumCrittersToSpawn();
		}

		FrogMesh.CachedJumpCurveAverage = CalculateJumpCurveAverage(FrogMesh.JumpCurve);
		FrogMesh.CachedAnimationDuration = FrogMesh.GetAnimationTextureDuration();

		// +1 because we have the default mesh on the actor
		Critters.Empty(NumFrogsToSpawn+1);
		Critters.Add(FrogMesh);

		// -1 because we have the default mesh on the actor
		int SpawnFrogCounter = NumFrogsToSpawn-1;
		while(SpawnFrogCounter > 0)
		{
			auto NewFrogMesh = CreateComponent(UCritterFrogComponent, FName("Frog"+SpawnFrogCounter));
			NewFrogMesh.CopyScriptPropertiesFrom(FrogMesh);
			NewFrogMesh.NoGoZones = FrogMesh.NoGoZones;
			NewFrogMesh.StaticMesh = FrogMesh.StaticMesh;
			NewFrogMesh.CollisionProfileName = FName("NoCollision");
			NewFrogMesh.CollisionEnabled = ECollisionEnabled::NoCollision;
			NewFrogMesh.TickGroup = ETickingGroup::TG_PrePhysics;
			NewFrogMesh.RelativeScale3D = FrogMesh.RelativeScale3D;

			NewFrogMesh.CachedAnimationDuration = FrogMesh.CachedAnimationDuration;
			NewFrogMesh.CachedJumpCurveAverage = FrogMesh.CachedJumpCurveAverage;

			if(bApplyLinkedCritterScale == false)
			{
				float RngScaler = RandomMeshSizeScaler.Min;
				float A = RandomMeshSizeScaler.Max - RandomMeshSizeScaler.Min; 
				float B = Math::Pow(Math::RandRange(0.0, 1.0), RandomMeshSizeRangeBias);
				RngScaler += (A*B);
				NewFrogMesh.AssignedRandomSizeScaler = RngScaler;
				NewFrogMesh.RelativeScale3D *= RngScaler;
				devCheck(Math::IsWithinInclusive(
					RngScaler,
					RandomMeshSizeScaler.Min,
					RandomMeshSizeScaler.Max
				));
			}

			NewFrogMesh.CritterIndex = Critters.Num();

			Critters.Add(NewFrogMesh);

			--SpawnFrogCounter;

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
		if(FrogMesh.bDebug == false)
			return;

		Debug::DrawDebugCircle(
			GetActorLocation(), 
			FrogMesh.SphereConstraintRadius, 
			32, 
			FLinearColor::Red
		);

		if(FrogMesh.NoGoZones.Num() > 0)
		{
			for(auto IterNoGoZone : FrogMesh.NoGoZones)
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

	int GetNumCrittersToSpawn() override
	{
		return NumFrogs;
	}

}

class UCritterFrogComponent : UBaseCritterComponent
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

	// Settings
	//////////////////////////////////////////////7
	// Transient variables

	FHazeAcceleratedVector Move;
	FVector StartLocation = FVector::ZeroVector;
	FVector PrevJumpDirection = FVector::ForwardVector;
	FVector JumpDirection = FVector::ForwardVector;
	FQuat PrevJumpQuat = FQuat::Identity;
	FHazeAcceleratedFloat AccTimeScale;
	FQuat JumpQuat = FQuat::Identity;
	float CurrentLoopPauseTime = 0;
	float AnimationAlpha = 0;
	float SlowDown = 0.0;
	bool bInAir = false;
	int LoopCount = 0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();

		StartLocation = GetWorldLocation();
		Move.SnapTo(StartLocation);
		AccTimeScale.SnapTo(0);
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

		// calculate distance to edge
		float EdgeProximityAlpha = 0;
		const FVector DeltaFromFrogToCenter = StartLocation - GetWorldLocation();
		float DistanceFromSphereCenter = DeltaFromFrogToCenter.Size();

		// project an esstimate of how far we are gonna jump and check if this is to far
		DistanceFromSphereCenter += GetEstimatedJumpLength();

		const FVector FrogToCenterNormalized = DeltaFromFrogToCenter.GetSafeNormal();
		const float EdgeDistanceThreshold = SphereConstraintRadius * 0.9;
		const float EdgeBlendDistance = SphereConstraintRadius * 0.1;
		if(DistanceFromSphereCenter > EdgeDistanceThreshold)
		{
			float CrossedDistance = DistanceFromSphereCenter - EdgeDistanceThreshold;
			EdgeProximityAlpha = CrossedDistance / EdgeBlendDistance;
			EdgeProximityAlpha = Math::Saturate(EdgeProximityAlpha);
		}

		// Calcualte params for closest No-Go-Zone
		FVector NoGoToFrogNormalized = FVector::ZeroVector; float NoGoToFrogProximityAlpha = 0;
		FindClosestNoGoZoneParams(NoGoToFrogNormalized, NoGoToFrogProximityAlpha);

		// 1 Player is chasing us, are we are outside bubble or near the edge
		const bool bChasedByPlayer = ClosestProximity.DistanceAlpha > 0;
		if(bChasedByPlayer)
		{
			// FVector AwayFromPlayer = GetWorldLocation() - ClosestProximity.ClosestLocation;
			FVector AwayFromPlayer = ClosestProximity.AwayFromPlayerDelta;
			AwayFromPlayer.Normalize();

			// close to the edge or outside the bubble?
			if(EdgeProximityAlpha > 0 || NoGoToFrogProximityAlpha > 0)
			{
				// random generate location men slerpa den mot mitten baserat på en alpha, but hopefully ortho to player
				// lerp from player or 
				FVector SlerpedDirection = FVector::ZeroVector;
				if(EdgeProximityAlpha > NoGoToFrogProximityAlpha)
				{
					SlerpedDirection = AwayFromPlayer.SlerpTowards(FrogToCenterNormalized, EdgeProximityAlpha);
				}
				else
				{
					SlerpedDirection = AwayFromPlayer.SlerpTowards(NoGoToFrogNormalized, NoGoToFrogProximityAlpha);
				}

				// SlerpedDirection = Math::GetRandomConeDirection( SlerpedDirection, Math::DegreesToRadians(5));
				if(EdgeProximityAlpha < 1.0 && NoGoToFrogProximityAlpha < 1.0)
					SlerpedDirection = SlerpedDirection.CrossProduct(AwayFromPlayer);

				SlerpedDirection = SlerpedDirection.VectorPlaneProject(FVector::UpVector);
				SlerpedDirection.Normalize();

				NextDir = SlerpedDirection;

				if(bDebug)
				{
					Debug::DrawDebugPoint(GetWorldLocation(), 20, FLinearColor::Red, 0.2);
				}
			}
			else
			{
				// just away from player then
				AwayFromPlayer = Math::GetRandomConeDirection( AwayFromPlayer, Math::DegreesToRadians(35));
				AwayFromPlayer = AwayFromPlayer.VectorPlaneProject(FVector::UpVector);
				AwayFromPlayer.Normalize();

				NextDir = AwayFromPlayer;
			}
		}
		// 2 Outside bubble or near edge
		else if(EdgeProximityAlpha > 0 || NoGoToFrogProximityAlpha > 0)
		{
			// to close to the edge, start blending towards middle
			FVector SlerpedDir = Math::GetRandomPointOnCircle_XY();
			if(EdgeProximityAlpha > NoGoToFrogProximityAlpha)
				SlerpedDir = SlerpedDir.SlerpTowards(FrogToCenterNormalized, EdgeProximityAlpha);
			else
				SlerpedDir = SlerpedDir.SlerpTowards(NoGoToFrogNormalized, NoGoToFrogProximityAlpha);

			SlerpedDir = SlerpedDir.VectorPlaneProject(FVector::UpVector);
			SlerpedDir.Normalize();

			NextDir = SlerpedDir;

		}
		// 3 safe inside, far from everything
		else
		{
			// we can safely jump around
			NextDir = Math::GetRandomPointInCircle_XY().GetSafeNormal();
		}

		// if(bDebug)
		// {
		// 	Debug::DrawDebugPoint(GetWorldLocation(), 20, FLinearColor::Red, 0.2);
		// 	Debug::DrawDebugLine(
		// 		GetWorldLocation(),
		// 		GetWorldLocation() + NextDir * 1000.0,
		// 		FLinearColor::Yellow,
		// 		3, 0.5
		// 	);
		// }

		// if(bDebug)
		// {
		// 	Debug::DrawDebugLine(
		// 		GetWorldLocation(),
		// 		StartLocation + (FrogToCenterNormalized * -PlayerProximityRadius),
		// 		FLinearColor::Yellow,
		// 		3, 0.5
		// 	);
		// }

		return NextDir;
	}

	void MirroredMovement(const float Dt) override
	{
		UBaseCritterComponent OtherCritter = CritterOwner.LinkedCritter.Critters[CritterIndex];
		FVector TargetPos = OtherCritter.GetWorldLocation();
		TargetPos -= CritterOwner.LinkedCritter.GetActorLocation();

		// PrintToScreen("Delta: " + TargetPos);

		// the z offset needs to be normalized to our maximum range. 
		// first we normalize the delta then multiple it with our max.

		TargetPos.Z /= OtherCritter.MovementScalerUp;

		devCheck(TargetPos.Z <= 1.0);

		TargetPos.Z *= MovementScalerUp;

		TargetPos += CritterOwner.GetActorLocation();
		SetWorldLocation(TargetPos);
		const FQuat TargetQuat = OtherCritter.GetComponentQuat();
		SetComponentQuat(TargetQuat);
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

		if(bHasPassedAlphaMarker)
		{
			// then we have loop
			LoopCount += 1;

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
			float ElapsedTimeSinceLoop = Time - TimeStampLoop;
			RotationAlpha = Math::Saturate(ElapsedTimeSinceLoop / RotationBlendTime);
		}

		AnimationAlpha = NewAnimationAlpha;

		float MeshScale = GetWorldScale().Size();
		float CurveAlpha = JumpCurve.GetFloatValue(AnimationAlpha);

		// Keep track of when the frogs jump/land
		bInAir = CurveAlpha != 0;

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

		SetWorldLocation(Move.Value);
		SetComponentQuat(NewRot);

		if(bDebug)
		{
			// PrintToScreen("RotationAlpha " + RotationAlpha);
			// // PrintToScreen("Slowdown " + SlowDown);
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
			// Debug::DrawDebugArrow( O, O + JumpDirection * 1000, 2000, FLinearColor::Green);
			// Debug::DrawDebugArrow( O, O + NextJumpDirection * 1000, 1000, FLinearColor::Red);
			// PrintToScreen("World Z " + O.Z);
		}
	}

	float GetAnimationTextureDuration() const
	{
		float Duration = 0;
		
		if(Animation0 != nullptr)
		{
			float DurationAnimation0 = float(Animation0.Blueprint_GetSizeY()) / 30.0;
			Duration += DurationAnimation0;
		}

		if(Animation1 != nullptr)
		{
			float DurationAnimation1 = float(Animation1.Blueprint_GetSizeY()) / 30.0;
			Duration += DurationAnimation1;
		}

		return Duration;
	}

}

class UCritterFrogVisualizer : UHazeScriptComponentVisualizer
{
	default VisualizedClass = UCritterFrogComponent;

	UFUNCTION(BlueprintOverride)
	void VisualizeComponent(const UActorComponent InComponent)
	{
		auto SelectableComponent = Cast<UCritterFrogComponent>(InComponent);
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
			10.0,
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
			10.0,
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