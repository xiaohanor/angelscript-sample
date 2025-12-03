class UIslandPunchotronFollowSplineBehaviour : UBasicBehaviour
{
	default Requirements.Add(EBasicBehaviourRequirement::Movement);
	default Requirements.AddBlock(EBasicBehaviourRequirement::Weapon);

	UIslandPunchotronFollowSplineComponent SplineFollowComp;
	UHazeSplineComponent Spline;
	UIslandPunchotronSettings Settings;
	UHazeCapsuleCollisionComponent CollisionComp;
	AAIIslandPunchotron Punchotron;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		SplineFollowComp = UIslandPunchotronFollowSplineComponent::Get(Owner);
		Settings = UIslandPunchotronSettings::GetSettings(Owner);
		UBasicAIMovementSettings::SetSplineFollowCaptureDistance(Owner, 10000.0, Owner, EHazeSettingsPriority::Defaults);
		CollisionComp = Cast<AHazeCharacter>(Owner).CapsuleComponent;
		Punchotron = Cast<AAIIslandPunchotron>(Owner);
	}


	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Super::ShouldActivate())
			return false;
		if (SplineFollowComp.Spline == nullptr)
			return false;
		if (!TargetComp.HasValidTarget())
			return false;
		if (TargetComp.Target.GetDistanceTo(Owner) < Settings.FollowSplineStartMinDistToPlayer)
			return false;
		if (IsInSameWedgeAsPlayer())
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Super::ShouldDeactivate())
			return true;
		if (TargetComp.Target.GetDistanceTo(Owner) < Settings.FollowSplineStopMinDistToPlayer)
			return true;
		if (IsInSameWedgeAsPlayer())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
		Spline = SplineFollowComp.Spline;
		CollisionComp.AddComponentCollisionBlocker(this);
		UIslandPunchotronEffectHandler::Trigger_OnJetsStart(Owner, FIslandPunchotronJetsParams(Punchotron.LeftJetLocation, Punchotron.RightJetLocation));
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		CollisionComp.RemoveComponentCollisionBlocker(this);
		UIslandPunchotronEffectHandler::Trigger_OnJetsStop(Owner);
		Cooldown.Set(4.0);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		DestinationComp.MoveAlongSpline(Spline, Settings.FollowSplineSpeed);

#if EDITOR
		//Owner.bHazeEditorOnlyDebugBool = true;
		if (Owner.bHazeEditorOnlyDebugBool) 
			Spline.DrawDebug(200, Thickness = 10.0);
#endif
	}

	// Check if on the same side of the battle arena specified as an angle wedge from center of spline
	bool IsInSameWedgeAsPlayer() const
	{
		FVector ToPlayer = (TargetComp.Target.ActorLocation - SplineFollowComp.Spline.Owner.ActorLocation).GetSafeNormal2D();
		FVector ToOwner = (Owner.ActorLocation - SplineFollowComp.Spline.Owner.ActorLocation).GetSafeNormal2D();

		if (ToPlayer.DotProduct(ToOwner) > Math::Cos(Math::DegreesToRadians(50)))
			return true;

		return false;
	}
}
