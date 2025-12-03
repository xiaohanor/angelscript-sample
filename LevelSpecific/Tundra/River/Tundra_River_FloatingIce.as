class ATundra_River_FloatingIce : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UFauxPhysicsConeRotateComponent FPConeRotationComp;
	default FPConeRotationComp.ForceScalar = 1;
	default FPConeRotationComp.Friction = 20;
	default FPConeRotationComp.SpringStrength = 0.1;
	default FPConeRotationComp.ConeAngle = 20;
	default FPConeRotationComp.ConstrainBounce = 0;

	UPROPERTY(DefaultComponent, Attach = FPConeRotationComp)
	UFauxPhysicsTranslateComponent FPTranslateComp;
	default FPTranslateComp.ForceScalar = 2;
	default FPTranslateComp.Friction = 8;
	default FPTranslateComp.bConstrainX = true;
	default FPTranslateComp.bConstrainY = true;
	default FPTranslateComp.bConstrainZ = true;
	default FPTranslateComp.MinZ = -250;
	default FPTranslateComp.SpringStrength = 5;

	UPROPERTY()
	FHazeTimeLike MovingUpAnimation;	
	default MovingUpAnimation.Duration = 3;
	default MovingUpAnimation.Curve.AddDefaultKey(0.0, 0.0);
	default MovingUpAnimation.Curve.AddDefaultKey(2.0, 1.0);
	default MovingUpAnimation.Curve.AddDefaultKey(3.0, 1.0);
	
	UPROPERTY()
	FHazeTimeLike MovingDownAnimation;	
	default MovingDownAnimation.Duration = 2;
	default MovingDownAnimation.Curve.AddDefaultKey(0.0, 1.0);
	default MovingDownAnimation.Curve.AddDefaultKey(2.0, 0.0);

	UPROPERTY(EditInstanceOnly)
	TArray<ATundra_River_FloatingIce_AttachRope> AttachRopes;
	FVector StartLocation;
	TArray<FVector> UntetherLocations;

	UPROPERTY(DefaultComponent, Attach = Root)
	UBillboardComponent WaterSurface;
	default WaterSurface.RelativeLocation = FVector(0,0,300);

	FVector WaterSurfaceWorldLocation;

	bool bIsAttachedToBottom = false;
	
	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedComponent;

	UPROPERTY()
	bool bMioIsOverlapping = false;

	UPROPERTY()
	bool bZoeIsOverlapping = false;

	UPROPERTY(DefaultComponent, Attach = FPTranslateComp)
	UStaticMeshComponent Mesh;

	UPROPERTY(DefaultComponent)
	UTundraPlayerSnowMonkeyGroundSlamResponseComponent GroundSlamComponent;

	UPROPERTY(DefaultComponent)
	UMovementImpactCallbackComponent MovementImpactCallbackComp;

	TArray<UTundraPlayerShapeshiftingComponent> OverlappingShapeShiftingComponents;

	UPROPERTY(EditInstanceOnly)
	float SmallMultiplier = 0.2;

	UPROPERTY(EditInstanceOnly)
	float PlayerMultiplier = 1;

	UPROPERTY(EditInstanceOnly)
	float BigMultiplier = 1.5;

	UPROPERTY(EditInstanceOnly)
	float Force = 100;

	UPROPERTY(EditAnywhere)
	float GroundSlamImpulse = 500;

	UPROPERTY(EditAnywhere)
	float AirborneGroundSlamImpulse = 3000;

	UPROPERTY(EditInstanceOnly)
	float Depth;

	bool bHasBreachedWater = false;

	UPROPERTY(EditInstanceOnly)
	bool bSpawnedFromStart = true;

	bool bIsSpawned = true;

	bool bHasReachedTop = false;
	bool bIsTemporarilyDown = false;
	float TempDownTimer = 0;
	float MaxTempDownTimer = 5;

	UPROPERTY(EditInstanceOnly)
	TArray<AActor> ActorsAttachedToPlatform;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		MovementImpactCallbackComp.OnGroundImpactedByPlayer.AddUFunction(this, n"HandlePlayerStartGroundImpact");
		MovementImpactCallbackComp.OnGroundImpactedByPlayerEnded.AddUFunction(this, n"HandlePlayerEndGroundImpact");
		GroundSlamComponent.OnGroundSlam.AddUFunction(this, n"HandleGroundSlam");
		WaterSurfaceWorldLocation = WaterSurface.WorldLocation;

		if(AttachRopes.Num() > 0)
		{
			bIsAttachedToBottom = true;
			for(auto Rope : AttachRopes)
			{
				Rope.Untethered.AddUFunction(this, n"HandleAttachRopeDetached");
			}
		}

		StartLocation = GetActorLocation();
		MovingUpAnimation.BindUpdate(this, n"TL_MovingUpAnimationUpdate");
		MovingUpAnimation.BindFinished(this, n"TL_MovingUpAnimationFinished");
		MovingDownAnimation.BindUpdate(this, n"TL_MovingDownAnimationUpdate");
		MovingDownAnimation.BindFinished(this, n"TL_MovingDownAnimationFinished");

		for(auto Actor : ActorsAttachedToPlatform)
		{
			Actor.AttachToComponent(Mesh, n"None", EAttachmentRule::KeepWorld, EAttachmentRule::KeepWorld, EAttachmentRule::KeepWorld, true);
		}

		if(!bSpawnedFromStart)
		{
			SetActorEnableCollision(false);
			SetActorHiddenInGame(true);
			bIsSpawned = false;

			for(auto Actor : ActorsAttachedToPlatform)
			{
				Actor.SetActorEnableCollision(false);
				Actor.SetActorHiddenInGame(true);
			}
		}
	}

	UFUNCTION()
	private void TL_MovingDownAnimationFinished()
	{
		SetActorLocation(Math::Lerp(StartLocation, StartLocation + FVector(0,0,Depth), 0));
		TempDownTimer = MaxTempDownTimer;
	}

	UFUNCTION()
	private void TL_MovingDownAnimationUpdate(float CurrentValue)
	{
		SetActorLocation(Math::Lerp(StartLocation, StartLocation + FVector(0,0,Depth), CurrentValue));
	}

	UFUNCTION()
	void TL_MovingUpAnimationFinished()
	{
		UTundra_River_FloatingIce_EffectHandler::Trigger_StopMoving(this);
		bHasReachedTop = true;
	}

	UFUNCTION(CrumbFunction)
	void CrumbSpawnPlatform(bool bTriggerMovement)
	{
		SpawnPlatform(bTriggerMovement);
	}

	UFUNCTION()
	void SpawnPlatform(bool bTriggerMovement)
	{
		bIsSpawned = true;
		SetActorEnableCollision(true);
		SetActorHiddenInGame(false);

		for(auto Actor : ActorsAttachedToPlatform)
		{
			Actor.SetActorEnableCollision(true);
			Actor.SetActorHiddenInGame(false);
		}

		if(bTriggerMovement)
		{
			MovingUpAnimation.PlayFromStart();
			UTundra_River_FloatingIce_EffectHandler::Trigger_StartMoving(this);
			bHasBreachedWater = false;
		}
	}

	UFUNCTION()
	void TemporarilySendDown()
	{
		bHasReachedTop = false;
		bHasBreachedWater = false;
		MovingDownAnimation.PlayFromStart();
	}

	UFUNCTION()
	void DespawnPlatform()
	{
		bIsSpawned = false;
		SetActorEnableCollision(false);
		SetActorHiddenInGame(true);

		for(auto Actor : ActorsAttachedToPlatform)
		{
			Actor.SetActorEnableCollision(false);
			Actor.SetActorHiddenInGame(true);
		}
	}

	UFUNCTION()
	void TL_MovingUpAnimationUpdate(float CurveValue)
	{
		SetActorLocation(Math::Lerp(StartLocation, StartLocation + FVector(0,0,Depth), CurveValue));

		if(!bHasBreachedWater && (GetActorLocation().Z + 75 > WaterSurfaceWorldLocation.Z))
		{
			bHasBreachedWater = true;
			UTundra_River_FloatingIce_EffectHandler::Trigger_BreachWater(this);
		}
	}

	UFUNCTION()
	void HandleAttachRopeDetached(ATundra_River_FloatingIce_AttachRope AttachRope)
	{
		UntetherLocations.AddUnique(AttachRope.Cable_Top.GetWorldLocation());
		if(CheckIfAllRopesAreUntethered())
		{
			bIsAttachedToBottom = false;
			MovingUpAnimation.PlayFromStart();
			UTundra_River_FloatingIce_EffectHandler::Trigger_StartMoving(this);
			bHasBreachedWater = false;
		}

		UTundra_River_FloatingIce_EffectHandler::Trigger_OnRopeDetached(this);
	}

	UFUNCTION()
	bool CheckIfAllRopesAreUntethered()
	{
		for(auto Rope : AttachRopes)
		{
			if(!Rope.bCompleted)
				return false;
		}
		return true;
	}

	UFUNCTION()
	void HandleGroundSlam(ETundraPlayerSnowMonkeyGroundSlamType Type, FVector PlayerLocation)
	{
		FVector SlamForce = FVector(0,0,0);
		switch(Type)
		{
			case ETundraPlayerSnowMonkeyGroundSlamType::Grounded:
				SlamForce = FVector(0,0,-GroundSlamImpulse);
				break;
			
			case ETundraPlayerSnowMonkeyGroundSlamType::Airborne:
				SlamForce = FVector(0,0,-AirborneGroundSlamImpulse);
				break;

		}
		FauxPhysics::ApplyFauxImpulseToActorAt(this, PlayerLocation, SlamForce);

		UTundra_River_FloatingIce_EffectHandler::Trigger_OnSnowMonkeyGroundSlam(this);
	}

	UFUNCTION()
	void HandlePlayerEndGroundImpact(AHazePlayerCharacter Player)
	{
		if(Player.IsMio())
		{
			bMioIsOverlapping = false;
		}

		else if(Player.IsZoe())
		{
			bZoeIsOverlapping = false;
		}

		UTundraPlayerShapeshiftingComponent TempShapeShiftComp = UTundraPlayerShapeshiftingComponent::Get(Player);
		if(TempShapeShiftComp == nullptr)
			return;

		OverlappingShapeShiftingComponents.Remove(TempShapeShiftComp);
	}

	UFUNCTION()
	void HandlePlayerStartGroundImpact(AHazePlayerCharacter Player)
	{
		if(Player.IsMio())
		{
			bMioIsOverlapping = true;
		}

		else if(Player.IsZoe())
		{
			bZoeIsOverlapping = true;
		}

		UTundraPlayerShapeshiftingComponent TempShapeShiftComp = UTundraPlayerShapeshiftingComponent::Get(Player);
		if(TempShapeShiftComp == nullptr)
			return;

		OverlappingShapeShiftingComponents.AddUnique(TempShapeShiftComp);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(bIsAttachedToBottom)
		{
			for(auto Location : UntetherLocations)
			{
				FauxPhysics::ApplyFauxForceToActorAt(this, Location, FVector(0,0,300));
			}
		}

		else
		{
			for(auto ShapeShiftComp : OverlappingShapeShiftingComponents)
			{
				float ForceMultiplier = 0;
				switch(ShapeShiftComp.GetCurrentShapeType())
				{
					case ETundraShapeshiftShape::None:
						ForceMultiplier = 1;
						break;

					case ETundraShapeshiftShape::Small:
						ForceMultiplier = SmallMultiplier;
						break;

					case ETundraShapeshiftShape::Player:
						ForceMultiplier = PlayerMultiplier;
						break;

					case ETundraShapeshiftShape::Big:
						ForceMultiplier = BigMultiplier;
						break;
				}

				FVector WorldLocation = ShapeShiftComp.GetOwner().GetActorLocation();
				FVector ForceToApply = (-ShapeShiftComp.GetOwner().GetActorUpVector())*Force*ForceMultiplier;


				FauxPhysics::ApplyFauxForceToActorAt(this, WorldLocation, ForceToApply);
			}
		}

		if(TempDownTimer > 0)
		{
			TempDownTimer -= DeltaSeconds;
			if(TempDownTimer <= 0)
			{
				MovingUpAnimation.PlayFromStart();
				UTundra_River_FloatingIce_EffectHandler::Trigger_StartMoving(this);
			}
		}
	}
}

// For managers, it can be helpful to add a helper function to look it up from the list:
namespace TundraFloatingIce
{
	// Get the example listed actor in the level
	UFUNCTION()
	TArray<ATundra_River_FloatingIce> GetAllTundraFloatingIce()
	{
		return TListedActors<ATundra_River_FloatingIce>().Array;
	}
}