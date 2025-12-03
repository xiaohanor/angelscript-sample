struct FSanctuaryLavamoleActionSplitData
{
	FVector OGLocation;
	FVector TargetLocation;
	FRotator OGRotation;
	FRotator TargetRotation;
}

struct FSanctuaryLavamoleActionActivateData
{
	FVector RandomImpulse;
}

class USanctuaryLavamoleActionSplitCapability : UHazeActionQueueCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	FSanctuaryLavamoleActionSplitData Params;

	default CapabilityTags.Add(LavamoleTags::LavaMole);
	default CapabilityTags.Add(LavamoleTags::Action);

	AAISanctuaryLavamole Lavamole;
	USanctuaryLavamoleSettings Settings;

	ASanctuaryLavamoleWhackSplitBody LeftoverHead;
	FHazeAcceleratedFloat AccSquishyLeftoverBody;
	float LeftOverBodyAddScale = 1.0;

	FVector LeftOverUp;
	FVector LeftOverDown;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Settings = USanctuaryLavamoleSettings::GetSettings(Owner);
		Lavamole = Cast<AAISanctuaryLavamole>(Owner);
		AccSquishyLeftoverBody.SnapTo(1.0);
	}

	UFUNCTION(BlueprintOverride)
	void OnBecomeFrontOfQueue(FSanctuaryLavamoleActionSplitData Parameters)
	{
		Params = Parameters;
		Params.OGLocation = Lavamole.ActorLocation;
		Params.OGRotation = Lavamole.ActorRotation;
		FVector SplitDirection = -Lavamole.ActorForwardVector;
		Params.TargetLocation = Params.OGLocation + SplitDirection * 100.0 + FVector::UpVector * 200.0;
		Params.TargetRotation = Lavamole.ActorRotation; //FQuat(Math::GetRandomPointInSphere().GetSafeNormal(), Math::RandRange(-PI, PI));
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FSanctuaryLavamoleActionActivateData & Data) const
	{
		FVector2D PlaneDirection = Math::RandPointInCircle(Math::RandRange(900, 1500));
		Data.RandomImpulse = FVector::UpVector * Math::RandRange(500, 700);
		Data.RandomImpulse.X += PlaneDirection.X;
		Data.RandomImpulse.Y += PlaneDirection.Y;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (ActiveDuration > Settings.WhackDeathDuration)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FSanctuaryLavamoleActionActivateData Data)
	{
		Lavamole.WhackedTimes++;
		float Diff = Lavamole.HealthComp.GetCurrentHealth() - 0.01;
		Lavamole.HealthComp.TakeDamage(Diff, EDamageType::Default, Lavamole);
		Lavamole.AnimationMode = ESanctuaryLavamoleAnimation::BodyDying;

		Lavamole.RemoveUnlaunchedMortar();
		ASanctuaryLavamoleWhackSplitBody SplitHead = Lavamole.Manager.EnableFunnyDeadHead(Lavamole.ActorLocation, Lavamole.ActorRotation, Data.RandomImpulse);
		Lavamole.Mesh.SkeletalMeshAsset = Lavamole.BittenBodySkelMesh;

		// {
		// 	LeftoverHead = Cast<ASanctuaryLavamoleWhackSplitBody>(SpawnActor(Lavamole.WhackSplitBody, Lavamole.ActorLocation, Lavamole.ActorRotation));
		// 	// LeftOverBodyAddScale = LeftoverHead.Mesh.GetWorldScale().Size();
		// 	LeftOverUp = Lavamole.ActorLocation;
		// 	LeftOverDown = LeftOverUp - FVector::UpVector * 100.0;
		// }

		Lavamole.HealthBar.SetPlayerVisibility(EHazeSelectPlayer::Both);
		Timer::SetTimer(this, n"DelayedHideHealth", 1.2);
		
		FSanctuaryLavaMoleOnDyingParams DyingParams;
		DyingParams.Head = SplitHead;
		USanctuaryLavamoleEventHandler::Trigger_OnDying(Lavamole, DyingParams);

		Lavamole.OnMoleStartedDying.Broadcast(Lavamole);

		if (Lavamole.WhackDeathForceFeedbackEffect != nullptr)
		{
			if (Lavamole.Bite1Comp != nullptr && Lavamole.Bite1Comp.Biter != nullptr)
				Lavamole.Bite1Comp.Biter.PlayForceFeedback(Lavamole.WhackDeathForceFeedbackEffect, false, false, this, 2.0);

			if (Lavamole.Bite2Comp != nullptr && Lavamole.Bite2Comp.Biter != nullptr)
				Lavamole.Bite2Comp.Biter.PlayForceFeedback(Lavamole.WhackDeathForceFeedbackEffect, false, false, this, 2.0);
		}
	}

	UFUNCTION()
	void DelayedHideHealth()
	{
		if (Lavamole != nullptr)
			Lavamole.HealthBar.SetPlayerVisibility(EHazeSelectPlayer::None);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		if (Lavamole.HasControl())
		{
			bool bKilledByTearing = false;
			Lavamole.CrumbKillMole(bKilledByTearing);
		}
		LeftoverHead = nullptr;
	}

	// UFUNCTION(BlueprintOverride)
	// void TickActive(float DeltaTime)
	// {
	// 	UpdateLeftoverBody(DeltaTime);

	// 	Params.TargetLocation = Params.OGLocation - Params.OGRotation.ForwardVector * 200.0;
	// 	Params.TargetRotation = Params.OGRotation; 
	// 	Params.TargetRotation.Pitch += 35.0;
	// 	Params.TargetRotation.Roll += 25.0;

	// 	float ActualAlpha = Math::Wrap(ActiveDuration / Settings.WhackDeathDuration, 0.0, 1.0);
	// 	float EasedAlpha = Math::EaseOut(0.0, 1.0, ActualAlpha, 2.0);
	// 	FVector LerpedLocation = Math::Lerp(Params.OGLocation, Params.TargetLocation, EasedAlpha);
	// 	LerpedLocation.Z += SanctuaryLavamoleWhackSplitFallCurve.GetFloatValue(ActualAlpha) * 300.0;
	// 	FQuat LerpedRotation = FQuat::Slerp(Params.OGRotation.Quaternion(), Params.TargetRotation.Quaternion(), EasedAlpha);
	// 	Lavamole.MeshOffsetComponent.SetWorldLocation(LerpedLocation);
	// 	Lavamole.MeshOffsetComponent.SetWorldRotation(LerpedRotation);
	// 	FVector Scaling = FVector::OneVector;
	// 	Scaling.X = 0.5;

	// 	const float ScalingDown = Math::Clamp(SanctuaryLavamoleWhackSplitScaleCurve.GetFloatValue(ActualAlpha), 0.05, 2.0);
	// 	Lavamole.MeshOffsetComponent.SetWorldScale3D(Scaling * ScalingDown);
	// }

	// void UpdateLeftoverBody(float DeltaTime)
	// {
	// 	if (LeftoverBody == nullptr)
	// 		return;

	// 	// FVector Scaling = FVector::OneVector;
	// 	float Alpha = Math::Wrap(ActiveDuration / Settings.WhackDeathDuration, 0.0, 1.0);
	// 	// AccSquishyLeftoverBody.AccelerateTo(SanctuaryLavamoleWhackSplitScaleCurve.GetFloatValue(Alpha), 0.1, DeltaTime);
	// 	// Scaling.X = AccSquishyLeftoverBody.Value;
	// 	// if (Scaling.X > 1.0)
	// 	// {
	// 	// 	float ScalingValue = Math::Clamp(1 + (1 - Scaling.X) * 0.5, 0.05, 50.0);
	// 	// 	Scaling.Z = ScalingValue;
	// 	// 	Scaling.Y = ScalingValue;
	// 	// }
	// 	// LeftoverBody.Mesh.SetWorldScale3D(Scaling * LeftOverBodyAddScale);

	// 	LeftoverBody.SetActorLocation(Math::Lerp(LeftOverDown, LeftOverUp, SanctuaryLavamoleWhackSplitScaleCurve.GetFloatValue(Alpha)));
	// }
};