class UMoonMarketSnailMovementCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);

	default TickGroup = EHazeTickGroup::Movement;

	AMoonMarketSnail Snail;
	UMoonMarketRideSnailComponent SnailComp;
	UHazeMovementComponent PlayerMovementComp;
	UHazeMovementComponent MoveComp;
	USteppingMovementData MoveData;

	const float GroundOffset = 10;

	float CurrentSpineYaw = 0;
	FQuat CurrentSpineRotation;
	float MoveSpeed = 0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Snail = Cast<AMoonMarketSnail>(Owner);
		MoveComp = Snail.MoveComp;
		MoveData = MoveComp.SetupSteppingMovementData();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(Snail.InteractingPlayer == nullptr)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(Snail.InteractingPlayer == nullptr)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Snail.bIsHome = false;
		SnailComp = UMoonMarketRideSnailComponent::Get(Snail.InteractingPlayer);
		PlayerMovementComp = UHazeMovementComponent::Get(Snail.InteractingPlayer);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		SnailComp = nullptr;
		PlayerMovementComp = nullptr;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(!MoveComp.PrepareMove(MoveData))
			return;

		if(HasControl())
		{
			MoveData.AddOwnerVerticalVelocity();
			
			FVector Velocity;
			FVector TargetDirection = PlayerMovementComp.MovementInput;

			if(!TargetDirection.IsNearlyZero())
			{
				MoveSpeed = Math::FInterpConstantTo(MoveSpeed, SnailComp.Snail.MoveSpeed, DeltaTime, 100);
				FQuat ProjectedQuat = FQuat::MakeFromZX(MoveComp.WorldUp, TargetDirection);
				FQuat Rotation = Math::QInterpTo(SnailComp.Snail.GetActorQuat(), ProjectedQuat, DeltaTime, SnailComp.Snail.RotateSpeed);
				

				if(!IsShellBlocked(Rotation))
				{
					MoveData.SetRotation(Rotation);
				}
				else
				{
					Velocity += ProjectedQuat.ForwardVector * MoveSpeed;
					MoveData.SetRotation(Math::QInterpTo(SnailComp.Snail.GetActorQuat(), Snail.ActorVelocity.ToOrientationQuat(), DeltaTime, SnailComp.Snail.RotateSpeed));
				}
			}
			else
			{
				MoveSpeed = Math::FInterpConstantTo(MoveSpeed, 0, DeltaTime, 200);
			}

			Velocity += SnailComp.Snail.ActorForwardVector * MoveSpeed;
			Velocity = Velocity.GetSafeNormal() * Math::Min(Snail.MoveSpeed, Velocity.Size());

			MoveData.AddHorizontalVelocity(Velocity);
			MoveData.AddGravityAcceleration();
		}
		else
		{
			MoveData.ApplyCrumbSyncedGroundMovement();
		}

		MoveComp.ApplyMove(MoveData);

		if(MoveComp.Velocity.Size() > 0)
		Snail.TrailComp.SetWorldLocation(Snail.SkelMeshComp.GetSocketLocation(n"Tail3"));
	}

	bool IsShellBlocked(FQuat NewRotation)
	{
		//Copy the snail's current transform
		FTransform RotatedTransform = Snail.ActorTransform;
		//Set rotation on new transform
		RotatedTransform.SetRotation(NewRotation);

		float TraceRadius = Snail.ShellCollission.SphereRadius;
		FVector ShellRelativeLocation = Snail.ActorTransform.InverseTransformPosition(Snail.ShellCollission.WorldLocation);
		//Get desired world position of shell after rotation
		FVector NewShellLocation = RotatedTransform.TransformPosition(ShellRelativeLocation) + FVector::UpVector * TraceRadius / 2;

		//Overlap check at desired shell location
		FHazeTraceSettings Trace = Trace::InitProfile(n"PlayerCharacter");
		Trace.IgnoreActor(Snail);
		Trace.IgnorePlayers();
		Trace.UseSphereShape(TraceRadius);

		FHitResultArray Hits = Trace.QueryTraceMulti(NewShellLocation, NewShellLocation + FVector::UpVector * TraceRadius / 2);
		for(auto Hit : Hits)
		{
			//If the overlap hits anything, the snail will be blocked from rotating
			if(Hit.bBlockingHit)
			{
				//Debug::DrawDebugSphere(NewShellLocation, TraceRadius);
				return true;
			}
		}

		return false;
	}

	FHitResult TraceForEdge(FVector MoveDelta) const
	{
		FHazeTraceSettings TraceSettings = Trace::InitObjectType(EObjectTypeQuery::WorldStatic);
		TraceSettings.UseLine();
		TraceSettings.IgnoreActor(Owner);
		TraceSettings.IgnoreActor(SnailComp.Snail);

		const FVector Start = SnailComp.Snail.ActorLocation + FVector::UpVector * 10 + MoveDelta;
		const FVector End = SnailComp.Snail.ActorLocation + FVector::DownVector * 50 + MoveDelta;
		FHitResult GroundHit = TraceSettings.QueryTraceSingle(Start, End);

		Debug::DrawDebugLine(Start, End, GroundHit.bBlockingHit ? FLinearColor::Green : FLinearColor::Red, bDrawInForeground = true);

		return GroundHit;
	}
};