class UAiming2DSyncDirectionCapability : UHazePlayerCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default TickGroup = EHazeTickGroup::Input;
	default TickGroupOrder = 200;

	UPlayerAimingComponent AimComp;
	UHazeCrumbSyncedRotatorComponent SyncedAimDirection;
	bool bIsGivingAimInput = false;
	
	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		AimComp = UPlayerAimingComponent::Get(Player);
		SyncedAimDirection = UHazeCrumbSyncedRotatorComponent::Create(Player, n"Synced2DAimDirection");
		SyncedAimDirection.OverrideSyncRate(EHazeCrumbSyncRate::High);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Network::IsGameNetworked())
			return false;

		if (!AimComp.HasAiming2DConstraint())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!AimComp.HasAiming2DConstraint())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		SyncedAimDirection.TransitionSync(this);
		bIsGivingAimInput = false;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		AimComp.ClearAimingRayOverride(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (HasControl())
		{
			auto Ray = AimComp.GetPlayerAimingRay();

			// Send over when our input giving flag changes
			if (Ray.bIsGivingAimInput != bIsGivingAimInput)
				CrumbSetIsInputGiven(Ray.bIsGivingAimInput);
			SyncedAimDirection.Value = FRotator::MakeFromX(Ray.Direction);
		}
		else
		{
			// In some cases the constraint is cleared on the remote side before control so the capability still ticks, in that case, just return and wait for deactivation.
			if(!AimComp.HasAiming2DConstraint())
				return;

			FVector AimDirection = SyncedAimDirection.Value.ForwardVector;

			const FVector PlaneNormal = AimComp.Get2DConstraintPlaneNormal();
			const FVector AimCenter = AimComp.Get2DAimingCenter();

			FAimingRay Ray;
			Ray.AimingMode = EAimingMode::Directional2DAim;
			Ray.Origin = AimCenter;
			Ray.Direction = AimDirection;
			Ray.ConstraintPlaneNormal = PlaneNormal;
			Ray.bIsGivingAimInput = bIsGivingAimInput;
			AimComp.ApplyAimingRayOverride(Ray, this, EInstigatePriority::High);
		}
	}

	UFUNCTION(CrumbFunction)
	void CrumbSetIsInputGiven(bool bNewInputGiven)
	{
		bIsGivingAimInput = bNewInputGiven;
	}
}