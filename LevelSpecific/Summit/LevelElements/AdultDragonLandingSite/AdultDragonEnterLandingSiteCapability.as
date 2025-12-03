enum EAdultDragonEnterLandingSiteState
{
	TowardsBezierStartPoint,
	InBezier,
	Descending
}

class UAdultDragonEnterLandingSiteCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);

	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 1;

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	UPlayerTargetablesComponent TargetablesComp;
	UPlayerMovementComponent MoveComp;
	UAdultDragonLandingSiteComponent LandingSiteComp;
	UAdultDragonLandingSiteSettings Settings;
	UTeleportingMovementData Movement;
	AAdultDragonLandingSite TargetLandingSite;
	UAdultDragonLandingSiteTargetableComponent TargetableComp;
	UCameraUserComponent User;

	float Speed;
	bool bMoveDone = false;
	EAdultDragonEnterLandingSiteState CurrentMoveState = EAdultDragonEnterLandingSiteState::TowardsBezierStartPoint;

	FVector OriginalDragonLocation;
	const float DebugLineWidth = 15.0;

	// How the bezier works, to smooth out the transition from when dragon flies in towards the HeightOffsetPoint and should then transition to moving straight down
	// O────────O ◁─── BezierControlPoint
	// ▲ \		│
	// │	\	│
	// │	  \ O ◁─── HeightOffsetPoint (closest to the site)
	// │
	// Bezier start point (closest to the dragon)

	// Bezier points
	FVector HeightOffsetPoint;
	FVector BezierControlPoint;
	FVector BezierStartPoint;
	float BezierCurveLength;
	float CurrentBezierAlpha;

	const float BezierDebugLineAlphaStep = 0.05;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		TargetablesComp = UPlayerTargetablesComponent::Get(Player);
		LandingSiteComp = UAdultDragonLandingSiteComponent::Get(Player);
		Settings = UAdultDragonLandingSiteSettings::GetSettings(Player);

		MoveComp = UPlayerMovementComponent::Get(Player);
		Movement = MoveComp.SetupTeleportingMovementData();
		User = UCameraUserComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		if (!IsBlocked() && !IsActive())
		{
			TargetablesComp.ShowWidgetsForTargetables(UAdultDragonLandingSiteTargetableComponent);
		}
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FAdultDragonLandingSiteCapabilityActivatedParams& Params) const
	{
		if(MoveComp.HasMovedThisFrame())
			return false;

		if(!WasActionStarted(ActionNames::Interaction))
			return false;

		auto PrimaryTarget = TargetablesComp.GetPrimaryTarget(UAdultDragonLandingSiteTargetableComponent);

		if(PrimaryTarget == nullptr)
			return false;

		AAdultDragonLandingSite LandingSite = Cast<AAdultDragonLandingSite>(PrimaryTarget.Owner);

		if(LandingSite.bLandingSiteOccupied)
			return false;

		Params.TargetableComponent = PrimaryTarget;
		Params.LandingSite = LandingSite;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate(FAdultDragonLandingSiteCapabilityDeactivatedParams& Params) const
	{
		if(MoveComp.HasMovedThisFrame())
			return true;

		if(WasActionStarted(ActionNames::Cancel))
			return true;

		if(bMoveDone)
		{
			Params.bLandedAtSite = true;
			return true;
		}

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FAdultDragonLandingSiteCapabilityActivatedParams Params)
	{
		TargetLandingSite = Params.LandingSite;
		TargetableComp = Params.TargetableComponent;
		TargetLandingSite.bLandingSiteOccupied = true;

		TargetLandingSite.LandingPlayer = Player;
		Speed = MoveComp.Velocity.Size();
		bMoveDone = false;
		CurrentMoveState = EAdultDragonEnterLandingSiteState::TowardsBezierStartPoint;

		OriginalDragonLocation = Player.ActorLocation;
		HeightOffsetPoint = TargetLandingSite.TargetableComponent.WorldLocation + FVector::UpVector * Settings.LandingHeightOffset;
		BezierControlPoint = HeightOffsetPoint + FVector::UpVector * Settings.BezierControlToEndDistance;

		if(Player.ActorLocation.Distance(BezierControlPoint) < Settings.BezierStartToControlDistance)
		{
			// If dragon is closer to the control point than the start point would be at, just set start point of bezier curve to dragons current location.
			BezierStartPoint = Player.ActorLocation;
			CurrentMoveState = EAdultDragonEnterLandingSiteState::InBezier;
		}
		else
		{
			BezierStartPoint = BezierControlPoint + (Player.ActorLocation - BezierControlPoint).GetSafeNormal() * Settings.BezierStartToControlDistance;
		}

		CurrentBezierAlpha = 0.0;

		BezierCurveLength = BezierCurve::GetLength_1CP(BezierStartPoint, BezierControlPoint, HeightOffsetPoint);

		Player.BlockCapabilities(CameraTags::CameraControl, this);
		Player.BlockCapabilities(n"AdultDragon", this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FAdultDragonLandingSiteCapabilityDeactivatedParams Params)
	{
		if(Params.bLandedAtSite)
			LandingSiteComp.EnterLandingSite(TargetLandingSite);
		else
			TargetLandingSite.bLandingSiteOccupied = false;

		Player.UnblockCapabilities(CameraTags::CameraControl, this);
		Player.UnblockCapabilities(n"AdultDragon", this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FRotator NewRotation = Math::RInterpTo(User.GetDesiredRotation(), TargetLandingSite.ActorRotation + Settings.AdditionalCameraRotationOffset, DeltaTime, Settings.CameraInterpSpeedWhenEntering);
		User.SetDesiredRotation(NewRotation, this);

		if(IsDebugActive())
			DrawDebugPath();

		if(MoveComp.PrepareMove(Movement))
		{
			if(HasControl())
			{
				Speed = Math::FInterpTo(Speed, Settings.EnterFlySpeed, DeltaTime, Settings.EnterFlySpeedInterpSpeed);
				float CurrentDelta = Speed * DeltaTime;

				if(CurrentMoveState == EAdultDragonEnterLandingSiteState::TowardsBezierStartPoint)
				{
					if(DoLinearMovement(CurrentDelta, BezierStartPoint))
						CurrentMoveState = EAdultDragonEnterLandingSiteState::InBezier;
				}

				if(CurrentMoveState == EAdultDragonEnterLandingSiteState::InBezier)
				{
					if(DoBezierMovement(CurrentDelta, BezierStartPoint, BezierControlPoint, HeightOffsetPoint, CurrentBezierAlpha))
						CurrentMoveState = EAdultDragonEnterLandingSiteState::Descending;
				}

				if(CurrentMoveState == EAdultDragonEnterLandingSiteState::Descending)
				{
					if(DoLinearMovement(CurrentDelta, TargetLandingSite.TargetableComponent.WorldLocation))
						bMoveDone = true;
				}

				Movement.InterpRotationTo(TargetLandingSite.ActorQuat, Settings.RotationInterpSpeed);
			}
			else
			{
				Movement.ApplyCrumbSyncedAirMovement();
			}
			MoveComp.ApplyMoveAndRequestLocomotion(Movement, n"AdultDragonFlying");
		}
	}

	void DrawDebugPath()
	{
		Debug::DrawDebugLine(OriginalDragonLocation, BezierStartPoint, FLinearColor::Red, DebugLineWidth);

		Debug::DrawDebugSphere(BezierStartPoint, 25.0, 12, FLinearColor::Red);
		Debug::DrawDebugSphere(BezierControlPoint, 25.0, 12, FLinearColor::Red);
		Debug::DrawDebugSphere(HeightOffsetPoint, 25.0, 12, FLinearColor::Red);
		
		float CurrentAlpha = 0.0;
		FVector CurrentPoint = BezierStartPoint;

		while(CurrentAlpha < 1.0)
		{
			CurrentAlpha += BezierDebugLineAlphaStep;
			CurrentAlpha = Math::Min(1.0, CurrentAlpha);

			FVector NewPoint = BezierCurve::GetLocation_1CP(BezierStartPoint, BezierControlPoint, HeightOffsetPoint, CurrentAlpha);

			Debug::DrawDebugLine(CurrentPoint, NewPoint, FLinearColor::Red, DebugLineWidth);
			CurrentPoint = NewPoint;
		}

		Debug::DrawDebugLine(HeightOffsetPoint, TargetLandingSite.TargetableComponent.WorldLocation, FLinearColor::Red, DebugLineWidth);
	}

	/* Will return true if reached TargetPoint, current delta will then be the remaining delta after this move */
	bool DoLinearMovement(float& CurrentDelta, FVector TargetPoint)
	{
		bool bReachedPoint = false;
		float Distance = Player.ActorLocation.Distance(TargetPoint);
		float SubDelta = CurrentDelta;

		if(CurrentDelta > Distance)
		{
			SubDelta = Distance;
			bReachedPoint = true;
		}
		
		Movement.AddDelta((TargetPoint - Player.ActorLocation).GetSafeNormal() * SubDelta);
		return bReachedPoint;
	}

	/* Will return true if reached end of bezier curve, current delta will then be the remaining delta after this move */
	bool DoBezierMovement(float& CurrentDelta, FVector Start, FVector ControlPoint, FVector End, float& CurrentAlpha)
	{
		bool bReachedEnd = false;
		float AlphaToAdd = CurrentDelta / BezierCurveLength;
		float MaxAlphaToAdd = 1.0 - CurrentAlpha;

		if(AlphaToAdd > MaxAlphaToAdd)
		{
			CurrentAlpha = 1.0;
			CurrentDelta = (AlphaToAdd - MaxAlphaToAdd) * BezierCurveLength;
			bReachedEnd = true;
		}
		else
		{
			CurrentAlpha += AlphaToAdd;
		}

		FVector TargetPoint = BezierCurve::GetLocation_1CP(Start, ControlPoint, End, CurrentAlpha);
		Movement.AddDelta(TargetPoint - Player.ActorLocation);
		return bReachedEnd;
	}
}

struct FAdultDragonLandingSiteCapabilityActivatedParams
{
	UAdultDragonLandingSiteTargetableComponent TargetableComponent;
	AAdultDragonLandingSite LandingSite;
}

struct FAdultDragonLandingSiteCapabilityDeactivatedParams
{
	bool bLandedAtSite = false;
}