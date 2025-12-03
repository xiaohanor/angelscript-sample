class UGoatLaserEyesCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	
	default TickGroup = EHazeTickGroup::Gameplay;
	default TickGroupOrder = 100;

	UGenericGoatPlayerComponent GoatComp;
	UGoatLaserEyesPlayerComponent LaserEyesComp;
	UPlayerAimingComponent AimComp;

	UGoatLaserEyesResponseComponent CurrentTargetComp;

	UNiagaraComponent ImpactEffectComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		GoatComp = UGenericGoatPlayerComponent::Get(Player);
		LaserEyesComp = UGoatLaserEyesPlayerComponent::Get(Player);
		AimComp = UPlayerAimingComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!IsActioning(ActionNames::PrimaryLevelAbility))
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!IsActioning(ActionNames::PrimaryLevelAbility))
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		LaserEyesComp.LeftLaserComp = Niagara::SpawnLoopingNiagaraSystemAttached(LaserEyesComp.LaserSystem, GoatComp.CurrentGoat.LeftEyeComp);
		LaserEyesComp.RightLaserComp = Niagara::SpawnLoopingNiagaraSystemAttached(LaserEyesComp.LaserSystem, GoatComp.CurrentGoat.RightEyeComp);

		Player.EnableStrafe(this);

		AimComp.StartAiming(this, LaserEyesComp.AimSettings);

		CurrentTargetComp = nullptr;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		LaserEyesComp.LeftLaserComp.DeactivateImmediate();
		LaserEyesComp.RightLaserComp.DeactivateImmediate();

		Player.DisableStrafe(this);

		AimComp.StopAiming(this);

		if (CurrentTargetComp != nullptr)
			CurrentTargetComp.StopLaser();

		if (ImpactEffectComp != nullptr)
		{
			ImpactEffectComp.Deactivate();
			ImpactEffectComp = nullptr;
		}
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		LaserEyesComp.LeftLaserComp.SetNiagaraVariableVec3("BeamStart", GoatComp.CurrentGoat.LeftEyeComp.WorldLocation);
		LaserEyesComp.RightLaserComp.SetNiagaraVariableVec3("BeamStart", GoatComp.CurrentGoat.RightEyeComp.WorldLocation);

		FVector AimTarget;

		FAimingResult AimResult = AimComp.GetAimingTarget(this);
		if (AimResult.AutoAimTarget != nullptr)
		{
			AimTarget = AimResult.AutoAimTargetPoint;

			UGoatLaserEyesResponseComponent ResponseComp = UGoatLaserEyesResponseComponent::Get(AimResult.AutoAimTarget.Owner);
			if (ResponseComp != nullptr)
			{
				if (CurrentTargetComp != ResponseComp)
				{
					if (CurrentTargetComp != nullptr)
						CurrentTargetComp.StopLaser();

					CurrentTargetComp = ResponseComp;
					CurrentTargetComp.StartLaser();
				}

				ResponseComp.Update();
			}
			else
			{
				if (CurrentTargetComp != nullptr)
				{
					CurrentTargetComp.StopLaser();
					CurrentTargetComp = nullptr;
				}
			}
		}
		else
		{
			AimTarget = AimResult.AimOrigin + (AimResult.AimDirection * 2000.0);
			if (CurrentTargetComp != nullptr)
			{
				CurrentTargetComp.StopLaser();
				CurrentTargetComp = nullptr;
			}
		}

		FHazeTraceSettings Trace = Trace::InitChannel(ECollisionChannel::ECC_Visibility);
		Trace.UseLine();
		
		FHitResult Hit = Trace.QueryTraceSingle(AimResult.AimOrigin, AimTarget);

		FVector HitLoc = Hit.bBlockingHit ? Hit.ImpactPoint : Hit.TraceEnd;

		LaserEyesComp.LeftLaserComp.SetNiagaraVariableVec3("BeamEnd", HitLoc + (Player.ActorRightVector * -15.0));
		LaserEyesComp.RightLaserComp.SetNiagaraVariableVec3("BeamEnd", HitLoc + (Player.ActorRightVector * 15.0));

		if (Hit.bBlockingHit)
		{
			if (ImpactEffectComp == nullptr)
			{
				ImpactEffectComp = Niagara::SpawnLoopingNiagaraSystemAttached(LaserEyesComp.ImpactSystem, Player.RootComponent);
				ImpactEffectComp.SetWorldLocationAndRotation(Hit.ImpactPoint, Hit.ImpactNormal.Rotation());
			}
			else
			{
				ImpactEffectComp.SetWorldLocationAndRotation(Hit.ImpactPoint, Hit.ImpactNormal.Rotation());
			}
		}
		else
		{
			if (ImpactEffectComp != nullptr)
			{
				ImpactEffectComp.Deactivate();
				ImpactEffectComp = nullptr;
			}
		}
	}
}