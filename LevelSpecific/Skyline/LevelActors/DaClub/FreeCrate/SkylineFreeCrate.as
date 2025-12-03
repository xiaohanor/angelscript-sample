class ASkylineFreeCrate : AHazeActor
{

/*
	UPROPERTY(DefaultComponent, RootComponent)
	UCapsuleComponent Collision;
	default Collision.CapsuleHalfHeight = 100.0;
	default Collision.CapsuleRadius = 150.0;
	default Collision.bGenerateOverlapEvents = false;
	default Collision.SetCollisionResponseToAllChannels(ECollisionResponse::ECR_Ignore);
	default Collision.SetCollisionResponseToChannel(ECollisionChannel::ECC_WorldStatic, ECollisionResponse::ECR_Block);
//	default Collision.SetCollisionResponseToChannel(ECollisionChannel::ECC_WorldDynamic, ECollisionResponse::ECR_Block);
	default Collision.SetCollisionResponseToChannel(ECollisionChannel::WorldGeometry, ECollisionResponse::ECR_Block);
*/

	UPROPERTY(DefaultComponent, RootComponent)
	UBoxComponent Collision;
	default Collision.SetBoxExtent(FVector::OneVector * 150.0, false);
	default Collision.bGenerateOverlapEvents = false;
	default Collision.SetCollisionResponseToAllChannels(ECollisionResponse::ECR_Ignore);
	default Collision.SetCollisionResponseToChannel(ECollisionChannel::ECC_WorldStatic, ECollisionResponse::ECR_Block);
//	default Collision.SetCollisionResponseToChannel(ECollisionChannel::ECC_WorldDynamic, ECollisionResponse::ECR_Block);
	default Collision.SetCollisionResponseToChannel(ECollisionChannel::WorldGeometry, ECollisionResponse::ECR_Block);

/*
	UPROPERTY(DefaultComponent, RootComponent)
	USphereComponent Collision;
	default Collision.SphereRadius = 150.0;
	default Collision.bGenerateOverlapEvents = false;
	default Collision.SetCollisionResponseToAllChannels(ECollisionResponse::ECR_Ignore);
	default Collision.SetCollisionResponseToChannel(ECollisionChannel::ECC_WorldStatic, ECollisionResponse::ECR_Block);
//	default Collision.SetCollisionResponseToChannel(ECollisionChannel::ECC_WorldDynamic, ECollisionResponse::ECR_Block);
	default Collision.SetCollisionResponseToChannel(ECollisionChannel::WorldGeometry, ECollisionResponse::ECR_Block);
*/

	UPROPERTY(DefaultComponent)
	UPlayerInheritMovementComponent InheritMovementComp;
	default InheritMovementComp.Shape.BoxExtents = FVector::OneVector * 200.0;
	default InheritMovementComp.Shape.Type = EHazeShapeType::Box;

	UPROPERTY(DefaultComponent)
	UMovementImpactCallbackComponent MovementImpactCallbackComp;

	UPROPERTY(DefaultComponent)
	UGravityWhipTargetComponent WhipTargetComp;

	UPROPERTY(DefaultComponent, Attach = WhipTargetComp)
	UTargetableOutlineComponent WhipOutlineComp;

	UPROPERTY(DefaultComponent)
	UCapsuleComponent BladeCollision;
	default BladeCollision.CapsuleHalfHeight = 150.0;
	default BladeCollision.CapsuleRadius = 20.0;
	default BladeCollision.bGenerateOverlapEvents = false;
	default BladeCollision.SetCollisionResponseToAllChannels(ECollisionResponse::ECR_Ignore);
	default BladeCollision.SetCollisionResponseToChannel(ECollisionChannel::WeaponTraceMio, ECollisionResponse::ECR_Block);

	UPROPERTY(DefaultComponent)
	UGravityBladeCombatTargetComponent BladeCombatTargetComp;

	UPROPERTY(DefaultComponent, Attach = BladeCombatTargetComp)
	UTargetableOutlineComponent BladeOutlineComp;

	UPROPERTY(DefaultComponent)
	UHazeMovementComponent MoveComp;
	default MoveComp.bAllowUsingBoxCollisionShape = true;
	USweepingMovementData Movement;

	UPROPERTY(DefaultComponent)
	UGravityWhipResponseComponent WhipResponseComp;
	default WhipResponseComp.bAllowMultiGrab = false;
	default WhipResponseComp.ImpulseMultiplier = 0.0;
	default WhipResponseComp.OffsetDistance = 500.0;
	default WhipResponseComp.ForceMultiplier = 0.5;

	UPROPERTY(DefaultComponent)
	UGravityBladeCombatResponseComponent BladeCombatResponseComp;

	UPROPERTY(DefaultComponent)
	UMoveIntoPlayerShapeComponent MoveIntoPlayerShapeComp;

	UPROPERTY(DefaultComponent)
	USkylineInterfaceComponent InterfaceComp;

	UPROPERTY(EditAnywhere)
	UHazeCameraSpringArmSettingsDataAsset CameraSettings;

	float Drag = 0.5;
	float GroundDrag = 6.0;
	FVector Gravity = FVector::UpVector * -980.0 * 3.0;

	FVector Origin;
	UPROPERTY(EditAnywhere)
	float StrapLength = 600.0;
	bool bConstrained = true;

	TArray<AHazePlayerCharacter> ImpactingPlayers;
	float ImpactForce = 0.0;

	AHazePlayerCharacter GrabbingPlayer;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		MoveComp.AddMovementIgnoresActor(this, Game::Mio);

		Origin = ActorRelativeLocation + ActorUpVector * StrapLength;

		Movement = MoveComp.SetupSweepingMovementData();

		MovementImpactCallbackComp.OnGroundImpactedByPlayer.AddUFunction(this, n"HandleGroundImpactedByPlayer");
		MovementImpactCallbackComp.OnGroundImpactedByPlayerEnded.AddUFunction(this, n"HandleGroundImpactedByPlayerEnded");
		BladeCombatResponseComp.OnHit.AddUFunction(this, n"HandleHit");
		WhipResponseComp.OnGrabbed.AddUFunction(this, n"HandleGrabbed");
		WhipResponseComp.OnReleased.AddUFunction(this, n"HandleReleased");
	}

	UFUNCTION()
	private void HandleGrabbed(UGravityWhipUserComponent UserComponent, UGravityWhipTargetComponent TargetComponent, TArray<UGravityWhipTargetComponent> OtherComponents)
	{
		GrabbingPlayer = Cast<AHazePlayerCharacter>(UserComponent.Owner);
		GrabbingPlayer.ApplyCameraSettings(CameraSettings, 2.0, this, EHazeCameraPriority::VeryHigh);
	}

	UFUNCTION()
	private void HandleReleased(UGravityWhipUserComponent UserComponent, UGravityWhipTargetComponent TargetComponent, FVector Impulse)
	{
		GrabbingPlayer.ClearCameraSettingsByInstigator(this, 2.0);
		GrabbingPlayer = nullptr;
	}

	UFUNCTION()
	private void HandleHit(UGravityBladeCombatUserComponent CombatComp, FGravityBladeHitData HitData)
	{
		bConstrained = false;
		BladeCombatTargetComp.Disable(this);
		BladeCollision.CollisionEnabled = ECollisionEnabled::NoCollision;
		BP_BladeHit();

		WhipResponseComp.ForceMultiplier = 2.0;

		InterfaceComp.TriggerActivate();
	}

	UFUNCTION()
	private void HandleGroundImpactedByPlayer(AHazePlayerCharacter Player)
	{
		ImpactingPlayers.Add(Player);
		WhipTargetComp.DisableForPlayer(Player, this);
	}

	UFUNCTION()
	private void HandleGroundImpactedByPlayerEnded(AHazePlayerCharacter Player)
	{
		ImpactingPlayers.Remove(Player);
		WhipTargetComp.EnableForPlayer(Player, this);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (MoveComp.PrepareMove(Movement))
		{
			if (HasControl())
			{
				FVector Velocity = MoveComp.Velocity;

				FVector WhipForce = WhipTargetComp.ConsumeForce();


				if (!bConstrained && GrabbingPlayer != nullptr)
				{
					FVector ToGrabbingPlayer = GrabbingPlayer.ActorLocation - ActorLocation;
					FVector RotationAxis = ToGrabbingPlayer.CrossProduct(GrabbingPlayer.ActorUpVector).SafeNormal;


//					WhipForce = WhipForce.RotateAngleAxis(90.0, RotationAxis);
//					WhipForce = WhipForce.VectorPlaneProject(ActorUpVector);
//					FVector ExtraTurnForce = WhipForce.ProjectOnToNormal(RotationAxis);
//					WhipForce *= (FVector::OneVector + ExtraTurnForce);
//					Debug::DrawDebugLine(ActorLocation, ActorLocation + ExtraTurnForce * 500.0, FLinearColor::Yellow, 10.0, 0.0);

					WhipForce = WhipForce.VectorPlaneProject(FVector::UpVector);

//					Debug::DrawDebugLine(ActorLocation, ActorLocation + ToGrabbingPlayer, FLinearColor::Red, 10.0, 0.0);
//					Debug::DrawDebugLine(ActorLocation, ActorLocation + RotationAxis * 1000.0, FLinearColor::Green, 10.0, 0.0);
				}



//				Debug::DrawDebugLine(ActorLocation, ActorLocation + WhipForce, FLinearColor::Yellow, 10.0, 0.0);

				FVector Acceleration = WhipForce
									 + Gravity
									 + PlayerImpactForce
									 - MoveComp.Velocity * (MoveComp.HasGroundContact() ? GroundDrag : Drag);

				PrintToScreen("Ground: "  + MoveComp.HasGroundContact(), 0.0);

				Velocity += Acceleration * DeltaSeconds;

				FVector DeltaMove = Velocity * DeltaSeconds;
				FVector NewLocation = ActorLocation + DeltaMove;
				FVector OriginToNewLocation = NewLocation - Origin;

				// Hitting contraint and calculating new delta
				if (bConstrained && OriginToNewLocation.Size() > StrapLength)
				{
					NewLocation = Origin + OriginToNewLocation.SafeNormal * StrapLength;
					DeltaMove = NewLocation - ActorLocation;
				}

				FQuat Rotation = FQuat::MakeFromZX((bConstrained ? -OriginToNewLocation : FVector::UpVector), FVector::ForwardVector);

				if (bConstrained)
					Rotation = FQuat::MakeFromZX(-OriginToNewLocation, FVector::ForwardVector);
/*
				else if (GrabbingPlayer != nullptr)
				{
					FVector ToGrabbingPlayer = GrabbingPlayer.ViewLocation - ActorLocation;
					ToGrabbingPlayer = ToGrabbingPlayer.VectorPlaneProject(FVector::UpVector);
					Rotation = FQuat::MakeFromXZ(ToGrabbingPlayer, FVector::UpVector);
				}
*/
				Movement.SetRotation(Rotation);
				Movement.AddDelta(DeltaMove);
			}
			// Remote update
			else
			{
				Movement.ApplyCrumbSyncedGroundMovement();
			}

			MoveComp.ApplyMove(Movement);
		}		
	}

	FVector GetPlayerImpactForce() property
	{
		FVector Force = FVector::ZeroVector;
		for (auto ImpactingPlayer : ImpactingPlayers)
			Force += -ImpactingPlayer.MovementWorldUp * ImpactForce;
	
		return Force;
	}

	UFUNCTION(BlueprintEvent)
	void BP_BladeHit()
	{

	}
};