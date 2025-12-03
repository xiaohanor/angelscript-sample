class UCoastTrainCircuitLockeAttackBehaviour : UBasicBehaviour
{
	// Movement only (which is replicated separately)
	default CompoundNetworkSupport = EHazeCompoundNetworkSupport::ActivatesOnControlOnly;

	UCoastTrainCircuitLockeSplineMoveComponent SplineComp;
	UBasicAIProjectileLauncherComponent Launcher;

	float AttackDuration = 1;
	bool bArrived;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		SplineComp = UCoastTrainCircuitLockeSplineMoveComponent::GetOrCreate(Owner);
		Launcher = UBasicAIProjectileLauncherComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Super::ShouldActivate())
			return false;
		if(SplineComp.bActioned)
			return false;
		if(SplineComp.CurrentSpline == nullptr)
			return false;
		FHazeSplinePoint Point = SplineComp.CurrentSpline.Spline.SplinePoints[1];
		FVector WorldLocation = SplineComp.CurrentSpline.ActorTransform.TransformPosition(Point.RelativeLocation);
		if(!Owner.ActorLocation.IsWithinDist(WorldLocation, 100))
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Super::ShouldDeactivate())
			return true;
		if(ActiveDuration > AttackDuration)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
		SplineComp.bActioned = true;

		UBasicAIAnimationFeatureAdditiveShooting ShootingFeature = Cast<UBasicAIAnimationFeatureAdditiveShooting>(AnimComp.GetFeatureByClass(UBasicAIAnimationFeatureAdditiveShooting));
		if ((ShootingFeature != nullptr) && (ShootingFeature.SingleShot != nullptr))
			Owner.PlayAdditiveAnimation(FHazeAnimationDelegate(), ShootingFeature.SingleShot);

		for(AHazePlayerCharacter Player: Game::Players)
		{
			FVector Dir = (Player.ActorCenterLocation - Launcher.LaunchLocation).GetSafeNormal();
			FVector Velocity = Dir * 1000;

			UBasicAIProjectileComponent Projectile = Launcher.Launch(Velocity);
			auto Cart = Cast<ACoastTrainCart>(Owner.AttachParentActor).Driver.GetCartClosestToPlayer(Player);
			check(Cart != nullptr);
			Projectile.Owner.AttachToActor(Cart, AttachmentRule = EAttachmentRule::KeepWorld);

			auto ProjectileActor = Cast<ACoastTrainDroneProjectile>(Projectile.Owner);
			FTransform CartTransform = Owner.AttachParentActor.ActorTransform;
			ProjectileActor.LocalVelocity = CartTransform.InverseTransformVectorNoScale(Projectile.Velocity);
			ProjectileActor.Mesh1PreviousLocation = ProjectileActor.Mesh.WorldLocation;
			ProjectileActor.Mesh2PreviousLocation = ProjectileActor.Mesh2.WorldLocation;
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		Owner.ClearSettingsByInstigator(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		DestinationComp.RotateTowards(Game::Mio.ActorLocation);
	}
}