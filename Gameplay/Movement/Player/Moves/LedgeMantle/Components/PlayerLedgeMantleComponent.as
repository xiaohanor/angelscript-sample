namespace PlayerLedgeMantle
{
	const FConsoleVariable CVar_EnableLedgeMantle("Haze.Movement.EnableLedgeMantle", 1);
	const FConsoleVariable CVar_DebugLedgeMantle("Haze.Movement.Debug.LedgeMantle", 0);
}

class UPlayerLedgeMantleComponent : UActorComponent
{
	UPROPERTY(Category = "Haptics")
	UForceFeedbackEffect FallingLowImpactFeedback;

	UPROPERTY(Category = "Haptics")
	UForceFeedbackEffect FF_AirborneRollMantle;

	UPROPERTY(Category = "Haptics")
	UForceFeedbackEffect FF_ClimbMantle;

	UPROPERTY(Category = "Haptics")
	UForceFeedbackEffect FF_AirborneLow;

	UPROPERTY(Category = "Haptics")
	UForceFeedbackEffect FF_ScrambleMantle;

	FPlayerLedgeMantleData Data;
	FPlayerLedgeMantleAnimData AnimData;
	UPlayerLedgeMantleSettings Settings;
	UPlayerWallSettings WallSettings;

	EPlayerLedgeMantleState CurrentState;
	EPlayerLedgeMantleState TracedForState;

