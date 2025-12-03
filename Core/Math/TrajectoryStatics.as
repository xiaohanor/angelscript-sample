namespace Trajectory
{

/**
 * Structure containing positions and tangents for a trajectory
 */
struct FTrajectoryPoints
{
	UPROPERTY()
	TArray<FVector> Positions;
	UPROPERTY()
	TArray<FVector> Tangents;

	int Num()
	{
		return Positions.Num();
	}
}

/**
 * This function takes some variables describing a projectile
 * and returns its height at time X
 * Helper function only used in this file
 */
float TrajectoryFunction(float X, float G, float V)
{
	/*
	Formula for the projectile is:
	-G/2 * (X - V/G) + V^2/2G
	Where X is the time
	G is the gravity/s
	V is the initial vertical velocity
	*/

	float Exp = (X - V / G);
	return -(0.5 * G) * Exp * Exp + ((V * V) / (2.0 * G));
}

/**
 * This function takes some variables describing a projectile
 * and returns its height at time X, but also takes into account the
 * 		objects' terminal speed (for example player max fall-speed)
 * Helper function only used in this file
 */
float TrajectoryFunctionWithTerminalSpeed(float X, float G, float V, float TerminalSpeed)
{
	float TimeToReachTerminal = -((-TerminalSpeed) - V);
	TimeToReachTerminal = TimeToReachTerminal / G;

	if (X > TimeToReachTerminal)
	{
		float HeightAtTerminal = TrajectoryFunction(TimeToReachTerminal, G, V);
		return HeightAtTerminal - TerminalSpeed * (X - TimeToReachTerminal);
	}
	
	return TrajectoryFunction(X, G, V);
}

/**
 * Helper function only used in this file
 */
void SplitVectorIntoVerticalHorizontal(FVector Vec, FVector UpVector, FVector& VerticalDirection, float& VerticalLength, FVector& HorizontalDirection, float& HorizontalLength)
{
	//Math::DecomposeVector(VerticalDirection, HorizontalDirection, Vec, UpVector);
	VerticalLength = Vec.DotProduct(UpVector);
	VerticalDirection = UpVector;

	HorizontalDirection = Vec.ConstrainToPlane(UpVector);
	HorizontalLength = HorizontalDirection.Size();
	HorizontalDirection.Normalize();
}

/**
 * Calculates the projectile trajectory based on some velocity, gravity etc.
 * Returns a collection of points and tangents that approximates the trajectory
 * The resolution increases the amount of points (higher resolution = more points)
 */
UFUNCTION(Category = "Trajectory|Calculation")
FTrajectoryPoints CalculateTrajectory(FVector StartLocation, float TrajectoryLength, FVector Velocity, float _GravityMagnitude, float Resolution, float TerminalSpeed = -1.0, FVector WorldUp = FVector::UpVector)
{
	FTrajectoryPoints Result;
	
	// Get horizontal speed and direction
	const float GravityMagnituded = Math::Abs(_GravityMagnitude);
	float HorizontalSpeed = 0.0;
	FVector HorizontalDirection;
	float VerticalSpeed = 0.0;
	FVector VerticalDirection;
	SplitVectorIntoVerticalHorizontal(Velocity, WorldUp, VerticalDirection, VerticalSpeed, HorizontalDirection, HorizontalSpeed);

	// If speed or distance is zero, just get out
	if (HorizontalSpeed <= 0.0 || TrajectoryLength <= 0.0)
	{
		Result.Positions.Add(StartLocation);
		Result.Tangents.Add(Velocity.GetSafeNormal());
		return Result;
	}

	// Total time to fly
	float TotalTime =  TrajectoryLength / ((HorizontalSpeed + Math::Abs(VerticalSpeed)) * 0.5);

	// Calculate number of steps to take, based on the resolution, horizontal and vertical distance
	int Steps = 1;
	if (Resolution > 0.0)
	{
		float ResolutionLength = 500.0 / Resolution;
		Steps = Math::Abs(Math::CeilToInt(TrajectoryLength / ResolutionLength)) + Math::Abs(Math::CeilToInt(TrajectoryLength / (ResolutionLength * 0.4)));
	}

	// Maximum steps
	Steps = Math::Min(Steps, 64);

	TArray<FVector> ResultPoints;

	const float VelocityZ = WorldUp.DotProduct(Velocity);

	for(int i=0; i <= Steps; i++)
	{
		// X is the time
		float X = TotalTime * (float(i) / Steps);

		// Height at time X
		float Eval = 0.0;
		// Tangent at time X (height/s)
		float Tangent = VelocityZ - X * GravityMagnituded;

		if (TerminalSpeed > 0.0)
		{
			Eval = TrajectoryFunctionWithTerminalSpeed(X, GravityMagnituded, VelocityZ, TerminalSpeed);
			Tangent = VelocityZ - X * GravityMagnituded;

			// Limit tangent to terminal speed
			if (Tangent < -TerminalSpeed)
				Tangent = -TerminalSpeed;
		}
		else
		{
			Eval = TrajectoryFunction(X, GravityMagnituded, VelocityZ);
			Tangent = VelocityZ - X * GravityMagnituded;
		}

		FVector TangentVector = HorizontalDirection * HorizontalSpeed + FVector(0.0, 0.0, Tangent);
		TangentVector.Normalize();

		// Add position and tangent
		Result.Positions.Add(StartLocation + FVector(0.0, 0.0, Eval) + HorizontalDirection * HorizontalSpeed * X);
		Result.Tangents.Add(TangentVector);
	}

	return Result;
}

struct FOutCalculateVelocity
{
	FVector Velocity;
	float Time;
	float MaxHeight;
}

/**
 * Calculates the velocity from StartLocation, which hits EndLocation
 * The velocity will have a set HorizontalSpeed, the vertical speed will be calculated
 * TODO: Make this function return the final length of the trajectory
 */
UFUNCTION(Category = "Trajectory|Calculation")
FVector CalculateVelocityForPathWithHorizontalSpeed(FVector StartLocation, FVector EndLocation, float _GravityMagnitude, float HorizontalSpeed, FVector WorldUp = FVector::UpVector)
{
	return CalculateParamsForPathWithHorizontalSpeed(StartLocation, EndLocation, _GravityMagnitude, HorizontalSpeed, WorldUp).Velocity;
}

FOutCalculateVelocity CalculateParamsForPathWithHorizontalSpeed(FVector StartLocation, FVector EndLocation, float _GravityMagnitude, float HorizontalSpeed, FVector WorldUp = FVector::UpVector)
{
	if (StartLocation.Equals(EndLocation))
		return FOutCalculateVelocity();

	// Get distance and stuff
	const float GravityMagnituded = Math::Abs(_GravityMagnitude);
	float HorizontalDistance = 0.0;
	float VerticalDistance = 0.0;
	FVector HorizontalDirection;
	FVector VerticalDirection;
	SplitVectorIntoVerticalHorizontal(
		EndLocation - StartLocation,
		WorldUp,
		VerticalDirection,
		VerticalDistance,
		HorizontalDirection,
		HorizontalDistance
	);
	
	// Horizontal flytime
	float FlyTime = HorizontalDistance / HorizontalSpeed;
	/*
	Calculate vertical velocity to achieve given airtime
	(where the curve equals VerticalDifference after FlyTime seconds) 

	Parabola:
	-G/2 * (X - V/G)^2 + V^2/2G = A

	Which gives:
	X = V / G + sqrt((-2A / G) + (V / G)^2)
	V = ((G * X^2) + 2A) / 2X
	*/
	float VerticalVelocity = (VerticalDistance * 2.0 + (FlyTime * FlyTime * GravityMagnituded)) / (2.0 * FlyTime);

	// Horizontal + Vertical velocity
	FOutCalculateVelocity OutParams;
	OutParams.Velocity = HorizontalDirection * HorizontalSpeed + VerticalDirection * VerticalVelocity;
	OutParams.Time = FlyTime;
	OutParams.MaxHeight = VerticalDistance;
	return OutParams;
}

/**
 * Calculates the projectile velocity from StartLocation, which hits EndLocation
 * The projectile will always reach "Height" in its trajectory
 * Terminal velocity is the maximum downwards velocity of the path
 * 		(for example player fall-speed). It is assumed to be POSITIVE.
 * TODO: Make this function return the final length of the trajectory
 */
UFUNCTION(Category = "Projectile|Calculation")
FOutCalculateVelocity CalculateParamsForPathWithHeight(FVector StartLocation, FVector EndLocation, float _GravityMagnitude, float Height, float TerminalSpeed = -1.0, FVector WorldUp = FVector::UpVector)
{
	if (StartLocation.Equals(EndLocation))
		return FOutCalculateVelocity();

	// Get distance and stuff
	const float GravityMagnitude = Math::Abs(_GravityMagnitude);
	float HorizontalDistance = 0.0;
	float VerticalDistance = 0.0;
	FVector HorizontalDirection;
	FVector VerticalDirection;

	SplitVectorIntoVerticalHorizontal(
		EndLocation - StartLocation,
		WorldUp,
		VerticalDirection,
		VerticalDistance,
		HorizontalDirection,
		HorizontalDistance
	);

	/* Edge cases */
	// Start == End
	if (HorizontalDistance <= 0.0)
		return FOutCalculateVelocity();

	// Height <= 0 (Not possible)
	float _Height = Height;
	if (_Height < 0.0)
		_Height = 0.0;

	// If the vertical distance is greater, it will never reach the target
	// If it's equal, it will reach it at infinite speed
	if (VerticalDistance >= _Height)
		_Height = VerticalDistance + 0.1;
// 		VerticalDistance = _Height - 0.1;

	// Calculation to reach certain height 
	// V = sqrt(2HG)
	float Velocity = Math::Sqrt(2.0 * _Height * GravityMagnitude);

/*
	Calculate the airtime of this curve, ending where the curve reaches target height
	(wheTrajectoryve equals VerticalDifference) 

	Parabola:
	-G/2 * (X - V/G)^2 + V^2/2G = A

	(-2A / G) + (V / G)^2
	*/
	float ValueToSqrt = (-2.0 * VerticalDistance) / GravityMagnitude +
		((Velocity / GravityMagnitude) * (Velocity / GravityMagnitude));

	// negative values will generate NaNs
	if(ValueToSqrt < 0.0)
		return FOutCalculateVelocity();

	// X = V / G + sqrt((-2A / G) + (V / G)^2)
	float FlyTime = Velocity/GravityMagnitude + Math::Sqrt(ValueToSqrt);

	if(!Math::IsFinite(FlyTime))
		return FOutCalculateVelocity();

	// Take terminal velocity into the equation!
	if (TerminalSpeed > 0.0)
	{
		float TimeToReachTerminal = -((-TerminalSpeed) - Velocity);
		TimeToReachTerminal = TimeToReachTerminal / GravityMagnitude;

		// We'll reach terminal before landing!
		if (TimeToReachTerminal < FlyTime)
		{
			// Height on trajectory when terminal is reached
			float TerminalHeight = TrajectoryFunction(TimeToReachTerminal, GravityMagnitude, Velocity);

			float DistanceToFall = TerminalHeight - VerticalDistance;
			float TimeToFall = DistanceToFall / TerminalSpeed;

			FlyTime = TimeToReachTerminal + TimeToFall;
		}
	}
	
	FOutCalculateVelocity Out;
	Out.Velocity = HorizontalDirection * (HorizontalDistance / FlyTime) + (VerticalDirection * Velocity);
	Out.Time = FlyTime;
	Out.MaxHeight = _Height;
	
	// Horizontal speed will be horizontal distance divided by the airtime
	return Out;
}

/**
 * 
 */
UFUNCTION(Category = "Projectile|Calculation")
FVector CalculateVelocityForPathWithHeight(FVector StartLocation, FVector EndLocation, float _GravityMagnitude, float Height, float TerminalSpeed = -1.0, FVector WorldUp = FVector::UpVector)
{
	return CalculateParamsForPathWithHeight(StartLocation, EndLocation, _GravityMagnitude, Height, TerminalSpeed, WorldUp).Velocity;
}

// NOT IMPLEMENTED YET
// UFUNCTION(Calculation= "Projectile|Movement")
//FVector CalculateProjectileVelocityForPathWithSpeed(FVector StartLocation, FVector EndLocation, float Gravity, float Speed)
// {
// 	FVector HoriDiff = EndLocation - StartLocation;
// 	HoriDiff.Z = 0.0;

// 	FVector HoriDir;
// 	float HoriDistance = 0.0;
// 	HoriDiff.ToDirectionAndLength(HoriDir, HoriDistance);

// 	float Velocity = 0.5 * (Math::Sqrt(Speed * Speed - 2.0 * Gravity * HoriDistance) + Speed);
// 	return HoriDir * Velocity + FVector(0.0, 0.0, Speed - Velocity);
// }

/**
 * 
 */
UFUNCTION()
void InitArrivalPhysics(
	AActor StartActor,
	AActor TargetActor,
	FVector& LinearVelocity,
	FVector& LinearAcceleration,
	FVector& AngularVelocity,
	FVector& AngularAcceleration
)
{
	UPrimitiveComponent PrimComp = UPrimitiveComponent::Get(StartActor);

	// Gather ToTarget data.
	FVector ToTarget = TargetActor.GetActorLocation() - StartActor.GetActorLocation();
// 	ToTarget = ToTarget.VectorPlaneProject(FVector::UpVector);
	FVector ToTargetNormalized = ToTarget.GetSafeNormal();
	float ToTargetDistance = ToTarget.Size();

	// Calculate velocity towards target
	LinearVelocity = PrimComp.GetPhysicsLinearVelocity().ProjectOnTo(ToTarget);
// 	LinearVelocity = LinearVelocity.VectorPlaneProject(FVector::UpVector);

	// Calculate acceleration towards target
	FVector LinearAccelerationDirection = ToTarget.GetSafeNormal() * -1.0;
	float LinearAccelerationMagnitude = LinearVelocity.SizeSquared() / (2.0 * ToTarget.Size());
	LinearAcceleration = LinearAccelerationDirection * LinearAccelerationMagnitude;

	// Calculate AngularVelocity towards target
	const FVector ToTargetAngular = ToTarget.CrossProduct(FVector::UpVector);
	AngularVelocity = PrimComp.GetPhysicsAngularVelocityInDegrees() * -1.0;
	AngularVelocity = AngularVelocity.ProjectOnTo(ToTargetAngular);

	// Calculate Angular acceleration towards target
	const float TimeUntilArrival = 2.0 * ToTarget.Size() / LinearVelocity.Size();
	AngularAcceleration = AngularVelocity * (-1.0 / TimeUntilArrival);

	// Turn off physics
	PrimComp.SetSimulatePhysics(false);
}

/**
 * 
 */
UFUNCTION()
void UpdateArrivalPhysics(
	AActor StartActor,
	AActor TargetActor,
	FVector& LinearVelocity,
	FVector& LinearAcceleration,
	FVector& AngularVelocity,
	FVector& AngularAcceleration,
	const float Dt
)
{
	// Update velocities
	LinearVelocity += (LinearAcceleration * Dt);
	AngularVelocity += AngularAcceleration * Dt;

	// Calculate delta moves
	FVector DeltaLinear = LinearVelocity * Dt + LinearAcceleration * 0.5*Dt*Dt;
	FVector DeltaAngular = AngularVelocity * Dt + AngularAcceleration * 0.5*Dt*Dt;
 	FRotator DeltaRotator = FRotator(DeltaAngular.Y, DeltaAngular.Z, DeltaAngular.X);		// This is make FRotator::MakeFromEuler()

	// Apply DeltaMoves
	StartActor.AddActorWorldRotation(DeltaRotator);
	StartActor.AddActorWorldOffset(DeltaLinear);
}

/**
 * 
 */
UFUNCTION()
bool TrajectoryTimeToReachHeight(float Velocity, float GravityMagnitude, float Height, float& OutTime)
{
	/*
	Parabola:
	-G/2 * (X - V/G)^2 + V^2/2G = A

	Which gives:
	X = V / G + sqrt((-2A / G) + (V / G)^2)
	*/
	float ValueToSqrt = ((-Height * 2.0) / GravityMagnitude + Math::Square(Velocity / GravityMagnitude));
	if (ValueToSqrt < 0.0)
		return false;

	OutTime = Velocity / GravityMagnitude + Math::Sqrt(ValueToSqrt);
	return true;
}

/**
 * 
 */
UFUNCTION()
bool TrajectoryPlaneIntersection(FVector Origin, FVector Velocity, FVector PlanePoint, float _GravityMagnitued, FVector& OutIntersection, FVector WorldUp = FVector::UpVector)
{
	const float GravityMagnitued = Math::Abs(_GravityMagnitued);
	float Height = WorldUp.DotProduct(PlanePoint - Origin);

	float VertVelocity = 0.0;
	float HoriVelocity = 0.0;
	FVector VertDirection;
	FVector HoriDirection;
	SplitVectorIntoVerticalHorizontal(Velocity, WorldUp, VertDirection, VertVelocity, HoriDirection, HoriVelocity);

	float AirTime = 0.0;
	if (!TrajectoryTimeToReachHeight(VertVelocity, GravityMagnitued, Height, AirTime))
		return false;

	OutIntersection = Origin + HoriDirection * HoriVelocity * AirTime;
	OutIntersection = OutIntersection.ConstrainToPlane(WorldUp);
	OutIntersection += PlanePoint.ConstrainToDirection(WorldUp);
	return true;
}

/**
 * 
 */
UFUNCTION()
FVector TrajectoryPositionAfterTime(FVector Origin, FVector Velocity, float _GravityMagnitued, float Time, float TerminalSpeed = -1.0, FVector WorldUp = FVector::UpVector)
{
	const float GravityMagnitued = Math::Abs(_GravityMagnitued);
	FVector HorizontalVelocity = Velocity.ConstrainToPlane(WorldUp);
	float VerticalSpeed = Velocity.DotProduct(WorldUp);
	float HeightGain = 0.0;

	if (TerminalSpeed <= 0.0)
		HeightGain = TrajectoryFunction(Time, GravityMagnitued, VerticalSpeed);
	else
		HeightGain = TrajectoryFunctionWithTerminalSpeed(Time, GravityMagnitued, VerticalSpeed, TerminalSpeed);

	return Origin + HorizontalVelocity * Time + WorldUp * HeightGain;
}

/**
 * 
 */
UFUNCTION()
FVector TrajectoryVelocityAfterTime(FVector Velocity, float _GravityMagnitued, float Time, float TerminalSpeed = -1.0, FVector WorldUp = FVector::UpVector)
{
	const float GravityMagnitued = Math::Abs(_GravityMagnitued);
	FVector HorizontalVelocity = Velocity.ConstrainToPlane(WorldUp);
	float VerticalSpeed = Velocity.DotProduct(WorldUp);

	if (TerminalSpeed <= 0.0)
		return HorizontalVelocity + WorldUp * (VerticalSpeed - GravityMagnitued * Time);
	else
		return HorizontalVelocity + WorldUp * Math::Max(-TerminalSpeed, VerticalSpeed - GravityMagnitued * Time);
}

/**
 * 
 */
UFUNCTION()
FVector TrajectoryHighestPoint(FVector Origin, FVector Velocity, float GravityMagnitude, FVector WorldUp = FVector::UpVector)
{
	// If gravity is negative, we will just go upwards forever, so no "highest" point....
	if (GravityMagnitude < 0.0)
		return FVector(MAX_flt);

	float VerticalSpeed = Velocity.DotProduct(WorldUp);

	// If we're moving downwards to start with, the origin is the highest point
	if (VerticalSpeed <= 0.0)
		return Origin;

	// Right!
	// So first, we want to find how long it will take until we reach 0 vertical speed
	float TimeToReachZero = VerticalSpeed / GravityMagnitude;

	// And.. thats the highest point. That's all folks.
	return TrajectoryPositionAfterTime(Origin, Velocity, GravityMagnitude, TimeToReachZero, -1.0, WorldUp);
}

/**
 * 
 */
UFUNCTION()
void DebugDrawTrajectory(FVector Origin, FVector Velocity, FVector Gravity, float TerminalSpeed = -1.0)
{
	FTrajectoryPoints Points = CalculateTrajectory(Origin, 5000.0, Velocity, Gravity.Size(), 1.5, TerminalSpeed, -Gravity.GetSafeNormal());

	for(int i=0; i<Points.Positions.Num() - 1; ++i)
	{
		FVector Start = Points.Positions[i];
		FVector End = Points.Positions[i + 1];

		Debug::DrawDebugLine(Start, End);
	}
}

/**
 * 
 */
UFUNCTION()
void DebugDrawTrajectoryWithDestination(FVector Origin, FVector Destination, FVector Velocity, FVector GravityDirection, float GravityMagnitude, FLinearColor Color = FLinearColor::Red, float Thickness = 10)
{
	FVector HighestPoint = TrajectoryHighestPoint(Origin, Velocity, GravityMagnitude, -GravityDirection);

	FTransform WorldTransform = FTransform::MakeFromXZ(FVector::ForwardVector, -GravityDirection);
	FVector LocalOrigin = WorldTransform.InverseTransformPosition(Origin);
	FVector LocalDestination = WorldTransform.InverseTransformPosition(Destination);
	FVector LocalHighestPoint = WorldTransform.InverseTransformPosition(HighestPoint);
	
	float ParabolaHeight = LocalHighestPoint.Z - (LocalOrigin.Z < LocalDestination.Z ? LocalOrigin.Z : LocalDestination.Z);
	float ParabolaBase = LocalOrigin.DistXY(LocalDestination);

	// Length of a parabola segment formula (b = base, h = height): sqrt(4h²+b²) + b²/2h * log((2h + sqrt(4h²+b²)) / b)
	float ParabolaLengthSqrRt = Math::Sqrt(4 * Math::Square(ParabolaHeight) + Math::Square(ParabolaBase));
	float ParabolaLength = ParabolaLengthSqrRt + (Math::Square(ParabolaBase) / (2 * ParabolaBase)) * Math::Loge((2 * ParabolaHeight + ParabolaLengthSqrRt) / ParabolaBase);

	FTrajectoryPoints Points = CalculateTrajectory(Origin, ParabolaLength, Velocity, GravityMagnitude, 1.5, -1.0, -GravityDirection);

	for(int i=0; i<Points.Positions.Num() - 1; ++i)
	{
		FVector Start = Points.Positions[i];
		FVector End = Points.Positions[i + 1];
		bool bDone = false;

		if((HighestPoint - Destination).GetSafeNormal().DotProduct((End - Destination).GetSafeNormal()) < 0.0)
		{
			End = Destination;
			bDone = true;
		}

		Debug::DrawDebugLine(Start, End, Color, Thickness);
		if(bDone)
			break;
	}
}

/**
 * If we start at speed StartSpeed and accelerate up to TargetSpeed, how long will it take to reach the specified distance
 */
float GetTimeToReachTarget(float Distance, float StartSpeed, float TargetSpeed, float Acceleration)
{
	if (TargetSpeed == StartSpeed)
		return Distance / StartSpeed;

	float AccelerationSign = Math::Sign(TargetSpeed - StartSpeed);
	if (AccelerationSign == 0.0)
		AccelerationSign = 1.0;

	float DirAccel = Math::Abs(Acceleration) * AccelerationSign;
	float AccelTime = (TargetSpeed - StartSpeed) / DirAccel;
	float DistanceOverAccelTime = StartSpeed * AccelTime + 0.5 * DirAccel * AccelTime * AccelTime;

	if (DistanceOverAccelTime * Math::Sign(Distance) > Distance * Math::Sign(Distance))
	{
		// We reach the point during our acceleration period
		// Distance = StartSpeed * Time + 0.5 * DirAccel * Time * Time
		// Quadratic Equation:
		float A = 0.5 * DirAccel;
		float B = StartSpeed;
		float C = -Distance;

		float D = Math::Sqrt(B*B - 4.0*A*C);
		float Root1 = (-B + D) / (2.0 * A);
		if (Root1 >= 0.0)
			return Root1;

		float Root2 = (-B - D) / (2.0 * A);
		if (Root2 >= 0.0)
			return Root2;

		return 0.0;
	}
	else
	{
		// First accelerate, then linear after that
		float DistanceAfterAccel = Distance - DistanceOverAccelTime;
		return AccelTime + DistanceAfterAccel / TargetSpeed;
	}
}

/**
 * If we start at speed StartSpeed and accelerate indefinitely, how long will it take to reach the specified distance
 */
float GetTimeToReachTarget(float Distance, float StartSpeed, float Acceleration)
{
	// We reach the point during our acceleration period
	// Distance = StartSpeed * Time + 0.5 * DirAccel * Time * Time
	// Quadratic Equation:
	float A = 0.5 * Acceleration;
	float B = StartSpeed;
	float C = -Distance;

	float D = Math::Sqrt(B*B - 4.0*A*C);
	float Root1 = (-B + D) / (2.0 * A);
	if (Root1 >= 0.0)
		return Root1;

	float Root2 = (-B - D) / (2.0 * A);
	if (Root2 >= 0.0)
		return Root2;

	return 0.0;
}

/**
 * If we accelerate with constant speed, how fast does our start speed need to be to reach Distance at Time
 */
float GetSpeedToReachTarget(float Distance, float Time, float Acceleration)
{
	if (Math::Abs(Time) == 0.0)
		return 0.0;

	// Distance = StartSpeed * Time + 0.5 * Acceleration * Time * Time
	return (Distance - 0.5 * Acceleration * Time * Time) / Time;
}

/**
 * How fast do we need to accelerate to get to the target in time with the given start speed
 */
float GetAccelerationToReachTarget(float Distance, float Time, float StartSpeed)
{
	if (Math::Abs(Time) == 0.0)
		return 0.0; // Technically this is 'infinite'

	// Distance = StartSpeed * Time + 0.5 * Acceleration * Time * Time
	return (Distance - StartSpeed * Time) / (0.5 * Time * Time);
}

/**
 * How long will it take for a projectile to hit a moving target
 * Returns -1 if the target will never be hit
 */
float GetTimeUntilHitMovingTarget(FVector StartLocation, FVector StartVelocity, FVector TargetLocation, FVector TargetVelocity, float ProjectileSpeed)
{
    const FVector RelativeVelocity = TargetVelocity - StartVelocity;
    const FVector RelativeLocation = TargetLocation - StartLocation;
    const float ProjectileSpeedSquared = Math::Square(ProjectileSpeed);

	// Quadratic equation coefficients
	// ax2 + bx + c = 0
	// This equation with X as time would describe a hyperbola of the distance from the start location to the target over time
    const float A = RelativeVelocity.SizeSquared() - ProjectileSpeedSquared;
    const float B = 2 * RelativeVelocity.DotProduct(RelativeLocation);
	const float C = RelativeLocation.SizeSquared();

	// Discriminant of a quadratic equation:
	// b2 – 4ac
	// If the discriminant is negative, we have no solution (the projectile is too slow)
	// If the discriminant is 0, the projectile is moving in parallel to the target
    const float Discriminant = Math::Square(B) - (4 * A * C);

    if (Discriminant <= 0)
    {
        return -1;
    }
    else
    {
		// The quadratic formula:
		// -b±√(b²-4ac))/(2a)
		// Get the first intersection
        const float InterceptTime = (-B - Math::Sqrt(Discriminant)) / (2 * A);

        if (InterceptTime < 0)
        {
            // Projectile has already passed the target
            return -1;
        }
        else
        {
            return InterceptTime;
        }
    }
}

};