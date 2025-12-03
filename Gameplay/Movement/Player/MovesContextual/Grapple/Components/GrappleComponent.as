
enum EGrappleImpactType
{
	Default,
	Metal,
	Leaves
}

class UPlayerGrappleComponent : UActorComponent
{
	UPROPERTY()
	TSubclassOf<AGrappleHook> HookClass;
	UPROPERTY()
	UCurveFloat SpeedCurve;
	UPROPERTY()
	UCurveFloat HeightCurve;
	UPROPERTY()
	UHazeCameraSettingsDataAsset GrappleEnterCamSetting;
	UPROPERTY()
	UHazeCameraSettingsDataAsset GrappleCamSetting;
	UPROPERTY()
	UHazeCameraSettingsDataAsset GrappleLagCamSetting;
	UPROPERTY()
	TSubclassOf<UCameraShakeBase> GrappleShake;
	UPROPERTY()
	UNiagaraSystem GrappleImpactDefault;
	UPROPERTY()
	UNiagaraSystem GrappleImpactMetal;
	UPROPERTY()
	UNiagaraSystem GrappleImpactLeaves;

	UPROPERTY()
	UForceFeedbackEffect GrappleImpactFeedbackRumble;

	UPROPERTY()
	UForceFeedbackEffect GrappleToPointExitFeedbackRumble;

	UPROPERTY()
	UForceFeedbackEffect GrappleToPointGroundExitRumble;

	UPROPERTY(Category = "GrappleToPoint Settings")
	FRuntimeFloatCurve AccelerationCurve;

	UPROPERTY(Category = "GrappleToPoint Settings")
	FRuntimeFloatCurve GrappleToPointExitCurve;

	UPROPERTY(Category = "GrappleToPoint Settings")
	FRuntimeFloatCurve HeightOffsetCurve;

	UPROPERTY(Category = "GrappleToPoint Settings")
	FRuntimeFloatCurve ExitDecelerationCurve;

	UPROPERTY(Category = "GrappleToSlide Settings")
	FRuntimeFloatCurve GrappleToSlideGroundedSpeedCurve;

	AHazePlayerCharacter Player;
	AGrappleHook Grapple;

	UHazeMovementComponent MoveComp;
	UPlayerGrappleSettings Settings;

	float GrappleHeightOffset;
	float DistToTarget;
	const float GrapplePullBackDistance = 10;

	FPlayerGrappleData Data;
	FPlayerGrappleAnimData AnimData;

	UPROPERTY(EditDefaultsOnly)
	UAnimSequence HardLandingAnim;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		MoveComp = UHazeMovementComponent::Get(Player);
		Settings = UPlayerGrappleSettings::GetSettings(Player);

