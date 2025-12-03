
class UPlayerWallRunComponent : UActorComponent
{
	access TransferInternalWithCapability = private, UPlayerWallRunTransferCapability;

	AHazePlayerCharacter OwningPlayer;

	UPlayerWallRunSettings Settings;
	UPlayerWallRunJumpSettings JumpSettings;
	UPlayerWallRunTransferSettings TransferSettings;
	UPlayerWallRunLedgeClimbSettings ClimbSettings;
	UPlayerWallSettings WallSettings;

	protected EPlayerWallRunState CurrentState = EPlayerWallRunState::None;

	bool bWallRunAvailableUntilGrounded = true;	
	bool bHasWallRunnedSinceLastGrounded = false;
	FVector LastWallRunNormal;
	FVector InitialWallRunHeightLimitLocation;
	float LastWallRunStartTime = 0.0;

	UPROPERTY()
	UHazeCameraSpringArmSettingsDataAsset CameraSettings;

	FPlayerWallRunData ActiveData;
	FPlayerWallRunData PreviousData;
	FPlayerWallRunClimbData ClimbData;
	FPlayerWallRunLedgeTurnaroundData LedgeTurnaroundData;

	UPROPERTY(EditDefaultsOnly, Category = "ForceFeedback")
	UForceFeedbackEffect FF_WallrunJumpOut;

	UPROPERTY(BlueprintReadOnly)
	FPlayerWallRunAnimationData AnimData;
	/* ------------------- */

	// Time after the air dash ends that we still do dash-enter
	const float DashEnterGraceTime = 0.2;
	// If we convert an air dash into a wall run, if the air dash lasted shorter than this time, refresh it
	const float DashRefreshThresholdTime = 0.1666;

	private float GraceTransferWindowInitiatedAt = 0;
	private bool bAllowGraceTransfer = false;
	FRotator StoredGraceWallRotation;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		OwningPlayer = Cast<AHazePlayerCharacter>(Owner);

