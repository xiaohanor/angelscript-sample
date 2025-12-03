struct FHoverPerchBumpActivationParams
{
	FHitResult BumpHit;
}

class UHoverPerchBumpCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::InfluenceMovement;

	default NetworkMode = EHazeCapabilityNetworkMode::Local;

	AHoverPerchActor PerchActor;

	UHazeMovementComponent MoveComp;
	UHoverPerchComponent HoverPerchComp;

	const float BumpCooldown = 0.7;
	const float BumpFlatImpulse = 300.0;
	const float BumpSpeedMultiplier = 1.0;
	const float BumpFauxPhysicsMultiplier = 0.5;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		HoverPerchComp = UHoverPerchComponent::Get(Owner);
		MoveComp = UHazeMovementComponent::Get(Owner);
		PerchActor = Cast<AHoverPerchActor>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FHoverPerchBumpActivationParams& Params) const
	{
		if(HoverPerchComp.bIsDestroyed)
			return false;

		if(Time::GetGameTimeSince(HoverPerchComp.TimeLastBumpedOtherPerch) < BumpCooldown)
			return false;

		if(HoverPerchComp.bIsGrinding)
			return false;

		FHitResult Impact;
		if(MoveComp.GetFirstValidImpact(Impact, EMovementAnyContactOrder::WallCeilingGround))
		{
			auto OtherPerchComp = UHoverPerchComponent::Get(Impact.Actor);
			if(OtherPerchComp == nullptr && Impact.Actor.AttachParentActor != nullptr)
				OtherPerchComp = UHoverPerchComponent::Get(Impact.Actor.AttachParentActor);
			if(OtherPerchComp == nullptr)
				return false;

			if(OtherPerchComp.bIsGrinding)
				return false;

			auto OtherPerchActor = Cast<AHoverPerchActor>(OtherPerchComp.Owner);
			if(OtherPerchActor != nullptr && OtherPerchActor.PlayerLocker == nullptr)
				return false;

			Params.BumpHit = Impact;
			return true;
		}

		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FHoverPerchBumpActivationParams Params)
	{
		if(PerchActor.PlayerLocker != nullptr)
		{
			PerchActor.PlayerLocker.PlayForceFeedback(PerchActor.BumpPlayerForceFeedback, false, false, this);
			PerchActor.PlayerLocker.PlayCameraShake(PerchActor.BumpPlayerCameraShake, this);

			PerchActor.PlayerLocker.SetAnimTrigger(n"HoverPerchBump");
		}

		auto OtherPerchComp = UHoverPerchComponent::Get(Params.BumpHit.Actor);
		if(OtherPerchComp == nullptr && Params.BumpHit.Actor.AttachParentActor != nullptr)
			OtherPerchComp = UHoverPerchComponent::Get(Params.BumpHit.Actor.AttachParentActor);

		if(OtherPerchComp.PerchingPlayer != nullptr)
		{
			OtherPerchComp.PerchingPlayer.PlayForceFeedback(PerchActor.BumpPlayerForceFeedback, false, false, this);
			OtherPerchComp.PerchingPlayer.PlayCameraShake(PerchActor.BumpPlayerCameraShake, this);

			OtherPerchComp.PerchingPlayer.SetAnimTrigger(n"HoverPerchBump");
		}

		auto OtherMoveComp = UHazeMovementComponent::Get(Params.BumpHit.Actor);

		FMovementHitResult Impact;
		if(MoveComp.HasWallContact())
			Impact = MoveComp.GetWallContact();
		else if(MoveComp.HasCeilingContact())
			Impact = MoveComp.GetCeilingContact();
		else if(MoveComp.HasGroundContact())
			Impact = MoveComp.GetGroundContact();

		FVector DirToOtherPerch = (OtherPerchComp.Owner.ActorLocation - HoverPerchComp.Owner.ActorLocation).GetSafeNormal2D();
		float SpeedTowardsOtherPerch = Math::Max(MoveComp.PreviousVelocity.DotProduct(DirToOtherPerch), 0);
		FVector DirFromOtherPerch = (HoverPerchComp.Owner.ActorLocation - OtherPerchComp.Owner.ActorLocation).GetSafeNormal2D();
		float SpeedTowardsThisPerch = Math::Max(OtherMoveComp.PreviousVelocity.DotProduct(DirFromOtherPerch), 0);
		
		float SpeedTowardsEachOther = SpeedTowardsOtherPerch + SpeedTowardsThisPerch;

		const float ImpulseMagnitude = (SpeedTowardsEachOther * BumpSpeedMultiplier) + BumpFlatImpulse;

		FHoverPerchOnImpactedOtherPerchEffectParams EffectParams;
		EffectParams.ImpactLocation = Impact.ImpactPoint;
		EffectParams.ImpactVelocity = MoveComp.PreviousVelocity;
		EffectParams.SpeedTowardsImpact = MoveComp.PreviousVelocity.DotProduct(-Impact.Normal);

		FVector SelfImpulse = -DirToOtherPerch * ImpulseMagnitude;

		if(HoverPerchComp.PerchingPlayer != nullptr)
		{
			FHazeCameraImpulse CameraImpulse;
			CameraImpulse.WorldSpaceImpulse = -SelfImpulse;
			CameraImpulse.Dampening = 1.0;
			CameraImpulse.ExpirationForce = 5.0;
			HoverPerchComp.PerchingPlayer.ApplyCameraImpulse(CameraImpulse, this);
		}
		HoverPerchComp.TimeLastBumpedOtherPerch = Time::GameTimeSeconds;

		FHoverPerchOnImpactedOtherPerchEffectParams OtherEffectParams;
		OtherEffectParams.ImpactLocation = Impact.ImpactPoint;
		OtherEffectParams.ImpactVelocity = OtherMoveComp.PreviousVelocity;
		OtherEffectParams.SpeedTowardsImpact = OtherMoveComp.PreviousVelocity.DotProduct(-Impact.Normal);

		FVector OtherImpulse = -DirFromOtherPerch * ImpulseMagnitude;
		if(HasControl())
			Crumb_ApplyImpulseToPerch(HoverPerchComp, SelfImpulse, EffectParams, OtherPerchComp, OtherImpulse, OtherEffectParams);
		
		if(OtherPerchComp.PerchingPlayer != nullptr)
		{
			FHazeCameraImpulse CameraImpulse;
			CameraImpulse.WorldSpaceImpulse = -OtherImpulse;
			CameraImpulse.Dampening = 1.0;
			CameraImpulse.ExpirationForce = 5.0;
			OtherPerchComp.PerchingPlayer.ApplyCameraImpulse(CameraImpulse, this);
		}

		OtherPerchComp.TimeLastBumpedOtherPerch = Time::GameTimeSeconds;

		TEMPORAL_LOG(HoverPerchComp.Owner, "Bump")
			.DirectionalArrow("Direction To Other Perch", HoverPerchComp.Owner.ActorLocation, DirToOtherPerch * 500, 5, 20, FLinearColor::Red)
			.DirectionalArrow("Direction From Other Perch", OtherPerchComp.Owner.ActorLocation, DirFromOtherPerch * 500, 5, 20, FLinearColor::Red)
			.DirectionalArrow("Self Impulse", HoverPerchComp.Owner.ActorLocation, SelfImpulse, 5, 20, FLinearColor::DPink)
			.DirectionalArrow("Other Impulse", OtherPerchComp.Owner.ActorLocation, OtherImpulse, 5, 20, FLinearColor::DPink)
			.Value("Speed Towards Other", SpeedTowardsOtherPerch)
			.Value("Speed From Other", SpeedTowardsThisPerch)
		;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
	}

	UFUNCTION(NotBlueprintCallable, CrumbFunction)
	private void Crumb_ApplyImpulseToPerch(UHoverPerchComponent PerchActorForImpulse, FVector Impulse, FHoverPerchOnImpactedOtherPerchEffectParams EffectParams
		, UHoverPerchComponent OtherPerchActorForImpulse, FVector OtherImpulse, FHoverPerchOnImpactedOtherPerchEffectParams OtherEffectParams)
	{
		Cast<AHazeActor>(PerchActorForImpulse.Owner).AddMovementImpulse(Impulse);
		FauxPhysics::ApplyFauxImpulseToActorAt(PerchActorForImpulse.Owner, PerchActorForImpulse.Owner.ActorLocation + PerchActorForImpulse.Owner.ActorUpVector * 200, Impulse * BumpFauxPhysicsMultiplier);
		UHoverPerchEffectHandler::Trigger_OnImpactedOtherPerch(Cast<AHazeActor>(PerchActorForImpulse.Owner), EffectParams);

		Cast<AHazeActor>(OtherPerchActorForImpulse.Owner).AddMovementImpulse(OtherImpulse);
		FauxPhysics::ApplyFauxImpulseToActorAt(OtherPerchActorForImpulse.Owner, OtherPerchActorForImpulse.Owner.ActorLocation + OtherPerchActorForImpulse.Owner.ActorUpVector * 200, OtherImpulse * BumpFauxPhysicsMultiplier);
		UHoverPerchEffectHandler::Trigger_OnImpactedOtherPerch(Cast<AHazeActor>(OtherPerchActorForImpulse.Owner), OtherEffectParams);
	}
};