		//Spawn our Grapple Cable
		Grapple = SpawnActor(HookClass, bDeferredSpawn = true);
		Grapple.UsingPlayer = Player;
		FinishSpawningActor(Grapple);
		Grapple.AttachToActor(Player, n"LeftAttach", EAttachmentRule::SnapToTarget);
		Grapple.SetActorHiddenInGame(true);
	}
	
	void SetHeightAndAngleDiff()
	{
		if(Data.CurrentGrapplePoint == nullptr)
			return; 
		
		FVector Direction = Data.CurrentGrapplePoint.WorldLocation - Player.ActorLocation;
		DistToTarget = Direction.Size();
		FVector Diff = Data.CurrentGrapplePoint.WorldLocation - Player.ActorLocation;
		FVector ConstrainedDiff = Diff.ConstrainToDirection(MoveComp.WorldUp);
		AnimData.HeightDiff = ConstrainedDiff.Size() * (Math::Sign(MoveComp.WorldUp.DotProduct(ConstrainedDiff)));

		FVector FlattenedDirection = Direction.ConstrainToPlane(MoveComp.WorldUp);
		AnimData.AngleDiff = Math::Atan2(FlattenedDirection.DotProduct(Player.ActorRightVector), FlattenedDirection.DotProduct(Player.ActorForwardVector));
		AnimData.AngleDiff = Math::RadiansToDegrees(AnimData.AngleDiff);
	}

	void CalculateHeightOffset()
	{
		FVector Diff = Data.CurrentGrapplePoint.WorldLocation - Player.ActorLocation;
		FVector2D Input = FVector2D(500.0, 1250.0);
		FVector2D Output = FVector2D(450.0, 800.0);
		FVector ConstrainedDiff = Diff.ConstrainToDirection(MoveComp.WorldUp);
		float NewHeightOffset = Math::GetMappedRangeValueClamped(Input, Output, ConstrainedDiff.Size() * (Math::Sign(MoveComp.WorldUp.DotProduct(ConstrainedDiff))));
		GrappleHeightOffset = NewHeightOffset;
	}

	void VerifyAndStoreSlideAssistDirection(UGrappleSlidePointComponent SlidePoint)
	{
		if(SlidePoint == nullptr)
			return;

		if(!SlidePoint.bUsePreferedDirection)
			return;

		Data.StoredSlideDirection = SlidePoint.Owner.ActorTransform.TransformVector(SlidePoint.PreferedDirection.GetSafeNormal());
	}


	void SetGrappleMaterialParams(FVector TargetLocation)
	{
		float CableDistToTarget = (TargetLocation - Player.Mesh.GetSocketLocation(n"LeftAttach")).Size();
		float CableMaxLength = Math::Max(Grapple.Cable.CableLength, CableDistToTarget);
		Grapple.Cable.TileMaterial = CableMaxLength * 0.1;
	}

	bool GetValidGrappleHookTargetTransform(FTransform& TargetTransform)
	{
		if(Data.CurrentGrapplePoint == nullptr)
			return false;
		
		FVector OffsetLocation = Data.CurrentGrapplePoint.WorldLocation + (Data.CurrentGrapplePoint.Owner.ActorTransform.TransformVector(Data.CurrentGrapplePoint.RopeAttachOffset));
		TargetTransform.Location = OffsetLocation + (OffsetLocation - Player.Mesh.GetSocketLocation(n"LeftAttach")).GetSafeNormal() * -GrapplePullBackDistance;

		//Probably wont use this
		TargetTransform.Rotation = Data.CurrentGrapplePoint.GrappleRotation;

		return true;
	}

	//Trace for Grapple and populate our data to define which GrappleTo/Exit to perform
	void TraceForGrappleToPointTarget(bool DebugDraw = false)
	{
		UGrapplePointComponent TargetPoint = Cast<UGrapplePointComponent>(Data.CurrentGrapplePoint);

		//Calculate vertical angular delta
		FVector PlayerToPoint = TargetPoint.WorldLocation - Player.ActorLocation;
		float PlayerToPointVerticalSign = Math::Sign(PlayerToPoint.DotProduct(MoveComp.WorldUp));
		FVector PlayerToPointFlattened = PlayerToPoint.ConstrainToPlane(MoveComp.WorldUp);
		float AngularDelta = PlayerToPoint.GetSafeNormal().AngularDistanceForNormals(PlayerToPointFlattened.GetSafeNormal());
		AngularDelta = Math::RadiansToDegrees(AngularDelta) * PlayerToPointVerticalSign;

		//We now have a signed angle diff (-Angle meaning point is below us)
		Data.VerticalAngleDelta = AngularDelta;

		FHazeTraceSettings TargetLocationTrace = Trace::InitFromMovementComponent(MoveComp);
		TargetLocationTrace.UseLine();
		TargetLocationTrace.UseShapeWorldOffset(FVector::ZeroVector);
	
		if(DebugDraw)
			TargetLocationTrace.DebugDraw(5);

		FVector TargetDirection = (TargetPoint.WorldLocation - Player.ActorLocation).ConstrainToPlane(MoveComp.WorldUp).GetSafeNormal();
		const float PullbackDistance = 100;

		//Trace for wall in the TargetDirection
		FVector TraceStart = TargetPoint.WorldLocation + (TargetDirection * -PullbackDistance);
		TraceStart += -MoveComp.WorldUp * 25;
		FVector TraceEnd = TargetPoint.WorldLocation + (TargetDirection * (50 + PullbackDistance));
		TraceEnd += -MoveComp.WorldUp * 25;
		FHitResult LedgeTraceHit = TargetLocationTrace.QueryTraceSingle(TraceStart, TraceEnd);

		if(TargetPoint.bForceAerialExit || ((!LedgeTraceHit.bStartPenetrating && LedgeTraceHit.bBlockingHit) && (AngularDelta > Settings.GrappleToGroundAngleLimit && AngularDelta < Settings.GrappleToJumpOverAngle)))
		{
			//We found a valid ledge and we are roughly straight ahead meaning we want our TargetLocation to be ahead of the ledge and perform a jump over
			TraceStart = TargetPoint.WorldLocation + (TargetDirection * Settings.InwardsTraceDistance) + (MoveComp.WorldUp * Player.ScaledCapsuleHalfHeight * 2);
			TraceEnd = TraceStart;
			TraceEnd += MoveComp.WorldUp * (-Player.ScaledCapsuleHalfHeight * 3);

			FHitResult ExitTraceHit = TargetLocationTrace.QueryTraceSingle(TraceStart, TraceEnd);

			if(ExitTraceHit.bBlockingHit && !ExitTraceHit.bStartPenetrating)
			{
				Data.GrappleToPointRelativeTargetLocation = TargetPoint.WorldTransform.InverseTransformPosition(
					TargetPoint.WorldLocation - (TargetPoint.WorldLocation - Player.ActorLocation).ConstrainToPlane(MoveComp.WorldUp).GetSafeNormal() * Settings.EnterOffsetFromWall);

				Data.GrappleToPointRelativeExitLocation = TargetPoint.WorldTransform.InverseTransformPosition(ExitTraceHit.ImpactPoint);
				Data.bLedgeExit = true;
			}
			else
			{
				//if we are just forcing an aerial exit and we didnt find anything tracing then just set our target location to be vertically aligned with our enter position and horizontally with our to target, aiming past the point.
				Data.GrappleToPointRelativeTargetLocation = TargetPoint.WorldTransform.InverseTransformPosition(
					TargetPoint.WorldLocation - (TargetPoint.WorldLocation - Player.ActorLocation).ConstrainToPlane(MoveComp.WorldUp).GetSafeNormal() * Settings.EnterOffsetFromWall);

				Data.GrappleToPointRelativeExitLocation = TargetPoint.WorldTransform.InverseTransformPosition(
					TargetPoint.WorldLocation + (TargetPoint.WorldLocation - Player.ActorLocation).ConstrainToPlane(MoveComp.WorldUp).GetSafeNormal() * (Settings.EnterOffsetFromWall * 1.5));

				Data.bLedgeExit = true;
			}

			return;
		}
		else if(LedgeTraceHit.bStartPenetrating || (LedgeTraceHit.bBlockingHit && AngularDelta < Settings.GrappleToGroundAngleLimit))
		{
			//We are above the point enough that we want to travel past it and into a ground deceleration exit
			TraceStart = TargetPoint.WorldLocation + (MoveComp.WorldUp * Player.ScaledCapsuleHalfHeight * 2);
			TraceStart += TargetDirection * Settings.GroundedInwardsTraceDistance;
			TraceEnd = TraceStart - (MoveComp.WorldUp * Player.ScaledCapsuleHalfHeight * 3);

			FHitResult EndLocationTrace = TargetLocationTrace.QueryTraceSingle(TraceStart, TraceEnd);
			
			if(EndLocationTrace.bStartPenetrating || !EndLocationTrace.bBlockingHit || (Data.VerticalAngleDelta > 75 || Data.VerticalAngleDelta < -75))
			{
				//if we didnt find a proper ground hit behind the point then just move us to the point itself
				//[AL] - We could step back a set distance (say half the inwardsTrace) and try again if we dont have a valid hit
				Data.GrappleToPointRelativeTargetLocation = TargetPoint.WorldTransform.InverseTransformPosition(TargetPoint.WorldLocation);
			}
			else
			{
				Data.GrappleToPointRelativeTargetLocation = TargetPoint.WorldTransform.InverseTransformPosition(EndLocationTrace.ImpactPoint + EndLocationTrace.ImpactNormal);
			}

			Data.bLedgeExit = false;
			return;
		}
		else
		{
			//We are below the point and want our target to be in front of the point for a rising exit carrying our velocity

			TraceStart = TargetPoint.WorldLocation + (TargetDirection * Settings.InwardsTraceDistance) + (MoveComp.WorldUp * Player.ScaledCapsuleHalfHeight * 2);
			TraceEnd = TraceStart;
			TraceEnd += MoveComp.WorldUp * (-Player.ScaledCapsuleHalfHeight * 3);

			FHitResult ExitTraceHit = TargetLocationTrace.QueryTraceSingle(TraceStart, TraceEnd);

			if(ExitTraceHit.bBlockingHit && !ExitTraceHit.bStartPenetrating)
			{
				//We found a valid exit location

				Data.GrappleToPointRelativeTargetLocation = TargetPoint.WorldTransform.InverseTransformPosition(
					TargetPoint.WorldLocation - (TargetPoint.WorldLocation - Player.ActorLocation).ConstrainToPlane(MoveComp.WorldUp).GetSafeNormal() * Settings.EnterOffsetFromWall);

				Data.GrappleToPointRelativeExitLocation = TargetPoint.WorldTransform.InverseTransformPosition(ExitTraceHit.ImpactPoint);
				Data.bLedgeExit = true;
				return;
			}
			else
			{
				//Above logic will most likely just push us into a mesh and cause us to redirect at high velocity, rather we just perform an aerial exit which limits our exit speed and gives us air mobility

				Data.GrappleToPointRelativeTargetLocation = TargetPoint.WorldTransform.InverseTransformPosition(
					TargetPoint.WorldLocation - (TargetPoint.WorldLocation - Player.ActorLocation).ConstrainToPlane(MoveComp.WorldUp).GetSafeNormal() * Settings.EnterOffsetFromWall);

				Data.GrappleToPointRelativeExitLocation = TargetPoint.WorldTransform.InverseTransformPosition(
					TargetPoint.WorldLocation + (TargetPoint.WorldLocation - Player.ActorLocation).ConstrainToPlane(MoveComp.WorldUp).GetSafeNormal() * (Settings.EnterOffsetFromWall * 1.5));

				Data.bLedgeExit = true;

				return;
			}
		}
	}

	void CalculateGrappleToPerchData()
	{
		UPerchPointComponent PerchPoint = Cast<UPerchPointComponent>(Data.CurrentGrapplePoint);

		if(!PerchPoint.bHasConnectedSpline)
		{
			//Single point
			FVector PlayerToPointDelta = PerchPoint.WorldLocation - Player.ActorLocation;
			FVector PlayerToPointDir = (PerchPoint.WorldLocation - Player.ActorLocation).GetSafeNormal();
			
			FVector PlayerToPointFlattened = PlayerToPointDir.ConstrainToPlane(MoveComp.WorldUp);

			float PlayerToPointVerticalSign = Math::Sign(PlayerToPointDir.DotProduct(MoveComp.WorldUp));
			float AngularDelta = PlayerToPointDir.GetSafeNormal().AngularDistanceForNormals(PlayerToPointFlattened.GetSafeNormal());
			AngularDelta = Math::RadiansToDegrees(AngularDelta) * PlayerToPointVerticalSign;

			if (AngularDelta < Settings.GrappleToPerchAbovePointAngleCutoff && !PerchPoint.bForcePerchGrappleExit)
			{
				//We are above the point enough that we want to skip the Grapple Exit and transition into perpendicular landing
				Data.bPerformPerchExit = false;
			}
			else
			{
				//We are even with the point or below it enough that we want to perform our exit
				float EnterOffset = Math::Min(PlayerToPointDelta.Size() / 2, Settings.EnterOffsetFromPerch);
				Data.GrappleToPointRelativeTargetLocation = PerchPoint.WorldTransform.InverseTransformPosition(PerchPoint.WorldLocation + (-PlayerToPointFlattened * EnterOffset));
				Data.GrappleToPointRelativeExitLocation = PerchPoint.WorldTransform.InverseTransformPosition(PerchPoint.WorldLocation);
			
				Data.bPerformPerchExit = true;
			}
		}
		else
		{
			//Perch Spline
			float TargetedSplineDistance = PerchPoint.ConnectedSpline.Spline.GetClosestSplineDistanceToWorldLocation(PerchPoint.WorldLocation);
			FVector TargetLocation = PerchPoint.ConnectedSpline.Spline.GetWorldLocationAtSplineDistance(TargetedSplineDistance);

			FVector PlayerToPointDelta = TargetLocation - Player.ActorLocation;
			FVector PlayerToPointDir = (TargetLocation - Player.ActorLocation).GetSafeNormal();

			FVector PlayerToPointFlattened = PlayerToPointDir.ConstrainToPlane(MoveComp.WorldUp);

			float PlayerToPointVerticalSign = Math::Sign(PlayerToPointDir.DotProduct(MoveComp.WorldUp));
			float AngularDelta = PlayerToPointDir.GetSafeNormal().AngularDistanceForNormals(PlayerToPointFlattened.GetSafeNormal());
			AngularDelta = Math::RadiansToDegrees(AngularDelta) * PlayerToPointVerticalSign;

			if (AngularDelta < Settings.GrappleToPerchAbovePointAngleCutoff)
			{
				Data.bPerformPerchExit = false;
			}
			else
			{
				float EnterOffset = Math::Min(PlayerToPointDelta.Size() / 2, Settings.EnterOffsetFromPerch);
				Data.GrappleToPointRelativeTargetLocation = PerchPoint.WorldTransform.InverseTransformPosition(TargetLocation + (-PlayerToPointFlattened * EnterOffset));
				Data.GrappleToPointRelativeExitLocation = PerchPoint.WorldTransform.InverseTransformPosition(TargetLocation);

				Data.bPerformPerchExit = true;
			}
		}
	}

	void VerifyGrappleToSlideType(bool DebugDraw = false)
	{
		if(MoveComp.IsOnWalkableGround() && TraceForGroundedGrapple(DebugDraw))
		{
			Data.SlideGrappleVariant = ESlideGrappleVariants::Grounded;
			return;
		}
		else
			Data.SlideGrappleVariant = ESlideGrappleVariants::InAir;
	}

	private bool TraceForGroundedGrapple(bool bDebug = false)
	{
		FHazeTraceSettings GroundTrace = Trace::InitChannel(ECollisionChannel::PlayerCharacter);
		GroundTrace.UseLine();
		
		if(bDebug)
			GroundTrace.DebugDraw(5);

		FVector PlayerToPoint = Data.CurrentGrapplePoint.Owner.ActorLocation - Player.ActorLocation;
		FVector PlayerToPointDirection = PlayerToPoint.GetSafeNormal();

		//First trace need to be some distance infront of player and equal distance before last point
		const float TotalDelta = PlayerToPoint.Size();
		const float InitialOffset = (TotalDelta / 4) / 2;
		const float StepSize = TotalDelta / 4;

		const float HeightOffset = 50;

		for (int i = 1; i < 4; i++)
		{
			FVector TraceLocation = Player.ActorLocation + (PlayerToPointDirection * InitialOffset) + ((PlayerToPointDirection * StepSize) * i);
			FHitResult GroundHit = GroundTrace.QueryTraceSingle(TraceLocation + (MoveComp.WorldUp * HeightOffset), TraceLocation + (MoveComp.WorldUp * -HeightOffset));

			if(!GroundHit.bBlockingHit)
				return false;
		}

		return true;
	}

	bool IsGrappleActive() const
	{
		return Data.GrappleState != EPlayerGrappleStates::Inactive;
	}

	void RetractGrapple(float ActiveDuration)
	{
		if(ActiveDuration < Settings.GRAPPLE_REEL_DELAY)
		{
			Grapple.SetActorLocation(Data.CurrentGrapplePoint.WorldLocation + Data.CurrentGrapplePoint.WorldTransform.TransformVector(Data.CurrentGrapplePoint.RopeAttachOffset));
		}
		else
		{
			float ReelAlpha = Math::Clamp((ActiveDuration - Settings.GRAPPLE_REEL_DELAY) / Settings.GRAPPLE_REEL_DURATION , 0, 1);

			FVector NewLoc = Math::Lerp(Data.CurrentGrapplePoint.WorldLocation + Data.CurrentGrapplePoint.WorldTransform.TransformVector(Data.CurrentGrapplePoint.RopeAttachOffset), Player.Mesh.GetSocketLocation(n"LeftAttach"), ReelAlpha);
			Grapple.SetActorLocation(NewLoc);
			float NewTense = Math::Lerp(0.15, 2.15, ReelAlpha);
			Grapple.Tense = NewTense;

			if(ReelAlpha >= 1)
			{
				Grapple.AttachToActor(Player, n"LeftAttach", EAttachmentRule::SnapToTarget);
				Grapple.SetActorHiddenInGame(true);
			}
		}
	}
}

