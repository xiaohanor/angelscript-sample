struct FGravityBikeFreeJumpTriggerBlockJumpActivateParams
{
	UGravityBikeFreeJumpTriggerComponent JumpTrigger;
};

class UGravityBikeFreeJumpTriggerBlockJumpCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(CapabilityTags::Movement);

	default TickGroup = EHazeTickGroup::BeforeMovement;

	AGravityBikeFree GravityBike;
	UGravityBikeFreeJumpComponent JumpComp;

	UGravityBikeFreeJumpTriggerComponent CurrentJumpTrigger;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		GravityBike = Cast<AGravityBikeFree>(Owner);
		JumpComp = UGravityBikeFreeJumpComponent::Get(GravityBike);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FGravityBikeFreeJumpTriggerBlockJumpActivateParams& Params) const
	{
		auto JumpTriggerComp = GetFirstValidTrigger();
		if(JumpTriggerComp == nullptr)
			return false;

		Params.JumpTrigger = JumpTriggerComp;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(!CurrentJumpTrigger.ShouldBlockJump(GravityBike))
		{
			if(CurrentJumpTrigger.bDeactivateOnlyIfGrounded)
			{
				if(GravityBike.IsAirborne.Get())
					return false;
			}
		}

		if(GetFirstValidTrigger() == nullptr)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FGravityBikeFreeJumpTriggerBlockJumpActivateParams Params)
	{
		CurrentJumpTrigger = Params.JumpTrigger;
		ApplyTriggerSettings(CurrentJumpTrigger);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		ClearTrigger(CurrentJumpTrigger);
		CurrentJumpTrigger = nullptr;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(HasControl())
		{
			if(!CurrentJumpTrigger.ShouldBlockJump(GravityBike))
			{
				auto NewJumpTrigger = GetFirstValidTrigger();
				if(NewJumpTrigger != nullptr)
					CrumbSwapTrigger(CurrentJumpTrigger, NewJumpTrigger);
			}
		}
	}

	UGravityBikeFreeJumpTriggerComponent GetFirstValidTrigger() const
	{
		for(int i = 0; i < JumpComp.JumpTriggers.Num(); i++)
		{
			if(JumpComp.JumpTriggers[i].ShouldBlockJump(GravityBike))
				return JumpComp.JumpTriggers[i];
		}

		return nullptr;
	}

	void ApplyTriggerSettings(const UGravityBikeFreeJumpTriggerComponent Trigger) const
	{
		UGravityBikeFreeJumpSettings::SetCanApplyJumpImpulse(GravityBike, false, this);
	}

	void ClearTrigger(const UGravityBikeFreeJumpTriggerComponent Trigger) const
	{
		UGravityBikeFreeJumpSettings::ClearCanApplyJumpImpulse(GravityBike, this);
	}

	UFUNCTION(CrumbFunction)
	void CrumbSwapTrigger(const UGravityBikeFreeJumpTriggerComponent Old, const UGravityBikeFreeJumpTriggerComponent New)
	{
		check(CurrentJumpTrigger == Old);
		ClearTrigger(Old);
		ApplyTriggerSettings(New);
	}
};