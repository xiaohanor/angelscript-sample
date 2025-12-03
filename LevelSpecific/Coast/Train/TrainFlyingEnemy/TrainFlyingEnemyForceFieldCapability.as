class UTrainFlyingEnemyForcefieldCapability : UHazeCapability
{
	ATrainFlyingEnemy Enemy;
	UTrainFlyingEnemyForceFieldComponent Forcefield;
	UGrapplePointComponent GrapplePoint;
	UTrainFlyingEnemySettings Settings;
	float BreachTime = -BIG_NUMBER;
	bool bWasBreached = false;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Enemy = Cast<ATrainFlyingEnemy>(Owner);
		Forcefield = UTrainFlyingEnemyForceFieldComponent::Get(Owner);
		UCoastShoulderTurretGunResponseComponent::Get(Owner).OnBulletHit.AddUFunction(this, n"OnHitByTurret");
		Settings = UTrainFlyingEnemySettings::GetSettings(Owner);

		Forcefield.AddComponentVisualsBlocker(this);
		Forcefield.AddComponentCollisionBlocker(this);
		Forcefield.InitializeVisuals();

		GrapplePoint = UGrapplePointComponent::Get(Owner); 
		GrapplePoint.Disable(this);
	}

	UFUNCTION()
	private void OnHitByTurret(FCoastShoulderTurretBulletHitParams Params)
	{
		if (!Params.PlayerInstigator.HasControl())
			return;
		FVector LocalImpactPoint = Forcefield.WorldTransform.InverseTransformPosition(Params.ImpactPoint);
		CrumbDamageForceField(Params.Damage, LocalImpactPoint);
	}

	UFUNCTION(CrumbFunction)
	void CrumbDamageForceField(float AttackDamage, FVector LocalImpactPoint)
	{
		Forcefield.TakeDamage(Settings.ForceFieldDamageFromTurretsFactor * AttackDamage, LocalImpactPoint);
		if (Forcefield.IsBreached())
			BreachTime = Time::GameTimeSeconds; // Update breach time as long as we're taking breaching damage
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (Enemy.bDestroyedByPlayer)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Enemy.bDestroyedByPlayer && Forcefield.AccIntegrity.Value < 0.001)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Forcefield.RemoveComponentVisualsBlocker(this);
		Forcefield.RemoveComponentCollisionBlocker(this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Forcefield.AddComponentVisualsBlocker(this);
		Forcefield.AddComponentCollisionBlocker(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		// Forcefield is locally simulated based on crumbed damage so it will match player expectation.	
		if (Enemy.bDestroyedByPlayer)
			Forcefield.TakeDamage(Forcefield.CurrentIntegrity, FVector(Forcefield.BoundsRadius, 0.0, 0.0));

		if (Forcefield.IsBreached() && !bWasBreached)
		{
			// New breach, allow grapple!
			bWasBreached = true;
			GrapplePoint.Enable(this);
		}
		if (Time::GetGameTimeSince(BreachTime) > Settings.ForceFieldBreachPauseDuration)
		{
			Forcefield.Regenerate(DeltaTime / Math::Max(0.01, Settings.ForceFieldBreachRecoveryDuration));

			if (bWasBreached && (Forcefield.CurrentIntegrity > 0.6))
			{
				// Back up!
				bWasBreached = false;
				GrapplePoint.Disable(this);
			}
		}

		Forcefield.UpdateVisuals(DeltaTime);	
	}
}