struct FPlayerGrappleData
{
	EPlayerGrappleStates GrappleState;
	ESlideGrappleVariants SlideGrappleVariant;
	UGrapplePointBaseComponent CurrentGrapplePoint;
	UGrapplePointBaseComponent ForceGrapplePoint;

	//If slide point was set to lock in activation assist direction
	FVector StoredSlideDirection = FVector::ZeroVector;

	FVector GrappleToPointRelativeExitLocation;
	//Our EndLocation for GrappleToPoint Capability (prior to activating Exit)
	FVector GrappleToPointRelativeTargetLocation;

	//Have we finished the main translation move (Are we ready to perform exit)
	bool bGrappleToPointFinished = false;
	bool bEnterFinished = false;

	//Have we detected a ledge we need to clear during exit?
	bool bLedgeExit = false;

	bool bPerformPerchExit = false;

	bool bFailedToDetectValidExit = false;

	float VerticalAngleDelta = 0;

	TArray<AActor> ActorsToIgnore;

	FVector GetGrappleToPointWorldExitLocation() property
	{
		return CurrentGrapplePoint.WorldTransform.TransformPosition(GrappleToPointRelativeExitLocation);
	}

	FVector GetGrappleToPointWorldTargetLocation() property
	{
		return CurrentGrapplePoint.WorldTransform.TransformPosition(GrappleToPointRelativeTargetLocation);
	}

