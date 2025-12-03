
UCLASS(Meta = (HideCategories = "LOD Physics AssetUserData Collision Tags Cooking Activation Rendering"))
class ACoastTrainCart : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UCoastTrainInheritMovementComponent TrainInheritMovement;
	default TrainInheritMovement.Shape.BoxExtents = FVector(3000.0, 3000.0, 3000.0);
	default TrainInheritMovement.RelativeLocation = FVector(0.0, 0.0, 0.0);

	UPROPERTY(DefaultComponent)
	UTemporalLogTransformLoggerComponent TransformLogComponent;



	// VFX beam connecting the carts
	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UNiagaraComponent ConnectionBeam;
	default ConnectionBeam.bAutoActivate = true;
	// default ConnectionBeam.TickBehavior = ENiagaraTickBehavior::ForceTickLast;
	default ConnectionBeam.RelativeLocation = FVector(1760.0, 0.0, -260.0);

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	USceneComponent MeshRootAbsoluteComp;
	// default MeshRootAbsoluteComp.bAbsoluteRotation = true;

	UPROPERTY(DefaultComponent, Attach = MeshRootAbsoluteComp)
	USceneComponent DisconnectDroneLocation;

	// Location and rotation anchors for other carts to anchor their connection beam
	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	USceneComponent ConnectionBeamAnchor;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	USceneComponent DisconnectVFXLoc;

	UPROPERTY(Category = Rail, EditInstanceOnly)
	AActor RailActor;

	UPROPERTY(Category = Rail, EditInstanceOnly)
	bool bSnapToRail = false;

	UPROPERTY(Category = Rail, EditInstanceOnly)
	bool bReverseOnRail = false;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	ACoastTrainDriver Driver;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	ACoastTrainCart NextCart;

	UPROPERTY(EditAnywhere)
	UNiagaraSystem DisconnectVFX;

	UPROPERTY(EditAnywhere)
	UNiagaraSystem TrainDisconnectExplosionVFX;

	UPROPERTY(BlueprintReadOnly, EditAnywhere, Meta = (InlineEditConditionToggle))
	bool bBossAttackSafeZone = false;

	UPROPERTY(BlueprintReadOnly, EditAnywhere, Meta = (EditCondition = "bBossAttackSafeZone"))
	float AttackSafeZoneExtents = 2000.0;  

	UPROPERTY(BlueprintReadOnly, EditAnywhere, Meta = (EditCondition = "bBossAttackSafeZone", EditConditionHides))
	float AttackSafeZoneOffset = 0.0;  

	float SplineDistanceFromDriver = 0.0;
	FSplinePosition CurrentPosition;

	float WobbleUpMultiplier = 1.0;
	float WobbleSideMultiplier = 1.0;
	float WobbleUpTime = 0.0;
	float WobbleSideTime = 0.0;

	float CurrentSpin = 0.0;
	float CurrentSpinSpeed = 0.0;
	float CurrentMovementSpeed = 0.0;

	FVector SuspensionOffset;
	FVector SuspensionVelocity;

	bool bCartDisconnected = false;
	bool bCartDisabled = false;
	float DisconnectDeceleration = 0.0;
	float DisconnectInitialDistance = 0.0;
	float DisconnectInitialDistanceDuration = 0.0;
	float DisconnectInitialDistanceTimer = 0.0;
	float DisconnectDecelerationDelay = 0.0;

	TArray<ACoastTrainRespawnPoint> RespawnPoints;

	float GetCartDistanceToPlayer(AHazePlayerCharacter Player)
	{
		return TrainInheritMovement.Shape.GetWorldDistanceToShape(TrainInheritMovement.WorldTransform, Player.ActorLocation);
	}

	float GetCartDistanceToLocation(FVector Location)
	{
		return TrainInheritMovement.Shape.GetWorldDistanceToShape(TrainInheritMovement.WorldTransform, Location);
	}

	UHazeSplineComponent GetRailSpline() const property
	{
		if (RailActor == nullptr)
			return nullptr;

		return UHazeSplineComponent::Get(RailActor);
	}

	FSplinePosition FindClosestSplinePosition() const
	{
		auto Spline = RailSpline;
		if (Spline == nullptr)
			return FSplinePosition();

		FSplinePosition Position = Spline.GetClosestSplinePositionToWorldLocation(ActorLocation);
		if (bReverseOnRail)
			Position.ReverseFacing();
		return Position;
	}

	void MoveNiagaraConnectionBeamAnchors()
	{
		// don't update anchors for carts that don't want the connection beam
		if(ConnectionBeam.Asset == nullptr)
			return;

		// final cart
		if(NextCart == nullptr)
			return;

		// Move beam anchor, Start pos.
		// const FVector BeamStart = ConnectionBeam.GetWorldLocation();
		// ConnectionBeam.SetNiagaraVariableVec3("BeamStart", BeamStart);
		// ConnectionBeam.SetNiagaraVariableVec3("BeamStartTangent", ConnectionBeam.ForwardVector);

		/**
		 * Move beam anchor, End pos.
		 * 
		 * Note that here we have to put the BeamEnd into local space of the Owner of the niagara system.
		 * We can't do that inside niagara because the transform is supposedly 1 frame behind so the
		 * effects start lagging behind when the cart goes really fast. 
		 */
		FVector BeamEnd = NextCart.ConnectionBeamAnchor.GetWorldLocation();
		BeamEnd= ConnectionBeam.GetWorldTransform().InverseTransformPosition(BeamEnd);
		FVector BeamEndTangent = NextCart.ConnectionBeamAnchor.ForwardVector;
		BeamEndTangent = ConnectionBeam.GetWorldTransform().InverseTransformVector(BeamEndTangent);

		ConnectionBeam.SetNiagaraVariableVec3("BeamEnd", BeamEnd);
		ConnectionBeam.SetNiagaraVariableVec3("BeamEndTangent", BeamEndTangent);
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		CookChecks::EnsureSplineCanBeUsedOutsideEditor(this, GetRailSpline());

		WobbleUpMultiplier = Math::RandRange(4.0, 8.0);
		WobbleSideMultiplier = Math::RandRange(3.0, 5.0);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		// Lucas, I made this for the bot that shoots (and disconnects) the carts for prototyping. Lets have a look at another potential solution when you see this :D /Per
		FRotator NewRot = FRotator(MeshRootAbsoluteComp.WorldRotation.Pitch, MeshRootAbsoluteComp.WorldRotation.Yaw, 0.0);
		MeshRootAbsoluteComp.SetWorldRotation(NewRot);
	}

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		if (bSnapToRail && RailSpline != nullptr && RailSpline.ComputedSpline.IsValid())
			SnapTo(FindClosestSplinePosition());
	}

	/**
	 * Disconnect the train cart from the train driver so it no longer moves with it.
	 * The cart will continue moving forward at its current speed, decelerating down to 
	 * standstill at the specified u/s^2.
	 */
	UFUNCTION(BlueprintCallable)
	void DisconnectCart(float Deceleration = 200, float InitialDistance = 1200.0, float InitialDistanceDuration = 0.5, float DecelerationDelay = 1.0)
	{
		if (bCartDisconnected)
			return;

		bCartDisconnected = true;
		DisconnectDeceleration = Deceleration;
		DisconnectInitialDistance = InitialDistance;
		DisconnectInitialDistanceDuration = InitialDistanceDuration;
		DisconnectInitialDistanceTimer = 0.0;
		DisconnectDecelerationDelay = DecelerationDelay;
		Niagara::SpawnOneShotNiagaraSystemAttached(DisconnectVFX, ConnectionBeamAnchor);
		Timer::SetTimer(this, n"ExplodeCart", 6);
	}

	UFUNCTION(DevFunction)
	void ExplodeCart()
	{
		Niagara::SpawnOneShotNiagaraSystemAtLocation(TrainDisconnectExplosionVFX, ActorLocation);
		DisableCart();
	}

	UFUNCTION(DevFunction)
	void DisableCart()
	{
		bCartDisabled = true;
		SetActorHiddenInGame(true);
		SetActorEnableCollision(false);
		DisableGrapplePoints(this);

		TArray<AActor> AttachedActors;
		GetAttachedActors(AttachedActors, true, true);

		for (AActor Actor : AttachedActors)
		{
			Actor.AddActorCollisionBlock(this);
			Actor.AddActorVisualsBlock(this);
		}
	}

	void DisableGrapplePoints(FInstigator Instigator)
	{
		TArray<UCoastTrainCartGrapplePointLine> Lines;
		TArray<UGrapplePointBaseComponent> Points;
		TArray<AActor> AttachedActors;

		GetComponentsByClass(Lines);
		for (auto Line : Lines)
			Line.DisableGrapplePointLine(Instigator);

		GetComponentsByClass(Points);
		for (auto Point : Points)
			Point.Disable(Instigator);

		GetAttachedActors(AttachedActors, true, true);
		for (AActor Attach : AttachedActors)
		{
			auto TwistingSpline = Cast<ACoastTrainTwistingGrappleSpline>(Attach);
			if (TwistingSpline != nullptr)
				TwistingSpline.AddActorDisable(this);
		}
	}

	void SnapTo(FSplinePosition SplinePosition)
	{
		CurrentPosition = SplinePosition;
		ActorTransform = SplinePosition.WorldTransform;
	}

	void AddSuspensionImpulse(FVector LocalSpaceImpulse)
	{
		SuspensionVelocity += LocalSpaceImpulse;
	}

	float GetDisconnectOffset() const
	{
		float LinearAlpha = Math::Saturate(DisconnectInitialDistanceTimer / DisconnectInitialDistanceDuration);
		float Alpha = Math::EaseInOut(0.0, 1.0, LinearAlpha, 2.0);

		float DelayAlpha = 0.0;
		if (DisconnectDecelerationDelay != 0.0)
			DelayAlpha = Math::Saturate(DisconnectInitialDistanceTimer / DisconnectDecelerationDelay);

		float Offset = DisconnectInitialDistance * Alpha;
		Offset += Math::Sin(DisconnectInitialDistanceTimer * PI * 1.5) * 200.0 * Math::Pow(1.0 - DelayAlpha, 0.5);
		return Offset;
	}

	void UpdateDisconnectedMovement(float DeltaTime)
	{
		if (DisconnectInitialDistanceTimer > DisconnectDecelerationDelay)
		{
			CurrentMovementSpeed = Math::FInterpConstantTo(
				CurrentMovementSpeed, 0.0, DeltaTime, DisconnectDeceleration
			);
		}

		float PrevOffset = GetDisconnectOffset();
		DisconnectInitialDistanceTimer += DeltaTime;
		float CurOffset = GetDisconnectOffset();

		float Offset = (CurOffset - PrevOffset);

		CurrentPosition.Move(CurrentMovementSpeed * DeltaTime - Offset);
		UpdateMovement(DeltaTime, CurrentPosition);
	}
	
	FQuat GetPredictedRotation(float TimeInFuture) const
	{
		float Spin = CurrentSpin;
		float SpinSpeed = 0.0;
		GetUpdatedSpin(TimeInFuture, CurrentPosition, Spin, SpinSpeed);

		FSplinePosition FuturePosition = CurrentPosition;
		FuturePosition.Move(TimeInFuture * CurrentMovementSpeed);

		FTransform SplineTransform = FuturePosition.WorldTransform;
		FQuat SplineRotation = SplineTransform.Rotation;
		FQuat SpinRotation = SplineRotation * FQuat(FVector::ForwardVector, Math::DegreesToRadians(Spin));
		return SpinRotation;
	}

	private void GetUpdatedSpin(
		float DeltaTime,
		FSplinePosition CartPosition,
		float& OutSpin, float& OutSpinSpeed) const
	{
		float PreviousSpin = OutSpin;

		for (const FCoastTrainSpinRegion& Spin : Driver.ActiveSpins)
		{
			bool bIsWithinSpin = false;
			if (Spin.bHasEnded)
			{
				bIsWithinSpin = CartPosition.IsBetweenPositionsWithPolarity(
					Spin.StartPosition, Spin.EndPosition, ESplineMovementPolarity::Positive
				);
			}
			else
			{
				bIsWithinSpin = CartPosition.IsBetweenPositionsWithPolarity(
					Spin.StartPosition, Driver.CurrentPosition, ESplineMovementPolarity::Positive
				);
			}

			if (bIsWithinSpin)
			{
				if (Spin.bSpinToTarget)
				{
					OutSpin = Math::InterpAngleDegreesConstantTo(
						OutSpin, Spin.SpinTarget, DeltaTime, Spin.SpinSpeed
					);

				}
				else
				{
					OutSpin += Spin.SpinSpeed * DeltaTime;
					OutSpin = Math::Wrap(OutSpin, -180.0, 180.0);
				}
			}
		}

		OutSpinSpeed = Math::FindDeltaAngleDegrees(PreviousSpin, OutSpin) / DeltaTime;
	}

	void UpdateSpin(float DeltaTime, FSplinePosition CartPosition)
	{
		GetUpdatedSpin(DeltaTime, CartPosition,
			CurrentSpin, CurrentSpinSpeed);
	}

	void UpdateMovement(float DeltaTime, FSplinePosition SplinePosition)
	{
		// Update forces applied to suspension
		if (!SuspensionVelocity.IsNearlyZero() || !SuspensionOffset.IsNearlyZero())
		{
			SuspensionVelocity *= Math::Pow(0.01, DeltaTime);
			SuspensionOffset += SuspensionVelocity * DeltaTime;
			SuspensionOffset *= Math::Pow(0.01, DeltaTime);
		}

		// Update wobbling
		WobbleUpTime += WobbleUpMultiplier * DeltaTime;
		float UpSinCurve = Math::Sin(WobbleUpTime);
		WobbleSideTime += WobbleSideMultiplier * DeltaTime;
		float SideSinCurve = Math::Sin(WobbleSideTime);
		FVector Wobble = FVector(0.0, SideSinCurve * 7.0, UpSinCurve * 7.0);

		// Update the position of the cart
		CurrentPosition = SplinePosition;

		FTransform SplineTransform = SplinePosition.WorldTransform;
		FQuat SplineRotation = SplineTransform.Rotation;
		FQuat SpinRotation = SplineRotation * FQuat(FVector::ForwardVector, Math::DegreesToRadians(CurrentSpin));

		// OBS! The train needs to apply teleport physics when it moves.
		// There is a bug in chaos where the collision "disappears" when moving it right now.
		// Teleporting seams to fix this issue. (Tyko)
		bool bTeleportPhysics = true;
		SetActorLocationAndRotation(SplineTransform.TransformPosition(SuspensionOffset + Wobble), SpinRotation, bTeleportPhysics);
	}

	bool IsInBossAttackSafeZone(FVector Location) const
	{
		if (!bBossAttackSafeZone)
			return false;
		FVector SafeZoneCenter = ActorLocation + ActorForwardVector * AttackSafeZoneOffset;
		if (!Location.IsWithinDist(SafeZoneCenter, AttackSafeZoneExtents + 1000.0))
			return false;
		if (Math::Abs(ActorForwardVector.DotProduct(Location - SafeZoneCenter)) > AttackSafeZoneExtents)
			return false;
		return true;
	}

#if EDITOR
	UFUNCTION(BlueprintOverride)
	void OnVisualizeInEditor() const
	{
		if (bBossAttackSafeZone)
		{
			FVector SafeZoneCenter = ActorLocation + ActorForwardVector * AttackSafeZoneOffset;
			FVector SafeZoneExtents = FVector(AttackSafeZoneExtents, 600.0, 600.0);
			Debug::DrawDebugSolidBox(SafeZoneCenter, SafeZoneExtents, ActorRotation, FLinearColor::Green * 0.2);
		}
	}
#endif
}