		Settings = UPlayerWallRunSettings::GetSettings(Cast<AHazeActor>(Owner));
		JumpSettings = UPlayerWallRunJumpSettings::GetSettings(Cast<AHazeActor>(Owner));
		TransferSettings = UPlayerWallRunTransferSettings::GetSettings(Cast<AHazeActor>(Owner));
		ClimbSettings = UPlayerWallRunLedgeClimbSettings::GetSettings(Cast<AHazeActor>(Owner));
		WallSettings = UPlayerWallSettings::GetSettings(Cast<AHazeActor>(Owner));
	}

	EPlayerWallRunState GetState() const property
	{
		return CurrentState;
	}

	void SetState(EPlayerWallRunState NewState) property
	{
		CurrentState = NewState;
		AnimData.State = CurrentState;
	}

	// Returns true if the state completed was the active state (nothing else took over)
	bool StateCompleted(EPlayerWallRunState CompletedState)
	{
		if (State == CompletedState)
		{
			ResetWallRun();
			return true;
		}
		return false;
	}

	// Reset wall run data
	void ResetWallRun()
	{
		State = EPlayerWallRunState::None;
		ActiveData.Reset();
		AnimData.Reset();
	}

	bool HasActiveWallRun() const
	{
		return ActiveData.Component != nullptr;
	}

	void StartTransferGraceWindow()
	{
		GraceTransferWindowInitiatedAt = Time::GameTimeSeconds;
		bAllowGraceTransfer = true;
	}

	float GetGraceWindowInitiatedAt() property
	{
		return GraceTransferWindowInitiatedAt;
	}

	bool IsGraceTransferAllowed()
	{
		return bAllowGraceTransfer;
	}

	access:TransferInternalWithCapability
	void ClearTransferGrace()
	{
		bAllowGraceTransfer = false;
	}

	void StartWallRun(FPlayerWallRunData WallRunData)
	{
		if (WallRunData.Component == nullptr)
			return;
		
		FPlayerWallRunData NewWallRunData = WallRunData;
		if (NewWallRunData.InitialVelocity.IsNearlyZero())
		{
			const float DirectionCorrection = Math::Sign(NewWallRunData.WallRight.DotProduct(OwningPlayer.ActorVelocity));
			NewWallRunData.InitialVelocity = NewWallRunData.WallRight * TransferSettings.WallRunEnterSpeed * DirectionCorrection;
			NewWallRunData.InitialVelocity = FQuat(NewWallRunData.WallNormal, Math::DegreesToRadians(TransferSettings.WallRunEnterVelocityAngle * DirectionCorrection)) * NewWallRunData.InitialVelocity;
		}

		ActiveData = NewWallRunData;
	}

	/*
		Traces in the specific direction, testing head and feet
		bTraceFullCapsule true will trace the entire player capsule. False will trace a smaller sphere. Good for activation vs active test (maybe?)
	*/
	FPlayerWallRunData TraceForWallRun(AHazePlayerCharacter Player, FVector TraceDirection, FInstigator Instigator) const
	{
#if !RELEASE
		FTemporalLog TemporalLog = TEMPORAL_LOG(this).Section(Instigator.ToString());
#endif

		UHazeMovementComponent MoveComp = UHazeMovementComponent::Get(Player);
		FPlayerWallRunData WallRunData;

		const FHazeTraceSettings TraceSettings = Trace::InitFromMovementComponent(MoveComp);
		
		const float TraceDistance = Math::Max(WallSettings.WallTraceForwardReach - Player.CapsuleComponent.CapsuleRadius, 0.0);
		
		if(TraceDistance < KINDA_SMALL_NUMBER)
			return FPlayerWallRunData();

		const FVector TraceStart = Player.ActorLocation;
		const FVector TraceDelta = TraceDirection * TraceDistance;
		const FVector TraceEnd = TraceStart + TraceDelta;

		FHitResult WallHit = TraceSettings.QueryTraceSingle(TraceStart, TraceEnd);

#if !RELEASE
		TemporalLog.HitResults("Wall Hit 1 of 2", WallHit, TraceSettings.Shape, TraceSettings.ShapeWorldOffset);
#endif

		if(WallHit.IsValidBlockingHit() && ShouldRedirect(WallHit, Player.MovementWorldUp))
		{
			RedirectedWallTrace(WallHit, TraceSettings, Instigator);
		}

		if (!WallHit.bBlockingHit)
			return FPlayerWallRunData();

		if (!WallHit.Component.HasTag(ComponentTags::WallRunnable))
			return FPlayerWallRunData();

		FVector WallRight = Player.MovementWorldUp.CrossProduct(WallHit.ImpactNormal).GetSafeNormal();
		// FVector WallUp = WallHit.ImpactNormal.CrossProduct(WallRight).GetSafeNormal();

		WallRunData.Component = WallHit.Component;
		WallRunData.WallRotation = FRotator::MakeFromXY(WallHit.ImpactNormal, WallRight);
		WallRunData.Location = WallHit.ImpactPoint;

		// Check for the verticality of the surface
		float WallPitch = 90.0 - Math::RadiansToDegrees(WallRunData.WallNormal.AngularDistance(Player.MovementWorldUp));
		if (WallPitch > WallSettings.WallPitchMaximum + KINDA_SMALL_NUMBER || WallPitch < WallSettings.WallPitchMinimum - KINDA_SMALL_NUMBER)
			return FPlayerWallRunData();

		/* Head & Foot trace
			Test to see if the head and feet land on something valid
			Take the hit location and trace towards to find head and foot location towards the normal
			Could probably move this into a "TraceForPlanting" function
		*/
		FHazeTraceSettings HeadFootTraceSettings = Trace::InitFromMovementComponent(MoveComp);
		HeadFootTraceSettings.UseLine();

		const FVector FlattenedTraceNormal = WallHit.Normal.ConstrainToPlane(MoveComp.WorldUp).GetSafeNormal();

		{
			const FVector HeadTraceStart = WallHit.Location + (Player.MovementWorldUp * 100.0);
			const FVector HeadTraceEnd = HeadTraceStart - FlattenedTraceNormal * Player.CapsuleComponent.CapsuleRadius * 2.0;

			const FHitResult HeadFootHit = HeadFootTraceSettings.QueryTraceSingle(HeadTraceStart, HeadTraceEnd);

#if !RELEASE
			TemporalLog.HitResults("Head Hit", HeadFootHit, HeadFootTraceSettings.Shape, HeadFootTraceSettings.ShapeWorldOffset);
#endif

			if (!HeadFootHit.bBlockingHit)
				return FPlayerWallRunData();
		}

		{
			const FVector FootTraceStart = WallHit.Location + (Player.MovementWorldUp * 25.0);
			const FVector FootTraceEnd = FootTraceStart - FlattenedTraceNormal * Player.CapsuleComponent.CapsuleRadius * 2.0;

			const FHitResult FootHit = HeadFootTraceSettings.QueryTraceSingle(FootTraceStart, FootTraceEnd);

#if !RELEASE
			TemporalLog.HitResults("Foot Hit", FootHit, HeadFootTraceSettings.Shape, HeadFootTraceSettings.ShapeWorldOffset);
#endif

			if (!FootHit.bBlockingHit)
				return FPlayerWallRunData();
		}
		
		return WallRunData;
	}

	private bool ShouldRedirect(FHitResult Hit, FVector WorldUp) const
	{
		const float WallPitch = 90.0 - Hit.Normal.GetAngleDegreesTo(WorldUp);
		if (WallPitch > WallSettings.WallPitchMaximum - KINDA_SMALL_NUMBER)
			return true;

		if(WallPitch < WallSettings.WallPitchMinimum + KINDA_SMALL_NUMBER)
			return true;

		// This feels more correct, but our walls are not always perfectly vertical, so it would need some threshold,
		// which is basically what the angles are, so now we use those instead
		// if(!Math::IsNearlyZero(Hit.Normal.DotProduct(WorldUp)))
		// 	return true;

		return false;
	}

	private void RedirectedWallTrace(FHitResult& WallHit, FHazeTraceSettings TraceSettings, FInstigator Instigator) const
	{
#if !RELEASE
		FTemporalLog TemporalLog = TEMPORAL_LOG(this).Section(Instigator.ToString());
#endif

		FVector TraceDelta = WallHit.TraceEnd - WallHit.TraceStart;
		float TraceDistance = TraceDelta.Size();
		const FVector PreviousTraceDirection = TraceDelta / TraceDistance;

		const FVector TraceDirection = PreviousTraceDirection.VectorPlaneProject(WallHit.Normal).GetSafeNormal();

		if(TraceDelta.IsNearlyZero())
			return;

		const float Dot = TraceDirection.DotProduct(PreviousTraceDirection);
		if(Dot < KINDA_SMALL_NUMBER)
			return;

		TraceDistance /= Dot;
		if(TraceDistance <= 0)
			return;

		TraceDelta = TraceDirection * TraceDistance;

		// The impact hit one of the caps on the capsule
		// We do a second trace along the normal to find the actual wall
		const FVector TraceStart = WallHit.Location + WallHit.Normal;
		const FVector TraceEnd = (TraceStart + TraceDelta) - WallHit.Normal;

		if(!TraceStart.Equals(TraceEnd))
		{
			WallHit = TraceSettings.QueryTraceSingle(TraceStart, TraceEnd);
#if !RELEASE
			TemporalLog.HitResults("Wall Hit 2 of 2", WallHit, TraceSettings.Shape, TraceSettings.ShapeWorldOffset);
#endif
		}
	}
}

