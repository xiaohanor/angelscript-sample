/**
 * Optional capability that can be added to reset the 2D aim back to the player facing if this is natural
 * based on the input.
 * 
 * This is not a default capability, and makes some assumptions on how the gameplay works:
 * - The player moves with left stick
 * - The player facing is an appropriate aim direction
 * - The player fires with RT (delays aim reset until not firing anymore)
 * 
 * If your use case does not match these assumptions, you can make your own reset to facing capability.
 */
class UAiming2DResetToFacingCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(n"AimingGamepadInput2D");

	default TickGroup = EHazeTickGroup::Input;
	default TickGroupOrder = 101;

	const float NoAimInputDelay = 0.6;
	float NoAimInputTimer = 0.0;

	const float NoFireInputDelay = 1.0;
	float NoFireInputTimer = 0.0;

	UPlayerAimingComponent AimComp;
	FVector2D PreviousMoveInput;

	bool bIsAimReset = true;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		AimComp = UPlayerAimingComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!AimComp.HasAiming2DConstraint())
			return false;

		if (!Player.IsUsingGamepad())
			return false;

		if (!HasControl())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!AimComp.HasAiming2DConstraint())
			return true;

		if (!Player.IsUsingGamepad())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		NoAimInputTimer = MAX_flt;
		NoFireInputTimer = MAX_flt;
		PreviousMoveInput = GetAttributeVector2D(AttributeVectorNames::MovementRaw);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		AimComp.ClearAimingRayOverride(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FVector2D AimInput = GetAttributeVector2D(n"GamepadRightStick_NoDeadZone");
		FVector2D MoveInput = GetAttributeVector2D(AttributeVectorNames::MovementRaw);
		bool bFireInput = IsActioning(ActionNames::WeaponFire);

		if (AimInput.Size() > 0.3)
			NoAimInputTimer = 0.0;
		else
			NoAimInputTimer += DeltaTime;

		if (bFireInput)
			NoFireInputTimer = 0.0;
		else
			NoFireInputTimer += DeltaTime;

		// If we're not firing, not aiming, but changing our movement input, always override
		if (!PreviousMoveInput.Equals(MoveInput, 0.2) && NoAimInputTimer >= NoAimInputDelay && NoFireInputTimer > 0.0)
		{
			NoFireInputTimer = MAX_flt;
			NoAimInputTimer = MAX_flt;
			PreviousMoveInput = MoveInput;
		}
		else if (NoFireInputTimer == 0.0 || NoAimInputTimer == 0.0)
		{
			PreviousMoveInput = MoveInput;
		}

		if (NoAimInputTimer >= NoAimInputDelay && NoFireInputTimer >= NoFireInputDelay)
			bIsAimReset = true;
		if (NoAimInputTimer == 0.0)
			bIsAimReset = false;

		if (bIsAimReset)
		{
			const FVector PlaneNormal = AimComp.Get2DConstraintPlaneNormal();
			const FVector AimCenter = AimComp.Get2DAimingCenter();

			const FVector AimDirection = Player.ActorForwardVector.VectorPlaneProject(PlaneNormal).GetSafeNormal();

			FAimingRay Ray;
			Ray.AimingMode = EAimingMode::Directional2DAim;
			Ray.Origin = AimCenter;
			Ray.Direction = AimDirection;
			Ray.ConstraintPlaneNormal = PlaneNormal;
			Ray.bIsGivingAimInput = false;
			AimComp.ApplyAimingRayOverride(Ray, this, EInstigatePriority::High);
		}
		else
		{
			AimComp.ClearAimingRayOverride(this);
		}
	}
};