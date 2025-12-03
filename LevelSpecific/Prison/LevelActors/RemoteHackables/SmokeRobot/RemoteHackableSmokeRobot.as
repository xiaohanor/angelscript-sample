namespace Prison
{
	namespace RemoteHackableSmokeRobot
	{
		const float MaxAcceleration = 1000.0;
		const float Drag = 1.2;
	}
}

UCLASS(Abstract)
class ARemoteHackableSmokeRobot : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UCapsuleComponent CapsuleComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent HoverRoot;

	UPROPERTY(DefaultComponent, Attach = HoverRoot)
	UPoseableMeshComponent SkelMeshComp;

	UPROPERTY(DefaultComponent, Attach = HoverRoot)
	UHazeSphereComponent HazeSphereComp;

	UPROPERTY(DefaultComponent, Attach = HoverRoot)
	UPointLightComponent PointLightComp;

	UPROPERTY(DefaultComponent, Attach = HoverRoot)
	UNiagaraComponent SmokeComp;

	UPROPERTY(DefaultComponent)
	UHazeMovementComponent MoveComp;

	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComp;
	default CapabilityComp.DefaultCapabilities.Add(n"RemoteHackableSmokeRobotCapability");

	UPROPERTY(DefaultComponent, Attach = HoverRoot)
	URemoteHackingResponseComponent RemoteHackingResponseComp;

	UPROPERTY(DefaultComponent)
	UHazeCrumbSyncedActorPositionComponent SyncedActorPosition;
	default SyncedActorPosition.SyncDetailLevel = EHazeActorPositionSyncDetailLevel::Character;

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;

	UPROPERTY(EditAnywhere)
	float MaxLaserDistance = 6000.0;

	USweepingMovementData Movement;
	FVector PlayerForward;
	FVector PlayerRight;

	float UpperRingRot = 0.0;
	float LowerRingRot = 0.0;
	float MinRingRotSpeed = 20.0;
	float MaxRingRotSpeed = 180.0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SetActorControlSide(Game::Mio);

		if (AttachParentActor != nullptr)
			DetachFromActor(EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld);

		Movement = MoveComp.SetupSweepingMovementData();
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (MoveComp.PrepareMove(Movement))
		{
			if (HasControl())
			{
				FVector Velocity = MoveComp.Velocity;
				Velocity += (PlayerForward + PlayerRight) * DeltaTime;

				const float IntegratedDragFactor = Math::Exp(-Prison::RemoteHackableSmokeRobot::Drag);
				Velocity = Velocity * Math::Pow(IntegratedDragFactor, DeltaTime);
				
				Velocity = Velocity.ConstrainToPlane(FVector::UpVector);

				Movement.AddVelocity(Velocity);
			}
			else
			{
				// Since we normally don't want to replicate velocity, we use move since last frame instead.
				// This can fluctuate wildly, introduce smoothing/velocity replication if necessary
				Movement.ApplyCrumbSyncedAirMovement();
			}

			MoveComp.ApplyMove(Movement);
		}

		float HoverOffset = Math::Sin(Time::GameTimeSeconds * 1.2) * 12.0;
		HoverRoot.SetRelativeLocation(FVector(0.0, 0.0, HoverOffset));

		float RingRotSpeed = Math::GetMappedRangeValueClamped(FVector2D(0.0, 700.0), FVector2D(MinRingRotSpeed, MaxRingRotSpeed), GetSpeed());
		UpperRingRot = Math::Wrap(UpperRingRot + (RingRotSpeed * DeltaTime), 0.0, 360.0);
		LowerRingRot = Math::Wrap(LowerRingRot - (RingRotSpeed * DeltaTime), 0.0, 360.0);
		SkelMeshComp.SetBoneRotationByName(n"UpperRing", FRotator(0.0, UpperRingRot, 0.0), EBoneSpaces::ComponentSpace);
		SkelMeshComp.SetBoneRotationByName(n"LowerRing", FRotator(0.0, LowerRingRot, 0.0), EBoneSpaces::ComponentSpace);
	}

	void UpdatePlayerInput(FVector Fwd, FVector Right)
	{
		PlayerForward = Fwd;
		PlayerRight = Right;
	}

	UFUNCTION(BlueprintPure)
	bool IsHacked() const
	{
		return RemoteHackingResponseComp.bHacked;
	}

	UFUNCTION(BlueprintPure)
	float GetYawSpeed() const
	{
		if(!RemoteHackingResponseComp.bHacked)
			return 0;

		AHazePlayerCharacter HackingPlayer = RemoteHackingResponseComp.HackingPlayer;
		return Math::Abs(HackingPlayer.ViewAngularVelocity.Yaw);
	}

	UFUNCTION(BlueprintPure)
	float GetSpeed() const
	{
		return ActorVelocity.Size();
	}
}