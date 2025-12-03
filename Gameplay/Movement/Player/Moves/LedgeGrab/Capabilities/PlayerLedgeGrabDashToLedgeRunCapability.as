
class UPlayerLedgeGrabDashToLedgeRunCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(CapabilityTags::GameplayAction);	
	default CapabilityTags.Add(PlayerMovementTags::CoreMovement);
	default CapabilityTags.Add(PlayerMovementTags::LedgeGrab);
	default CapabilityTags.Add(PlayerMovementTags::WallRun);
	default CapabilityTags.Add(PlayerMovementTags::Dash);
	default CapabilityTags.Add(PlayerLedgeGrabTags::LedgeGrabDash);

	default DebugCategory = n"Movement";
	
	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 25;
	default TickGroupSubPlacement = 11;

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	UPlayerMovementComponent MoveComp;
	USteppingMovementData Movement;

	UPlayerLedgeGrabComponent LedgeGrabComp;
	UPlayerWallRunComponent WallRunComp;

	const float TestTraceDistance = 100.0;

	const float SpeedEnd = 1200.0;
	const float Duration = 0.5;
	const float NoMoveDuration = 0.2;
	
	float SpeedStart = 0.0;
	float DashDirectionScale = 1.0;

	bool bReachedAcceleratedLocation = false;
	FHazeAcceleratedVector AcceleratedLedgeOffset;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MoveComp = UPlayerMovementComponent::Get(Player);
		Movement = MoveComp.SetupSteppingMovementData();

		LedgeGrabComp = UPlayerLedgeGrabComponent::GetOrCreate(Player);
		WallRunComp = UPlayerWallRunComponent::GetOrCreate(Player);
	}

	// UFUNCTION(BlueprintOverride)
	// void PreTick(float DeltaTime)
	// {
	// 	LedgeGrabComp.bLedgeGrabDashCompleted = false;
	// }

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FLedgeGrabDashToLedgeRunActivatonParams& ActivationParams) const
	{
		if (MoveComp.HasMovedThisFrame())
			return false;

		if (LedgeGrabComp.State != EPlayerLedgeGrabState::LedgeGrab)
			return false;

		if (!IsActioning(ActionNames::MovementDash))
			return false;

		if (!LedgeGrabComp.Data.bFeetPlanted)
			return false;

		FVector MoveDirection = LedgeGrabComp.Data.LedgeRightVector * GetAttributeFloat(AttributeNames::MoveRight);
		MoveDirection.Normalize();
		if (MoveDirection.IsNearlyZero())
			return false;

		FVector TestLocation = Player.ActorLocation + MoveDirection * TestTraceDistance;		
		FPlayerLedgeGrabData LedgeGrabData;
		if (!LedgeGrabComp.TraceForLedgeGrabAtLocation(Player, Player.ActorForwardVector, TestLocation, LedgeGrabData, this, IsDebugActive()))
			return false;

		ActivationParams.DashDirectionScale = Math::Sign(LedgeGrabComp.Data.LedgeRightVector.DotProduct(MoveDirection));
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{	
		if (MoveComp.HasMovedThisFrame())
			return true;

		if (ActiveDuration >= Duration)
			return true;

		if (MoveComp.HasWallContact())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FLedgeGrabDashToLedgeRunActivatonParams ActivationParams)
	{
		Player.BlockCapabilities(BlockedWhileIn::LedgeGrab, this);

		DashDirectionScale = ActivationParams.DashDirectionScale;
		//SpeedStart = DashDirection.DotProduct(MoveComp.Velocity);

		bReachedAcceleratedLocation = false;
		FVector PlayerLedgeOffset = Player.ActorLocation - LedgeGrabComp.Data.PlayerLocation;
		AcceleratedLedgeOffset.SnapTo(PlayerLedgeOffset, MoveComp.Velocity);
		
		LedgeGrabComp.SetState(EPlayerLedgeGrabState::Dash);
		LedgeGrabComp.AnimData.ShimmyScale = DashDirectionScale;

		// Player.TriggerEffectEvent(n"PlayerLedgeGrab.DashActivated"); // UNKNOWN EFFECT EVENT NAMESPACE		
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.UnblockCapabilities(BlockedWhileIn::LedgeGrab, this);

		FPlayerWallRunData WallRunData = WallRunComp.TraceForWallRun(Player, -LedgeGrabComp.Data.WallImpactNormal, FInstigator(this, n"OnDeactivated"));
		if (WallRunData.HasValidData())
		{
			//FVector VelocityDirection = LedgeGrabComp.Data.LedgeRightVector * Math::Sign(LedgeGrabComp.Data.LedgeRightVector.DotProduct(DashDirection));
			WallRunData.InitialVelocity = MoveComp.Velocity;
			WallRunComp.StartWallRun(WallRunData);
			WallRunComp.ActiveData.LedgeGrabData = LedgeGrabComp.Data;

			LedgeGrabComp.Data.Reset();
			// LedgeGrabComp.bLedgeGrabDashCompleted = true;
		}

		LedgeGrabComp.AnimData.Reset();

		// Player.TriggerEffectEvent(n"PlayerLedgeGrab.DashDeactivated"); // UNKNOWN EFFECT EVENT NAMESPACE
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		LedgeGrabComp.AnimData.ShimmyScale = DashDirectionScale;

		if (MoveComp.PrepareMove(Movement))
		{
			const float MovePercentage = Math::Clamp((ActiveDuration - NoMoveDuration) / (Duration - NoMoveDuration), 0.0, 1.0);
			FVector MoveDirection = LedgeGrabComp.Data.LedgeRightVector * DashDirectionScale;
			float MoveSpeed = Math::Lerp(SpeedStart, SpeedEnd, MovePercentage);
			FVector DeltaMove = MoveDirection * MoveSpeed * DeltaTime;

			/*
				DO THE SAME THING FOR WALL RUN CLIMB
				Wall runs climb could do thet same logic, just offset from the ledge grab location.. YEE BOY
			*/

			FPlayerLedgeGrabData LedgeGrabData;
			if (LedgeGrabComp.TraceForLedgeGrabAtLocation(Player, -LedgeGrabComp.Data.WallImpactNormal, Player.ActorLocation + DeltaMove, LedgeGrabData, this, IsDebugActive()))
			{
				LedgeGrabComp.Data = LedgeGrabData;

				DeltaMove = (LedgeGrabComp.Data.PlayerLocation) - Player.ActorLocation;
			}
			Movement.AddDelta(DeltaMove);

			// Hug the ledge
			if (!AcceleratedLedgeOffset.Value.IsNearlyZero(SMALL_NUMBER))
			{
				AcceleratedLedgeOffset.AccelerateTo(FVector::ZeroVector, 0.2, DeltaTime);
				FVector PlayerLedgeOffset = Player.ActorLocation - LedgeGrabComp.Data.PlayerLocation;
				FVector LedgeOffsetDelta = AcceleratedLedgeOffset.Value - PlayerLedgeOffset - DeltaMove;
				Movement.AddDeltaWithCustomVelocity(LedgeOffsetDelta, FVector::ZeroVector);
			}
			
			FRotator StartRotation = FRotator::MakeFromXZ(-LedgeGrabComp.Data.WallImpactNormal, MoveComp.WorldUp);
			FRotator TargetRotation = FRotator::MakeFromXZ(MoveDirection, MoveComp.WorldUp);
			FRotator NewRotation = Math::LerpShortestPath(StartRotation, TargetRotation, MovePercentage);
			Movement.SetRotation(NewRotation);
					
			MoveComp.ApplyMoveAndRequestLocomotion(Movement, n"LedgeGrab");

			LedgeGrabComp.AnimData.bCanPlantFeet = LedgeGrabComp.Data.bFeetPlanted;
		}
	}
}

struct FLedgeGrabDashToLedgeRunActivatonParams
{
	float DashDirectionScale = 1.0;
}