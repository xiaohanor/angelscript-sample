struct FSummitStoneBallEnterMovementActivationParams
{
	ASummitStoneBallStatue Statue;
}

class USummitStoneBallEnterMovementCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	default DebugCategory = n"Movement";

	default TickGroup = EHazeTickGroup::BeforeMovement;
	default TickGroupOrder = 90;

	ASummitStoneBall Ball;
	ASummitStoneBallStatue Statue;

	UHazeMovementComponent MoveComp;
	USummitBallMovementData Movement;

	float SplineDistance = 0.0;

	bool bHasIgnoredStatue = false;

	const float EnterAngularImpulse = 5000.0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Ball = Cast<ASummitStoneBall>(Owner);
		Ball.EnterDeathVolume.DisableTrigger(this);

		MoveComp = UHazeMovementComponent::Get(Owner);
		Movement = MoveComp.SetupMovementData(USummitBallMovementData);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FSummitStoneBallEnterMovementActivationParams& Params) const
	{
		if (MoveComp.HasMovedThisFrame())
			return false;

		if(Ball.bHasEntered)
			return false;

		if(Ball.Statue == nullptr)
			return false;

		Params.Statue = Ball.Statue;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return true;

		if(Ball.bHasEntered)
			return true;

		if(Ball.Statue == nullptr)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FSummitStoneBallEnterMovementActivationParams Params)
	{
		Statue = Params.Statue;
		Ball.MoveComp.AddMovementIgnoresActor(this, Statue);
		for(auto Player : Game::Players)
		{
			Ball.MoveComp.AddMovementIgnoresActor(this, Player);
		}
		Ball.EnterDeathVolume.EnableTrigger(this);
		bHasIgnoredStatue = true;

		SplineDistance = 0.0;

		auto EnterSpline = Statue.GetEnterSpline();
		Ball.ActorLocation = GetLocationBasedOnSplineDistance(EnterSpline, SplineDistance);
		Ball.ActorRotation = FRotator::MakeFromZX(FVector::UpVector, EnterSpline.GetRotationAtDistance(0.0).ForwardVector);
		Ball.AngularVelocity += Ball.ActorRightVector * EnterAngularImpulse;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		if(!bHasIgnoredStatue)
			return;

		if(!IsActive()
		&& DeactiveDuration > 0.5)
		{
			Ball.MoveComp.RemoveMovementIgnoresActor(this);
			Ball.EnterDeathVolume.DisableTrigger(this);
			bHasIgnoredStatue = false;
		}
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (MoveComp.PrepareMove(Movement))
		{
			if (HasControl())
			{
				SplineDistance += Statue.StoneBallEnterSpeed * DeltaTime;
				auto EnterSpline = Statue.GetEnterSpline();
				if(SplineDistance <= EnterSpline.Length)
				{
					FVector TargetLocation = GetLocationBasedOnSplineDistance(EnterSpline, SplineDistance);
					Movement.AddDeltaFromMoveTo(TargetLocation);
				}
				else
				{
					Ball.bHasEntered = true;
					FVector TargetLocation = GetLocationBasedOnSplineDistance(EnterSpline, EnterSpline.Length);
					Movement.AddDeltaFromMoveTo(TargetLocation);
					
					float OvershotSpeed = SplineDistance - EnterSpline.Length;
					FVector ExitDirection = EnterSpline.GetDirectionAtDistance(EnterSpline.Length);
					Movement.AddDelta(ExitDirection * OvershotSpeed);
				}
			}
			// Remote update
			else
			{
				Movement.ApplyCrumbSyncedGroundMovement();
			}

			MoveComp.ApplyMove(Movement);
		}
	}

	FVector GetLocationBasedOnSplineDistance(FHazeRuntimeSpline EnterSpline, float Distance) const
	{
		FVector Location;
		Location = EnterSpline.GetLocationAtDistance(Distance);
		return Location;
	}
};