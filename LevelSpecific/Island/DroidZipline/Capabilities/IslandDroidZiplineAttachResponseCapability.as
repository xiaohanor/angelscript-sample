class UIslandDroidZiplineAttachResponseCapability : UIslandDroidZiplineBaseCapability
{
	//default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	
	UIslandDroidZiplineSettings Settings;
	bool bShakePeakReached = false;
	bool bShakeDone = false;
	float RandomRollRotation;
	FVector TargetShakeLocation;
	FRotator TargetShakeRotation;
	FVector OriginalLocation;
	FRotator OriginalRotation;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		
		Settings = UIslandDroidZiplineSettings::GetSettings(Droid);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(Droid.AttachedPlayer == nullptr)
			return false;

		if(Droid.CurrentDroidState != EIslandDroidZiplineState::Patrolling)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(Droid.AttachedPlayer == nullptr)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		FIslandDroidZiplineManagerAttachParams Params;
		Params.Player = Droid.AttachedPlayer;
		UIslandDroidZiplineManagerEffectHandler::Trigger_OnPlayerAttached(Droid.Manager, Params);
		
		Droid.CurrentDroidState = EIslandDroidZiplineState::Ziplining;
		bShakePeakReached = false;
		bShakeDone = false;
		RandomRollRotation = Math::RandRange(-Settings.AttachShakeMaxRandomRoll, -Settings.AttachShakeMaxRandomRoll);

		TargetShakeLocation = FVector(0.0, 0.0, -Settings.AttachShakePeakDownardsDistance);
		TargetShakeRotation = Settings.AttachShakePeakRotation + FRotator(0.0, 0.0, RandomRollRotation);
		OriginalLocation = Droid.Mesh.RelativeLocation;
		OriginalRotation = Droid.Mesh.RelativeRotation;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		FIslandDroidZiplineManagerAttachParams Params;
		Params.Player = Droid.AttachedPlayer;
		UIslandDroidZiplineManagerEffectHandler::Trigger_OnPlayerDetached(Droid.Manager, Params);

		Droid.Mesh.RelativeLocation = OriginalLocation;
		Droid.Mesh.RelativeRotation = OriginalRotation;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		HandleAttachShake(DeltaTime);
	}

	void HandleAttachShake(float DeltaTime)
	{
		if(bShakeDone)
			return;

		if(bShakePeakReached)
		{
			float BackAlpha = (ActiveDuration - Settings.AttachShakeDuration) / Settings.AttachShakeBackLerpDuration;
			if(BackAlpha >= 1.0)
			{
				BackAlpha = 1.0;
				bShakeDone = true;
			}

			Droid.Mesh.RelativeRotation = FQuat::Slerp(TargetShakeRotation.Quaternion(), FQuat::Identity, BackAlpha).Rotator();
			Droid.Mesh.RelativeLocation = Math::Lerp(TargetShakeLocation, OriginalLocation, BackAlpha);
			return;
		}

		float ShakeAlpha = ActiveDuration / Settings.AttachShakeDuration;
		if(ShakeAlpha >= 1.0)
		{
			ShakeAlpha = 1.0;
			bShakePeakReached = true;
		}

		Droid.Mesh.RelativeRotation = FQuat::Slerp(FQuat::Identity, TargetShakeRotation.Quaternion(), ShakeAlpha).Rotator();
		Droid.Mesh.RelativeLocation = Math::Lerp(OriginalLocation, TargetShakeLocation, ShakeAlpha);
	}
}