class USanctuaryBossHydraFireBreathAttackCapability : USanctuaryBossHydraChildCapability
{
	float SweepDuration;

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (ActiveDuration > SweepDuration)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		auto SweepAttack = Cast<USanctuaryBossHydraSweepAttackData>(GetAttackData());
		
		SweepDuration = SweepAttack.SweepDuration;
		if (SweepDuration < KINDA_SMALL_NUMBER)
			SweepDuration = Settings.FireBreathSweepDuration;

		if (Settings.OpenJawAnimation != nullptr && Settings.bUseAnimSequences)
		{
			FHazePlayFaceAnimationParams FaceParams;
			FaceParams.Animation = Settings.OpenJawAnimation;
			FaceParams.bLoop = true;
			Head.PlayFaceAnimation(FHazeAnimationDelegate(), FaceParams);
		}

		Head.AnimationData.bIsFireBreathing = true;
		USanctuaryBossHydraEventHandler::Trigger_FireBreathBegin(Head);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		if (Settings.IdleAnimation != nullptr && Settings.bUseAnimSequences)
		{
			FHazePlayFaceAnimationParams FaceParams;
			FaceParams.Animation = Settings.IdleAnimation;
			FaceParams.bLoop = true;
			Head.PlayFaceAnimation(FHazeAnimationDelegate(), FaceParams);
		}

		Head.AnimationData.bIsFireBreathing = false;
		USanctuaryBossHydraEventHandler::Trigger_FireBreathEnd(Head);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		float Alpha = (ActiveDuration / SweepDuration);
		float TimeRemaining = Math::Max(0.0, SweepDuration - ActiveDuration);

		auto SweepAttack = Cast<USanctuaryBossHydraSweepAttackData>(GetAttackData());

		// Just grab the first point if we only have one
		//  otherwise evaluate alpha on spline
		auto HeadSpline = SweepAttack.HeadSpline;
		FVector HeadLocation = HeadSpline.Points[0];
		if (HeadSpline.Points.Num() > 1)
			HeadLocation = HeadSpline.GetLocation(Alpha);

		auto TargetSpline = SweepAttack.TargetSpline;
		FVector TargetLocation = TargetSpline.Points[0];
		if (TargetSpline.Points.Num() > 1)
			TargetLocation = TargetSpline.GetLocation(Alpha);

		if (SweepAttack.TargetComponent != nullptr)
		{
			HeadLocation = SweepAttack.TargetComponent.WorldTransform.TransformPosition(HeadLocation);
			TargetLocation = SweepAttack.TargetComponent.WorldTransform.TransformPosition(TargetLocation);
		}

		FVector ToTarget = (TargetLocation - HeadLocation).GetSafeNormal();
		FQuat RotationOffset = FRotator(Settings.MouthPitch, 0.0, 0.0).Quaternion();
		FQuat HeadRotation = ToTarget.ToOrientationQuat() * RotationOffset.Inverse();

		Head.HeadPivot.SetWorldLocationAndRotation(
			Head.AcceleratedLocation.AccelerateTo(HeadLocation, TimeRemaining, DeltaTime),
			Head.AcceleratedQuat.AccelerateTo(HeadRotation, TimeRemaining, DeltaTime)
		);

		// Head pivot forward points towards the nose, so in order to get the forward vector
		//  of the mouth we have to rotate downwards
		FVector MouthForwardVector = Head.HeadPivot.ForwardVector.RotateAngleAxis(-Settings.MouthPitch, Head.HeadPivot.RightVector).GetSafeNormal();

		// Trace for VFX
		{
			float BeamLength = Settings.FireBreathBeamLength;
			auto Trace = Trace::InitChannel(ECollisionChannel::WeaponTraceEnemy);
			auto HitResult = Trace.QueryTraceSingle(Head.HeadPivot.WorldLocation, Head.HeadPivot.WorldLocation + MouthForwardVector * BeamLength);

			Head.FireBreathStartLocation = HitResult.TraceStart;
			Head.FireBreathEndLocation = (HitResult.bBlockingHit ? HitResult.ImpactPoint : HitResult.TraceEnd);
		}

		// Kill players "touching" beam
		{
			// float BreathLength = (Head.FireBreathStartLocation - Head.FireBreathEndLocation).Size() * 0.5;
			// FVector BreathCenterLocation = (Head.FireBreathStartLocation + Head.FireBreathEndLocation) * 0.5;
			// Debug::DrawDebugCapsule(BreathCenterLocation, BreathLength, Settings.FireBreathRadius, FRotator::MakeFromZ(MouthForwardVector));

			float BreathRadiusSqr = Math::Square(Settings.FireBreathRadius);

			for (auto Player : Game::Players)
			{
				if (!Player.HasControl())
					continue;
				if (Player.IsPlayerDead())
					continue;

				FVector ToPlayer = (Player.ActorCenterLocation - Head.HeadPivot.WorldLocation);
				FVector ToPlayerConstrained = ToPlayer.ConstrainToPlane(MouthForwardVector);

				if (SweepAttack.bInfiniteHeight)
				{
					ToPlayerConstrained = ToPlayerConstrained.ConstrainToPlane(FVector::UpVector);
				}
				
				if (ToPlayerConstrained.SizeSquared() > BreathRadiusSqr)
					continue;

				float ForwardDot = MouthForwardVector.DotProduct(ToPlayer.GetSafeNormal());
				if (ForwardDot < 0.0)
					continue;

				float BeamLengthSqr = (Head.FireBreathEndLocation - Head.HeadPivot.WorldLocation).SizeSquared();
				float ForwardDistanceSqr = ToPlayer.ConstrainToDirection(MouthForwardVector).SizeSquared();
				if (ForwardDistanceSqr > BeamLengthSqr + Math::Square(Player.ScaledCapsuleRadius + 1.0))
					continue;

				// Ensure beam isn't occluded
				auto Trace = Trace::InitChannel(ECollisionChannel::WeaponTraceEnemy);
				auto HitResult = Trace.QueryTraceSingle(Head.HeadPivot.WorldLocation, Player.ActorCenterLocation);
				if (HitResult.bBlockingHit && HitResult.Actor == Player)
					Player.KillPlayer();
			}
		}
	}
}