class USandHandShootCapability : UHazePlayerCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default CapabilityTags.Add(SandHand::Tags::SandHand);
	default CapabilityTags.Add(SandHand::Tags::SandHandShootCapability);

	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 99;

	USandHandPlayerComponent PlayerComp;
	UPlayerAimingComponent AimComp;
	UProjectileProximityManagerComponent ProjectileProximityComp;

	const float CapabilityDuration = SandHand::ShootDelay + SandHand::AfterShootDelay;

	FVector ShootVector;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		PlayerComp = USandHandPlayerComponent::Get(Owner);
		AimComp = UPlayerAimingComponent::Get(Owner);
		ProjectileProximityComp = UProjectileProximityManagerComponent::GetOrCreate(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!PlayerComp.bSandHandQueued)
			return false;

		if(!AimComp.IsAiming(PlayerComp))
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (ActiveDuration >= CapabilityDuration)
			return true;

		if(!AimComp.IsAiming(PlayerComp))
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		if (HasControl())
		{
			// Fetch fresh hand projectile
			PlayerComp.ReadyProjectile_Control();
		}

		PlayerComp.bSandHandQueued = false;
		PlayerComp.SandHandThrowFrame = Time::FrameNumber;
		PlayerComp.bSandHandHasShot = false;

		Player.Mesh.ResetSubAnimationInstance(EHazeAnimInstEvalType::Override);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		// If we got blocked/died while throwing, destroy the projectile
		if((IsBlocked()))
			PlayerComp.DismissCurrentProjectile(true);
		
		PlayerComp.bSandHandLeft = !PlayerComp.bSandHandLeft;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(PlayerComp.CurrentProjectile == nullptr)
			return;

		PlayerComp.CurrentProjectile.bIsAimingAtTarget = IsAimingAtTarget();

		if (ActiveDuration > SandHand::ShootDelay)
		{
			if (!PlayerComp.bSandHandHasShot && HasControl())
			{
				FAimingResult ShootAimResult = AimComp.GetAimingTarget(PlayerComp);

				FSandHandShotData ShotData;
				ShotData.StartLocation = PlayerComp.CurrentProjectile.ActorLocation;
				ShotData.InitialVelocity = CalculateLaunchVelocity(ShootAimResult);
				ShotData.Target = Cast<USandHandAutoAimTargetComponent>(ShootAimResult.AutoAimTarget);
				ShotData.SandHandProjectile = PlayerComp.CurrentProjectile;

				ShootVector = ShootAimResult.AimDirection;
				CrumbShoot(ShotData);
			}
		}
		else
		{
			const float Alpha = Math::Saturate(ActiveDuration / SandHand::ShootDelay);

			FVector MeshScale = FVector(SandHand::MeshScale, (PlayerComp.bSandHandLeft ? -SandHand::MeshScale : SandHand::MeshScale), SandHand::MeshScale);
			MeshScale = Math::Lerp(FVector(0.01), FVector(SandHand::MeshScale), Alpha);
			PlayerComp.CurrentProjectile.Mesh.SetRelativeScale3D(MeshScale);
		}
	}

	UFUNCTION(CrumbFunction)
	void CrumbShoot(FSandHandShotData ShotData)
	{
		const FVector MeshScale = FVector(SandHand::MeshScale, (PlayerComp.bSandHandLeft ? -SandHand::MeshScale : SandHand::MeshScale), SandHand::MeshScale);
		PlayerComp.CurrentProjectile.Mesh.SetRelativeScale3D(MeshScale);

		// Detach from player and launch
		PlayerComp.CurrentProjectile.DetachFromActor();
		PlayerComp.CurrentProjectile.Shoot(ShotData.InitialVelocity, Player, ShotData.Target, ProjectileProximityComp);

		// Fire shoot effect event
		USandHandEventHandler::Trigger_OnSandHandShot(Player, ShotData);

		PlayerComp.CurrentProjectile = nullptr;
		PlayerComp.bSandHandHasShot = true;
	}

	FVector CalculateLaunchVelocity(FAimingResult ShootAimResult)
	{
		FHazeTraceSettings Trace = Trace::InitChannel(ECollisionChannel::PlayerAiming, n"FireballShoot");
		Trace.UseSphereShape(5.0);

		Trace.IgnoreActor(Owner);
		Trace.IgnoreActor(PlayerComp.CurrentProjectile);

		FVector AimStart = Math::RayPlaneIntersection(ShootAimResult.AimOrigin, ShootAimResult.AimDirection, FPlane(PlayerComp.Owner.ActorLocation, ShootAimResult.AimDirection));

		// Trace to get aiming target
		FVector Target;
		FHitResult HitResult = Trace.QueryTraceSingle(AimStart, AimStart + ShootAimResult.AimDirection.GetSafeNormal() * SandHand::Range);
		if (HitResult.bBlockingHit)
		{
			Target = HitResult.ImpactPoint;
		}
		else
		{
			// Launch blindly otherwise
			Target = AimStart + ShootAimResult.AimDirection.GetSafeNormal() * SandHand::Range;
		}

		const FName HandSocket = PlayerComp.bSandHandLeft ? n"LeftHand" : n"RightHand";
		const FVector SandHandOrigin = Player.Mesh.GetSocketLocation(HandSocket);
		const float HorizontalSpeed = Math::Min(100.0 * Math::Sqrt(SandHandOrigin.Distance(Target)), SandHand::MaxHorizontalVelocity);
		FVector LaunchVelocity = Trajectory::CalculateVelocityForPathWithHorizontalSpeed(SandHandOrigin, Target, SandHand::Gravity, HorizontalSpeed);

		LaunchVelocity.Z = Math::Clamp(LaunchVelocity.Z, -SandHand::MaxHorizontalVelocity, SandHand::MaxHorizontalVelocity);

		return LaunchVelocity;
	}

	bool ShouldRecoil() const
	{
		if (Player.IsAnyCapabilityActive(PlayerMovementTags::ContextualMovement))
			return false;

		UPlayerPerchComponent PlayerPerchComponent = UPlayerPerchComponent::Get(Owner);
		if (PlayerPerchComponent != nullptr)
		{
			if (PlayerPerchComponent.Data.bPerching)
				return false;
		}

		return true;
	}
	
	bool IsAimingAtTarget()
	{
		FAimingResult AimResult = AimComp.GetAimingTarget(PlayerComp);
		if (AimResult.AutoAimTarget != nullptr)
		{
			if (AimResult.AutoAimTarget.Owner != nullptr)
			{
				USandHandResponseComponent SandHandResponseComponent = USandHandResponseComponent::Get(AimResult.AutoAimTarget.Owner);
				if (SandHandResponseComponent != nullptr)
					return true;
			}
		}

		// Look for something if there wasn't an auto aim target
		FHazeTraceSettings Trace = Trace::InitChannel(ETraceTypeQuery::WeaponTraceZoe);
		Trace.UseSphereShape(5);
		Trace.IgnoreActor(Owner);
		Trace.IgnoreActor(PlayerComp.CurrentProjectile);

		FHitResult HitResult = Trace.QueryTraceSingle(AimResult.AimOrigin, AimResult.AimOrigin + AimResult.AimDirection.GetSafeNormal() * SandHand::Range);
		if (HitResult.bBlockingHit)
		{
			if (HitResult.Actor != nullptr)
			{
				USandHandResponseComponent SandHandResponseComponent = USandHandResponseComponent::Get(HitResult.Actor);
				if (SandHandResponseComponent != nullptr)
					return true;
			}
		}

		return false;
	}
}