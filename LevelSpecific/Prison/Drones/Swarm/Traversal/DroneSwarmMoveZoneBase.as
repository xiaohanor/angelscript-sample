struct FSwarmDroneMoveZoneLocationInfo
{
	float HeightInVolume;
	float HeightFraction;

	float ZoneHeight;
}

UCLASS(Abstract)
class ADroneSwarmMoveZone : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent, ShowOnActor)
	protected UDroneSwarmMovementZoneComponent MovementZoneComponent;

	UPROPERTY(DefaultComponent)
	private UArrowComponent MoveDirection;
	default MoveDirection.SetWorldRotation(ActorUpVector.Rotation());
	default MoveDirection.ArrowSize = 2.0;
	default MoveDirection.ArrowColor = FLinearColor::LucBlue;

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 10000;

	UPROPERTY(BlueprintReadWrite)
	bool bZoneEnabled = false;

	UPROPERTY()
	protected UPlayerSwarmDroneComponent ActiveSwarmDroneComponent;

#if EDITOR
	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		MoveDirection.SetRelativeLocation(FVector(0.0, 0.0, -MovementZoneComponent.Shape.BoxExtents.Z));
		MoveDirection.ArrowLength = MovementZoneComponent.Shape.BoxExtents.Z;

		UShapeComponent Shape;
		switch (MovementZoneComponent.Shape.Type)
		{
			case EHazeShapeType::Sphere:
			{
				auto SphereShape = USphereComponent::GetOrCreate(this, n"SphereShape");
				SphereShape.SetSphereRadius(MovementZoneComponent.Shape.SphereRadius);
				Shape = SphereShape;
				break;
			}
			case EHazeShapeType::Box:
			{
				auto BoxShape = UBoxComponent::GetOrCreate(this, n"BoxShape");
				BoxShape.SetBoxExtent(MovementZoneComponent.Shape.BoxExtents);
				Shape = BoxShape;

			MoveDirection.SetRelativeLocation(FVector(0.0, 0.0, -MovementZoneComponent.Shape.BoxExtents.Z));
			MoveDirection.ArrowLength = MovementZoneComponent.Shape.BoxExtents.Z;

				break;
			}
			case EHazeShapeType::Capsule:
			{
				auto CapsuleShape = UCapsuleComponent::GetOrCreate(this, n"CapsuleShape");
				CapsuleShape.SetCapsuleSize(MovementZoneComponent.Shape.CapsuleRadius, MovementZoneComponent.Shape.CapsuleHalfHeight);
				Shape = CapsuleShape;

				MoveDirection.SetRelativeLocation(FVector(0.0, 0.0, -MovementZoneComponent.Shape.CapsuleHalfHeight));
				MoveDirection.ArrowLength = MovementZoneComponent.Shape.CapsuleHalfHeight;

				break;
			}
			case EHazeShapeType::None:
			break;
		}

		Shape.SetCollisionEnabled(ECollisionEnabled::NoCollision);
		Shape.SetHiddenInGame(true, true);
		Shape.SetComponentTickEnabled(false);
		Shape.ShapeColor = FLinearColor::LucBlue.ToFColor(true);
	}
#endif 

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SetActorControlSide(Game::Mio);

		MovementZoneComponent.OnPlayerEnter.AddUFunction(this, n"OnZoneEnter");
		MovementZoneComponent.OnPlayerLeave.AddUFunction(this, n"OnZoneExit");
	}

