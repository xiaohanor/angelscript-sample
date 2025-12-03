class USanctuaryGhostChaseCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(n"SanctuaryGhost");
	default CapabilityTags.Add(n"SanctuaryGhostChase");

	default TickGroup = EHazeTickGroup::Gameplay;

	ASanctuaryGhost Ghost;

	FHazeAcceleratedFloat AcceleratedFloat;
	float AcitvationTime = 0.0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Ghost = Cast<ASanctuaryGhost>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (Ghost.TargetPlayer == nullptr)
			return false;

		if (Ghost.TargetPlayer.IsPlayerDead())
			return false;

		if (!Ghost.bIsRevealed)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Ghost.TargetPlayer == nullptr)
			return true;

		if (Ghost.TargetPlayer.IsPlayerDead())
			return true;

		if (!Ghost.bIsRevealed)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		AcceleratedFloat.SnapTo(0.0, 0.0);
		AcitvationTime = Time::GameTimeSeconds;

		Ghost.bIsChasing = true;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Ghost.bIsChasing = false;

//		Ghost.Godray.SetRenderedForPlayer(Game::Mio, false);
//		Ghost.Godray.SetRenderedForPlayer(Game::Zoe, false);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		AcceleratedFloat.AccelerateTo(1.0, 4.0, DeltaTime);

		FVector ToPlayer = Ghost.TargetPlayer.ActorLocation - Ghost.ActorLocation;

		float AttackRange = Ghost.AttackRange;

//		if (!CanSeePlayer(Ghost.TargetPlayer))
//			AttackRange = 100.0;

		FVector TargetLocation = GetTargetLocation();

//		FVector TargetLocation = Ghost.TargetPlayer.ActorLocation + FVector::UpVector * 200.0 + (-ToPlayer.SafeNormal * (AttackRange - 100.0)).VectorPlaneProject(FVector::UpVector);

		FVector ToTarget = TargetLocation - Ghost.ActorLocation;
//		Debug::DrawDebugLine(Ghost.ActorLocation, TargetLocation, FLinearColor::Green, 10.0, 0.0);

		FVector Direction = ToTarget.SafeNormal;

		float Distance = Math::Min(ToTarget.Size(), Ghost.ChaseSpeed * (Ghost.LightBirdResponseComp.IsIlluminated() ? 0.0 : 1.0) * DeltaTime);

		FVector DeltaMove = Direction * Distance;

//		float Force = Math::Min(ToTarget.Size(), Ghost.ChaseSpeed * (Ghost.LightBirdResponseComp.IsIlluminated() ? 0.0 : 1.0));
		float Force = Ghost.ChaseSpeed * (Ghost.LightBirdResponseComp.IsIlluminated() ? 0.0 : 1.0);

		FVector Offset = FVector::RightVector * Math::Sin((AcitvationTime + Time::GameTimeSeconds) * 0.8) * 320.0
					   + FVector::UpVector * Math::Sin((AcitvationTime + Time::GameTimeSeconds) * 2.8) * 60.0;

		FVector Acceleration = Direction * Force
							 + Ghost.Avoidance
							 - Ghost.Velocity * 1.0;

		Ghost.Velocity += Acceleration * DeltaTime;

		DeltaMove = Ghost.Velocity * DeltaTime;

		Ghost.ActorLocation += DeltaMove;

		float Alpha = Math::Min(Ghost.RevealDistance * 0.5, ToTarget.Size()) / (Ghost.RevealDistance * 0.5);
		Ghost.Pivot.RelativeLocation = Offset * Alpha * AcceleratedFloat.Value;

		Ghost.Pivot.SetWorldRotation(FQuat::Slerp(Ghost.Pivot.ComponentQuat, ToPlayer.ToOrientationQuat(), DeltaTime * 5.0));

//		Debug::DrawDebugLine(Ghost.ActorLocation, Ghost.ActorLocation + ToTarget, FLinearColor::Green, 10.0, 0.0);


//		Ghost.Godray.ComponentQuat = FQuat::MakeFromZ(-ToPlayer);

//		float GodrayAlpha = Math::Max(0.0, Ghost.TargetPlayer.ViewRotation.ForwardVector.DotProduct(ToPlayer.SafeNormal));
//		PrintToScreen("GodrayAlpha: " + GodrayAlpha, 0.0);
//		Ghost.Godray.GodrayMaterialInstanceDynamic.SetVectorParameterValue(n"Tint", Ghost.Godray.Template.Color * GodrayAlpha);
	}

	bool CanSeePlayer(AHazePlayerCharacter Player)
	{
		auto Trace = Trace::InitChannel(ECollisionChannel::WorldGeometry);
		Trace.IgnoreActor(Ghost);
		Trace.IgnoreActors(Game::Players);
		FVector Start = Ghost.AttackPivot.WorldLocation;
		FVector End = Player.ActorCenterLocation;
		auto HitResult = Trace.QueryTraceSingle(Start, End);

		auto Color = (HitResult.bBlockingHit ? FLinearColor::Red : FLinearColor::Green);
		FVector TraceEnd = (HitResult.bBlockingHit ? HitResult.Location : End);

		Debug::DrawDebugLine(HitResult.TraceStart, TraceEnd, Color, 10.0, 0.0);

		if (HitResult.bBlockingHit)
			return false;
		
		return true;
	}

	FVector GetTargetLocation()
	{
		FVector ToPlayer = Ghost.TargetPlayer.ActorLocation - Ghost.ActorLocation;

		auto Trace = Trace::InitChannel(ECollisionChannel::WorldGeometry);
		Trace.IgnoreActor(Ghost);
		Trace.IgnoreActors(Game::Players);
		FVector Start = Ghost.TargetPlayer.ActorCenterLocation;
		FVector End = Ghost.TargetPlayer.ActorLocation + FVector::UpVector * 200.0 + (-ToPlayer.SafeNormal * (Ghost.AttackRange - 100.0)).VectorPlaneProject(FVector::UpVector);
		auto HitResult = Trace.QueryTraceSingle(Start, End);

		auto Color = (HitResult.bBlockingHit ? FLinearColor::Red : FLinearColor::Green);
		FVector TraceEnd = (HitResult.bBlockingHit ? HitResult.Location : End);

//		Debug::DrawDebugLine(HitResult.TraceStart, TraceEnd, Color, 10.0, 0.0);


		return (HitResult.bBlockingHit ? HitResult.Location : End);
	}
};