	void ResetData()
	{
		StoredSlideDirection = FVector::ZeroVector;
		GrappleState = EPlayerGrappleStates::Inactive;
		SlideGrappleVariant = ESlideGrappleVariants::Inactive;
		CurrentGrapplePoint = nullptr;
		ForceGrapplePoint = nullptr;
		GrappleToPointRelativeExitLocation = FVector::ZeroVector;
		GrappleToPointRelativeTargetLocation = FVector::ZeroVector;
		bGrappleToPointFinished = false;
		bEnterFinished = false;
		bLedgeExit = false;
		bPerformPerchExit = false;
		bFailedToDetectValidExit = false;

		ActorsToIgnore.Empty();

		VerticalAngleDelta = 0;
	}
}

struct FPlayerGrappleAnimData
{
	//Are we performing the Grapple Enter
	UPROPERTY()
	bool bInEnter = false;
	UPROPERTY()
	bool bGrappling = false;
	UPROPERTY()
	bool bLaunching = false;
	UPROPERTY()
	bool bSliding = false;
	UPROPERTY()
	bool bWallrunGrappling = false;
	UPROPERTY()
	bool bPerchGrappling = false;
	UPROPERTY()
	bool bPerchGrappleJumping = false;
	UPROPERTY()
	bool bWallScrambleGrappling = false;
	UPROPERTY()
	bool bGrappleToPointAirborneExit = false;
	UPROPERTY()
	bool bAnticipatePerchLanding = false;
	UPROPERTY()
	bool bAnticipatePoleLanding = false;
	UPROPERTY()
	bool bPerformQuickPerchGrapple = false;
	UPROPERTY()
	float HeightDiff;
	UPROPERTY()
	float AngleDiff;
	UPROPERTY()
	ELeftRight EnterSide;
	//How far away from the point are we along the runtime spline
	UPROPERTY()
	float SlideSplineRemainingDistance;
	//Total distance to reach point
	UPROPERTY()
	float SlideSplineLength;