	UMovementImpactCallbackComponent ImpactedCallbackComp;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Settings = UPlayerLedgeMantleSettings::GetSettings(Cast<AHazeActor>(Owner));
		WallSettings = UPlayerWallSettings::GetSettings(Cast<AHazeActor>(Owner));
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
	}

	bool TraceForGroundedMantle(AHazePlayerCharacter Player, FVector MantleDirection, FPlayerLedgeMantleData& MantleData, bool bDebug = false)
	{
		//Function traces for Wall / Top and checks height delta to verify which grounded mantle to perform and assigns data accordingly

		if(Player == nullptr)
			return false;

		 UPlayerMovementComponent MoveComp = UPlayerMovementComponent::Get(Player);

		 MantleData.Reset();
		 MantleData.Direction = MantleDirection.ConstrainToPlane(MoveComp.WorldUp.GetSafeNormal());
		 MantleData.EnterSpeed = Math::Clamp(MoveComp.HorizontalVelocity.Size(), 500, 750);

		if(MantleData.Direction.IsNearlyZero())
			return false;

		if(Settings.EnterDistanceMax <= 0)
			return false;

		MantleData.EnterSpeed = Math::Clamp(MoveComp.HorizontalVelocity.Size(), UPlayerFloorMotionSettings::GetSettings(Player).MaximumSpeed, UPlayerSprintSettings::GetSettings(Player).MaximumSpeed);

		/* WallTrace */
		FHitResult WallTraceHit;
		{
			FHazeTraceSettings NearWallTraceSettings = Trace::InitFromMovementComponent(MoveComp);
			NearWallTraceSettings.UseLine();

			if(bDebug)
				NearWallTraceSettings.DebugDraw(4.0);

			FVector TraceStart = Player.ActorCenterLocation - (MoveComp.WorldUp * 10);
			FVector TraceEnd = TraceStart;
			TraceEnd += MantleData.Direction * Settings.EnterDistanceMax;
			WallTraceHit = NearWallTraceSettings.QueryTraceSingle(TraceStart, TraceEnd);
		}

		if (!WallTraceHit.bBlockingHit)
			return false;
		
		//Skip tag check for now, until we know we need to be able to disable it
		//if (!NearWallTraceHit.Component.HasTag(ComponentTags::LedgeMantleable))
			//return false;

		MantleData.WallHit = WallTraceHit;

		const float ToWallDeltaFlattened = (Player.ActorLocation - WallTraceHit.ImpactPoint).ConstrainToPlane(MoveComp.WorldUp).Size();

		const FRotator MantleRotationComparand = FRotator::MakeFromZX(MoveComp.WorldUp, MantleDirection);

		const FVector NearWallRight = Player.MovementWorldUp.CrossProduct(WallTraceHit.ImpactNormal).GetSafeNormal();
		const FRotator NearWallRotation = FRotator::MakeFromXY(WallTraceHit.ImpactNormal, NearWallRight);

		//Check our direction alignment with the wall normal
		float WallDirectionDot = MantleData.Direction.DotProduct(-WallTraceHit.ImpactNormal);
		float AngleDiff = Math::Acos(WallDirectionDot);
		AngleDiff = Math::RadiansToDegrees(AngleDiff);

		if(Settings.EnterAngleCutoff > 0 && AngleDiff > Settings.EnterAngleCutoff)
		{
			if(bDebug)
				PrintToScreen("EntryAngleToSteep", 3.);
			
			return false;
		}

		//Pitch Test the Near Wall
		{
			const FVector NearWallPitchVector = NearWallRotation.UpVector.ConstrainToPlane(MantleRotationComparand.RightVector).GetSafeNormal();
			const float NearWallPitchAngle = Math::RadiansToDegrees(NearWallPitchVector.AngularDistance(MantleRotationComparand.UpVector) * Math::Sign(NearWallPitchVector.DotProduct(MantleRotationComparand.ForwardVector)));
			if (NearWallPitchAngle < WallSettings.WallPitchMinimum - KINDA_SMALL_NUMBER
					|| NearWallPitchAngle > WallSettings.WallPitchMaximum + KINDA_SMALL_NUMBER)
				return false;
		}

		/* TopTrace */
		FHitResult TopTraceHit;	
		{
			FHazeTraceSettings TopTraceSettings = Trace::InitFromMovementComponent(MoveComp);
			TopTraceSettings.UseLine();

			if (bDebug)
				TopTraceSettings.DebugDraw(4.0);

			FVector ToWall = (WallTraceHit.ImpactPoint - Player.ActorLocation).ConstrainToPlane(MoveComp.WorldUp);

			FVector TopTraceStartlocation = Player.ActorLocation + ToWall + (MantleData.Direction * Settings.TopTraceDepth);
			FVector TopTraceEndLocation = TopTraceStartlocation;
			TopTraceStartlocation += Player.MovementWorldUp * (Settings.HighMantleMax);

			TopTraceHit = TopTraceSettings.QueryTraceSingle(TopTraceStartlocation, TopTraceEndLocation);
		}

		if (TopTraceHit.bStartPenetrating)
			return false;
		if (!TopTraceHit.bBlockingHit)
			return false;

		MantleData.TopLedgeHit = TopTraceHit;

		//Skip tag check here for now
		//if (!TopTraceHit.Component.HasTag(ComponentTags::LedgeMantleable))
		//	return false;

		//Delta Checks
		const FVector PlayerToPointDelta = Player.ActorLocation - TopTraceHit.ImpactPoint;
		const float PlayerForwardTraceVerticalOffset = PlayerToPointDelta.ConstrainToDirection(MantleRotationComparand.UpVector).Size();

		if (PlayerForwardTraceVerticalOffset > Settings.HighMantleMax)
			return false;

		if (bDebug)
			PrintToScreen( PlayerForwardTraceVerticalOffset > Settings.LowMantleCutoff ? "HighMantle: " + PlayerForwardTraceVerticalOffset : "LowMantle: " + PlayerForwardTraceVerticalOffset, 3);

		bool bLowMantle;
		if(PlayerForwardTraceVerticalOffset <= Settings.LowMantleCutoff)
			bLowMantle = true;
		else
		{
			//disabling high mantle for now
			return false;
			// bLowMantle = false;
		}

		const FRotator TopRotation = FRotator::MakeFromZX(TopTraceHit.ImpactNormal, MantleData.Direction);

		//Pitch Test the target surface
		{
			const FVector TopPitchVector = TopRotation.UpVector.ConstrainToPlane(MantleRotationComparand.RightVector).GetSafeNormal();
			const float TopPitchAngle = Math::RadiansToDegrees(TopPitchVector.AngularDistance(MantleRotationComparand.UpVector) * Math::Sign(TopPitchVector.DotProduct(MantleRotationComparand.ForwardVector)));
			if (TopPitchAngle < WallSettings.TopPitchMinimum - KINDA_SMALL_NUMBER
					|| TopPitchAngle > WallSettings.TopPitchMaximum + KINDA_SMALL_NUMBER)
				return false;
		}

		//Roll Test the target surface
		{
			const FVector TopRollVector = TopRotation.UpVector.ConstrainToPlane(MantleRotationComparand.ForwardVector).GetSafeNormal();
			const float TopRollAngle = Math::RadiansToDegrees(TopRollVector.AngularDistance(MantleRotationComparand.UpVector));
			if (!Math::IsNearlyEqual(TopRollAngle, 0.0, WallSettings.TopRollMaximum + 0.01))
				return false;
		}

		FVector WallToTop = TopTraceHit.ImpactPoint - WallTraceHit.ImpactPoint;
		MantleData.LedgeLocation = WallTraceHit.ImpactPoint + (NearWallRotation.UpVector * (WallToTop.DotProduct(NearWallRotation.UpVector)));
		MantleData.LedgePlayerLocation = MantleData.LedgeLocation; //- (MoveComp.WorldUp * Player.CapsuleComponent.CapsuleHalfHeight);

		MantleData.TopHitComponent = TopTraceHit.Component;
		MantleData.HitComponents.AddUnique(TopTraceHit.Component);
		MantleData.HitComponents.AddUnique(WallTraceHit.Component);

		if (bDebug)
			Debug::DrawDebugSphere(MantleData.LedgeLocation, 10, 10, FLinearColor::Yellow, 1, 4);
	
		//Trace for endlocation
		{
			FHazeTraceSettings EndLocationTrace = Trace::InitFromMovementComponent(MoveComp);
			EndLocationTrace.UseLine();

			if(bDebug)
				EndLocationTrace.DebugDraw(4.0);

			const float ExitDistance = Settings.ExitDuration * MantleData.EnterSpeed;
			FVector ExitTraceStartLocation = MantleData.LedgeLocation + (MantleData.Direction * ExitDistance) + (MoveComp.WorldUp * 40);
			FVector ExitTraceEndLocation = MantleData.LedgeLocation + (MantleData.Direction * ExitDistance) - (MoveComp.WorldUp * 40);

			FHitResult EndLocationHit = EndLocationTrace.QueryTraceSingle(ExitTraceStartLocation, ExitTraceEndLocation);
			if (EndLocationHit.bStartPenetrating)
				return false;
			if(!EndLocationHit.bBlockingHit)
				return false;

			MantleData.ExitFloorHit = EndLocationHit;
			MantleData.ExitLocation = EndLocationHit.ImpactPoint;
		}

		//Calculate and populate our move data struct
		MantleData.EnterDistance = (MantleData.LedgeLocation - Player.ActorLocation).ConstrainToPlane(MoveComp.WorldUp).Size();
		if(bLowMantle)
			MantleData.EnterDuration = Math::Clamp(MantleData.EnterDistance / MantleData.EnterSpeed, Settings.Low_EnterDurationMin , Settings.Low_EnterDurationMax);
		else
		{
			FVector ToTargetDelta = (MantleData.LedgeLocation - Player.ActorLocation);
			MantleData.EnterDuration = Math::Clamp(ToTargetDelta.Size() / MoveComp.HorizontalVelocity.Size(), Settings.High_EnterDurationMin, Settings.High_EnterDurationMax);
		}

		MantleData.ExitFacingDirection = -WallTraceHit.ImpactNormal.ConstrainToPlane(MoveComp.WorldUp);
		
		//[AL] Should we even be doing the state interpretation here or in separated capabilities?
		if(bLowMantle)
		{
			if (ToWallDeltaFlattened <= 50)
			{
				MantleData.MantleType = EPlayerLedgeMantleState::LowMantleCloseEnter;

				//feels bad modifying the data at the end like this, should this be interpreted when we set the initial data rather then in post? (AL)
				MantleData.EnterDuration = 0.2;
				// MantleData.ExitLocation -= (MantleData.ExitLocation - Player.ActorLocation).ConstrainToPlane(MoveComp.WorldUp).GetSafeNormal() * 50;
			}
			else
				MantleData.MantleType = EPlayerLedgeMantleState::LowMantleEnter;
		}
		else
			MantleData.MantleType = EPlayerLedgeMantleState::HighMantleEnter;

		MantleData.bHasCompleteData = true;

		return true;
	}

	bool TraceForAirborneMantle(AHazePlayerCharacter Player, FPlayerLedgeMantleData& MantleData, FHitResult WallTraceHit,
		 float TopTraceHeight, float VerticalDeltaCutoff, float ExitTraceDistance, bool bAlignExitWithWallNormal, EPlayerLedgeMantleState TraceForState, bool bDebug = false)
	{

#if !RELEASE
		FTemporalLog TemporalLog = TEMPORAL_LOG(this).Section(this.ToString());
		TemporalLog.Value("MantleType", TraceForState);
#endif

		MantleData.Reset();
		UPlayerMovementComponent MoveComp = UPlayerMovementComponent::Get(Player);

		EPlayerLedgeMantleState TargetState = TraceForState;
		float ExitDistanceToUse = ExitTraceDistance;

		MantleData.WallHit = WallTraceHit;

		/* Verify Wall Data */
		if(MoveComp.HasWallContact())
			MantleData.Direction = MoveComp.MovementInput.GetSafeNormal();
		else
			MantleData.Direction = MoveComp.HorizontalVelocity.GetSafeNormal();
		
		//We know we hit a wall from our previous capsule trace, now make sure we have a wall in our forward direction
		FHazeTraceSettings PlayerForwardTrace = Trace::InitFromMovementComponent(MoveComp);
		PlayerForwardTrace.UseLine();

		//Make sure we trace forward along the same height where the prediction impact happend (to detect floating platforms / etc)
		FVector PlayerForwardTraceVerticalOffset = (WallTraceHit.ImpactPoint - Player.ActorLocation).ConstrainToDirection(MoveComp.WorldUp);
		FVector PlayerForwardTraceStartLocation = Player.ActorLocation + PlayerForwardTraceVerticalOffset;
		FVector PlayerForwardTraceEndLocation = PlayerForwardTraceStartLocation;
		PlayerForwardTraceEndLocation += MoveComp.MovementInput.ConstrainToPlane(MoveComp.WorldUp).GetSafeNormal() * (MoveComp.HorizontalVelocity.Size() * Settings.AirborneMantleAnticipationTime + Player.ScaledCapsuleRadius);
		FHitResult PlayerForwardHit = PlayerForwardTrace.QueryTraceSingle(PlayerForwardTraceStartLocation, PlayerForwardTraceEndLocation);

#if !RELEASE
		TemporalLog.HitResults("ForwardTrace", PlayerForwardHit, PlayerForwardTrace.Shape, PlayerForwardTrace.ShapeWorldOffset);
#endif

		if(!PlayerForwardHit.bBlockingHit)
		{
			//Incase we hit an angled platform weirdly and our first trace missed, perform another trace slightly lower then initial one
			PlayerForwardTraceStartLocation -= MoveComp.WorldUp * 10;
			PlayerForwardTraceEndLocation -= MoveComp.WorldUp * 10;

			PlayerForwardHit = PlayerForwardTrace.QueryTraceSingle(PlayerForwardTraceStartLocation, PlayerForwardTraceEndLocation);

#if !RELEASE
		TemporalLog.HitResults("ForwardTrace2", PlayerForwardHit, PlayerForwardTrace.Shape, PlayerForwardTrace.ShapeWorldOffset);
#endif

			if(!PlayerForwardHit.bBlockingHit)
				return false;
		}

		if(PlayerForwardHit.bStartPenetrating)
			return false;

		const FVector ToWallFlattened = (PlayerForwardHit.ImpactPoint - Player.ActorLocation).ConstrainToPlane(MoveComp.WorldUp);
	
		//Construct a rotation for the wall
		const FRotator MantleRotationComparand = FRotator::MakeFromZX(MoveComp.WorldUp, ToWallFlattened);
		const FVector WallRight = Player.MovementWorldUp.CrossProduct(PlayerForwardHit.Normal).GetSafeNormal();
		const FRotator WallRotation = FRotator::MakeFromXY(PlayerForwardHit.Normal, WallRight);

		float WallDirectionDot = MantleData.Direction.ConstrainToPlane(MoveComp.WorldUp).GetSafeNormal().DotProduct(-PlayerForwardHit.Normal.ConstrainToPlane(MoveComp.WorldUp).GetSafeNormal());
		float AngleDiff = Math::Acos(WallDirectionDot);
		AngleDiff = Math::RadiansToDegrees(AngleDiff);

		//Make sure we are heading roughly into the wall (not along it)
		if (Settings.AirborneAngleCutoff > 0 && AngleDiff > Settings.AirborneAngleCutoff)
		{
			return false;
		}

		/* Pitch Test The Wall */
		const FVector WallPitchVector = WallRotation.UpVector.ConstrainToPlane(MantleRotationComparand.RightVector).GetSafeNormal();
		const float WallPitchAngle = Math::RadiansToDegrees(WallPitchVector.AngularDistance(MantleRotationComparand.UpVector) * Math::Sign(WallPitchVector.DotProduct(MantleRotationComparand.ForwardVector)));

#if !RELEASE
		TemporalLog.Value("WallPitchAngle:", WallPitchAngle);
#endif

		if (WallPitchAngle < Settings.WallPitchMinimum - KINDA_SMALL_NUMBER || WallPitchAngle > Settings.WallPitchMaximum + KINDA_SMALL_NUMBER)
		{

#if !RELEASE
			TemporalLog.Value("AllowedWallPitch:", Settings.WallPitchMaximum);
#endif
			return false;
		}

		/* Top Trace */
		FHitResult TopTraceHit;
		FHazeTraceSettings TopTraceSettings = Trace::InitFromMovementComponent(MoveComp);
		TopTraceSettings.UseLine();

		//Check if we should align our top/Exit direction with wall normal or not
		FVector ExitDirection = bAlignExitWithWallNormal ? -WallTraceHit.Normal : ToWallFlattened.GetSafeNormal();

		FVector TopTraceStartlocation = Player.ActorLocation + ToWallFlattened + (ExitDirection * Settings.TopTraceDepth);
		FVector TopTraceEndLocation = TopTraceStartlocation;
		TopTraceStartlocation += Player.MovementWorldUp * TopTraceHeight;

		TopTraceHit = TopTraceSettings.QueryTraceSingle(TopTraceStartlocation, TopTraceEndLocation);

#if !RELEASE
		TemporalLog.HitResults("TopTrace", TopTraceHit, TopTraceSettings.Shape, TopTraceSettings.ShapeWorldOffset);
#endif

		if (TopTraceHit.bStartPenetrating)
			return false;

		if (!TopTraceHit.bBlockingHit)
			return false;

		//Verify Ledge tag
		if(!TopTraceHit.Component.HasTag(n"LedgeClimbable"))
			return false;
		
		MantleData.TopLedgeHit = TopTraceHit;

		FVector VerticalDelta = (TopTraceHit.ImpactPoint - Player.ActorLocation).ConstrainToPlane(Player.ActorForwardVector);
		float VerticalDistance = Math::Abs(VerticalDelta.Size());

		//Check if we are within the high requirement
		if(VerticalDistance > VerticalDeltaCutoff)
		{

#if !RELEASE
			TemporalLog.Value("VerticalDistanceToTop:", VerticalDistance);
			TemporalLog.Value("VerticalTopDistanceCutoff:", VerticalDeltaCutoff);
#endif
			return false;
		}
		
		//Only check for obstructions above player if we are moving up to the ledge
		if(TraceForState == EPlayerLedgeMantleState::JumpClimbEnter)
		{
			FHazeTraceSettings VerticalObstructionTraceSettings = Trace::InitFromMovementComponent(MoveComp, n"VerticalObstructionTrace");
			FVector VerticalObstructionTraceStart = Player.ActorLocation;
			FVector VerticalObstructionTraceEnd = Player.ActorLocation + (MoveComp.WorldUp * (VerticalDistance - (Player.ScaledCapsuleHalfHeight)));

			FHitResult VerticalObstructionHit = VerticalObstructionTraceSettings.QueryTraceSingle(VerticalObstructionTraceStart, VerticalObstructionTraceEnd);

	#if !RELEASE
			TemporalLog.HitResults("VerticalObstructionTrace", VerticalObstructionHit, VerticalObstructionTraceSettings.Shape, VerticalObstructionTraceSettings.ShapeWorldOffset);
	#endif
			if(VerticalObstructionHit.bStartPenetrating)
				return false;

			if(VerticalObstructionHit.bBlockingHit)
				return false;
		}
		//Which Airborne move should we branch to if any
		else if (TraceForState == EPlayerLedgeMantleState::AirborneMantle)
		{
			if(VerticalDistance > Settings.AirborneRollMantleVerticalCutOff)
			{
				TargetState = EPlayerLedgeMantleState::AirborneLowEnter;
				ExitDistanceToUse = Settings.AirborneLowMantleExitDistance;
			}
			else
				TargetState = EPlayerLedgeMantleState::AirborneRollEnter;
		}

		const FRotator TopRotation = FRotator::MakeFromZX(TopTraceHit.ImpactNormal, MantleData.Direction);

		//Pitch Test the surface
		const FVector TopPitchVector = TopRotation.UpVector.ConstrainToPlane(MantleRotationComparand.RightVector).GetSafeNormal();
		const float TopPitchAngle = Math::RadiansToDegrees(TopPitchVector.AngularDistance(MantleRotationComparand.UpVector) * Math::Sign(TopPitchVector.DotProduct(MantleRotationComparand.ForwardVector)));
		
		if (TopPitchAngle < Settings.TopPitchMinimum - KINDA_SMALL_NUMBER
				|| TopPitchAngle > Settings.TopPitchMaximum + KINDA_SMALL_NUMBER)
		{
#if !RELEASE
			TemporalLog.Value("TopPitchAngle:", TopPitchAngle);
			TemporalLog.Value("AllowedTopPitch:", Settings.TopPitchMaximum);
#endif
			return false;
		}

		//Roll Test the surface
		const FVector TopRollVector = TopRotation.UpVector.ConstrainToPlane(MantleRotationComparand.ForwardVector).GetSafeNormal();
		const float TopRollAngle = Math::RadiansToDegrees(TopRollVector.AngularDistance(MantleRotationComparand.UpVector));
	
		if (!Math::IsNearlyEqual(TopRollAngle, 0.0, WallSettings.TopRollMaximum + 0.01))
			return false;

		//Populate our hit components and start tracing for endlocation
		MantleData.HitComponents.Add(WallTraceHit.Component);
		MantleData.HitComponents.Add(TopTraceHit.Component);
		MantleData.TopHitComponent = TopTraceHit.Component;

		//Store our LedgeLocation
		FVector WallToTopDelta = TopTraceHit.ImpactPoint - PlayerForwardHit.ImpactPoint;
		MantleData.LedgeLocation = PlayerForwardHit.ImpactPoint + (WallRotation.UpVector * (WallToTopDelta.DotProduct(WallRotation.UpVector)));
		MantleData.LedgeLocation += MoveComp.WorldUp * 1;
		
		//Depending on how we want the capsule translation to occur we could offset this by t.ex capsule halfheight but for now run it straight to ledge location
		MantleData.LedgePlayerLocation = MantleData.LedgeLocation;

		//We know we have a valid ledge, perform a shape trace downwards to find our actual plant
		FHazeTraceSettings LedgePlantTrace;
		LedgePlantTrace.TraceWithPlayerProfile(Player);
		LedgePlantTrace.UseSphereShape(Player.CapsuleComponent.CapsuleRadius);
		LedgePlantTrace.UseShapeWorldOffset(Player.MovementWorldUp * Player.CapsuleComponent.CapsuleRadius);

		FVector LedgePlantTraceStart = MantleData.LedgeLocation + (MoveComp.WorldUp * 120);
		FVector LedgePlantTraceEnd = LedgePlantTraceStart - (MoveComp.WorldUp * 140);

		FHitResult LedgePlantHit = LedgePlantTrace.QueryTraceSingle(LedgePlantTraceStart, LedgePlantTraceEnd);

#if !RELEASE
		TemporalLog.HitResults("LedgePlantHit", LedgePlantHit, LedgePlantTrace.Shape, LedgePlantTrace.ShapeWorldOffset);
#endif

		if(LedgePlantHit.bStartPenetrating)
			return false;

		if(!LedgePlantHit.bBlockingHit)
			return false;

#if !RELEASE
		if (bDebug || PlayerLedgeMantle::CVar_DebugLedgeMantle.GetInt() == 1)
		{
			Debug::DrawDebugString(MantleData.LedgePlayerLocation + FVector::UpVector * 15, "LedgeLocation", FLinearColor::DPink, 3);
			Debug::DrawDebugSphere(MantleData.LedgePlayerLocation, 15, LineColor = FLinearColor::Yellow, Duration = 3);
			Debug::DrawDebugString(TopTraceStartlocation, "TopHit", FLinearColor::DPink, 3);
		}
#endif
		//Trace for EndLocation
		FHitResult EndLocationHit;
		FHazeTraceSettings EndLocationTrace = Trace::InitFromMovementComponent(MoveComp);
		EndLocationTrace.TraceWithPlayerProfile(Player);
		EndLocationTrace.UseSphereShape(Player.CapsuleComponent.CapsuleRadius);
		EndLocationTrace.UseShapeWorldOffset(Player.MovementWorldUp * Player.CapsuleComponent.CapsuleRadius);

		FVector EndLocationTraceStart = MantleData.LedgeLocation + (ExitDirection * Math::Max(ExitDistanceToUse, 30) + (MoveComp.WorldUp * 120));
		FVector EndLocationTraceEnd = EndLocationTraceStart - (MoveComp.WorldUp * 140);

		EndLocationHit = EndLocationTrace.QueryTraceSingle(EndLocationTraceStart, EndLocationTraceEnd);

#if !RELEASE
		TemporalLog.HitResults("EndLocationHit", EndLocationHit, EndLocationTrace.Shape, EndLocationTrace.ShapeWorldOffset);
#endif

		//We have a valid EndLocation, verify block / start penetrating
		if (!EndLocationHit.bBlockingHit)
			return false;

		if (EndLocationHit.bStartPenetrating)
			return false;

		//Check for any obstructions inbetween our horizontal start/end location (slightly offset upwards)
		FHitResult ObstructionTraceHit;
		FVector ObstructionTraceStart = EndLocationHit.ImpactPoint + (MoveComp.WorldUp * 25);
		FVector ObstructionTraceEnd = ObstructionTraceStart + (PlayerForwardTraceStartLocation - ObstructionTraceStart).ConstrainToPlane(MoveComp.WorldUp);
		ObstructionTraceHit = EndLocationTrace.QueryTraceSingle(ObstructionTraceStart, ObstructionTraceEnd);

#if !RELEASE
		TemporalLog.HitResults("ObstructionTrace: ", ObstructionTraceHit, EndLocationTrace.Shape, EndLocationTrace.ShapeWorldOffset);
#endif

		if(ObstructionTraceHit.bBlockingHit)
			return false;

		//Populate remaining struct data
		MantleData.VerticalDistance = VerticalDistance;
		MantleData.ExitFloorHit = EndLocationHit;
		MantleData.ExitLocation = EndLocationHit.ImpactPoint + (MoveComp.WorldUp * 1);
		MantleData.FloorRelativeExitLocation = MantleData.ExitFloorHit.Component.WorldTransform.InverseTransformPosition(MantleData.ExitLocation);
		MantleData.ExitFacingDirection = (EndLocationHit.ImpactPoint - TopTraceHit.ImpactPoint).ConstrainToPlane(TopTraceHit.Normal).GetSafeNormal();
		MantleData.bHasCompleteData = true;

		TracedForState = TargetState;

#if !RELEASE
		TemporalLog.Value("Succesful Trace for: ", TargetState);
#endif
		return true;
	}

	bool TraceForScrambleMantle(AHazePlayerCharacter Player, FPlayerLedgeMantleData& MantleData, FPlayerWallScrambleData ScrambleData, bool bDebug = false)
	{
		MantleData.Reset();

		UPlayerMovementComponent MoveComp = UPlayerMovementComponent::Get(Player);

		MantleData.Direction = -ScrambleData.WallHit.Normal.ConstrainToPlane(MoveComp.WorldUp);
		MantleData.WallHit = ScrambleData.WallHit;

		/* TopTrace */
		FHitResult TopTraceHit;

		FHazeTraceSettings TopTraceSettings = Trace::InitFromMovementComponent(MoveComp);
		TopTraceSettings.TraceWithPlayerProfile(Player);
		TopTraceSettings.UseLine();
		TopTraceSettings.UseShapeWorldOffset(FVector::ZeroVector); 

		FVector WallRightVector = ScrambleData.WallHit.Normal.CrossProduct(MoveComp.WorldUp);
		FVector TraceUpDirection = ScrambleData.WallHit.Normal.CrossProduct(-WallRightVector);

#if !RELEASE
		FTemporalLog TempLog = TEMPORAL_LOG(this).Section("ScrambleMantle:");
#endif

		FVector ToWallFlattened = (ScrambleData.WallHit.ImpactPoint - Player.ActorLocation).ConstrainToPlane(MoveComp.WorldUp);
		FVector TopTraceStartLocation = Player.ActorLocation + (TraceUpDirection * Settings.ScrambleTopTraceHeight) + (MantleData.Direction * (Settings.TopTraceDepth + ToWallFlattened.Size()));
		FVector TopTraceEndLocation = TopTraceStartLocation;
		TopTraceEndLocation += -MoveComp.WorldUp * (Settings.ScrambleTopTraceHeight);

		TopTraceHit = TopTraceSettings.QueryTraceSingle(TopTraceStartLocation, TopTraceEndLocation);

#if !RELEASE
		TempLog.HitResults("TopTrace: ", TopTraceHit, TopTraceSettings.Shape, TopTraceSettings.ShapeWorldOffset);
#endif

		if(TopTraceHit.bStartPenetrating)
		{
			TopTraceStartLocation = TopTraceStartLocation + (TraceUpDirection * (Settings.ScrambleTopTraceHeight * 0.2));
			TopTraceHit = TopTraceSettings.QueryTraceSingle(TopTraceStartLocation, TopTraceEndLocation);

#if !RELEASE
		TempLog.HitResults("TopTrace2: ", TopTraceHit, TopTraceSettings.Shape, TopTraceSettings.ShapeWorldOffset);
#endif
			if(TopTraceHit.bStartPenetrating)
				return false;
		}

		if(!TopTraceHit.bBlockingHit)
			return false;

		if(!TopTraceHit.Component.HasTag(n"LedgeClimbable"))
			return false;

		MantleData.TopLedgeHit = TopTraceHit;

		const FRotator TopRotation = FRotator::MakeFromZX(TopTraceHit.ImpactNormal, MantleData.Direction);

		//Pitch Test Surface
		const FVector TopPitchVector = TopRotation.UpVector.ConstrainToPlane(WallRightVector).GetSafeNormal();
		const float TopPitchAngle = Math::Abs(Math::RadiansToDegrees(TopPitchVector.AngularDistance(MoveComp.WorldUp)));

		if(TopPitchAngle > MoveComp.GetWalkableSlopeAngle())
			return false;

		const FVector TopRollVector = TopRotation.UpVector.ConstrainToPlane(MantleData.Direction);
		const float TopRollAngle = Math::Abs(Math::RadiansToDegrees(TopRollVector.AngularDistance(MoveComp.WorldUp)));

		if(TopRollAngle > MoveComp.GetWalkableSlopeAngle())
			return false;

		//We know the ledge is a valid walkable surface rotation wise, now populate our data struct
		MantleData.HitComponents.Add(ScrambleData.WallHit.Component);
		MantleData.HitComponents.Add(TopTraceHit.Component);
		MantleData.TopHitComponent = TopTraceHit.Component;

		//Calculate our edge location
		FVector WallToTopDelta = TopTraceHit.ImpactPoint - ScrambleData.WallHit.ImpactPoint;
		MantleData.LedgeLocation = ScrambleData.WallHit.ImpactPoint + (TraceUpDirection * (WallToTopDelta.DotProduct(TraceUpDirection)));
		
		//Currently we run it straight to the ledge location but this could change if we want to run it through geo linearly to the end location
		MantleData.LedgePlayerLocation = MantleData.LedgeLocation;

		//We know we have a valid ledge, Shape trace downwards for our actual plant
		FHazeTraceSettings LedgePlantTrace;
		LedgePlantTrace.TraceWithPlayerProfile(Player);
		LedgePlantTrace.UseSphereShape(Player.CapsuleComponent.CapsuleRadius);
		LedgePlantTrace.UseShapeWorldOffset(Player.MovementWorldUp * Player.CapsuleComponent.CapsuleRadius);

		FVector LedgePlantTraceStart = MantleData.LedgeLocation + (MoveComp.WorldUp * 120);
		FVector LedgePlantTraceEnd = LedgePlantTraceStart - (MoveComp.WorldUp * 140);

		FHitResult LedgePlantHit = LedgePlantTrace.QueryTraceSingle(LedgePlantTraceStart, LedgePlantTraceEnd);

#if !RELEASE
		TempLog.HitResults("LedgePlant: ", LedgePlantHit, LedgePlantTrace.Shape, LedgePlantTrace.ShapeWorldOffset);
#endif
		if(LedgePlantHit.bStartPenetrating)
			return false;

		if(!LedgePlantHit.bBlockingHit)
			return false;

		//Trace For Endlocation
		FHitResult EndLocationHit;
		FHazeTraceSettings EndLocationTrace;
		EndLocationTrace.TraceWithPlayerProfile(Player);
		EndLocationTrace.UseSphereShape(Player.CapsuleComponent.CapsuleRadius);
		EndLocationTrace.UseShapeWorldOffset(Player.MovementWorldUp * Player.CapsuleComponent.CapsuleRadius);

		//Trace forward with our none sprint top speed * MoveDuration
		FVector EndLocationTraceStart = MantleData.LedgeLocation + (MantleData.Direction * (500 * Settings.ScrambleExitDuration)) + (MoveComp.WorldUp * 120);
		FVector EndLocationTraceEnd = EndLocationTraceStart - (MoveComp.WorldUp * (140));
		
		EndLocationHit = EndLocationTrace.QueryTraceSingle(EndLocationTraceStart, EndLocationTraceEnd);

#if !RELEASE
		TempLog.HitResults("EndLocationHit: ", EndLocationHit, EndLocationTrace.Shape, EndLocationTrace.ShapeWorldOffset);
#endif

		if(!EndLocationHit.bBlockingHit)
			return false;

		if(EndLocationHit.bStartPenetrating)
			return false;

		MantleData.ExitFloorHit = EndLocationHit;
		MantleData.ExitLocation = EndLocationHit.ImpactPoint + (MoveComp.WorldUp * 1);
		MantleData.FloorRelativeExitLocation = EndLocationHit.Component.WorldTransform.InverseTransformPosition(MantleData.ExitLocation);
		MantleData.bHasCompleteData = true;

		return true;
	}

	EPlayerLedgeMantleState GetState() const property
	{
		return CurrentState;
	}

	void SetState(EPlayerLedgeMantleState NewState) property
	{
		CurrentState = NewState;
		AnimData.State = NewState;
		TracedForState = EPlayerLedgeMantleState::Inactive;

		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(Owner);
		if (NewState == EPlayerLedgeMantleState::Inactive)
		{
			if (ImpactedCallbackComp != nullptr)
			{
				ImpactedCallbackComp.RemoveWallAttachInstigator(Player, this);
				ImpactedCallbackComp = nullptr;
			}
		}
		else if(ImpactedCallbackComp == nullptr && Data.HitComponents.Num() != 0)
		{
			for(auto HitComponent : Data.HitComponents)
			{
				if(HitComponent != nullptr)
					continue;

				ImpactedCallbackComp = UMovementImpactCallbackComponent::Get(HitComponent.Owner);
				if(ImpactedCallbackComp != nullptr)
					break;
			}

			if (ImpactedCallbackComp != nullptr)
				ImpactedCallbackComp.AddWallAttachInstigator(Player, this);
		}
	}

	//Verify that we are still in the given state and if so reset all relevant move data
	void StateCompleted(EPlayerLedgeMantleState CompletedState)
	{
		if(CompletedState == GetState())
		{
			Data.Reset();
			SetState(EPlayerLedgeMantleState::Inactive);
		}
	}
};

