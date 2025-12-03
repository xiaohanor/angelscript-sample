class ASkylineBossVulcanoProjectile : ASkylineBossProjectile
{
	float VulcanoProjectileLaunchSpeed = 10000.0;
	float VulcanoProjectileDamageRadius = 4000.0;

	default bUseLineTrace = true;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		Super::Tick(DeltaSeconds);
		
		FVector Acceleration = (FVector::UpVector * -Gravity.Size());

		Velocity += Acceleration * DeltaSeconds;

		FVector DeltaMove = Velocity * DeltaSeconds;

		Move(DeltaMove);
	}

	FVector GetLaunchDirection(FVector LaunchLocation, FVector TargetLocation, float LaunchSpeed)
	{
		float GravitySize = Gravity.Size();

		FVector Direction;

		FVector ToTarget = TargetLocation - LaunchLocation;
		float LaunchSpeedSquared = LaunchSpeed * LaunchSpeed;
		float DistanceSquared = ToTarget.SizeSquared();

		float Root = LaunchSpeedSquared * LaunchSpeedSquared - GravitySize * (GravitySize * DistanceSquared + (2.0 * ToTarget.Z * LaunchSpeedSquared));

		float Angle = 30.0;

		if (Root >= 0.0)
			Angle = Math::RadiansToDegrees(-Math::Atan2(GravitySize * Math::Sqrt(DistanceSquared), LaunchSpeedSquared + Math::Sqrt(Root)));

		FVector PitchAxis = ToTarget.CrossProduct(FVector::UpVector).SafeNormal;

		Direction = ToTarget.RotateAngleAxis(Angle, PitchAxis).SafeNormal;

		return Direction;
	}
};