	void ResetData()
	{
		bInEnter = false;
		bGrappling = false;
		bLaunching = false;
		bSliding = false;
		bWallrunGrappling = false;
		bPerchGrappling = false;
		bPerchGrappleJumping = false;
		bWallScrambleGrappling = false;
		bGrappleToPointAirborneExit = false;
		bAnticipatePoleLanding = false;
		bAnticipatePerchLanding = false;
		bPerformQuickPerchGrapple = false;
		HeightDiff = 0.0;
		AngleDiff = 0.0;
		SlideSplineLength = 0;
		SlideSplineRemainingDistance = 0;
	}
}

enum ELeftRight
{
	Left,
	Right
}

enum EPlayerGrappleStates
{
	Inactive,
	GrappleEnter,
	GrappleToPoint,
	GrappleToPointGrounded,
	GrappleToPointExit,
	GrappleToPointGroundedExit,
	GrappleLaunch,
	GrapplePerch,
	GrappleSlide,
	GrappleWallrun,
	GrappleWallScramble,
	QuickGrappleEnter,
	QuickGrapplePerch,
	GrappleBashStart,
	GrappleBashAim,
	GrapplePerchExit,
	GrappleToPole
}

enum ESlideGrappleVariants
{
	Inactive,
	Grounded,
	CloseToGround,
	InAir
}