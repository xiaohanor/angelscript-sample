class UIslandStormdrainToxicShiftLedgeMantleComponent : UActorComponent
{
	UPlayerLedgeMantleComponent LedgeMantleComp;
	UPlayerLedgeMantleSettings Settings;
	UPlayerWallSettings WallSettings;

	AHazePlayerCharacter PlayerOwner;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		PlayerOwner = Cast<AHazePlayerCharacter>(Owner);
		LedgeMantleComp = UPlayerLedgeMantleComponent::Get(PlayerOwner);
		Settings = UPlayerLedgeMantleSettings::GetSettings(PlayerOwner);
		WallSettings = UPlayerWallSettings::GetSettings(PlayerOwner);
	}

	// This is an exact copy of UPlayerLedgeMantleComponent::TraceForAirborneMantle just with all FHazeTraceSettings replaced with FIslandToxicShiftHazeTraceSettings and also it will set the traced for state on the original component.
	bool TraceForAirborneMantle(AHazePlayerCharacter Player, FPlayerLedgeMantleData& MantleData, FHitResult WallTraceHit,
		 float TopTraceHeight, float VerticalDeltaCutoff, float ExitTraceDistance, bool bAlignExitWithWallNormal, EPlayerLedgeMantleState TraceForState, bool bDebug = false)
	{
		// OLIVERL BEGIN EDIT
		float MantleDuration = MantleData.EnterDuration;
		// OLIVERL END EDIT

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
		// OLIVERL BEGIN EDIT
		FIslandHazeTraceSettings PlayerForwardTrace = IslandTrace::InitFromMovementComponent(MoveComp);
		PlayerForwardTrace.SetForceFieldTimeOffset(MantleDuration);
		// OLIVERL END EDIT
		PlayerForwardTrace.UseLine();

#if !RELEASE
		if(bDebug || PlayerLedgeMantle::CVar_DebugLedgeMantle.GetInt() == 1)
			PlayerForwardTrace.DebugDraw(3);
#endif

		//Make sure we trace forward along the same height where the prediction impact happend (to detect floating platforms / etc)
		FVector PlayerForwardTraceVerticalOffset = (WallTraceHit.ImpactPoint - Player.ActorLocation).ConstrainToDirection(MoveComp.WorldUp);
		FVector PlayerForwardTraceStartLocation = Player.ActorLocation + PlayerForwardTraceVerticalOffset;
		FVector PlayerForwardTraceEndLocation = PlayerForwardTraceStartLocation;
		PlayerForwardTraceEndLocation += MoveComp.MovementInput.GetSafeNormal() * (MoveComp.HorizontalVelocity.Size() * Settings.AirborneMantleAnticipationTime + Player.ScaledCapsuleRadius);
		FHitResult PlayerForwardHit = PlayerForwardTrace.QueryTraceSingle(PlayerForwardTraceStartLocation, PlayerForwardTraceEndLocation);

		if(!PlayerForwardHit.bBlockingHit)
		{
			//Incase we hit an angled platform weirdly and our first trace missed, perform another trace slightly lower then initial one
			PlayerForwardTraceStartLocation -= MoveComp.WorldUp * 10;
			PlayerForwardTraceEndLocation -= MoveComp.WorldUp * 10;

			PlayerForwardHit = PlayerForwardTrace.QueryTraceSingle(PlayerForwardTraceStartLocation, PlayerForwardTraceEndLocation);

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

		if (WallPitchAngle < Settings.WallPitchMinimum - KINDA_SMALL_NUMBER || WallPitchAngle > Settings.WallPitchMaximum + KINDA_SMALL_NUMBER)
			return false;

		/* Top Trace */
		FHitResult TopTraceHit;
		// OLIVERL BEGIN EDIT
		FIslandHazeTraceSettings TopTraceSettings = IslandTrace::InitFromMovementComponent(MoveComp);
		TopTraceSettings.SetForceFieldTimeOffset(MantleDuration);
		// OLIVERL END EDIT
		TopTraceSettings.UseLine();

#if !RELEASE
		if(bDebug || PlayerLedgeMantle::CVar_DebugLedgeMantle.GetInt() == 1)
			TopTraceSettings.DebugDraw(3);
#endif

		//Check if we should align our top/Exit direction with wall normal or not
		FVector ExitDirection = bAlignExitWithWallNormal ? -WallTraceHit.Normal : ToWallFlattened.GetSafeNormal();

		FVector TopTraceStartlocation = Player.ActorLocation + ToWallFlattened + (ExitDirection * Settings.TopTraceDepth);
		FVector TopTraceEndLocation = TopTraceStartlocation;
		TopTraceStartlocation += Player.MovementWorldUp * TopTraceHeight;

		TopTraceHit = TopTraceSettings.QueryTraceSingle(TopTraceStartlocation, TopTraceEndLocation);

		if (TopTraceHit.bStartPenetrating)
			return false;

		if (!TopTraceHit.bBlockingHit)
			return false;

		//Verify Ledge tag
		if(!TopTraceHit.Component.HasTag(n"LedgeClimbable"))
			return false;
		
		MantleData.TopLedgeHit = TopTraceHit;

		float VerticalDelta = (TopTraceHit.ImpactPoint - Player.ActorLocation).ConstrainToDirection(MoveComp.WorldUp).Size();

		//Check if we are within the high requirement
		if(VerticalDelta > VerticalDeltaCutoff)
			return false;

		//Which Airborne move should we branch to (Will dictate trace parameters from here on)
		if (TraceForState == EPlayerLedgeMantleState::AirborneMantle)
		{
			if(VerticalDelta > Settings.AirborneRollMantleVerticalCutOff)
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
		
		if (TopPitchAngle < WallSettings.TopPitchMinimum - KINDA_SMALL_NUMBER
				|| TopPitchAngle > WallSettings.TopPitchMaximum + KINDA_SMALL_NUMBER)
			return false;

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
		// OLIVERL BEGIN EDIT
		FIslandHazeTraceSettings LedgePlantTrace;
		LedgePlantTrace.SetForceFieldTimeOffset(MantleDuration);
		// OLIVERL END EDIT
		LedgePlantTrace.TraceWithPlayerProfile(Player);
		LedgePlantTrace.UseSphereShape(Player.CapsuleComponent.CapsuleRadius);
		LedgePlantTrace.UseShapeWorldOffset(Player.MovementWorldUp * Player.CapsuleComponent.CapsuleRadius);

		FVector LedgePlantTraceStart = MantleData.LedgeLocation + (MoveComp.WorldUp * 120);
		FVector LedgePlantTraceEnd = LedgePlantTraceStart - (MoveComp.WorldUp * 140);

		FHitResult LedgePlantHit = LedgePlantTrace.QueryTraceSingle(LedgePlantTraceStart, LedgePlantTraceEnd);

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
		// OLIVERL BEGIN EDIT
		FIslandHazeTraceSettings EndLocationTrace = IslandTrace::InitFromMovementComponent(MoveComp);
		EndLocationTrace.SetForceFieldTimeOffset(MantleDuration);
		// OLIVERL END EDITs
		EndLocationTrace.TraceWithPlayerProfile(Player);
		EndLocationTrace.UseSphereShape(Player.CapsuleComponent.CapsuleRadius);
		EndLocationTrace.UseShapeWorldOffset(Player.MovementWorldUp * Player.CapsuleComponent.CapsuleRadius);

		FVector EndLocationTraceStart = MantleData.LedgeLocation + (ExitDirection * Math::Max(ExitDistanceToUse, 30) + (MoveComp.WorldUp * 120));
		FVector EndLocationTraceEnd = EndLocationTraceStart - (MoveComp.WorldUp * 140);

#if !RELEASE
		if (bDebug || PlayerLedgeMantle::CVar_DebugLedgeMantle.GetInt() == 1)
		{
			EndLocationTrace.DebugDraw(3);
			Debug::DrawDebugString(EndLocationTraceStart, "ExitLocation", FLinearColor::DPink, 5);
		}
#endif
		EndLocationHit = EndLocationTrace.QueryTraceSingle(EndLocationTraceStart, EndLocationTraceEnd);

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
		if (bDebug || PlayerLedgeMantle::CVar_DebugLedgeMantle.GetInt() == 1)
			Debug::DrawDebugString(ObstructionTraceEnd, "ObstructionTrace", FLinearColor::Red, 5);
#endif

		if(ObstructionTraceHit.bBlockingHit)
			return false;

		//Populate remaining struct data
		MantleData.VerticalDistance = VerticalDelta;
		MantleData.ExitFloorHit = EndLocationHit;
		MantleData.ExitLocation = EndLocationHit.ImpactPoint + (MoveComp.WorldUp * 1);
		MantleData.FloorRelativeExitLocation = MantleData.ExitFloorHit.Component.WorldTransform.InverseTransformPosition(MantleData.ExitLocation);
		MantleData.ExitFacingDirection = (EndLocationHit.ImpactPoint - TopTraceHit.ImpactPoint).ConstrainToPlane(TopTraceHit.Normal).GetSafeNormal();
		MantleData.bHasCompleteData = true;

		// OLIVERL BEGIN EDIT
		LedgeMantleComp.TracedForState = TargetState;
		// OLIVERL END EDIT

		return true;
	}
}