asset SkylineBossDownSheet of UHazeCapabilitySheet
{
	Capabilities.Add(USkylineBossDownCompoundCapability);
	Components.Add(USkylineBossDownComponent);
};

struct FSkylineBossDownCompoundDeactivateParams
{
	bool bFinished = false;
};

class USkylineBossDownCompoundCapability : USkylineBossCompoundCapability
{
	default CapabilityTags.Add(SkylineBossTags::SkylineBossDown);

	USkylineBossDownComponent DownComp;	

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		
		DownComp = USkylineBossDownComponent::Get(Boss);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(Boss.IsStateActive(ESkylineBossState::Down))
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate(FSkylineBossDownCompoundDeactivateParams& Params) const
	{
		// We can never rise while bikes are jumping!
		if (Boss.HalfPipeJumpComponent.AreGravityBikesJumping())
			return false;

		if(DownComp.bShouldRise)
		{
			Params.bFinished = true;
			return true;
		}

		if(!Boss.IsStateActive(ESkylineBossState::Down))
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool PostChildrenShouldDeactivate(FSkylineBossDownCompoundDeactivateParams& Params) const
	{
		if(!IsAnyChildCapabilityActive())
		{
			Params.bFinished = true;
			return true;
		}

		if(DownComp.bShouldRise)
		{
			Params.bFinished = true;
			return true;
		}

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Boss.SetState(ESkylineBossState::Down);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FSkylineBossDownCompoundDeactivateParams Params)
	{
		ResetCompoundNodes();

		DownComp.Reset();

		if(Params.bFinished)
		{
			Boss.SetState(ESkylineBossState::Rise);
		}
	}

	UFUNCTION(BlueprintOverride, Meta = (NoSuperCall))
	UHazeCompoundNode GenerateCompound()
	{
		return UHazeCompoundRunAll()
		.Add(UHazeCompoundRunAll()
			// Movement
			.Add(USkylineBossDownBodyMovementCapability())
			.Add(USkylineBossFeetFollowAnimationCapability())

			// Hatch and Core sequence
			.Add(UHazeCompoundSequence()
				.Then(USkylineBossOpenHatchCapability())
				.Then(USkylineBossExposeCoreCapability())
				.Then(USkylineBossWaitForBikesToLandCapability())
//				.Then(USkylineBossStopExposeCoreCapability())
				.Then(USkylineBossCloseHatchCapability())
			)
			.Add(USkylineBossShockWaveAttackCapability())
//			.Add(USkylineBossPulseAttackCapability())
//			.Add(USkylineBossVulcanoAttackCapability())
		);
	}
};