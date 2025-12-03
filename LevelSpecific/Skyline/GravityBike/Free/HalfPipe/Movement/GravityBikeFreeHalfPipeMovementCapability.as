struct FGravityBikeFreeHalfPipeMovementActivateParams
{
	FGravityBikeFreeHalfPipeJumpData JumpData;
	float Speed;
};

struct FGravityBikeFreeHalfPipeMovementDeactivateParams
{
	bool bLanded = false;
};

class UGravityBikeFreeHalfPipeMovementCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(GravityBikeFree::HalfPipeTags::GravityBikeFreeHalfPipe);
	default CapabilityTags.Add(GravityBikeFree::HalfPipeTags::GravityBikeFreeHalfPipeMovement);

	default TickGroup = EHazeTickGroup::Movement;
	default TickGroupOrder = 10;

	AGravityBikeFree GravityBike;
	UGravityBikeFreeHalfPipeComponent HalfPipeComp;
	UGravityBikeFreeMovementComponent MoveComp;
	USweepingMovementData Movement;

	UGravityBikeFreeCameraDataComponent CameraDataComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		GravityBike = Cast<AGravityBikeFree>(Owner);
		HalfPipeComp = UGravityBikeFreeHalfPipeComponent::Get(Owner);
		MoveComp = UGravityBikeFreeMovementComponent::Get(GravityBike);
		Movement = MoveComp.SetupSweepingMovementData();

		CameraDataComp = UGravityBikeFreeCameraDataComponent::Get(GravityBike.GetDriver());
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FGravityBikeFreeHalfPipeMovementActivateParams& Params) const
	{
		if(MoveComp.HasMovedThisFrame())
			return false;

		if(!HalfPipeComp.JumpData.IsValid())
			return false;

		Params.JumpData = HalfPipeComp.JumpData;
		Params.Speed = GravityBike.ActorVelocity.DotProduct(HalfPipeComp.JumpData.GetStartDirection());
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate(FGravityBikeFreeHalfPipeMovementDeactivateParams& Params) const
	{
		if(MoveComp.HasMovedThisFrame())
			return true;

		if(!HalfPipeComp.JumpData.IsValid())
		{
			Params.bLanded = HalfPipeComp.JumpData.HasLanded();
			return true;
		}

		if(HalfPipeComp.DistanceAlongTrajectory > HalfPipeComp.JumpData.JumpTrajectoryDistance)
		{
			Params.bLanded = true;
			return true;
		}

		if(GravityBike.HasExploded())
		{
			Params.bLanded = false;
			return true;
		}

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FGravityBikeFreeHalfPipeMovementActivateParams Params)
	{
		HalfPipeComp.JumpData = Params.JumpData;
		HalfPipeComp.Speed = Params.Speed;

		GravityBike.BlockCapabilities(GravityBikeFree::Tags::GravityBikeFreeBoost, this);
		GravityBike.BlockCapabilities(GravityBikeFree::Tags::GravityBikeFreeMovement, this);
		GravityBike.BlockCapabilities(GravityBikeFree::Tags::GravityBikeFreeAlignment, this);
		GravityBike.GetDriver().BlockCapabilities(CapabilityTags::CenterView, this);

		HalfPipeComp.bIsJumping = true;
		HalfPipeComp.DistanceAlongTrajectory = 0;
		HalfPipeComp.RotationState = EGravityBikeFreeHalfPipeRotationState::BackFlip;
		HalfPipeComp.AccRotation.SnapTo(GravityBike.ActorQuat);

		GravityBike.IsAirborne.Apply(true, this);

		HalfPipeComp.JumpData.FromTrigger.OnHalfPipeJumpStarted.Broadcast(GravityBike);

		GravityBike.OnTeleported.AddUFunction(this, n"OnTeleported");
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FGravityBikeFreeHalfPipeMovementDeactivateParams Params)
	{
		GravityBike.UnblockCapabilities(GravityBikeFree::Tags::GravityBikeFreeBoost, this);
		GravityBike.UnblockCapabilities(GravityBikeFree::Tags::GravityBikeFreeMovement, this);
		GravityBike.UnblockCapabilities(GravityBikeFree::Tags::GravityBikeFreeAlignment, this);
		GravityBike.GetDriver().UnblockCapabilities(CapabilityTags::CenterView, this);

		HalfPipeComp.Reset();

		GravityBike.IsAirborne.Clear(this);

		if(IsValid(HalfPipeComp.JumpData.FromTrigger))
			HalfPipeComp.JumpData.FromTrigger.OnHalfPipeJumpEnded.Broadcast(GravityBike, Params.bLanded);

		GravityBike.OnTeleported.Unbind(this, n"OnTeleported");
	}
	
	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(!MoveComp.PrepareMove(Movement))
			return;

		const FVector TrajectoryDir = HalfPipeComp.JumpData.GetJumpTrajectoryDirection(HalfPipeComp.DistanceAlongTrajectory);
		const float Gravity = FVector(0, 0, -1000).DotProduct(TrajectoryDir);
		HalfPipeComp.Speed += Gravity * DeltaTime;
		HalfPipeComp.Speed = Math::Max(HalfPipeComp.Speed, GravityBikeFree::HalfPipe::MinimumVerticalSpeed);
		HalfPipeComp.DistanceAlongTrajectory += HalfPipeComp.Speed * DeltaTime;

		if(HasControl())
		{
			FVector NewLocation = HalfPipeComp.JumpData.CubicInterpolationDistance(HalfPipeComp.DistanceAlongTrajectory);
			FVector Delta = NewLocation - GravityBike.ActorLocation;

			FVector Velocity = Delta / DeltaTime;
			Movement.AddDeltaWithCustomVelocity(Delta, Velocity);

			// Rotation is set by rotation capabilities
			Movement.SetRotation(HalfPipeComp.AccRotation.Value);
			
			GravityBike.AccelerateUpTo(HalfPipeComp.AccRotation.Value.UpVector, TrajectoryDir, 0.1, DeltaTime, this);
		}
		else
		{
			Movement.ApplyCrumbSyncedAirMovement();
		}

		MoveComp.ApplyMove(Movement);

		// const int Resolution = 20;
		// for(int i = 0; i < Resolution; i++)
		// {
		// 	float StartAlpha = i / float(Resolution);
		// 	float EndAlpha = (i + 1.0) / float(Resolution);

		// 	FVector Start = HalfPipeComp.JumpData.CubicInterpolationAlpha(StartAlpha);
		// 	FVector End = HalfPipeComp.JumpData.CubicInterpolationAlpha(EndAlpha);
		// 	Debug::DrawDebugArrow(Start, End, 20, FLinearColor::Green, 20);
		// }
	}

	UFUNCTION()
	private void OnTeleported()
	{
		HalfPipeComp.JumpData.Invalidate();
	}
}