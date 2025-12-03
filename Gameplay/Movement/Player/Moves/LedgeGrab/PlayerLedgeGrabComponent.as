
class UPlayerLedgeGrabComponent : UActorComponent
{
	UPlayerLedgeGrabSettings Settings;
	UPlayerLedgeGrabClimbSettings ClimbSettings;
	UPlayerLedgeGrabEnterDropSettings DropSettings;
	UPlayerCrouchSettings CrouchSettings;
	UPlayerWallSettings WallSettings;

	/* 
		Transient Properties
	*/
	protected EPlayerLedgeGrabState CurrentState;
	protected EPlayerLedgeGrabClimbState CurrentClimbState;

	FPlayerLedgeGrabData Data;
	FPlayerLedgeGrabClimbData ClimbData;

	UPROPERTY(BlueprintReadOnly)
	FPlayerLedgeGrabAnimationData AnimData;

	//Override bool to allow snow monkey to LedgeGrab
	bool bSnowMonkeyLedgeGrabActivated = false;

	const float DebugDuration = 0;
	float DashDirectionSign = 0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Settings = UPlayerLedgeGrabSettings::GetSettings(Cast<AHazeActor>(Owner));
		ClimbSettings = UPlayerLedgeGrabClimbSettings::GetSettings(Cast<AHazeActor>(Owner));
		DropSettings = UPlayerLedgeGrabEnterDropSettings::GetSettings(Cast<AHazeActor>(Owner));
		CrouchSettings = UPlayerCrouchSettings::GetSettings(Cast<AHazeActor>(Owner));
		WallSettings = UPlayerWallSettings::GetSettings(Cast<AHazeActor>(Owner));
	}

	EPlayerLedgeGrabState GetState() const property
	{
		return CurrentState;
	}

	EPlayerLedgeGrabClimbState GetClimbState() const property
	{
		return CurrentClimbState;
	}

	void SetState(EPlayerLedgeGrabState NewState) property
	{
		CurrentState = NewState;
		AnimData.State = CurrentState;
	}

	void SetClimbUpState(EPlayerLedgeGrabClimbState NewState) property
	{
		CurrentClimbState = NewState;
		AnimData.ClimbState = NewState;
	}

	// Resets ledge grab to an inactive state, clearing all transient data
	void ResetLedgeGrab()
	{
		CurrentState = EPlayerLedgeGrabState::None;
		CurrentClimbState = EPlayerLedgeGrabClimbState::Inactive;
		Data.Reset();
		ClimbData.Reset();
		AnimData.Reset();
	}

	// Trace for LedgeGrab using player location
	bool TraceForLedgeGrab(AHazePlayerCharacter Player, FVector Direction, FPlayerLedgeGrabData& LedgeGrabData, FInstigator Instigator, bool bDebug = false, float OverrideTraceDistance = 0.0)
	{
		return TraceForLedgeGrabAtLocation(Player, Direction, Player.ActorLocation, LedgeGrabData, Instigator, bDebug, OverrideTraceDistance);
	}

	//Trace for LedgeGrab from defined location
	bool TraceForLedgeGrabAtLocation(AHazePlayerCharacter Player, FVector Direction, FVector Location, FPlayerLedgeGrabData& LedgeGrabData, FInstigator Instigator, bool bDebug = false, float OverrideTraceDistance = 0.0)
	{
		if (Player == nullptr)
			return false;

#if !RELEASE
		FTemporalLog TemporalLog = TEMPORAL_LOG(this).Section(Instigator.ToString());
#endif
		LedgeGrabData.Reset();
		UPlayerMovementComponent MoveComp = UPlayerMovementComponent::Get(Player);	

		/* Wall Trace */
		FHazeTraceSettings WallTraceSettings = Trace::InitFromPrimitiveComponent(Player.CapsuleComponent, bIncludePrimitivesMoveIgnoreActors = true);
		WallTraceSettings.TraceWithPlayerProfile(Player);
		WallTraceSettings.UseSphereShape(Player.CapsuleComponent.CapsuleRadius);

		if (bDebug)
			WallTraceSettings.DebugDraw(DebugDuration);
		
		FVector WallTraceStart = Location + (Player.MovementWorldUp * Settings.WallTraceVerticalOffset);
		FVector WallTraceEnd = WallTraceStart;
		float TraceDistance = OverrideTraceDistance > 0.0 ? OverrideTraceDistance : WallSettings.WallTraceForwardReach;
		WallTraceEnd += Direction.GetSafeNormal() * Math::Max(TraceDistance - Player.CapsuleComponent.CapsuleRadius, Player.CapsuleComponent.CapsuleRadius);

		FHitResult WallTraceHit = WallTraceSettings.QueryTraceSingle(WallTraceStart, WallTraceEnd);

#if !RELEASE
		TemporalLog.HitResults("LedgeTrace", WallTraceHit, WallTraceSettings.Shape, WallTraceSettings.ShapeWorldOffset);
#endif

		if (WallTraceHit.bStartPenetrating)
			return false;
		if (!WallTraceHit.bBlockingHit)
			return false;
		
		// A rotator that is only yawed in the direction of the wall and nothing more
		const FRotator TopRotationComparand = FRotator::MakeFromZX(MoveComp.WorldUp, -WallTraceHit.ImpactNormal);
		if (bDebug)
			Debug::DrawDebugCoordinateSystem(Player.ActorCenterLocation - TopRotationComparand.ForwardVector * 80.0, TopRotationComparand, 50.0, 2.0);

		LedgeGrabData.WallRotation = FRotator::MakeFromXZ(WallTraceHit.ImpactNormal, MoveComp.WorldUp);

		const FVector WallPitchVector = LedgeGrabData.WallRotation.UpVector.ConstrainToPlane(TopRotationComparand.RightVector).GetSafeNormal();
		const float WallPitchAngle = Math::RadiansToDegrees(WallPitchVector.AngularDistance(TopRotationComparand.UpVector) * Math::Sign(WallPitchVector.DotProduct(TopRotationComparand.ForwardVector))); 

		// Check angles of the wall
		if (WallPitchAngle < Settings.LedgePitchMinimum - KINDA_SMALL_NUMBER
				|| WallPitchAngle > Settings.LedgePitchMaximum + KINDA_SMALL_NUMBER)
			return false;

		/* Top Trace
			- First trace horizontally to test small gaps in walls, and fix BSP bugs
			- If that doesn't hit anything, test that vertically to find a top surface
		*/
		{
			FHazeTraceSettings TopTraceForwardSettings = Trace::InitFromMovementComponent(MoveComp);
			TopTraceForwardSettings.TraceWithPlayerProfile(Player);
			TopTraceForwardSettings.UseLine();
			TopTraceForwardSettings.UseShapeWorldOffset(FVector::ZeroVector);

			if (bDebug)
				TopTraceForwardSettings.DebugDraw(DebugDuration);
	
			// How far the forward trace till reach
			FVector TopTraceForwardReach = -WallTraceHit.ImpactNormal * (Player.CapsuleComponent.CapsuleRadius + Settings.TopTraceDepth);
			
			/* Start of the forward trace
				Trace's height is based on the location of the player (constrained so pitched walls don't make you ledge grab higher/lower than you should)
				Trace's horizontal position is based on the impact location
			*/
			FVector TopTraceForwardInitialPosition = WallTraceHit.ImpactPoint;
			TopTraceForwardInitialPosition += WallTraceHit.ImpactNormal.ConstrainToPlane(Player.MovementWorldUp).GetSafeNormal() * Player.CapsuleComponent.CapsuleRadius;
			TopTraceForwardInitialPosition += -Player.MovementWorldUp * ((Location + Player.MovementWorldUp * (Settings.SettleHeight + Settings.TopTraceUpwardsReach)) - TopTraceForwardInitialPosition).DotProduct(-Player.MovementWorldUp);

			// Draw the maximum horizontal range
			if (bDebug)
			{
				Debug::DrawDebugLine(TopTraceForwardInitialPosition, TopTraceForwardInitialPosition + TopTraceForwardReach, FLinearColor::Blue, 1.0, 0.0);
				FVector DownReach = -Player.MovementWorldUp * (Settings.TopTraceUpwardsReach + Settings.TopTraceDownwardsReach);
				Debug::DrawDebugLine(TopTraceForwardInitialPosition + DownReach, TopTraceForwardInitialPosition + DownReach + TopTraceForwardReach, FLinearColor::Blue, 1.0, 0.0);
			}

			const int Iterations = 5;
			const float DistancePerIteration = (Settings.TopTraceUpwardsReach + Settings.TopTraceDownwardsReach) / Iterations;
			for (int Index = 0; Index < Iterations; Index++)
			{
				FVector TopTraceForwardStart = TopTraceForwardInitialPosition;
				TopTraceForwardStart -= Player.MovementWorldUp * DistancePerIteration * Index;
				FVector TopTraceForwardEnd = TopTraceForwardStart + TopTraceForwardReach;
				FHitResult TopTraceForwardHit = TopTraceForwardSettings.QueryTraceSingle(TopTraceForwardStart, TopTraceForwardEnd);
#if !RELEASE
				TemporalLog.HitResults("TopTrace", TopTraceForwardHit, TopTraceForwardSettings.Shape, TopTraceForwardSettings.ShapeWorldOffset);
#endif

				if (TopTraceForwardHit.bStartPenetrating)
					continue;

				/*	
					If you hit something, there is a wall in the way, and you shouln't check down trace
					If you don't hit something, you are in open air, and should trace down to check for a plant
				*/
				if (!TopTraceForwardHit.bBlockingHit)
				{
					FHazeTraceSettings TopTraceDownwardSettings = Trace::InitFromMovementComponent(MoveComp);
					TopTraceDownwardSettings.TraceWithProfile(n"PlayerCharacter");
					TopTraceDownwardSettings.UseLine();
					TopTraceDownwardSettings.UseShapeWorldOffset(FVector::ZeroVector);

					if (bDebug)
					{
						TopTraceDownwardSettings.DebugDraw(DebugDuration);
					}

					FVector TopTraceDownwardStart = TopTraceForwardEnd;
					FVector TopTraceDownwardEnd = TopTraceForwardInitialPosition + TopTraceForwardReach - Player.MovementWorldUp * (Settings.TopTraceUpwardsReach + Settings.TopTraceDownwardsReach);							
					FHitResult TopTraceDownwardHit = TopTraceDownwardSettings.QueryTraceSingle(TopTraceDownwardStart, TopTraceDownwardEnd);
#if !RELEASE
					TemporalLog.HitResults("LedgeTopTrace", TopTraceDownwardHit, TopTraceDownwardSettings.Shape, TopTraceDownwardSettings.ShapeWorldOffset);
#endif
					if (TopTraceDownwardHit.bStartPenetrating)
						continue;

					if (TopTraceDownwardHit.bBlockingHit)
					{
						LedgeGrabData.TopRotation = FRotator::MakeFromZX(TopTraceDownwardHit.ImpactNormal, LedgeGrabData.WallRotation.ForwardVector);

						if (bDebug)
						{
							Debug::DrawDebugCoordinateSystem(WallTraceHit.ImpactPoint, LedgeGrabData.WallRotation, 50.0, 2.0);
							Debug::DrawDebugCoordinateSystem(TopTraceDownwardHit.ImpactPoint, LedgeGrabData.TopRotation, 50.0, 2.0);
						}
						
						// Check angles of the top
						const FVector TopPitchVector = LedgeGrabData.TopRotation.UpVector.ConstrainToPlane(TopRotationComparand.RightVector);
						const float TopPitchAngle = Math::RadiansToDegrees(TopPitchVector.AngularDistance(TopRotationComparand.UpVector) * Math::Sign(TopPitchVector.DotProduct(TopRotationComparand.ForwardVector)));
						if (TopPitchAngle < Settings.LedgePitchMinimum - KINDA_SMALL_NUMBER
							 || TopPitchAngle > Settings.LedgePitchMaximum + KINDA_SMALL_NUMBER)
							continue;

						const FVector TopRollVector = LedgeGrabData.TopRotation.UpVector.ConstrainToPlane(TopRotationComparand.ForwardVector);
						const float TopRollAngle = Math::RadiansToDegrees(TopRollVector.AngularDistance(TopRotationComparand.UpVector));
						if (!Math::IsNearlyEqual(TopRollAngle, 0.0, WallSettings.TopRollMaximum + 0.01))
							continue;
						
						// Set data
						LedgeGrabData.HitComponents.Add(WallTraceHit.Component);
						LedgeGrabData.HitComponents.Add(TopTraceDownwardHit.Component);
						LedgeGrabData.TopHitComponent = TopTraceDownwardHit.Component;

						//Assign a primitive component to follow, eventual follow comp checks could be done here to verify if we should inherit velocity/etc
						LedgeGrabData.FollowComponent = WallTraceHit.Component;

						LedgeGrabData.TopImpactPoint = TopTraceDownwardHit.ImpactPoint;
						FVector WallToTop = TopTraceDownwardHit.ImpactPoint - WallTraceHit.ImpactPoint;
						LedgeGrabData.LedgeLocation = WallTraceHit.ImpactPoint + (LedgeGrabData.WallRotation.UpVector * (WallToTop.DotProduct(LedgeGrabData.WallRotation.UpVector)));
						LedgeGrabData.LedgeRotation = FRotator::MakeFromZX(TopTraceDownwardHit.ImpactNormal, -WallTraceHit.ImpactNormal);					

						// Distance to wall is from edge location (Causes issues where you might not be able to reach it)
						FVector FlattenedNormal = WallTraceHit.ImpactNormal.ConstrainToPlane(Player.MovementWorldUp).GetSafeNormal();
						LedgeGrabData.PlayerLocation = LedgeGrabData.LedgeLocation + (FlattenedNormal * WallSettings.TargetDistanceToWall) - (Player.MovementWorldUp * Settings.SettleHeight);
						// Distance to wall is from the center location
							//FVector SlopeLocation = Math::LinePlaneIntersection(LedgeGrabData.LedgeLocation, LedgeGrabData.LedgeLocation + -LedgeGrabData.WallRotation.UpVector, LedgeGrabData.LedgeLocation - (Player.MovementWorldUp * Settings.Height * 0.5), Player.MovementWorldUp);
							//LedgeGrabData.PlayerLocation = SlopeLocation - LedgeGrabData.LedgeRotation.ForwardVector * 36.0 - Player.MovementWorldUp * Settings.Height * 0.5;
						
						//Assign our component relative player location
						LedgeGrabData.ComponentRelativePlayerLocation = WallTraceHit.Component.WorldTransform.InverseTransformPosition(LedgeGrabData.PlayerLocation);

						LedgeGrabData.PlayerRotation = FRotator::MakeFromXZ(-FlattenedNormal, Player.MovementWorldUp);

						// Trace for if feet are planted
						{
							FHazeTraceSettings FeetTraceSettings = Trace::InitFromMovementComponent(MoveComp);
							FeetTraceSettings.TraceWithPlayerProfile(Player);
							FeetTraceSettings.UseLine();
							FeetTraceSettings.UseShapeWorldOffset(FVector::ZeroVector);
							if (bDebug)
								FeetTraceSettings.DebugDraw(DebugDuration);
							FVector TraceStart = LedgeGrabData.PlayerLocation;
							FVector TraceEnd = TraceStart - (LedgeGrabData.WallImpactNormal.ConstrainToPlane(MoveComp.WorldUp).SafeNormal * (WallSettings.TargetDistanceToWall + 20.0));
							FHitResult FeetHit = FeetTraceSettings.QueryTraceSingle(TraceStart, TraceEnd);

							LedgeGrabData.bFeetPlanted = FeetHit.bBlockingHit;
						}
						return true;
					}
				}
			}
		}
		return false;	
	}

	bool TraceClimbUp(AHazePlayerCharacter Player, FPlayerLedgeGrabClimbData& InClimbData, bool bDebug = false)
	{
		//Do we have a valid ledgegrab
		if (!Data.HasValidData())
			return false;

		if (Player == nullptr)
			return false;

		InClimbData.Reset();

		/*
		 * First trace for standing.
		 * If standing fails, trace for crouching
		 */
		FHitResult TargetTraceHit;
		float TargetLocationDepth = ClimbSettings.TargetLocationDepth;
		if (!TraceResultingLocation(Player, Player.CapsuleComponent.CapsuleHalfHeight, TargetLocationDepth,TargetTraceHit))
			if (!TraceResultingLocation(Player, CrouchSettings.CapsuleHalfHeight, TargetLocationDepth,TargetTraceHit))
				return false;
			else
				InClimbData.bClimbIntoCrouch = true;

		// Trace for target location
		const FVector TargetLocation = Data.LedgeLocation - (Data.TopRotation.ForwardVector * TargetLocationDepth);
		FHazeTraceSettings ReachTraceSettings = Trace::InitChannel(ECollisionChannel::PlayerCharacter);
		ReachTraceSettings.UseLine();

		if (bDebug)
		{
			ReachTraceSettings.DebugDrawOneFrame();
		}
		
		const FVector ReachTraceStart = Data.LedgeLocation + (Player.MovementWorldUp * Player.CapsuleComponent.CapsuleHalfHeight) + (Data.TopRotation.ForwardVector * WallSettings.TargetDistanceToWall);
		const FVector ReachTraceEnd = TargetLocation + Player.MovementWorldUp * Player.CapsuleComponent.CapsuleHalfHeight;
		FHitResult ReachHit = ReachTraceSettings.QueryTraceSingle(ReachTraceStart, ReachTraceEnd);

		if (ReachHit.bStartPenetrating)
			return false;
		if (ReachHit.bBlockingHit)
			return false;

		InClimbData.TargetLocation = TargetTraceHit.Location + Player.MovementWorldUp * 0.001;
		InClimbData.Hit = TargetTraceHit;

		if (bDebug)
		{
			Debug::DrawDebugCapsule(ReachTraceEnd, Player.CapsuleComponent.CapsuleHalfHeight, Player.CapsuleComponent.CapsuleRadius, Player.ActorRotation, FLinearColor::Green, 1.0, 5.0 );
			Debug::DrawDebugCapsule(Player.CapsuleComponent.WorldLocation, Player.CapsuleComponent.CapsuleHalfHeight, Player.CapsuleComponent.CapsuleRadius, Player.ActorRotation, FLinearColor::Red, 1.0, 5.0 );
			Debug::DrawDebugLine(ReachTraceStart, ReachTraceEnd, FLinearColor::Green, 2.0, 5.0);
			Debug::DrawDebugLine(Player.ActorLocation, TargetTraceHit.Location, FLinearColor(1.0, 0.5, 0.0), 2.0, 5.0);

			Debug::DrawDebugLine(TargetTraceHit.TraceStart, TargetTraceHit.TraceEnd, FLinearColor::LucBlue, 2.0, 5.0);
			Debug::DrawDebugCapsule(TargetTraceHit.TraceStart, InClimbData.bClimbIntoCrouch ? CrouchSettings.CapsuleHalfHeight : Player.CapsuleComponent.CapsuleHalfHeight,
										Player.CapsuleComponent.CapsuleRadius, Player.CapsuleComponent.WorldRotation, FLinearColor::LucBlue, 1.0, 5.0);
		}

		return true;
	}

	/*
	 * Return a planting location for the player, where the entire capsule can fit
	 * There are probably better ways, but I wanted to test planting location within a range (to support sloped targets)
	 * If I just trace the capsule, the top of the capsule could hit, even though the floor is lower than the hit.
	 * I opted to do two sphere traces, one for planting, and one upwards to determine if the top of the capsule can fit
	 */
	bool TraceResultingLocation(AHazePlayerCharacter Player, float CapsuleHalfHeightToTest, float TargetDepth, FHitResult& PlantingTraceHit, bool bDebug = false)
	{
		if (bDebug)
		{
			Debug::DrawDebugCapsule(Data.LedgeLocation - (Data.TopRotation.ForwardVector * TargetDepth) + Player.MovementWorldUp * CapsuleHalfHeightToTest,
			CapsuleHalfHeightToTest,
			Player.CapsuleComponent.CapsuleRadius,
			FRotator::ZeroRotator,
			FLinearColor::Green, 1.0, 2.0);
		}

		// How far above/below the Ledge Location do we trace, to find a planting position
		const float PlantingTraceStartHeight = 25.0;
		const float PlantingTraceEndHeight = -25.0;

		// Trace for foot planting first, within the margin
		FHazeTraceSettings TraceSettings = Trace::InitFromPlayer(Player);
		TraceSettings.UseSphereShape(Player.CapsuleComponent.CapsuleRadius);
		TraceSettings.UseShapeWorldOffset(Player.MovementWorldUp * Player.CapsuleComponent.CapsuleRadius);
		if (bDebug)
			TraceSettings.DebugDraw(DebugDuration);

		// Trace for target location
		const FVector TargetLocation = Data.LedgeLocation - (Data.TopRotation.ForwardVector * TargetDepth);
		const FVector PlantingTraceStart = TargetLocation + (Player.MovementWorldUp * PlantingTraceStartHeight);
		const FVector PlantingTraceEnd = TargetLocation + (Player.MovementWorldUp * PlantingTraceEndHeight);

		PlantingTraceHit = TraceSettings.QueryTraceSingle(PlantingTraceStart, PlantingTraceEnd);

		if (PlantingTraceHit.bStartPenetrating)
			return false;
		if (!PlantingTraceHit.bBlockingHit)
			return false;

		const float PlantingDistance = (PlantingTraceStart - PlantingTraceHit.Location).Size();
		const float TraceDistance = ((CapsuleHalfHeightToTest - Player.CapsuleComponent.CapsuleRadius) * 2.0) - PlantingDistance;
		
		// Now that we have a valid planting location, we now trace upwards to make sure the rest of the capsule can fit
		const FVector CapsuleFitTraceStart = PlantingTraceStart;
		const FVector CapsuleFitTraceEnd = CapsuleFitTraceStart + (Player.MovementWorldUp * TraceDistance);
		FHitResult CapsuleFitTraceHit = TraceSettings.QueryTraceSingle(CapsuleFitTraceStart, CapsuleFitTraceEnd);

		if (CapsuleFitTraceHit.bBlockingHit)
			return false;

		return true;
	}
}

