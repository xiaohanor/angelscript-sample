namespace Acceleration
{
	float GetMaxSpeed(float Acceleration, float Friction)
	{
		if (Acceleration < SMALL_NUMBER)
			return 0.0;
		if (Friction < SMALL_NUMBER)
			return BIG_NUMBER;
		return Acceleration / Friction;
	}

	//  Based on calculate maximum height formula: h=v²/(2g). (this will be relative to the current height)
	float GetMaxHeight(float CurrentVerticalSpeed, float GravityForce)
	{
		return Math::Square(CurrentVerticalSpeed) / (2.0 * GravityForce);
	}


	/**
	* For an accelerated and decelerated movement, calculate the distance travelled at the specified time,
	* assuming that the movement accelerates up to a specific speed.
	* 
	* @param CurrentTime Time to calculate distance travelled for
	* @param Speed How fast to move after acceleration
	* @param TotalDuration Total duration of the entire movement
	* @param AccelerationDuration How much time at the beginning of the movement to accelerate up to Speed
	* @param DecelerationDuration How much time at the end of the movement to decelerate back down to 0
	*/
	float GetDistanceAtTimeWithSpeed(float CurrentTime, float Speed, float TotalDuration, float AccelerationDuration = 0.0, float DecelerationDuration = 0.0)
	{
		float Distance = 0.0;

		// Distance covered accelerating
		if (AccelerationDuration > 0.0)
		{
			float AccelTime = Math::Min(CurrentTime, AccelerationDuration);
			Distance += AccelTime * 0.5 * (Speed / AccelerationDuration * AccelTime);
		}

		// Distance covered decelerating
		float DecelStartTime = TotalDuration - DecelerationDuration;
		if (DecelerationDuration > 0.0)
		{
			if (CurrentTime > DecelStartTime)
			{
				float DecelTime = Math::Max(CurrentTime - DecelStartTime, 0.0);
				float DecelSpeed = Speed - (Speed / DecelerationDuration) * DecelTime;

				Distance += DecelTime * DecelSpeed;
				Distance += DecelTime * 0.5 * (Speed - DecelSpeed);
			}
		}

		// Distance covered moving at constant speed
		float ConstantTime = Math::Max(Math::Min(CurrentTime, DecelStartTime) - AccelerationDuration, 0.0);
		Distance += ConstantTime * Speed;

		return Distance;
	}

	/**
	* For an accelerated and decelerated movement, calculate the distance travelled at the specified time,
	* assuming that the movement ends up at a specified final destination
	* 
	* @param CurrentTime Time to calculate distance travelled for
	* @param FinalDistance Distance to reach at the end of the entire movement
	* @param TotalDuration Total duration of the entire movement
	* @param AccelerationDuration How much time at the beginning of the movement to accelerate up to Speed
	* @param DecelerationDuration How much time at the end of the movement to decelerate back down to 0
	*/
	float GetDistanceAtTimeWithDestination(float CurrentTime, float FinalDistance, float TotalDuration, float AccelerationDuration = 0.0, float DecelerationDuration = 0.0)
	{
		// Calculate the constant speed we need to go to to end up at this distance
		// float Distance = (AccelerationDuration * 0.5 * Speed) + (DecelerationDuration * 0.5 * Speed) + (TotalDuration - AccelerationDuration - DecelerationDuration) * Speed;
		// float Distance = Speed * ((AccelerationDuration * 0.5) + (DecelerationDuration * 0.5) + (TotalDuration - AccelerationDuration - DecelerationDuration));
		float Speed = FinalDistance / ((AccelerationDuration * 0.5) + (DecelerationDuration * 0.5) + (TotalDuration - AccelerationDuration - DecelerationDuration));
		return GetDistanceAtTimeWithSpeed(CurrentTime, Speed, TotalDuration, AccelerationDuration, DecelerationDuration);
	}

	float GetFrameMovementWithDestination(float FrameTime, float DeltaTime, float FinalDistance, float TotalDuration, float AccelerationDuration = 0.0, float DecelerationDuration = 0.0)
	{
		float LastFrameTime = Math::Max(FrameTime - DeltaTime, 0.0);
		float Speed = FinalDistance / ((AccelerationDuration * 0.5) + (DecelerationDuration * 0.5) + (TotalDuration - AccelerationDuration - DecelerationDuration));
		return 
			GetDistanceAtTimeWithSpeed(FrameTime, Speed, TotalDuration, AccelerationDuration, DecelerationDuration)
			- GetDistanceAtTimeWithSpeed(LastFrameTime, Speed, TotalDuration, AccelerationDuration, DecelerationDuration);
	}

	/** 
	 * Get the total distance covered by starting at StartSpeed and accelerating up to EndSpeed over AccelerationDuration seconds
	 * 
	 * @param CurrentTime Time to calculate distance travelled for
	 * @param AccelerationDuration How much time at the beginning of the movement to accelerate up to EndSpeed
	 * @param StartSpeed Starting speed to move at
	 * @param EndSpeed Ending speed to accelerate up to over AccelerationDuration seconds
	 */
	float GetDistanceAtTimeWithAcceleration(float CurrentTime, float AccelerationDuration, float StartSpeed, float EndSpeed)
	{
		float Distance = 0.0;

		// Distance during acceleration
		if (AccelerationDuration > 0)
		{
			float AccelTime = Math::Min(CurrentTime, AccelerationDuration);
			float Acceleration = (EndSpeed - StartSpeed) / AccelerationDuration;
			Distance += StartSpeed * AccelTime;
			Distance += Acceleration * 0.5 * Math::Square(AccelTime);
		}

		// Distance from travel at end speed
		Distance += EndSpeed * Math::Max(0.0, CurrentTime - AccelerationDuration);

		return Distance;
	}

	/**
	 * Interpolate a speed towards a target with a constant acceleration.
	 * Also outputs a delta movement to apply to make framerate-independent movement.
	 * 
	 * NB. Apply the delta movement _in addition_ to applying the new speed.
	 * 
	 * NB. Make sure the added delta does _not_ also apply its own velocity to the movement.
	 * i.e use AddDeltaWithCustomVelocity()
	 */
	float FInterpSpeedConstantToFramerateIndependent(
		float CurrentSpeed,
		float TargetSpeed,
		float DeltaSeconds,
		float InterpSpeed,
		float&out OutDeltaToAddTo,
	) no_discard
	{
		const float TargetSpeedDistance = Math::Abs(TargetSpeed - CurrentSpeed);
		const float MaxChange = DeltaSeconds * InterpSpeed;

		if (MaxChange <= 0.0)
		{
			OutDeltaToAddTo += 0.0;
			return CurrentSpeed;
		}

		if (MaxChange < TargetSpeedDistance)
		{
			// We can't reach the target speed this frame
			if (TargetSpeed > CurrentSpeed)
			{
				OutDeltaToAddTo += -MaxChange * 0.5 * DeltaSeconds;
				return CurrentSpeed + MaxChange;
			}
			else
			{
				OutDeltaToAddTo += MaxChange * 0.5 * DeltaSeconds;
				return CurrentSpeed - MaxChange;
			}
		}
		else
		{
			// We will reach the target speed somewhere this frame
			const float TimeAccelerating = TargetSpeedDistance / InterpSpeed;

			OutDeltaToAddTo += (CurrentSpeed - TargetSpeed) * 0.5 * TimeAccelerating;
			return TargetSpeed;
		}
	}

	/**
	 * Interpolate a velocity towards a target with a constant acceleration.
	 * Also outputs a delta movement to apply to make framerate-independent movement.
	 * 
	 * NB. Apply the delta movement _in addition_ to applying the new velocity.
	 * 
	 * NB. Make sure the added delta does _not_ also apply its own velocity to the movement.
	 * i.e use AddDeltaWithCustomVelocity()
	 */
	FVector VInterpVelocityConstantToFramerateIndependent(
		FVector CurrentVelocity,
		float TargetSpeed,
		float DeltaSeconds,
		float InterpSpeed,
		FVector& OutVectorToAddDeltaTo,
	) no_discard
	{
		float Speed = CurrentVelocity.Size();
		const FVector VelocityDirection = CurrentVelocity / Speed;

		if(Math::IsNearlyEqual(CurrentVelocity.Size(), TargetSpeed))
			return CurrentVelocity;

		if(!ensure(Speed > 0, "It's not possible to call this function without the vector having a valid direction, which means that the length of the vector must be > 0!"))
			return CurrentVelocity;

		float AdditionalDeltaToApply;
		Speed = Acceleration::FInterpSpeedConstantToFramerateIndependent(Speed, TargetSpeed, DeltaSeconds, InterpSpeed, AdditionalDeltaToApply);

		OutVectorToAddDeltaTo += VelocityDirection * AdditionalDeltaToApply;
		return VelocityDirection * Speed;
	}

	/**
	 * Interpolate a velocity towards a target with a constant acceleration.
	 * Also outputs a delta movement to apply to make framerate-independent movement.
	 * 
	 * NB. Apply the delta movement _in addition_ to applying the new velocity.
	 * 
	 * NB. Make sure the added delta does _not_ also apply its own velocity to the movement.
	 * i.e use AddDeltaWithCustomVelocity()
	 */
	FVector VInterpVelocityConstantToFramerateIndependent(
		FVector Velocity,
		FVector TargetVelocity,
		float DeltaSeconds,
		float InterpSpeed,
		FVector& OutVectorToAddDeltaTo,
	) no_discard
	{
		float VelocityDifference = TargetVelocity.Distance(Velocity);
		float TimeToReachTargetVelocity = VelocityDifference / InterpSpeed;

		if (TimeToReachTargetVelocity <= SMALL_NUMBER)
		{
			// We are already close enough to the target velocity
			return TargetVelocity;
		}

		const FVector NewVelocity = Math::VInterpConstantTo(Velocity, TargetVelocity, DeltaSeconds, InterpSpeed);
		const FVector DeltaFromNewVelocity = NewVelocity * DeltaSeconds;
		FVector IntegratedFullFrameDelta;

		if (TimeToReachTargetVelocity > DeltaSeconds)
		{
			// We haven't reached the target, so the velocity changed the whole frame:
			IntegratedFullFrameDelta = (Velocity + NewVelocity) * 0.5 * DeltaSeconds;
		}
		else
		{
			// We were able to reach the target velocity this frame, so we have both a
			// part of the frame where we changed velocity and a part where the velocity was static
			IntegratedFullFrameDelta =
				(Velocity + NewVelocity) * 0.5 * TimeToReachTargetVelocity // < Speeding up/down
				+ NewVelocity * (DeltaSeconds - TimeToReachTargetVelocity); // < Static speed
		}
		
		OutVectorToAddDeltaTo += (IntegratedFullFrameDelta - DeltaFromNewVelocity);
		return NewVelocity;
	}

	/**
	 * Adds an acceleration vector to a velocity vector, while returning the delta that
	 * should be applied to make framerate-independent movement.
	 * 
	 * NB. Apply the delta movement _in addition_ to applying the _initial_ velocity, e.g.:
	 *    FVector Delta = Velocity * DeltaTime;
	 *    Acceleration::ApplyAccelerationToVelocity(Velocity, Acceleration, DeltaTime, Delta);
	 * 
	 * NB. Make sure the added delta does _not_ also apply its own velocity to the movement.
	 * i.e use AddDeltaWithCustomVelocity()
	 */
	void ApplyAccelerationToVelocity(
		FVector& Velocity,
		FVector Acceleration,
		float DeltaTime,
		FVector& OutVectorToAddDeltaTo
	)
	{
		Velocity += (Acceleration * DeltaTime);
		OutVectorToAddDeltaTo += (Acceleration * 0.5 * Math::Square(DeltaTime));
	}

	/**
	 * Adds an acceleration scalar to a speed scalar, while returning the delta that
	 * should be applied to make framerate-independent movement.
	 * @see ApplyAccelerationToVelocity()
	 */
	void ApplyAccelerationToSpeed(
		float& Speed,
		float Acceleration,
		float DeltaTime,
		float& OutValueToAddDeltaTo
	)
	{
		Speed += Acceleration * DeltaTime;
		OutValueToAddDeltaTo += (Acceleration * 0.5 * Math::Square(DeltaTime));
	}
}