// #if EDITOR
// 	UFUNCTION(BlueprintOverride)
// 	void Tick(float DeltaSeconds)
// 	{
// 		UShapeComponent Shape = UShapeComponent::Get(this);
// 		if (Shape != nullptr)
// 			Shape.SetHiddenInGame(true);
// 	}
// #endif

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason EndPlayReason)
	{
		if (ActiveSwarmDroneComponent != nullptr)
			ActiveSwarmDroneComponent = nullptr;
	}

	UFUNCTION()
	void Activate()
	{
		MovementZoneComponent.EnableTrigger(this);
		USwarmDroneHoverZoneEventHandler::Trigger_OnEnabled(this);

		bZoneEnabled = true;
	}

	UFUNCTION()
	void Deactivate()
	{
		MovementZoneComponent.DisableTrigger(this);
		USwarmDroneHoverZoneEventHandler::Trigger_OnDisabled(this);

		bZoneEnabled = false;
	}

	UFUNCTION(NotBlueprintCallable)
	private void OnZoneEnter(AHazePlayerCharacter OtherActor)
	{
		ActiveSwarmDroneComponent = UPlayerSwarmDroneComponent::Get(OtherActor);
		ActiveSwarmDroneComponent.ActiveSwarmMoveZones.AddUnique(this);

		ADroneSwarmHoverZone HoverZone = Cast<ADroneSwarmHoverZone>(this);
		if(HoverZone != nullptr)
		{
			// Notify audio that a player has entered a HoverZone
			USwarmDroneHoverZoneEventHandler::Trigger_OnPlayerEnter(this, FSwarmDroneHoverZonePlayerParams(OtherActor));
		}
	}

	UFUNCTION(NotBlueprintCallable)
	private void OnZoneExit(AHazePlayerCharacter OtherActor)
	{
		// Will be null on end play
		if (ActiveSwarmDroneComponent != nullptr)
		{
			ActiveSwarmDroneComponent.ActiveSwarmMoveZones.Remove(this);
			ActiveSwarmDroneComponent = nullptr;
		}

		ADroneSwarmHoverZone HoverZone = Cast<ADroneSwarmHoverZone>(this);
		if(HoverZone != nullptr)
		{
			// Notify audio that a player has exited a HoverZone
			USwarmDroneHoverZoneEventHandler::Trigger_OnPlayerExit(this, FSwarmDroneHoverZonePlayerParams(OtherActor));
		}
	}

	FVector CalculateAccelerationAtLocation(FVector WorldLocation) const
	{
		return FVector::ZeroVector;
	}

	FVector CalculateDrag(FVector Velocity, FVector WorldLocation, FVector WorldUp) const
	{
		return FVector::ZeroVector;
	}

	FVector GetMoveDirection() const
	{
		return MoveDirection.ForwardVector;
	}

	FSwarmDroneMoveZoneLocationInfo GetZoneInfoAtLocation(FVector WorldLocation) const
	{
		const float ZoneHalfHeight = MovementZoneComponent.Shape.BoxExtents.Z;

		FSwarmDroneMoveZoneLocationInfo LocationInfo;
		LocationInfo.ZoneHeight = ZoneHalfHeight * 2;

		FVector ShapeBase = ActorLocation - ActorUpVector * ZoneHalfHeight;
		LocationInfo.HeightInVolume = Math::Abs(WorldLocation.Z - ShapeBase.Z);

		LocationInfo.HeightFraction = Math::Saturate(LocationInfo.HeightInVolume / (ZoneHalfHeight * 2.0));

		return LocationInfo;
	}

	FVector GetZonePeak() const
	{
		FVector Peak = ActorLocation + ActorUpVector * MovementZoneComponent.Shape.BoxExtents.Z;
		return Peak;
	}

	float GetMoveFractionAtLocation(FVector WorldLocation) const
	{
		float MoveFraction = GetZoneInfoAtLocation(WorldLocation).HeightFraction;

		/** Eman TODO: Fucking hell this is disgusting but can't be solved without full reimplementation (for after uxr).
		 * -------------------------------------------------------------------------------------------------------------
		 * Patches of whitewater during boat sections were wrongfully implemented as MoveZones (BP_DroneSwarmWaterRapidFloatZone),
		 * this is wrong and needs to be reworked. Do a hack for now.
		 */

		// ⚠ ⚠ ⚠ Gross ⚠ ⚠ ⚠ 
		if (ActorHasTag(n"TEMP_RapidFloatZone"))
			MoveFraction = Math::Min(MoveFraction, 0.8);
		// ⚠ ⚠ ⚠ Gross ⚠ ⚠ ⚠ 


		// 50 pesetos says this ^ is gonna ship

		return MoveFraction;
	}

	void DebugDrawZone(float Duration = 0)
	{
		Debug::DrawDebugShape(MovementZoneComponent.Shape.CollisionShape, MovementZoneComponent.Bounds.Origin, MovementZoneComponent.WorldRotation, FLinearColor::Teal, 3, Duration);
	}

	UFUNCTION(BlueprintPure)
	AHazePlayerCharacter GetCurrentPlayerInsideZone() const
	{
		if (!IsPlayerInsideZone())
			return nullptr;

		return Cast<AHazePlayerCharacter>(ActiveSwarmDroneComponent.Owner);
	}

	UFUNCTION(BlueprintPure)
	bool IsPlayerInsideZone() const
	{
		return ActiveSwarmDroneComponent != nullptr;
	}
}