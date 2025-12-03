

class UCameraAssistMovementActivationCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CameraTags::Camera);
	default CapabilityTags.Add(CameraTags::CameraChaseAssistance);
	default CapabilityTags.Add(CameraTags::CameraChaseAssistanceActivation);

	// [Eman] Don't auto-block camera chase assistance via movement, do it explicitly instead
	// default CapabilityTags.Add(CapabilityTags::Movement);

	default TickGroup = EHazeTickGroup::AfterGameplay;
	default TickGroupOrder = 200;
    default DebugCategory = CameraTags::Camera;

	UCameraUserComponent User;
	UHazeMovementComponent MoveComp;
	UPlayerTargetablesComponent PlayerTargetablesComponent;
	UCameraAssistComponent AssistComp;
	UCameraSettings CameraSettings;
	UPlayerCameraAssistSettings ChaseValidationSettings;
	FHazeAcceleratedFloat TargetValue;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		User = UCameraUserComponent::Get(Player);
		AssistComp = UCameraAssistComponent::Get(Player);
		MoveComp = UHazeMovementComponent::Get(Player);
		PlayerTargetablesComponent = UPlayerTargetablesComponent::Get(Player);
		CameraSettings = UCameraSettings::GetSettings(Player);
		ChaseValidationSettings = UPlayerCameraAssistSettings::GetSettings(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(CameraSettings.HasActiveKeepInView())
			return false;

		if(Player.HasAnyActivePointOfInterest())
			return false;

		if(MoveComp.IsOnAnyGround())
			return true;

		if(MoveComp.IsInAir())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(CameraSettings.HasActiveKeepInView())
			return true;

		if(Player.HasAnyActivePointOfInterest())
			return true;

		if(MoveComp.IsOnAnyGround())
			return false;

		if(MoveComp.IsInAir())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		TargetValue.SnapTo(1);
		AssistComp.AddAssistEnabled(this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		AssistComp.RemoveAssistEnabled(this);
		AssistComp.ContextualMultiplier.Clear(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float OriginalDeltaTime)
	{
		const float DeltaTime = Time::GetCameraDeltaSeconds();
		float NewTargetValue = 1;
		float TargetValueBlendTime = 1;

		if(ChaseValidationSettings.bUpdateChaseAssistBasedOnPhysicsStateType)
			UpdateBasedOnPhysicsStateType(DeltaTime, NewTargetValue, TargetValueBlendTime);

		if(ChaseValidationSettings.bUpdateChaseAssistBasedOnContextualTargetType)
			UpdateBasedOnContextualTargetType(DeltaTime, NewTargetValue, TargetValueBlendTime);

		if(ChaseValidationSettings.bUpdateChaseAssistBasedOnPitchWithUpwardsCutoff)
			UpdateBasedOnPitchLookUpCutOff(DeltaTime, NewTargetValue, TargetValueBlendTime);

		if(ChaseValidationSettings.bUpdateChaseAssistBasedOnPitch)
			UpdateBasedOnPitch(DeltaTime, NewTargetValue, TargetValueBlendTime);

		if(ChaseValidationSettings.bUpdateChaseBasedOnAiming)
			UpdateBasedOnAiming(DeltaTime, NewTargetValue, TargetValueBlendTime);

		TargetValue.AccelerateTo(NewTargetValue, TargetValueBlendTime, DeltaTime);
		AssistComp.ContextualMultiplier.Apply(TargetValue.Value, this, EInstigatePriority::Low);
	}

	/**
	 * Default function for checking the movements physics state
	 */
	void UpdateBasedOnPhysicsStateType(float DeltaTime, float& OutTargetValue, float& OutTargetValueBlendTime) const
	{
		if(MoveComp.IsInAir())
		{
			OutTargetValue *= 0.5;
			OutTargetValueBlendTime *= 0.5;
		}
	}

	/**
	 * Default function for basing the chase assist amount if we are aiming or not
	 */
	void UpdateBasedOnAiming(float DeltaTime, float& OutTargetValue, float& OutTargetValueBlendTime) const
	{
		if(User.IsAiming())
		{
			OutTargetValue = 0;
			OutTargetValueBlendTime = 0;
		}
	}

	/**
	 * Default function for handling found contextual move targetables being visible or not
	 */
	void UpdateBasedOnContextualTargetType(float DeltaTime, float& OutTargetValue, float& OutTargetValueBlendTime) const
	{
		// If we have a prime target in sight, we stop the chase quickly
		auto PrimTarget = PlayerTargetablesComponent.GetPrimaryTargetForCategory(n"ContextualMoves");
		if(PrimTarget != nullptr)
		{
			OutTargetValue *= 0.05;
			OutTargetValueBlendTime *= 0.05;
			return;
		}

		TArray<UTargetableComponent> Targetables;
		PlayerTargetablesComponent.GetVisibleTargetables(n"ContextualMoves", Targetables);

		// If we have any possible targetables in sight
		// we slow down the chase assist a lot
		for(auto Target : Targetables)
		{
			FVector TargetLocation = Target.WorldLocation;
			FVector DirToLocation = (TargetLocation - User.ViewLocation).GetSafeNormal();

			float Dot = DirToLocation.DotProduct(User.ViewRotation.ForwardVector);
			if(Dot > 0.81)
			{
				OutTargetValue *= 0.25;
				OutTargetValueBlendTime *= 0.1;
				return;
			}
		}	
	}

	/**
	 * Default function for disabling the chase assist based on the pitch amount
	 */
	void UpdateBasedOnPitchLookUpCutOff(float DeltaTime, float& OutTargetValue, float& OutTargetValueBlendTime) const
	{
		// If we are looking up, we don't apply any rotation help at all, 
		// since that usually means that we are looking at something
		if(Player.ViewRotation.ForwardVector.DotProduct(Player.MovementWorldUp) > 0.25)
		{
			OutTargetValue = 0;
			OutTargetValueBlendTime *= 0.25;
		}
		// The more pitch we have, the less we should be rotating
		else
		{
			float PitchMultiplier = 1 - Player.ViewRotation.ForwardVector.DotProductLinear(Player.MovementWorldUp);
			const float PitchBoarder = 0.3;
			PitchMultiplier = Math::Max(PitchMultiplier - PitchBoarder, 0.0) / (1 - PitchBoarder);
			PitchMultiplier = Math::EaseOut(0, 1, PitchMultiplier, 2);
			OutTargetValue *= PitchMultiplier;
		}
	}

	void UpdateBasedOnPitch(float DeltaTime, float& OutTargetValue, float& OutTargetValueBlendTime) const
	{
			float PitchMultiplier = 1 - Player.ViewRotation.ForwardVector.DotProductLinear(Player.MovementWorldUp);
			const float PitchBoarder = 0.3;
			PitchMultiplier = Math::Max(PitchMultiplier - PitchBoarder, 0.0) / (1 - PitchBoarder);
			PitchMultiplier = Math::EaseOut(0, 1, PitchMultiplier, 2);
			OutTargetValue *= PitchMultiplier;
	}
};