namespace Pinball
{
	AHazePlayerCharacter GetBallPlayer()
	{
		return Drone::GetMagnetDronePlayer();
	}

	AHazePlayerCharacter GetPaddlePlayer()
	{
		return Drone::GetSwarmDronePlayer();
	}

	UHackablePinballManager GetManager()
	{
		auto Mio = Game::Mio;
		if(Mio == nullptr)
			return nullptr;

		return UHackablePinballManager::GetOrCreate(Mio);
	}

	TArray<APinballPaddle> GetPaddles()
	{
		return TListedActors<APinballPaddle>().Array;
	}

	FVector GetWorldUp(float Time = -1)
	{
		if(!Pinball::ShouldGravityFollowCameraDown())
			return FVector::UpVector;

		float SampleTime = Time >= 0 ? Time : Time::GameTimeSeconds;

		FRotator CameraRot = Pinball::GetPaddlePlayer().ViewRotation;
		FVector CameraUp = CameraRot.UpVector;
		FQuat UpRotation = FQuat::MakeFromZX(CameraUp, FVector::ForwardVector);
		return UpRotation.UpVector;
	}

	FVector GetGravityDirection(FVector WorldUp)
	{
		FVector Up = WorldUp;
		Up.Y *= 0.5;
		Up.Normalize();
		return -Up;
	}

	FVector GetWorldRight(FVector WorldUp)
	{
		return FQuat::MakeFromZX(WorldUp, FVector::ForwardVector).RightVector;
	}

	bool IsLaunching(FVector Velocity, FVector LaunchDirection, UPinballLauncherComponent LauncherComp, float LaunchTime, float CurrentTime)
	{
		if(LauncherComp == nullptr)
			return false;
		
		// If we are moving back the way we were launched, stop launching
		if(Velocity.DotProduct(LaunchDirection) < 0)
			return false;

		// If launch duration is over the duration, stop launching
		if(CurrentTime - LaunchTime > LauncherComp.MaxLaunchDuration)
			return false;

		const FVector WorldUp = Pinball::GetWorldUp(CurrentTime);

		if(LauncherComp.bStayLaunchedWhenMovingDown)
		{
			if(LaunchDirection.DotProduct(WorldUp) > 0)
			{
				// If we launched upwards and we are going down, stop launching
				if(Velocity.DotProduct(WorldUp) < 0)
					return false;
			}
		}
		else
		{
			// Stop launching when moving down
			if(Velocity.DotProduct(WorldUp) < 0)
				return false;
		}

		return true;
	}

	UFUNCTION(BlueprintCallable)
	void ApplyGravityFollowsCameraDown()
	{
		check(!Pinball::GetManager().bGravityFollowsCameraDown);
		Pinball::GetManager().bGravityFollowsCameraDown = true;
	}

	UFUNCTION(BlueprintCallable)
	void ClearGravityFollowsCameraDown()
	{
		check(Pinball::GetManager().bGravityFollowsCameraDown);
		Pinball::GetManager().bGravityFollowsCameraDown = false;
	}

	bool ShouldGravityFollowCameraDown()
	{
		auto Manager = GetManager();
		if(Manager == nullptr)
			return false;

		return Pinball::GetManager().bGravityFollowsCameraDown;
	}

	bool FindAutoAim(FVector PlayerLocation, FVector Direction, const TArray<FPinballPaddleAutoAimTargetData>& AutoAimTargets, FPinballPaddleAutoAimTargetData&out OutAutoAim)
	{
		if(AutoAimTargets.Num() == 0)
			return false;

		bool bFoundAutoAim = false;
		float BestTargetDistance = BIG_NUMBER;
		FPinballPaddleAutoAimTargetData BestAutoAimTargetData;

		for(int i = 0; i < AutoAimTargets.Num(); i++)
		{
			auto AutoAimActor = AutoAimTargets[i];

			if(!AutoAimActor.IsValid())
				continue;

			float DistanceFromTarget = 0;
			if(AutoAimActor.GetAutoAimComp().IntersectsWithRay(PlayerLocation, Direction, 10000, DistanceFromTarget))
			{
				if(DistanceFromTarget < BestTargetDistance)
				{
					OutAutoAim = AutoAimActor;
					BestTargetDistance = DistanceFromTarget;
					bFoundAutoAim = true;
				}
			}
		}

		return bFoundAutoAim;
	}

#if EDITOR
	void DrawAutoAims(UHazeScriptComponentVisualizer Visualizer, FVector StartLocation, const TArray<FPinballPaddleAutoAimTargetData>& AutoAimTargets)
	{
		for(auto AutoAimTargetData : AutoAimTargets)
		{
			if(!AutoAimTargetData.IsValid())
				continue;

			auto AutoAim = AutoAimTargetData.GetAutoAimComp();
			AutoAim.VisualizeAutoAim(Visualizer, AutoAimTargetData.GetAutoAimTargetLocation());
			Visualizer.DrawArrow(StartLocation, AutoAim.WorldLocation, FLinearColor::Yellow, 10, 3);
		}
	}
#endif
}