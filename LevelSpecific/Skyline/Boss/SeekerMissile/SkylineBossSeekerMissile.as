class ASkylineBossSeekerMissile : ASkylineBossProjectile
{
	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		Super::Tick(DeltaSeconds);

		PrintToScreen("SeekerTarget: " + Target, 0.0, FLinearColor::Green);

		FVector ToTarget = Target.ActorLocation - ActorLocation;

		// SeekerLaser TEMP
//		Debug::DrawDebugLine(ActorLocation, ActorLocation + ToTarget, FLinearColor::Red, 10.0, 0.0);

		FVector Force = ToTarget.SafeNormal * 10000.0;

		FVector Acceleration = Force
							 - Velocity * Drag;

		Velocity += Acceleration * DeltaSeconds;

		FQuat TargetRotation = ActorQuat;

		if (!Force.IsNearlyZero())
			TargetRotation = Force.ToOrientationQuat();

		FQuat Rotation = FQuat::Slerp(ActorQuat, TargetRotation, 5.0 * DeltaSeconds);
		SetActorRotation(Rotation);

		FVector DeltaMove = Velocity * DeltaSeconds;

		Move(DeltaMove);
	}
}