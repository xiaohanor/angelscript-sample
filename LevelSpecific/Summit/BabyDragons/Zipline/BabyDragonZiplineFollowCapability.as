struct FBabyDragonZiplineFollowDeactivationParams
{
	bool bReachedEnd = false;
};

class UBabyDragonZiplineFollowCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);	
	default CapabilityTags.Add(n"BabyDragon");
	default CapabilityTags.Add(n"Zipline");

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 4;
	default TickGroupSubPlacement = 10;

	UPlayerTailBabyDragonComponent DragonComp;
	UPlayerMovementComponent MoveComp;
	USteppingMovementData Movement;

	FHazeAcceleratedFloat Speed;
	bool bZiplineFinished = false;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		DragonComp = UPlayerTailBabyDragonComponent::Get(Player);

		MoveComp = UPlayerMovementComponent::Get(Player);
		Movement = MoveComp.SetupSteppingMovementData();
	}
	
	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		// Activate follow after enter is finished
		if (DragonComp.ZiplineState == ETailBabyDragonZiplineState::Enter)
		{
			if (!DragonComp.bZiplineReachedLine)
				return false;
			return true;
		}
		else
		{
			return false;
		}
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate(FBabyDragonZiplineFollowDeactivationParams& Params) const
	{
		if (DragonComp.ZiplineState != ETailBabyDragonZiplineState::Follow)
			return true;
		if (bZiplineFinished)
		{
			Params.bReachedEnd = true;
			return true;
		}
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		DragonComp.AnimationState.Apply(ETailBabyDragonAnimationState::ZiplineFollow, this);
		DragonComp.ZiplineState = ETailBabyDragonZiplineState::Follow;
		bZiplineFinished = false;
		Speed.SnapTo(BabyDragonZipline::ZiplineInitialSpeed);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FBabyDragonZiplineFollowDeactivationParams Params)
	{
		DragonComp.AnimationState.Clear(this);

		// If we reached the end of the zipline, we stop ziplining altogether
		if (Params.bReachedEnd)
		{
			DragonComp.ZiplineState = ETailBabyDragonZiplineState::None;
		}
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		Speed.AccelerateTo(BabyDragonZipline::ZiplineMaxSpeed, BabyDragonZipline::EnterAccelerationDuration, DeltaTime);

		bool bCouldMove = DragonComp.ZiplinePosition.Move(DeltaTime * Speed.Value);
		if (!bCouldMove)
		{
			Player.SetActorVelocity(DragonComp.ZiplinePosition.WorldForwardVector * Speed.Value);
			bZiplineFinished = true;
			return;
		}

		FTransform TargetTransform = DragonComp.ZiplinePosition.WorldTransform;
		FVector TargetLocation = TargetTransform.TransformPosition(BabyDragonZipline::PlayerZiplineOffset);
		Player.SetMovementFacingDirection(TargetTransform.Rotation.ForwardVector.ConstrainToPlane(MoveComp.WorldUp).GetSafeNormal());

		if (MoveComp.PrepareMove(Movement))
		{
			Movement.AddDelta(TargetLocation - Player.ActorLocation);
			Movement.InterpRotationToTargetFacingRotation(800.0);
			MoveComp.ApplyMoveAndRequestLocomotion(Movement, n"BackpackDragonZipline");
			DragonComp.RequestBabyDragonLocomotion(n"BackpackDragonZipline");
		}
	}
}
