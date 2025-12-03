/**
 * Shared helper that calculates a standard dash' movement in a framerate-independent way.
 * Is used by the various dash capabilities to avoid having shorter dashes at lower framerate.
 */
struct FDashMovementCalculator
{
	private float TotalDuration;
	private float AccelDuration;
	private float LinearDuration;
	private float DecelDuration;

	private float StartSpeed;
	private float DashSpeed;
	private float ExitSpeed;

	private float StartTimeOffset;

	FDashMovementCalculator(
		float StartDeltaTime,
		float DashDistance,
		float DashDuration,
		float DashAccelerationDuration,
		float DashDecelerationDuration,
		float InitialSpeed,
		float WantedExitSpeed
	)
	{
		float BaseSpeed = DashDistance / DashDuration;
		StartSpeed = InitialSpeed;
		ExitSpeed = WantedExitSpeed;
		StartTimeOffset = StartDeltaTime;

		if (DashAccelerationDuration > 0.0)
		{
			if (StartSpeed >= BaseSpeed * 0.9)
			{
				// We're going faster(ish) than the dash, so we don't need to accelerate
				AccelDuration = 0.0;
				DashSpeed = BaseSpeed;
				StartSpeed = 0.0;
			}
			else
			{
				AccelDuration = DashAccelerationDuration;

				// We need to adapt our speed so we get the same distance
				// Distance = CurrentSpeed * AccelerationDuration + (FinalSpeed - CurrentSpeed) * AccelerationDuration * 0.5 + FinalSpeed * DashDuration
				DashSpeed = (2.0 * DashDistance - (AccelDuration * StartSpeed)) / (AccelDuration + 2.0 * DashDuration);
			}
		}
		else
		{
			// We have 0-duration acceleration configured
			AccelDuration = 0.0;
			DashSpeed = BaseSpeed;
			StartSpeed = 0.0;
		}

		TotalDuration = AccelDuration + DashDuration;

		// Calculate our deceleration down to normal speed
		if (DashDecelerationDuration > 0.0)
		{
			DecelDuration = DashDecelerationDuration;
			LinearDuration = DashDuration - DecelDuration;

			// DashDistance = (DashSpeed * TotalDuration) - 0.5 * (DashSpeed - StartSpeed) * AccelDuration - 0.5 * (DashSpeed - ExitSpeed) * DecelDuration
			// DashDistance = (DashSpeed * TotalDuration) - (0.5 * DashSpeed * AccelDuration) + (0.5 * StartSpeed * AccelDuration) - (0.5 * DashSpeed * DecelDuration) + (0.5 * ExitSpeed * DecelDuration)
			// DDConst = DashDistance - (0.5 * StartSpeed * AccelDuration) - (0.5 * ExitSpeed * DecelDuration) 
			// DDConst = (DashSpeed * TotalDuration) - (0.5 * DashSpeed * AccelDuration) - (0.5 * DashSpeed * DecelDuration)
			// DDConst = DashSpeed * (TotalDuration - 0.5 * AccelDuration - 0.5 * DecelDuration)
			// MConst = TotalDuration - 0.5 * AccelDuration - 0.5 * DecelDuration
			// DashSpeed = DDConst / MConst

			float DDConst = DashDistance - (0.5 * StartSpeed * AccelDuration) - (0.5 * ExitSpeed * DecelDuration);
			float MConst = TotalDuration - (0.5 * AccelDuration) - (0.5 * DecelDuration);
			DashSpeed = DDConst / MConst;
		}
		else
		{
			DecelDuration = 0.0;
		}

		LinearDuration = DashDuration - DecelDuration;
	}

	// Whether the dash is finished at the specified timer
	bool IsFinishedAtTime(float TimeInDash) const
	{
		return TimeInDash > TotalDuration;
	}

	// Whether the dash has started decelerating at the specified timer
	bool IsDeceleratingAtTime(float TimeInDash) const
	{
		return TimeInDash > TotalDuration - DecelDuration;
	}

	// How long the dash takes total, including acceleration and deceleration
	float GetTotalDashDuration() const
	{
		return TotalDuration;
	}

	// The speed we should set when we exit the dash
	float GetExitSpeed() const
	{
		return ExitSpeed;
	}

	// Calculate how much to move and how fast to be at a particular point in the dash
	void CalculateMovement(float TimeInDash, float DeltaTime, float&out OutDeltaMove, float&out OutVelocity) const
	{
		float LastFrameTime = TimeInDash - DeltaTime;

		OutDeltaMove = GetDistanceAtTime(TimeInDash) - GetDistanceAtTime(LastFrameTime);
		OutVelocity = GetSpeedAtTime(TimeInDash);
	}

	float GetDistanceAtTime(float TimeInDash) const
	{
		float OffsetTimeInDash = Math::Max(TimeInDash + StartTimeOffset, 0.0);
		float Distance = 0.0;

		// Movement during the acceleration
		if (AccelDuration > 0.0)
		{
			float AccelTime = Math::Min(OffsetTimeInDash, AccelDuration);
			float VelocityAccel = (DashSpeed - StartSpeed) / AccelDuration;
			Distance += StartSpeed * AccelTime;
			Distance += VelocityAccel * (AccelTime * AccelTime * 0.5);
		}

		// Movement during the linear part
		float LinearTime = Math::Clamp(OffsetTimeInDash - AccelDuration, 0.0, LinearDuration);
		Distance += DashSpeed * LinearTime;

		// Movement during the deceleration
		if (DecelDuration > 0.0)
		{
			float DecelTime = Math::Clamp(OffsetTimeInDash - AccelDuration - LinearDuration, 0.0, DecelDuration);
			float VelocityDecel = (ExitSpeed - DashSpeed) / DecelDuration;
			Distance += DashSpeed * DecelTime;
			Distance += VelocityDecel * (DecelTime * DecelTime * 0.5);
		}

		// Movement after the dash is over
		//  This is added because the dash may end in the 'middle' of a frame,
		//  so we simulate what normal movement would be next frame so we don't drop speed.
		float AfterDashTime = Math::Max(OffsetTimeInDash - TotalDuration, 0.0);
		Distance += ExitSpeed * AfterDashTime;

		return Distance;
	}

	float GetSpeedAtTime(float TimeInDash) const
	{
		float OffsetTimeInDash = Math::Max(TimeInDash + StartTimeOffset, 0.0);

		float Speed = DashSpeed;
		if (OffsetTimeInDash < AccelDuration)
		{
			Speed = Math::Lerp(StartSpeed, DashSpeed, OffsetTimeInDash / AccelDuration);
		}
		else if (DecelDuration > 0.0)
		{
			float DecelTime = (OffsetTimeInDash - TotalDuration + DecelDuration);
			float DecelAlpha = Math::Clamp(DecelTime / DecelDuration, 0.0, 1.0);

			Speed = Math::Lerp(DashSpeed, ExitSpeed, DecelAlpha);
		}
		else if (OffsetTimeInDash > TotalDuration)
		{
			Speed = ExitSpeed;
		}

		return Speed;
	}

};