class UHoverPerchWorldCollisionCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::InfluenceMovement;

	default NetworkMode = EHazeCapabilityNetworkMode::Local;

	AHoverPerchActor PerchActor;
	UHazeMovementComponent MoveComp;

	const float ImpactDiscardThreshold = 75.0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		PerchActor = Cast<AHoverPerchActor>(Owner);
		MoveComp = UHazeMovementComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FHoverPerchBumpActivationParams& Params) const
	{
		if(PerchActor.HoverPerchComp.bIsDestroyed)
			return false;

		FHitResult Impact;
		if(MoveComp.GetFirstValidImpact(Impact, EMovementAnyContactOrder::WallCeilingGround))
		{
			FVector FlatNormal = -Impact.Normal.ConstrainToPlane(FVector::UpVector).GetSafeNormal();
			float SpeedTowardsImpact = MoveComp.PreviousVelocity.DotProduct(FlatNormal);
			TEMPORAL_LOG(PerchActor, "World Impact")
				.DirectionalArrow("Impact Normal", Impact.ImpactPoint, FlatNormal * 100, 5, 400, FLinearColor::LucBlue)
				.Value("Speed Towards Impact", SpeedTowardsImpact)
			;
			if(Math::IsNearlyZero(SpeedTowardsImpact, ImpactDiscardThreshold))
				return false;

			auto OtherPerchActor = Cast<AHoverPerchActor>(Impact.Actor);
			if(OtherPerchActor != nullptr)
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
			PerchActor.PlayerLocker.PlayForceFeedback(PerchActor.WallImpactForceFeedback, false, false, this);
			PerchActor.PlayerLocker.PlayCameraShake(PerchActor.WallImpactCameraShake, this);
		}
		
		FHoverPerchOnImpactedWorldEffectParams CollisionParams;

		float SpeedTowardsImpact = MoveComp.PreviousVelocity.DotProduct(-Params.BumpHit.ImpactNormal);
		CollisionParams.SpeedTowardsImpact = SpeedTowardsImpact;

		FHazeTraceSettings TraceSettings;
		TraceSettings.TraceWithMovementComponent(MoveComp);
		CollisionParams.ImpactedMaterial = AudioTrace::GetPhysMaterialFromHit(Params.BumpHit, TraceSettings);
		UHoverPerchEffectHandler::Trigger_OnCollided(PerchActor, CollisionParams);
	}
}