struct FPlayerLedgeMantleData
{
	bool bHasCompleteData = false;
	bool bEnterCompleted = false;

	float EnterSpeed;
	float EnterDistance;
	float EnterDuration;

	float VerticalDistance;

	float MantleDurationCarryOver;

	FVector Direction;
	FVector LedgeLocation;
	FVector LedgePlayerLocation;

	FVector ExitFacingDirection;
	FVector ExitLocation;
	FVector FloorRelativeExitLocation;

	FHitResult WallHit;
	FHitResult TopLedgeHit;
	FHitResult ExitFloorHit;

	UPrimitiveComponent TopHitComponent;
	TArray<UPrimitiveComponent> HitComponents;

	//Which mantle did enter trace set as our wanted based on trace parameters
	EPlayerLedgeMantleState MantleType;

	void Reset()
	{
		bEnterCompleted = false;
		bHasCompleteData = false;
		EnterSpeed = 0;
		EnterDistance = 0;
		EnterDuration = 0;
		VerticalDistance = 0;
		MantleDurationCarryOver = 0;

		Direction = FVector::ZeroVector;
		LedgeLocation = FVector::ZeroVector;
		LedgePlayerLocation = FVector::ZeroVector;

		TopHitComponent = nullptr;
		HitComponents.Reset();
	}

	bool HasValidData()
	{
		return bHasCompleteData;
	}
}

struct FPlayerLedgeMantleAnimData
{
	UPROPERTY()
	EPlayerLedgeMantleState State;

	UPROPERTY()
	bool bEnterFinished = false;

	UPROPERTY()
	bool bEnterFromRight = false;

	UPROPERTY()
	FVector2D EnterDistanceSpeed;

	void Reset()
	{
		State = EPlayerLedgeMantleState::Inactive;
		bEnterFinished = false;
		bEnterFromRight = false;
		EnterDistanceSpeed = FVector2D::ZeroVector;
	}
}

enum EPlayerLedgeMantleState
{
	Inactive,
	LowMantleEnter,
	LowMantleCloseEnter,
	HighMantleEnter,
	AirborneMantle,
	AirborneRollEnter,
	AirborneRollExit,
	AirborneLowEnter,
	AirborneLowExit,
	ScrambleEnter,
	ScrambleExit,
	FallingLowEnter,
	FallingLowExit,
	JumpClimbEnter,
	JumpClimbExit,
	Exit
}