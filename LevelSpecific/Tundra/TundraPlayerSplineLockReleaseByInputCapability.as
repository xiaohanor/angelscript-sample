class UTundraPlayerSplineLockReleaseByInputCapability : UHazePlayerCapability
{
	/**
	 * THIS CAPABILITY IS FOR USE WITH THE "TundraConditionalPlayerSplineLockZone"
	 * AND NOT GENERIC SPLINE LOCKING
	 */

	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(CapabilityTags::Movement);

	default TickGroup = EHazeTickGroup::BeforeMovement;
	default TickGroupOrder = 95;

	UPlayerSplineLockComponent SplineLockComp;
	UTundraPlayerSplineLockReleaseByInputComponent ReleaseByInputComp;
	UPlayerMovementComponent MoveComp;

	const float INPUT_TIME_REQUIRED = 0.5;
	const float INPUT_DOT_REQUIRED = 0.5;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		SplineLockComp = UPlayerSplineLockComponent::Get(Player);
		ReleaseByInputComp = UTundraPlayerSplineLockReleaseByInputComponent::GetOrCreate(Player);
		MoveComp = UPlayerMovementComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
	}

	bool ValidateInputRequirement() const
	{
		FVector NoneLockedInput = MoveComp.GetNonLockedMovementInput();
		FVector ViewForward = Player.GetViewRotation().ForwardVector.ConstrainToPlane(MoveComp.WorldUp);
		float InputViewDot = NoneLockedInput.DotProduct(ViewForward);

		if(InputViewDot < -INPUT_DOT_REQUIRED)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (ReleaseByInputComp.ActiveSplineLockZone == nullptr)
			return false;

		if (!SplineLockComp.HasActiveSplineLock())
			return false;

		if (!ValidateInputRequirement())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate(FTundraPlayerSplineReleaseByInputDeactivationParams& Params) const
	{
		if (ReleaseByInputComp.ActiveSplineLockZone == nullptr)
			return true;

		if (ActiveDuration >= INPUT_TIME_REQUIRED)
		{
			Params.bDeactivatedByInput = true;
			return true;
		}

		if (!ValidateInputRequirement())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{

	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FTundraPlayerSplineReleaseByInputDeactivationParams Params)
	{
		if(Params.bDeactivatedByInput)
		{
			SplineLockComp.DeactivateSplineZone(ReleaseByInputComp.ActiveSplineLockZone);
			ReleaseByInputComp.ActiveSplineLockZone = nullptr;
		}
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
	}
};

struct FTundraPlayerSplineReleaseByInputDeactivationParams
{
	bool bDeactivatedByInput = false;
}