struct FPlayerLedgeGrabData
{
	FRotator WallRotation;
	FRotator TopRotation;

	FVector TopImpactPoint;

	TArray<UPrimitiveComponent> HitComponents;
	UPrimitiveComponent TopHitComponent;
	UPrimitiveComponent FollowComponent;

	// Where the top and wall hits meet, to form the point of the ledge to grab on to
	FVector LedgeLocation;
	// The rotation of the edge, used to know which way to shimmy across the edge
	FRotator LedgeRotation;

	FVector PlayerLocation;
	FRotator PlayerRotation;

	// Same as Traced Player Location but in Ledge Relative Space
	FVector ComponentRelativePlayerLocation;

	// Will be updated to actual foot planting vectors in the future
	bool bFeetPlanted = true;

	bool HasValidData()
	{
		return HitComponents.Num() > 0;
	}

	FVector GetWallImpactNormal() property
	{
		return WallRotation.ForwardVector;
	}

	FVector GetTopImpactNormal() property
	{
		return TopRotation.UpVector;
	}

	FVector GetLedgeRightVector() property
	{
		return LedgeRotation.RightVector;
	}

	// Resets the stored data
	void Reset()
	{
		WallRotation = FRotator::ZeroRotator;
		TopRotation = FRotator::ZeroRotator;

		TopImpactPoint = FVector::ZeroVector;

		LedgeLocation = FVector::ZeroVector;
		LedgeRotation = FRotator::ZeroRotator;

		PlayerLocation = FVector::ZeroVector;
		PlayerRotation = FRotator::ZeroRotator;

		ComponentRelativePlayerLocation = FVector::ZeroVector;

		HitComponents.Reset();
		TopHitComponent = nullptr;
		FollowComponent = nullptr;
	}
}

