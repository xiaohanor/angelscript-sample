class UGravityWhipTorHammerCapability : UGravityWhipGrabCapability
{
	default bForceFeedbackBasedOnGrabMovement = false;
	default DebugCategory = GravityWhipTags::GravityWhip;

	default GrabMode = EGravityWhipGrabMode::TorHammer;
	default bAllowTurnIntoHit = false;

	UPlayerAimingComponent AimComp;
	USkylineTorHammerStolenPlayerComponent StolenComp;
	float ThrowStartTime = 0.0;

	const float BufferWindow = 0.5;

	float AttackStartTime = 0.0;
	bool bIsAttacking = false;
	bool bDoneFirstAttack = false;
	bool bBufferedAttack = false;

	FAimingResult AimResult;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		
		AimComp = UPlayerAimingComponent::Get(Owner);
		StolenComp = USkylineTorHammerStolenPlayerComponent::GetOrCreate(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!UserComp.IsGrabbingAny())
			return true;

		if (UserComp.GetPrimaryGrabMode() != GrabMode)
			return true;
		
		if (!StolenComp.bStolen && ActiveDuration > 0.5)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(const FGravityWhipGrabActivationParams& ActivationParams)
	{
		Super::OnActivated(ActivationParams);
		StolenComp.bAttack = false;
		bDoneFirstAttack = false;

		if (UserComp.SlingCameraSettings != nullptr)
			Player.ApplyCameraSettings(UserComp.SlingCameraSettings, 1.0, this, SubPriority = 62);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.ClearCameraSettingsByInstigator(this, 1.0);
		StolenComp.bAttack = false;
		Super::OnDeactivated();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		Super::TickActive(DeltaTime);

		if (bIsAttacking)
		{
			if (Time::GetGameTimeSince(AttackStartTime) > StolenComp.AttackDuration)
			{
				bIsAttacking = false;
				StolenComp.bAttack = false;
				UserComp.bTorHammerAttackStart = false;
				UserComp.bTorHammerAttackEnd = true;
			}
			else if (Time::GetGameTimeSince(AttackStartTime) > 0.1)
			{
				StolenComp.bAttack = false;
				UserComp.bTorHammerAttackStart = false;
			}

			if (WasActionStarted(ActionNames::PrimaryLevelAbility)
			&& Time::GetGameTimeSince(AttackStartTime) > StolenComp.AttackDuration - BufferWindow)
			{
				bBufferedAttack = true;
			}
		}
		else
		{
			// Check for new presses or 
			if (bDoneFirstAttack)
			{
				if (WasActionStarted(ActionNames::PrimaryLevelAbility) || bBufferedAttack)
				{
					bBufferedAttack = false;
					CrumbStartAttack();
				}
			}
			else
			{
				if (!IsActioning(ActionNames::PrimaryLevelAbility))
				{
					// Only launch the first attack on release if we held for a while
					if (ActiveDuration > 1.0)
						CrumbStartAttack();
					bDoneFirstAttack = true;
				}
			}
		}
	}

	UFUNCTION(CrumbFunction)
	void CrumbStartAttack()
	{
		bIsAttacking = true;
		StolenComp.bAttack = true;
		UserComp.bTorHammerAttackStart = true;
		UserComp.bTorHammerAttackEnd = false;
		AttackStartTime = Time::GameTimeSeconds;

		ASkylineTorHammer Hammer = ActorList::GetSingle(ASkylineTorHammer);
		if (IsValid(Hammer))
			USkylineTorHammerEventHandler::Trigger_OnWhipGrabbedSwing(Hammer);
	}
}