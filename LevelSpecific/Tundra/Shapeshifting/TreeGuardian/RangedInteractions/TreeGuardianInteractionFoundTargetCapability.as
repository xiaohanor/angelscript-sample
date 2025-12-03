class UTundraPlayerTreeGuardianRangedInteractionFoundTargetCapability : UHazePlayerCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	default TickGroup = EHazeTickGroup::Input;
	default TickGroupOrder = 75;

	UTundraPlayerTreeGuardianComponent TreeGuardianComp;
	UPlayerAimingComponent AimComp;
	UTundraPlayerTreeGuardianRangedInteractionCrosshairWidget CrosshairWidget;

	const float AngleToAddToMaxAngle = 2.0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		TreeGuardianComp = UTundraPlayerTreeGuardianComponent::Get(Player);
		AimComp = UPlayerAimingComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FTundraPlayerTreeGuardianRangedInteractionFoundTargetActivatedParams& Params) const
	{
		if(!AimComp.IsAiming(TreeGuardianComp))
			return false;

		if(TreeGuardianComp.CurrentRangedGrapplePoint != nullptr && !TreeGuardianComp.CurrentRangedGrapplePoint.Velocity.IsNearlyZero())
			return false;

		FAimingResult AimResult = AimComp.GetAimingTarget(TreeGuardianComp);
		if(AimResult.AutoAimTarget == nullptr)
			return false;
		
		auto Targetable = Cast<UTundraTreeGuardianRangedInteractionTargetableComponent>(AimResult.AutoAimTarget);
		if(!Targetable.Velocity.IsNearlyZero())
			return false;

		if(Targetable.IsInteracting())
			return false;

		Params.Targetable = Targetable;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(!AimComp.IsAiming(TreeGuardianComp))
			return true;

		if(TreeGuardianComp.CurrentRangedGrapplePoint != nullptr && !TreeGuardianComp.CurrentRangedGrapplePoint.Velocity.IsNearlyZero())
			return true;

		FAimingResult AimResult = AimComp.GetAimingTarget(TreeGuardianComp);
		if(AimResult.AutoAimTarget == nullptr)
			return true;

		auto Targetable = Cast<UTundraTreeGuardianRangedInteractionTargetableComponent>(AimResult.AutoAimTarget);
		if(!Targetable.Velocity.IsNearlyZero())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FTundraPlayerTreeGuardianRangedInteractionFoundTargetActivatedParams Params)
	{
		CrosshairWidget = TreeGuardianComp.TargetedRangedInteractionCrosshair;
		LocalSetTarget(Params.Targetable);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		LocalResetTarget();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(HasControl())
		{
			FAimingResult AimResult = AimComp.GetAimingTarget(TreeGuardianComp);
			if(AimResult.AutoAimTarget != TreeGuardianComp.CurrentlyFoundRangedInteractionTargetable)
			{
				CrumbSetTarget(Cast<UTundraTreeGuardianRangedInteractionTargetableComponent>(AimResult.AutoAimTarget));
			}
		}

		//Debug::DrawDebugSphere(TreeGuardianComp.CurrentlyFoundRangedInteractionTargetable.WorldLocation, 200.0, 12, FLinearColor::Red);
	}

	UFUNCTION(CrumbFunction)
	private void CrumbSetTarget(UTundraTreeGuardianRangedInteractionTargetableComponent Targetable)
	{
		LocalSetTarget(Targetable);
	}

	private void LocalSetTarget(UTundraTreeGuardianRangedInteractionTargetableComponent Targetable)
	{
		if(TreeGuardianComp.CurrentlyFoundRangedInteractionTargetable != nullptr)
		{
			AddAngleToTargetable(TreeGuardianComp.CurrentlyFoundRangedInteractionTargetable, -AngleToAddToMaxAngle);
			TreeGuardianComp.CurrentlyFoundRangedInteractionTargetable.StopLookingAt();
		}

		Targetable.StartLookingAt();

		TreeGuardianComp.CurrentlyFoundRangedInteractionTargetable = Targetable;
		AddAngleToTargetable(Targetable, AngleToAddToMaxAngle);
		SetAnimAimBools();
	}

	private void LocalResetTarget()
	{
		if(TreeGuardianComp.CurrentlyFoundRangedInteractionTargetable != nullptr)
		{
			TreeGuardianComp.CurrentlyFoundRangedInteractionTargetable.StopLookingAt();
			AddAngleToTargetable(TreeGuardianComp.CurrentlyFoundRangedInteractionTargetable, -AngleToAddToMaxAngle);
			TreeGuardianComp.CurrentlyFoundRangedInteractionTargetable = nullptr;
		}

		ResetAnimAimBools();
	}

	void AddAngleToTargetable(UTundraTreeGuardianRangedInteractionTargetableComponent Targetable, float Angle)
	{
		Targetable.AutoAimMaxAngle += Angle;
		Targetable.AutoAimMaxAngleAtMaxDistance += Angle;
		Targetable.AutoAimMaxAngleMinDistance += Angle;
	}

	void SetAnimAimBools()
	{
		ResetAnimAimBools();

		if(TreeGuardianComp.CurrentlyFoundRangedInteractionTargetable.InteractionType == ETundraTreeGuardianRangedInteractionType::Grapple)
			TreeGuardianComp.RangedInteractAnimData.bAimingOnGrappleInteract = true;
		else if(TreeGuardianComp.CurrentlyFoundRangedInteractionTargetable.InteractionType == ETundraTreeGuardianRangedInteractionType::LifeGive)
			TreeGuardianComp.RangedInteractAnimData.bAimingOnRangedLifeGivingInteract = true;
	}

	void ResetAnimAimBools()
	{
		TreeGuardianComp.RangedInteractAnimData.bAimingOnGrappleInteract = false;
		TreeGuardianComp.RangedInteractAnimData.bAimingOnRangedLifeGivingInteract = false;
	}
}

struct FTundraPlayerTreeGuardianRangedInteractionFoundTargetActivatedParams
{
	UTundraTreeGuardianRangedInteractionTargetableComponent Targetable;
}