struct FPlayerLedgeGrabClimbData
{
	FVector TargetLocation;
	FHitResult Hit;
	//Dictates trace distance for target location when tracing for valid climb up
	bool bClimbIntoMotion = false;
	//Did traces detect that we need to crouch when exiting climb up
	bool bClimbIntoCrouch = false;

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

		bClimbIntoMotion = false;
		bClimbIntoCrouch = false;
	}
}

//This struct contains anim data for all climb moves (even though LedgeGrabData/LedgeGrabClimbData are separated)
struct FPlayerLedgeGrabAnimationData
{
	// Movement state of ledge grab
	UPROPERTY()
	EPlayerLedgeGrabState State;

	//What kind of climb up we are performing
	UPROPERTY()
	EPlayerLedgeGrabClimbState ClimbState;

	UPROPERTY()
	bool bEnterDropTurnRight = true;

	// Scale of shimmy movement (-1/1) 
	UPROPERTY()
	float ShimmyScale = 0.0;

	//Which direction are we dashing (-1/1)
	UPROPERTY()
	float DashDirectionSign = 0.0;

	// [NYI] Whether the player has a wall to plant feet on, or should dangle the feet
	UPROPERTY()
	bool bCanPlantFeet = true;

	void Reset()
	{
		State = EPlayerLedgeGrabState::None;
		ClimbState = EPlayerLedgeGrabClimbState::Inactive;
		ShimmyScale = 0.0;
	}
}

enum EPlayerLedgeGrabState
{
	None,
	EnterDrop,
	LedgeGrab,
	Climb,
	Dash,
	Cancel
}

enum EPlayerLedgeGrabClimbState
{
	Inactive,
	ClimbToIdle,
	ClimbToIdleCrouch,
	ClimbToMoving,
	ClimbToMovingCrouch
}