struct FPlayerWallRunData
{
	// The hit component
	UPrimitiveComponent Component;

	// The initial velocity the player has on the wall. If not set, one will be picked for you
	FVector InitialVelocity;

	// Rotation of the wall, where forward is the normal of the wall
	FRotator WallRotation;

	// The impact location of the wall you run on
	FVector Location;

	FPlayerLedgeGrabData LedgeGrabData;

	FVector GetWallNormal() const property
	{
		return WallRotation.ForwardVector;
	}

	FVector GetWallUp() const property
	{
		return WallRotation.UpVector;
	}

	FVector GetWallRight() const property
	{
		return WallRotation.RightVector;
	}

	bool HasValidData() const
	{
		return Component != nullptr;
	}
	
	void Reset()
	{
		Component = nullptr;
		InitialVelocity = FVector::ZeroVector;
		WallRotation = FRotator::ZeroRotator;
		Location = FVector::ZeroVector;
		LedgeGrabData.Reset();
	}
}

struct FPlayerWallRunClimbData
{
	FVector TargetLocation;
	FHitResult Hit;

	UPrimitiveComponent GetHitComponent() const property
	{
		return Hit.Component;
	}

	bool HasValidData()
	{
		return HitComponent != nullptr;
	}

	void Reset()
	{
		Hit = FHitResult();
		TargetLocation = FVector::ZeroVector;
	}
}

struct FPlayerWallRunLedgeTurnaroundData
{
	//Current forward when move was initiated
	FVector InitiatedForwardDirection;

	//Are we currently in the slowing down part of the turnaround
	bool bSlowingDown = false;

	void Reset()
	{
		InitiatedForwardDirection = FVector::ZeroVector;
		bSlowingDown = false;
	}
}

struct FPlayerWallRunAnimationData
{
	UPROPERTY()
	EPlayerWallRunState State = EPlayerWallRunState::None;

	UPROPERTY()
	bool bLedgeGrabbing = false;

	UPROPERTY()
	float RunAngle = 0.0;

	void Reset()
	{
		// RunAngle = 0.0;
		// bLedgeGrabbing = false;
	}
}

enum EPlayerWallRunState
{
	None,
	WallRun,
	WallRunLedge,
	Jump,
	Transfer,
	WallRunLedgeClimb,
	WallRunLedgeTurnaround
}

namespace PlayerWallRunTags
{
	const FName WallRunEvaluate = n"WallRunEvaluate";
	const FName WallRunEnter = n"WallRunEnter";
	const FName WallRunCamera = n"WallRunCamera";
	const FName WallRunGroundedReset = n"WallRunGroundedReset";

	const FName WallRunMovement = n"WallRunMovement";
	const FName WallRunJump = n"WallRunJump";
	const FName WallRunTransfer = n"WallRunTransfer";
	const FName WallRunClimb = n"WallRunClimb";
	const FName WallRunLedgeTurnaround = n"WallRunLedgeTurnaround";
}