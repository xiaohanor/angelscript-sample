
class UPlayerWallRunLedgeTurnaroundCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(PlayerMovementTags::CoreMovement);
	default CapabilityTags.Add(PlayerMovementTags::WallRun);
	default CapabilityTags.Add(PlayerMovementTags::LedgeRun);
	default CapabilityTags.Add(PlayerMovementTags::LedgeMovement);
	default CapabilityTags.Add(PlayerWallRunTags::WallRunLedgeTurnaround);

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 32;

	default DebugCategory = n"Movement";

	UPlayerMovementComponent MoveComp;
	USteppingMovementData Movement;

	UPlayerWallRunComponent WallRunComp;
	UPlayerLedgeGrabComponent LedgeGrabComp;

	FHazeAcceleratedVector AcceleratedLedgeOffset;
	FVector InitialVelocity;
	FVector InitialAlignedDirection;
	float InitialDirectionSign;

	float WallOffset;
	
	/*
		TODO[AL]:
		- We may want to calculate / verify that we have enough distance ahead to perform the turnaround (might require some tricky tracing if the ledge isnt straight)
		- We probably wanna check that we covered a minimum distance or had ledgerun active for x amount of time + potentially tracing backwards to check final location (or are we rebounding back to activation location?)

		- verify trace location points as they vary wildly
		- Properly redirect velocity based on wall / ledge angle
	*/

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MoveComp = UPlayerMovementComponent::Get(Player);
		Movement = MoveComp.SetupSteppingMovementData();

		WallRunComp = UPlayerWallRunComponent::GetOrCreate(Player);
		LedgeGrabComp = UPlayerLedgeGrabComponent::GetOrCreate(Player);
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		if(IsActive() && WallRunComp.HasActiveWallRun())
			LedgeGrabComp.TraceForLedgeGrabAtLocation(Player, -WallRunComp.ActiveData.WallRotation.ForwardVector, Player.ActorLocation, WallRunComp.ActiveData.LedgeGrabData, FInstigator(this, n"TurnaroundPreTick"), IsDebugActive());
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(MoveComp.HasMovedThisFrame())
			return false;

		if(!WallRunComp.HasActiveWallRun())
			return false;

		if(WallRunComp.State != EPlayerWallRunState::WallRunLedge)
			return false;

		//Are we giving input away from our velocity direction (Backwards)
		if(MoveComp.MovementInput.GetSafeNormal().DotProduct(MoveComp.HorizontalVelocity.GetSafeNormal()) > -0.75)
			return false;
		
		//Are we giving above a certain amount of input (no accidental triggers)
		if(MoveComp.MovementInput.Size() < 0.35)
			return false;


		FPlayerLedgeGrabData LedgeGrabData;
		if(!LedgeGrabComp.TraceForLedgeGrab(Player, -WallRunComp.ActiveData.WallRotation.ForwardVector, LedgeGrabData, FInstigator(this, n"TurnaroundActivate")))
			return false;

		return true;	
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate(FPlayerWallRunLedgeTurnaroundDeactivationParams& Params) const
	{
		if(MoveComp.HasMovedThisFrame())
			return true;

		if(!WallRunComp.HasActiveWallRun())
			return true;
		
		if(!WallRunComp.ActiveData.LedgeGrabData.HasValidData())
		{
			Params.bWasWallRun = true;
			return true;
		}

		if(MoveComp.IsOnAnyGround())
			return true;

		if(MoveComp.HasWallContact())
		{
			FVector ImpactNormal = MoveComp.WallContact.ImpactNormal.ConstrainToPlane(MoveComp.WorldUp).GetSafeNormal();
			FVector WallNormal = WallRunComp.ActiveData.WallNormal.ConstrainToPlane(MoveComp.WorldUp).GetSafeNormal();

			if (Math::RadiansToDegrees(ImpactNormal.AngularDistance(WallNormal)) >= 30.0)
				return true;
		}

		if(ActiveDuration >= WallRunComp.Settings.TurnaroundSlowDownDuration + WallRunComp.Settings.TurnaroundSpeedUpDuration)
		{
			Params.bMoveCompleted = true;
			return true;
		}

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Player.BlockCapabilities(BlockedWhileIn::WallRun, this);
		WallRunComp.SetState(EPlayerWallRunState::WallRunLedgeTurnaround);

		//Store velocity (We could base our slowdown duration on the current/Max velocity)
		InitialVelocity = MoveComp.Velocity.ConstrainToDirection(WallRunComp.ActiveData.WallRotation.RightVector);

		//Calculate our direction along the current wall
		InitialDirectionSign = Math::Sign(WallRunComp.ActiveData.WallRight.DotProduct(InitialVelocity));
		InitialAlignedDirection = InitialDirectionSign > 0 ? WallRunComp.ActiveData.WallRotation.RightVector : WallRunComp.ActiveData.WallRotation.RightVector * -1;
		InitialAlignedDirection = InitialAlignedDirection.GetSafeNormal();
		WallRunComp.LedgeTurnaroundData.InitiatedForwardDirection = InitialAlignedDirection;

		//Set State bool for current Turnaround camera implementation
		WallRunComp.LedgeTurnaroundData.bSlowingDown = true;

		//Calculate Offset
		const float DistanceToWall = (Owner.ActorCenterLocation - WallRunComp.ActiveData.Location).ConstrainToDirection(WallRunComp.ActiveData.WallNormal).Size();
		WallOffset = DistanceToWall - WallRunComp.WallSettings.TargetDistanceToWall;

		if(IsDebugActive())
		{
			Debug::DrawDebugArrow(WallRunComp.ActiveData.Location, WallRunComp.ActiveData.Location + WallRunComp.ActiveData.WallNormal * 75, LineColor = FLinearColor::Red, Duration = 10);
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FPlayerWallRunLedgeTurnaroundDeactivationParams Params)
	{
		Player.UnblockCapabilities(BlockedWhileIn::WallRun, this);

		//Assign state if we fully complete the move and we have valid ledge grab at our current location
		if(Params.bMoveCompleted)
			WallRunComp.SetState(EPlayerWallRunState::WallRunLedge);
		else if(Params.bWasWallRun)
			WallRunComp.ActiveData.InitialVelocity = MoveComp.Velocity;
		else
			WallRunComp.ResetWallRun();

		//Cleanup
		WallRunComp.LedgeTurnaroundData.Reset();

		if(IsDebugActive())
			Debug::DrawDebugArrow(WallRunComp.ActiveData.Location, WallRunComp.ActiveData.Location + WallRunComp.ActiveData.WallNormal * 75, LineColor = FLinearColor::Green, Duration = 10);

		MoveComp.ClearCrumbSyncedRelativePosition(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(MoveComp.PrepareMove(Movement))
		{
			if(HasControl())
			{
				FVector Velocity;

				if(ActiveDuration >= 0.0 && ActiveDuration <= WallRunComp.Settings.TurnaroundSlowDownDuration)
				{
					float SlowdownAlpha = 1 - (ActiveDuration / WallRunComp.Settings.TurnaroundSlowDownDuration);
					Velocity = InitialVelocity * Math::Pow(SlowdownAlpha, 1.2);

					//Redirect Velocity Along the ledge
					// Velocity = WallRunComp.ActiveData.LedgeGrabData.LedgeRightVector * Velocity.Size() * Math::Sign(WallRunComp.ActiveData.LedgeGrabData.LedgeRightVector.DotProduct(Velocity));
					Movement.AddVelocity(Velocity);
				}
				else
				{
					if(WallRunComp.LedgeTurnaroundData.bSlowingDown)
						WallRunComp.LedgeTurnaroundData.bSlowingDown = false;

					//Recalculate new velocity accelerating up to ledge run speed
					float SpeedupAlpha = (ActiveDuration - WallRunComp.Settings.TurnaroundSlowDownDuration) / WallRunComp.Settings.TurnaroundSpeedUpDuration;

					//Assign new direction (Should be a cleaner way of doing this)
					FVector NewDirection = WallRunComp.ActiveData.WallRotation.RightVector.DotProduct(InitialAlignedDirection * -1) > 0 ? WallRunComp.ActiveData.WallRotation.RightVector : WallRunComp.ActiveData.WallRotation.RightVector * -1;
					Velocity = NewDirection.GetSafeNormal() * WallRunComp.Settings.LedgeGrabTargetSpeed * (0.5 + 0.5 * (Math::Pow(SpeedupAlpha, 0.7)));
					Movement.AddVelocity(Velocity);
				}

				// Hug the wall
				WallOffset = Math::FInterpTo(WallOffset, 0.0, DeltaTime, 20.0);
				FVector WallToTarget = WallRunComp.ActiveData.WallNormal * (WallRunComp.WallSettings.TargetDistanceToWall + WallOffset);
				FVector WallToPlayer = (Owner.ActorCenterLocation - WallRunComp.ActiveData.Location).ConstrainToDirection(WallRunComp.ActiveData.WallNormal);
				FVector WallHugDelta = WallToTarget - WallToPlayer;
				Movement.AddDeltaWithCustomVelocity(WallHugDelta, FVector::ZeroVector, EMovementDeltaType::HorizontalExclusive);

				// Keep capsule rotation aligned with forward ledge direction and let ledge run snap rotation once move finishes
				FRotator TargetRotation = FRotator::MakeFromXZ(WallRunComp.ActiveData.WallRight * InitialDirectionSign, MoveComp.WorldUp);
				Movement.SetRotation(TargetRotation);

				MoveComp.ApplyCrumbSyncedRelativePosition(this, WallRunComp.ActiveData.Component);

				if(IsDebugActive())
				{
					PrintToScreen("Velocity: " + Velocity.Size());
				}
			}
			else
			{
				Movement.ApplyCrumbSyncedAirMovement();
			}

			MoveComp.ApplyMoveAndRequestLocomotion(Movement, n"WallRun");
		}
	}
}

struct FPlayerWallRunLedgeTurnaroundDeactivationParams
{
	bool bMoveCompleted = false;
	bool bWasWallRun = false;
}