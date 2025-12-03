namespace Pinball::AirMoveSimulation
{
	void Tick(FVector& Delta, FVector& Velocity, bool bLaunched, float HorizontalInput, const UPinballMovementSettings Settings, float DeltaTime, float Time = -1)
	{
		TOptional<FLinearColor> OutVisualizeColor;
		TickVector(Delta, Velocity, OutVisualizeColor, bLaunched, HorizontalInput, Settings, DeltaTime, Time);

#if EDITOR
		if(Velocity.Size() > Pinball::MaximumAllowedMoveSpeed)
			PrintToScreen(f"Moving too fast! Speed of {Math::RoundToFloat(Velocity.Size())} when only {Pinball::MaximumAllowedMoveSpeed} is allowed!", Color = FLinearColor::Yellow);
#endif
	}

#if EDITOR
	void TickVisualize(FVector& Delta, FVector& Velocity, TOptional<FLinearColor>&out OutVisualizeColor, bool bLaunched, float HorizontalInput, const UPinballMovementSettings Settings, float DeltaTime, float Time = -1)
	{
		TickVector(Delta, Velocity, OutVisualizeColor, bLaunched, HorizontalInput, Settings, DeltaTime, Time);
	}
#endif

	void TickVector(FVector& Delta, FVector& Velocity, TOptional<FLinearColor>&out OutVisualizeColor, bool bLaunched, float HorizontalInput, const UPinballMovementSettings Settings, float DeltaTime, float Time)
	{
		Delta = Velocity * DeltaTime;

		const FVector WorldUp = Pinball::GetWorldUp(Time);
		const FVector WorldRight = Pinball::GetWorldRight(WorldUp);
		
		// If launched, apply no input while airborne
		const FVector MovementInput = WorldRight * (bLaunched ? 0 : HorizontalInput);
		
		FVector VerticalVelocity = Velocity.ProjectOnToNormal(WorldUp);
		FVector HorizontalVelocity = Velocity - VerticalVelocity;
		HorizontalVelocity.X = 0;

		if(VerticalVelocity.DotProduct(WorldUp) < Settings.AirVerticalSpeedHorizontalInputThreshold)
		{
			// Input
			const bool bIsInputting = Math::Abs(HorizontalInput) > KINDA_SMALL_NUMBER;

			if(bIsInputting)
			{
				const bool bIsAccelerating = HorizontalVelocity.DotProduct(MovementInput) > 0;
				const bool bIsRebound = !bIsAccelerating;

				float Multiplier = 1;
				if(bIsRebound)
					Multiplier *= Math::Lerp(1, Settings.AirReboundAccelerationMultiplier, Math::Abs(HorizontalInput));

				if(!IsOverHorizontalMaxSpeedVector(HorizontalVelocity, Settings) || bIsRebound)
				{
					// If we are below max speed, or decelerating, apply movement input
					const FVector Acceleration = MovementInput * Settings.AirMoveForce * Multiplier;
					Acceleration::ApplyAccelerationToVelocity(HorizontalVelocity, Acceleration, DeltaTime, Delta);
				}
			}

			if(IsOverHorizontalMaxSpeedVector(HorizontalVelocity, Settings))
			{
				// Decelerate if over max speed
				HorizontalVelocity = Acceleration::VInterpVelocityConstantToFramerateIndependent(HorizontalVelocity, Settings.AirMaxHorizontalSpeed, DeltaTime, Settings.AirMaxSpeedDeceleration, Delta);
			}
		}

		bool bApplyGravity = !bLaunched || Settings.bApplyGravityWhileLaunched;

		// Launch deceleration
		Velocity = HorizontalVelocity + VerticalVelocity;
		if(bLaunched && Settings.bApplyDecelerationWhileLaunched && Velocity.Size() > Settings.LaunchMaxSpeed)
		{
			Velocity = Acceleration::VInterpVelocityConstantToFramerateIndependent(Velocity, Settings.LaunchMaxSpeed, DeltaTime, Settings.LaunchDeceleration, Delta);

			VerticalVelocity = Velocity.ProjectOnToNormal(WorldUp);
			HorizontalVelocity = Velocity - VerticalVelocity;

			// Purple for breaking
			OutVisualizeColor.Set(FLinearColor::Purple);
		}
		else
		{
			bApplyGravity = true;
		}

		// Gravity
		const FVector GravityDirection = Pinball::GetGravityDirection(WorldUp);
		if(bApplyGravity)
		{
			Acceleration::ApplyAccelerationToVelocity(VerticalVelocity, GravityDirection * Settings.Gravity, DeltaTime, Delta);

			// Red for gravity
			//OutVisualizeColor.Set(FLinearColor::Red);
		}

		// Limit falling speed
		if(VerticalVelocity.DotProduct(-GravityDirection) < Settings.AirMaxFallSpeed)
		{
			VerticalVelocity = Acceleration::VInterpVelocityConstantToFramerateIndependent(VerticalVelocity, Math::Abs(Settings.AirMaxFallSpeed), DeltaTime, Settings.AirFallDeceleration, Delta);
		}

		Velocity = HorizontalVelocity + VerticalVelocity;
	}

	bool IsOverHorizontalMaxSpeedVector(FVector HorizontalVelocity, const UPinballMovementSettings Settings)
	{
		return HorizontalVelocity.Size() > Settings.AirMaxHorizontalSpeed;
	}

#if EDITOR
	void VisualizePath(const UHazeScriptComponentVisualizer Visualizer, FVector InitialLocation, FVector InitialVelocity, UPinballLauncherComponent LauncherComp, float MoveInput, FLinearColor Color = FLinearColor::Green, float Duration = 1, float DeltaTime = 0.02)
	{
		if(Duration <= 0)
			return;
		
		float Time = 0;
		FVector Location = InitialLocation;
		FVector Velocity = InitialVelocity;
		FVector Delta;

		float PointTime = Time::GameTimeSeconds % Duration;
		bool bHasDrawnPoint = false;

		const UPinballMovementSettings Settings = Cast<UPinballMovementSettings>(UPinballMovementSettings.DefaultObject);

		while(Time < Duration)
		{
			const FVector PreviousLocation = Location;
			const bool bLaunched = Pinball::IsLaunching(Velocity, InitialVelocity.GetSafeNormal(), LauncherComp, 0, Time);
			TOptional<FLinearColor> VisualizeColor;

			TickVisualize(Delta, Velocity, VisualizeColor, bLaunched, MoveInput, Settings, DeltaTime);

			// Framerate independent velocity add
			Location += Delta;

			if(!VisualizeColor.IsSet())
				VisualizeColor.Set(Color);
			
			Visualizer.DrawLine(PreviousLocation, Location, VisualizeColor.Value, 3, true);
			
			Time += DeltaTime;

			if(!bHasDrawnPoint && PointTime < Time)
			{
				bHasDrawnPoint = true;
				Visualizer.DrawWireSphere(Location, 39, Color, 3);
			}
		}
	}
#endif
}