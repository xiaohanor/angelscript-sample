struct FSkylineBossTankAssembleActivateParams
{
	FQuat InitialRotation;
};

class USkylineBossTankAssembleCapability : USkylineBossTankChildCapability
{
	FHazeAcceleratedFloat Speed;
	FHazeAcceleratedQuat Rotation;
	bool bAssembled = false;

	const float Delay = 3.0;

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FSkylineBossTankAssembleActivateParams& Params) const
	{
		if(!BossTank.bIsDefeated)
			return false;

		FVector ToHub = BossTank.Hub.ActorLocation - BossTank.ActorLocation;
		FVector Direction = ToHub.SafeNormal;
		Params.InitialRotation = FQuat::MakeFromZX(FVector::UpVector, Direction);

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FSkylineBossTankAssembleActivateParams Params)
	{
		bAssembled = false;

		BossTank.BlockCapabilities(SkylineBossTankTags::SkylineBossTankMovement, this);
		BossTank.BlockCapabilities(SkylineBossTankTags::SkylineBossTankAttack, this);
		BossTank.BlockCapabilities(SkylineBossTankTags::SkylineBossTankSpotlight, this);

		BossTank.SetActorRotation(Params.InitialRotation);

		FSkylineBossTankLight LightSettings;
		LightSettings.Color = FLinearColor::Red * 1000.0;
		LightSettings.BlendTime = 1.0;
		LightSettings.Freq = 16.0;
		LightSettings.FreqAlpha = 1.5;
		BossTank.LightComp.ApplyLightSettings(LightSettings, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		BossTank.UnblockCapabilities(SkylineBossTankTags::SkylineBossTankMovement, this);
		BossTank.UnblockCapabilities(SkylineBossTankTags::SkylineBossTankAttack, this);
		BossTank.UnblockCapabilities(SkylineBossTankTags::SkylineBossTankSpotlight, this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(HasControl())
			TickControl(DeltaTime);
		else
			TickRemote(DeltaTime);
	}

	void TickControl(float DeltaTime)
	{
		if (ActiveDuration < Delay)
			return;

		FVector ToHub = BossTank.Hub.ActorLocation - BossTank.ActorLocation;
		FVector Direction = ToHub.SafeNormal;
		float Distance = ToHub.Size();


//		if (BossTank.ActorForwardVector.DotProduct(Direction) >= 0.99)
//		{
			Speed.AccelerateTo(BossTank.InstigatedSpeed.Get(), 2.0, DeltaTime);
			FVector DeltaMove = Direction * Math::Min(Distance, Speed.Value * DeltaTime);
			FVector NewLocation = BossTank.ActorLocation + DeltaMove;
			BossTank.SetActorLocation(NewLocation);
//		}

		// TEMP STUFF
		if (Math::IsNearlyEqual(Distance, 0.0))
		{
			const FQuat TargetRotation = FQuat::MakeFromZX(FVector::UpVector, BossTank.Hub.ActorForwardVector);
			BossTank.SetActorRotation(FQuat::Slerp(BossTank.ActorQuat, TargetRotation, 1.0 * DeltaTime));

			float Dot = BossTank.ActorForwardVector.DotProduct(BossTank.Hub.ActorForwardVector);

			if (!bAssembled && Dot >= 0.99)
			{
				CrumbFinishAssembling();
			}
		}
		else
		{
			const FQuat TargetRotation = FQuat::MakeFromZX(FVector::UpVector, Direction);
			BossTank.SetActorRotation(FQuat::Slerp(BossTank.ActorQuat, TargetRotation, 1.0 * DeltaTime));
		}
	}

	void TickRemote(float DeltaTime)
	{
		const FHazeSyncedActorPosition& Position = BossTank.SyncedActorPositionComp.GetPosition();	
		BossTank.SetActorLocationAndRotation(Position.WorldLocation, Position.WorldRotation);
		BossTank.SetActorVelocity(Position.WorldVelocity);
	}

	UFUNCTION(CrumbFunction)
	void CrumbFinishAssembling()
	{
		USkylineBossTankEventHandler::Trigger_OnAssemble(BossTank);
		BossTank.OnAssemble.Broadcast();

		// Dont hide the actor
		//	BossTank.DestroyActor();
		BossTank.BlockCapabilities(SkylineBossTankTags::SkylineBossTank, BossTank);
		BossTank.SetActorTickEnabled(false);

		bAssembled = true;
	}
}